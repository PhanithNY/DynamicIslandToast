//
//  DynamicIslandTransitioningDelegate.swift
//  DIToastExample
//
//  Created by Suykorng on 21/10/24.
//

import UIKit

@available(iOS 17.0, *)
final class DynamicIslandTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
  
  func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    DynamicIslandAnimatedTransitioning(transitionType: .present)
  }
  
  func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    DynamicIslandAnimatedTransitioning(transitionType: .dismiss)
  }
  
  func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
    DynamicIslandPresentationController(presentedViewController: presented, presenting: presenting)
  }
  
}
