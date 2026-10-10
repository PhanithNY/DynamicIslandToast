import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else { return }
    let window = UIWindow(windowScene: windowScene)
    window.rootViewController = ExampleNavigationController(rootViewController: ExamplesViewController())
    self.window = window
    window.makeKeyAndVisible()
  }
}

/// Hold status-bar ownership until the toast has finished collapsing.
final class ExampleNavigationController: UINavigationController {
  var isToastVisible = false {
    didSet { setNeedsStatusBarAppearanceUpdate() }
  }

  override var prefersStatusBarHidden: Bool { isToastVisible }
  override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { .none }
  override var childForStatusBarHidden: UIViewController? { nil }
}
