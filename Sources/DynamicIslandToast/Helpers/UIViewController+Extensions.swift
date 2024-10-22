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
