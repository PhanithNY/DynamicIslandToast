//
//  UINavigationController+Extensions.swift
//  OnlineProfile
//
//  Created by Suykorng on 10/12/23.
//

import UIKit

extension UINavigationController {
  open override var prefersStatusBarHidden: Bool {
    (topViewController ?? visibleViewController)?.prefersStatusBarHidden ?? false
  }
  
  open override var childForStatusBarHidden: UIViewController? {
    topViewController ?? visibleViewController
  }
  
  open override var childForStatusBarStyle: UIViewController? {
    topViewController ?? visibleViewController
  }
}
