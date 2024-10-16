//
//  MessageBar.swift
//  
//
//  Created by Suykorng on 26/11/23.
//

import DeviceKit
import UIKit

@available(iOS 17.0, *)
final class MessageBar: NSObject {
  static let shared = MessageBar()
  
  private override init() {}
  
  private let durationForDelay: TimeInterval = 3.0
  private let window: UIWindow = {
    if let window = UIApplication.shared.currentWindow {
      return window
    } else {
      return UIWindow(frame: UIScreen.main.bounds)
    }
  }()
  
  private var messageView: DynamicIslandMessageBarSmall!
  
  final func toast(_ alertType: DynamicIslandToast.AlertType,
                   message: String,
                   style: DynamicIslandMessageBarStyle) {
    let hasDynamicIsland: Bool = UIDevice.current.hasDynamicIsland
    if hasDynamicIsland {
      toastWithDynamicIsland(for: alertType, message: message, style: style)
    }
  }
  
  // MARK: - DynamicIsland Message
  
  private func toastWithDynamicIsland(for alertType: DynamicIslandToast.AlertType,
                                      message: String,
                                      style: DynamicIslandMessageBarStyle) {
    topViewController()?.statusBarHidden = true
    
    let islandWidth: CGFloat = 126
    let islandHeight: CGFloat = 37
    let x: CGFloat = window.bounds.width/2 - 126/2
    var originY: CGFloat = 11
    
    let device = Device.current
    switch device {
    case .simulator(.iPhone16ProMax),
        .simulator(.iPhone16Pro):
      originY = 14
      
    case .iPhone16ProMax,
        .iPhone16Pro:
      originY = 14
      
    default:
      break
    }
    
    let frame = CGRect(x: x, y: originY, width: islandWidth, height: islandHeight)
    
    // Check if toast already display, and not yet removed.
    // If not yet remove, just set new contents and perform remove again
    if let messageView = window.subviews.first(where: { type(of: $0) == DynamicIslandMessageBarSmall.self }) as? DynamicIslandMessageBarSmall,
       messageView.frame.origin.x <= originY {
      messageView.setTitle(alertType.title.orEmpty, message: message)
      NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(removeToast), object: nil)
      perform(#selector(removeToast), with: nil, afterDelay: durationForDelay)
      return
    }
    
    // Instantiate and bind data
    messageView = .init(frame: frame)
    messageView.setTitle(alertType.title.orEmpty, message: message, style: style)
    messageView.layer.zPosition = 1000
//    messageView.layer.cornerCurve = .continuous
    messageView.layer.cornerRadius = islandHeight/2
    window.addSubview(messageView)
    
    // Use sample label to calculate height of message as we support multiple line
//    let inset: CGFloat = 12
//    let messageOriginX: CGFloat = 50 + 28 - inset*2
//    let maxWidth: CGFloat = window.bounds.width - 11*2
//    let label = UILabel(frame: CGRect(x: 11, y: 0, width: maxWidth - 11*2 - messageOriginX, height: 0))
//    label.font = UIFont.callout()
//    label.textAlignment = .left
//    label.numberOfLines = 0
//    label.text = message
//    label.sizeToFit()
//    
//    var maxHeight: CGFloat = 28 + UIFont.body(.medium).lineHeight + 11/2 + label.frame.height + 28
    
    // We assume to use circle, so the maximum height will be radius*2
    let radius: CGFloat = _CornerRadiusProvider.notchCornerRadius - originY
    let maxHeight: CGFloat = radius * 2//83
    
    let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 0.75) { [self] in
      messageView.setAlphaForSubviews(to: 1.0)
      messageView.frame.origin.x = originY
      messageView.frame.size.width = window.bounds.width - originY*2
      messageView.frame.size.height = maxHeight
      messageView.layer.cornerRadius = radius//83/2
      messageView.layoutIfNeeded()
    }
    
    animator.startAnimation()
    perform(#selector(removeToast), with: nil, afterDelay: durationForDelay)
  }
  
  @objc
  private func removeToast() {
    messageView.remove()
    MainThread.delay(after: .now() + .milliseconds(250)) {
      topViewController()?.statusBarHidden = false
    }
  }
}

fileprivate enum _CornerRadiusProvider {
  static var notchCornerRadius: CGFloat {
    UIScreen.main.displayCornerRadius
  }
}

extension UIScreen {
  fileprivate static let cornerRadiusKey: String = {
    let components = ["Radius", "Corner", "display", "_"]
    return components.reversed().joined()
  }()
  
  /// The corner radius of the display. Uses a private property of `UIScreen`,
  /// and may report 0 if the API changes.
  fileprivate var displayCornerRadius: CGFloat {
    guard let cornerRadius = self.value(forKey: Self.cornerRadiusKey) as? CGFloat else {
      return 0.0
    }
    
    return max(0, cornerRadius)
  }
}
