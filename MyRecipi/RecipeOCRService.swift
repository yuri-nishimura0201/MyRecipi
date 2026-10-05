import Foundation
import Vision
import ImageIO
import CoreImage

enum RecipeOCRError: Error {
    case imageUnavailable
    case noText
}

struct RecipeOCRDraft {
    var title: String
    var ingredients: [Ingredient]
    var steps: [String]
    var confidence: Float = 1
    var needsReview: Bool { confidence < 0.72 }
}

// 写真の文字を読み取って、料理名・材料・工程に分ける
enum RecipeOCRService {
    private struct TextFragment {
        let text: String
        let box: CGRect
        let confidence: Float
    }

    private struct OCRResult {
        let lines: [String]
        let confidence: Float
    }

    private static let recipeWords = [
        "材料", "食材", "分量", "作り方", "調理工程", "手順", "下準備",
        "大さじ", "小さじ", "適量", "少々", "ひとつまみ", "人分",
        "Ingredients", "Instructions", "Préparation", "Ingrédients",
        "cuillère à soupe", "cuillère à café", "écumer", "émincer", "ciseler",
        "concasser", "mijoter", "déglacer", "réduire", "tamiser", "incorporer"
    ]

    static func makeDraft(from data: Data) async throws -> RecipeOCRDraft {
        try await Task.detached(priority: .userInitiated) {
            guard let source = CGImageSourceCreateWithData(data as CFData, nil),
                  let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                throw RecipeOCRError.imageUnavailable
            }

            let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
            let rawOrientation = (properties?[kCGImagePropertyOrientation] as? NSNumber)?.uint32Value ?? 1
            let orientation = CGImagePropertyOrientation(rawValue: rawOrientation) ?? .up

            var images = [image]
            images.append(contentsOf: enhancedImages(from: image))

            let languageSets = [
                ["ja-JP", "fr-FR", "en-US"],
                ["ja-JP", "en-US"],
                ["fr-FR", "en-US", "ja-JP"]
            ]
            let results = try images.flatMap { candidate in
                try languageSets.map {
                    try recognizeLines(in: candidate, orientation: orientation, languages: $0)
                }
            }
                .filter { !$0.lines.isEmpty }
            guard !results.isEmpty else { throw RecipeOCRError.noText }

            let best = results.max { left, right in
                quality(of: left) < quality(of: right)
            }!
            var draft = parse(best.lines)
            draft.confidence = best.confidence
            return draft
        }.value
    }

    static func makeDraft(from pages: [Data]) async throws -> RecipeOCRDraft {
        guard !pages.isEmpty else { throw RecipeOCRError.imageUnavailable }
        var drafts: [RecipeOCRDraft] = []
        for page in pages { drafts.append(try await makeDraft(from: page)) }
        let first = drafts[0]
        return RecipeOCRDraft(
            title: first.title,
            ingredients: drafts.flatMap(\.ingredients),
            steps: drafts.flatMap(\.steps),
            confidence: drafts.map(\.confidence).min() ?? 0
        )
    }

    private static func recognizeLines(
        in image: CGImage,
        orientation: CGImagePropertyOrientation,
        languages: [String]
    ) throws -> OCRResult {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.automaticallyDetectsLanguage = true
        request.recognitionLanguages = languages
        request.customWords = recipeWords
        request.minimumTextHeight = 0.006

        let handler = VNImageRequestHandler(cgImage: image, orientation: orientation)
        try handler.perform([request])

        let fragments = (request.results ?? []).compactMap { observation -> TextFragment? in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return nil }
            return TextFragment(text: text, box: observation.boundingBox, confidence: candidate.confidence)
        }

        let lines = mergeFragmentsOnSameLine(fragments)
        let confidence = fragments.isEmpty
            ? 0
            : fragments.reduce(0) { $0 + $1.confidence } / Float(fragments.count)
        return OCRResult(lines: lines, confidence: confidence)
    }

    private static func mergeFragmentsOnSameLine(_ fragments: [TextFragment]) -> [String] {
        var rows: [[TextFragment]] = []
        let sorted = fragments.sorted { left, right in
            if abs(left.box.midY - right.box.midY) > 0.01 {
                return left.box.midY > right.box.midY
            }
            return left.box.minX < right.box.minX
        }

        for fragment in sorted {
            if let index = rows.firstIndex(where: { row in
                guard let first = row.first else { return false }
                let tolerance = max(0.009, min(first.box.height, fragment.box.height) * 0.42)
                return abs(first.box.midY - fragment.box.midY) <= tolerance
            }) {
                rows[index].append(fragment)
            } else {
                rows.append([fragment])
            }
        }

        return rows
            .sorted { ($0.first?.box.midY ?? 0) > ($1.first?.box.midY ?? 0) }
            .map { row in
                row.sorted { $0.box.minX < $1.box.minX }
                    .map(\.text)
                    .joined(separator: " ")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty }
    }

    private static func enhancedImages(from image: CGImage) -> [CGImage] {
        let input = CIImage(cgImage: image)
        let context = CIContext(options: [.useSoftwareRenderer: false])
        var results: [CGImage] = []

        guard let controls = CIFilter(name: "CIColorControls"),
              let sharpen = CIFilter(name: "CISharpenLuminance") else { return results }

        controls.setValue(input, forKey: kCIInputImageKey)
        controls.setValue(0, forKey: kCIInputSaturationKey)
        controls.setValue(1.35, forKey: kCIInputContrastKey)
        controls.setValue(0.04, forKey: kCIInputBrightnessKey)
        guard let contrasted = controls.outputImage else { return results }

        sharpen.setValue(contrasted, forKey: kCIInputImageKey)
        sharpen.setValue(0.65, forKey: kCIInputSharpnessKey)
        if let output = sharpen.outputImage,
           let rendered = context.createCGImage(output, from: input.extent) {
            results.append(rendered)
        }

        // 薄い鉛筆書きや黄ばんだ紙向け。明暗差を大きくして背景色を飛ばす。
        if let mono = CIFilter(name: "CIPhotoEffectMono"),
           let exposure = CIFilter(name: "CIExposureAdjust"),
           let highContrast = CIFilter(name: "CIColorControls") {
            mono.setValue(input, forKey: kCIInputImageKey)
            exposure.setValue(mono.outputImage, forKey: kCIInputImageKey)
            exposure.setValue(0.45, forKey: kCIInputEVKey)
            highContrast.setValue(exposure.outputImage, forKey: kCIInputImageKey)
            highContrast.setValue(1.75, forKey: kCIInputContrastKey)
            if let output = highContrast.outputImage,
               let rendered = context.createCGImage(output, from: input.extent) {
                results.append(rendered)
            }
        }
        return results
    }

    private static func quality(of result: OCRResult) -> Double {
        let draft = parse(result.lines)
        let parsedValue = Double(draft.ingredients.count * 12 + draft.steps.count * 4)
        let titleValue = draft.title.isEmpty ? 0.0 : 3.0
        return parsedValue + titleValue + Double(result.confidence) * 2
    }

    private static func parse(_ rawLines: [String]) -> RecipeOCRDraft {
        let lines = rawLines.map(normalize).filter { !$0.isEmpty }
        let ingredientHeaders = ["材料", "食材", "分量", "ingredients", "ingrédients"]
        let stepHeaders = ["作り方", "作りかた", "手順", "調理工程", "下準備", "préparation", "étapes", "instructions"]

        func isHeader(_ line: String, candidates: [String]) -> Bool {
            let normalized = line.lowercased().folding(options: .diacriticInsensitive, locale: .current)
            return candidates.contains {
                normalized.contains($0.folding(options: .diacriticInsensitive, locale: .current))
            }
        }

        let ingredientStart = lines.firstIndex { isHeader($0, candidates: ingredientHeaders) }
        let stepStart = lines.firstIndex { isHeader($0, candidates: stepHeaders) }
        let title = lines.first { line in
            !isHeader(line, candidates: ingredientHeaders + stepHeaders) &&
            parseIngredient(line) == nil &&
            !looksLikeServingInformation(line) &&
            !looksLikeNumberedStep(line)
        } ?? lines[0]

        var ingredientLines: [String] = []
        var stepLines: [String] = []

        if let start = ingredientStart {
            let end = stepStart ?? lines.count
            if start + 1 < end { ingredientLines = Array(lines[(start + 1)..<end]) }
        }
        if let start = stepStart, start + 1 < lines.count {
            stepLines = Array(lines[(start + 1)...])
        }

        if ingredientLines.isEmpty {
            ingredientLines = lines.dropFirst().filter { parseIngredient($0) != nil }
        }
        if stepLines.isEmpty {
            let used = Set(ingredientLines)
            stepLines = lines.dropFirst().filter {
                !used.contains($0) && parseIngredient($0) == nil && !looksLikeServingInformation($0)
            }
        }

        let ingredients = stitchIngredientRows(ingredientLines).compactMap(parseIngredient)
        let steps = assembleSteps(stepLines)
        return RecipeOCRDraft(title: title, ingredients: ingredients, steps: steps)
    }

    private static func normalize(_ line: String) -> String {
        var value = line.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? line
        let circledNumbers = ["①":"1. ", "②":"2. ", "③":"3. ", "④":"4. ", "⑤":"5. ",
                              "⑥":"6. ", "⑦":"7. ", "⑧":"8. ", "⑨":"9. ", "⑩":"10. ",
                              "⑪":"11. ", "⑫":"12. ", "⑬":"13. ", "⑭":"14. ", "⑮":"15. "]
        for (symbol, number) in circledNumbers where value.contains(symbol) {
            value = value.replacingOccurrences(of: symbol, with: number)
        }
        return value
            .replacingOccurrences(of: "½", with: "1/2")
            .replacingOccurrences(of: "¼", with: "1/4")
            .replacingOccurrences(of: "¾", with: "3/4")
            .replacingOccurrences(of: "ℓ", with: "L")
            .replacingOccurrences(of: "㎖", with: "ml")
            .replacingOccurrences(of: "㎎", with: "mg")
            .replacingOccurrences(of: "㎏", with: "kg")
            .replacingOccurrences(of: #"[\.．…]{2,}"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"^[・●○■□◆◇▶▷✓✔※\-]+\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func parseIngredient(_ rawLine: String) -> Ingredient? {
        let line = normalize(rawLine)
        let qualitativePattern = #"^(.+?)[\s:：・]*(適量|少々|ひとつまみ|au goût|selon goût)$"#
        if let parts = captures(in: line, pattern: qualitativePattern) {
            let unit = parts[1].lowercased().contains("goût") ? "適量" : parts[1]
            return Ingredient(name: cleanIngredientName(parts[0]), amount: 1, unit: unit)
        }
        let quantity = #"((?:約|各)?\s*[0-9]+(?:[\.,][0-9]+)?(?:\s+[0-9]+/[0-9]+)?(?:\s*[〜~～\-]\s*[0-9]+(?:[\.,][0-9]+)?)?|(?:約|各)?\s*[0-9]+/[0-9]+)"#
        let unit = #"(大さじ|小さじ|大匙|小匙|カップ|切れ|パック|cuillères? à soupe|cuillères? à café|tbsp|tsp|cups?|kg|mg|g|mL|ml|cl|dL|dl|L|l|cc|個分|個|本|枚|片|丁|玉|尾|袋|缶|束|株|房|合|%|℃|度)"#

        let suffixPattern = "^(.+?)[\\s:：・]*\(quantity)\\s*\(unit)(?:\\s*[（(].*)?$"
        if let parts = captures(in: line, pattern: suffixPattern),
           let amount = parseAmount(parts[1]) {
            return Ingredient(name: cleanIngredientName(parts[0]), amount: amount, unit: parts[2])
        }

        let prefixPattern = "^(.+?)[\\s:：・]+\(unit)\\s*\(quantity)(?:\\s*[（(].*)?$"
        if let parts = captures(in: line, pattern: prefixPattern),
           let amount = parseAmount(parts[2]) {
            return Ingredient(name: cleanIngredientName(parts[0]), amount: amount, unit: parts[1])
        }

        let amountOnlyPattern = "^(.+?)[\\s:：・]+\(quantity)$"
        if let parts = captures(in: line, pattern: amountOnlyPattern),
           let amount = parseAmount(parts[1]) {
            return Ingredient(name: cleanIngredientName(parts[0]), amount: amount, unit: "")
        }

        return nil
    }

    private static func captures(in text: String, pattern: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges >= 3 else { return nil }
        return (1..<match.numberOfRanges).compactMap { index in
            guard let range = Range(match.range(at: index), in: text) else { return nil }
            return String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private static func parseAmount(_ text: String) -> Double? {
        let normalized = text.replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: "約", with: "")
            .replacingOccurrences(of: "各", with: "")
            .trimmingCharacters(in: .whitespaces)
        let rangeParts = normalized.split(whereSeparator: { "〜~～-".contains($0) })
        if rangeParts.count == 2,
           let lower = Double(rangeParts[0].trimmingCharacters(in: .whitespaces)),
           let upper = Double(rangeParts[1].trimmingCharacters(in: .whitespaces)) {
            return (lower + upper) / 2
        }
        let parts = normalized.split(separator: " ")
        if parts.count == 2,
           let whole = Double(parts[0]),
           let fraction = fractionValue(String(parts[1])) {
            return whole + fraction
        }
        return fractionValue(normalized) ?? Double(normalized)
    }

    private static func fractionValue(_ text: String) -> Double? {
        let parts = text.split(separator: "/").compactMap { Double($0) }
        guard parts.count == 2, parts[1] != 0 else { return nil }
        return parts[0] / parts[1]
    }

    private static func cleanIngredientName(_ name: String) -> String {
        name.replacingOccurrences(of: #"[\.．…・:：\-]+$"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func stitchIngredientRows(_ lines: [String]) -> [String] {
        let standaloneAmount = #"^(?:約|各)?\s*(?:[0-9]+(?:[\.,][0-9]+)?(?:\s+[0-9]+/[0-9]+)?|[0-9]+/[0-9]+)(?:\s*[〜~～\-]\s*[0-9]+(?:[\.,][0-9]+)?)?\s*(?:大さじ|小さじ|大匙|小匙|カップ|切れ|パック|tbsp|tsp|cups?|kg|mg|g|mL|ml|cl|dL|dl|L|l|cc|個分|個|本|枚|片|丁|玉|尾|袋|缶|束|株|房|合|%)$"#
        var rows: [String] = []
        var index = 0
        while index < lines.count {
            let line = lines[index]
            if parseIngredient(line) == nil,
               index + 1 < lines.count,
               lines[index + 1].range(of: standaloneAmount, options: [.regularExpression, .caseInsensitive]) != nil {
                rows.append(line + " " + lines[index + 1])
                index += 2
            } else {
                rows.append(line)
                index += 1
            }
        }
        return rows
    }

    private static func assembleSteps(_ lines: [String]) -> [String] {
        let hasNumberedSteps = lines.contains(where: looksLikeNumberedStep)
        var steps: [String] = []
        for line in lines.map(normalize).filter({ !$0.isEmpty }) {
            let cleaned = cleanStep(line)
            guard !cleaned.isEmpty else { continue }
            if looksLikeNumberedStep(line) || steps.isEmpty {
                steps.append(cleaned)
            } else if !hasNumberedSteps {
                steps.append(cleaned)
            } else {
                steps[steps.count - 1] += " " + cleaned
            }
        }
        return steps
    }

    private static func looksLikeServingInformation(_ line: String) -> Bool {
        line.range(of: #"^[（(]?\s*[0-9]+\s*(人分|portions?|pers(?:onnes?)?)"#,
                   options: [.regularExpression, .caseInsensitive]) != nil
    }

    private static func looksLikeNumberedStep(_ line: String) -> Bool {
        line.range(of: #"^\s*[（(]?\s*[0-9]+\s*[)）\.．、:]"#, options: .regularExpression) != nil
    }

    private static func cleanStep(_ line: String) -> String {
        line.replacingOccurrences(of: #"^\s*[（(]?\s*[0-9]+\s*[)）\.．、:]\s*"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
