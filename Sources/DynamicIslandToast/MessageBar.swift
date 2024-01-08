//
//  MessageBar.swift
//  
//
//  Created by Suykorng on 26/11/23.
//

import UIKit

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
  
  final func toast(_ alertType: DynamicIslandToast.AlertType, message: String) {
    let hasDynamicIsland: Bool = UIDevice.current.hasDynamicIsland
    if hasDynamicIsland {
      toastWithDynamicIsland(for: alertType, message: message)
    }
  }
  
  // MARK: - DynamicIsland Message
  
  private func toastWithDynamicIsland(for alertType: DynamicIslandToast.AlertType, message: String) {
    topViewController()?.statusBarHidden = true
    
    let width: CGFloat = 126
    let x: CGFloat = window.bounds.width/2 - 126/2
    let y: CGFloat = 11
    let height: CGFloat = 37
    let frame = CGRect(x: x, y: y, width: width, height: height)
    
    // Check if toast already display, and not yet removed.
    // If not yet remove, just set new contents and perform remove again
    if let messageView = window.subviews.first(where: { type(of: $0) == DynamicIslandMessageBarSmall.self }) as? DynamicIslandMessageBarSmall,
       messageView.frame.origin.x <= y {
      messageView.setTitle(alertType.title.orEmpty, message: message)
      NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(removeToast), object: nil)
      perform(#selector(removeToast), with: nil, afterDelay: durationForDelay)
      return
    }
    
    // Instantiate and bind data
    messageView = .init(frame: frame)
    messageView.setTitle(alertType.title.orEmpty, message: message)
    messageView.layer.zPosition = 1000
    
    if #available(iOS 13.0, *) {
      messageView.layer.cornerCurve = .continuous
    }
    messageView.layer.cornerRadius = 37/2
    window.addSubview(messageView)
    
    // Use sample label to calculate height of message as we support multiple line
    let inset: CGFloat = 12
    let messageOriginX: CGFloat = 50 + 28 - inset*2
    let maxWidth: CGFloat = window.bounds.width - 11*2
    let label = UILabel(frame: CGRect(x: 11, y: 0, width: maxWidth - 11*2 - messageOriginX, height: 0))
    label.font = UIFont.callout()
    label.textAlignment = .left
    label.numberOfLines = 0
    label.text = message
    label.sizeToFit()
    
    var maxHeight: CGFloat = 28 + UIFont.body(.medium).lineHeight + 11/2 + label.frame.height + 28
    maxHeight = 83//max(maxHeight, 100) //200 //83
    
    let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 0.75) { [self] in
      messageView.setAlphaForSubviews(to: 1.0)
      messageView.frame.origin.x = y
      messageView.frame.size.width = window.bounds.width - 11*2
      messageView.frame.size.height = maxHeight
      messageView.layer.cornerRadius = 83/2//max(83/2, 37)
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
