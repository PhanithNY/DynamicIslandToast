//
//  UIViewController+DynamicIslandPresentation.swift
//  DIToastExample
//
//  Created by Suykorng on 22/10/24.
//

import UIKit

extension UIViewController {
  @available(iOS 17.0, *)
  public final func presentDynamicIsland(_ viewControllerToPresent: UIViewController,
                                         dismissAfterDelayed duration: TimeInterval?,
                                         completion: (() -> Void)? = nil) {
    viewControllerToPresent.transitioningDelegate = DynamicIslandSize.delegate
    present(viewControllerToPresent, animated: true) {
      completion?()
      
      if let duration {
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
          viewControllerToPresent.dismiss(animated: true)
        }
      }
    }
  }
}
