//
//  UIViewController+Extensions.swift
//  OnlineProfile
//
//  Created by Suykorng on 10/12/23.
//

import UIKit

extension UIViewController {
  
  fileprivate struct Holder {
    static var _statusBarHidden = [String: Bool]()
  }
  
  public var statusBarHidden: Bool {
    get {
      Holder._statusBarHidden[self.debugDescription] ?? false
    }
    set {
      Holder._statusBarHidden[self.debugDescription] = newValue
      (parent ?? self).setNeedsStatusBarAppearanceUpdate()
    }
  }
  
}

func topViewController(_ viewController: UIViewController? = UIApplication.shared.currentWindow?.rootViewController) -> UIViewController? {
  if let nav = viewController as? UINavigationController {
    return topViewController(nav.visibleViewController)
  }
  if let tab = viewController as? UITabBarController {
    if let selected = tab.selectedViewController {
      return topViewController(selected)
    }
  }
  if let presented = viewController?.presentedViewController {
    return topViewController(presented)
  }
  
  return viewController
}
