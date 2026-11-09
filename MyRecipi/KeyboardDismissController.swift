import SwiftUI
import UIKit

// 入力欄以外を押した時に、アプリ全体のキーボードを閉じるための処理です。
struct KeyboardDismissController: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> KeyboardDismissViewController {
        KeyboardDismissViewController()
    }

    func updateUIViewController(
        _ uiViewController: KeyboardDismissViewController,
        context: Context
    ) {
        uiViewController.installTapGestureIfNeeded()
    }

    static func dismantleUIViewController(
        _ uiViewController: KeyboardDismissViewController,
        coordinator: ()
    ) {
        uiViewController.removeTapGesture()
    }
}

final class KeyboardDismissViewController: UIViewController, UIGestureRecognizerDelegate {
    private weak var installedWindow: UIWindow?

    private lazy var tapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(
            target: self,
            action: #selector(closeKeyboard)
        )
        gesture.cancelsTouchesInView = false
        gesture.delegate = self
        return gesture
    }()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        installTapGestureIfNeeded()
    }

    func installTapGestureIfNeeded() {
        guard let window = view.window,
              installedWindow !== window else { return }

        removeTapGesture()
        window.addGestureRecognizer(tapGesture)
        installedWindow = window
    }

    func removeTapGesture() {
        installedWindow?.removeGestureRecognizer(tapGesture)
        installedWindow = nil
    }

    @objc private func closeKeyboard() {
        installedWindow?.endEditing(true)
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        // 入力欄を押した時は閉じず、そのまま文字を入力できるようにします。
        var touchedView = touch.view
        while let view = touchedView {
            if view is UITextField || view is UITextView {
                return false
            }
            touchedView = view.superview
        }
        return true
    }
}
