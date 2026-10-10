import DynamicIslandToast
import UIKit

/// Hosts the package's message view inside a custom modal presentation.
final class ToastViewController: UIViewController {
  private let messageView = DynamicIslandMessageView()
  private let example: ToastExample
  var onDismiss: (() -> Void)?

  override var prefersStatusBarHidden: Bool { true }
  override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { .none }

  init(example: ToastExample) {
    self.example = example
    super.init(nibName: nil, bundle: nil)
    modalPresentationStyle = .custom
    modalPresentationCapturesStatusBarAppearance = true
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black
    view.layer.masksToBounds = true

    messageView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(messageView)
    NSLayoutConstraint.activate([
      messageView.topAnchor.constraint(equalTo: view.topAnchor),
      messageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      messageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      messageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])

    if example == .customFonts {
      messageView.setFonts(
        title: .systemFont(ofSize: 12, weight: .bold),
        message: .systemFont(ofSize: 19, weight: .semibold)
      )
    }
    messageView.setTitle(example.toastTitle, message: example.message, style: example.messageStyle)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if let transitionCoordinator {
      transitionCoordinator.animate(alongsideTransition: { [weak self] _ in
        self?.messageView.setAlphaForSubviews(to: 1)
      })
    } else {
      messageView.setAlphaForSubviews(to: 1)
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    transitionCoordinator?.animate(alongsideTransition: { [weak self] _ in
      self?.messageView.setAlphaForSubviews(to: 0)
    })
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    if isBeingDismissed || presentingViewController == nil {
      onDismiss?()
      onDismiss = nil
    }
  }
}
