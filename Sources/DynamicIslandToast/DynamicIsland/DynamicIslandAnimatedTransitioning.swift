//
//  DynamicIslandAnimatedTransitioning.swift
//  DIToastExample
//
//  Created by Suykorng on 21/10/24.
//

import UIKit

@available(iOS 17.0, *)
final class DynamicIslandAnimatedTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
  
  // MARK: - Properties
  
  enum TransitionType {
    case dismiss
    case present
  }
  
  // MARK: - Init
  
  private var animator: UIViewPropertyAnimator?
  private let duration: TimeInterval
  private let transitionType: TransitionType
  
  init(transitionType: TransitionType, duration: TimeInterval = 0.6) {
    self.transitionType = transitionType
    self.duration = duration
  }
  
  func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
    switch transitionType {
    case .present:
      return duration
      
    case .dismiss:
      return 0.3
    }
  }
  
  func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    switch transitionType {
    case .present:
      animatePresentation(using: transitionContext)
      
    case .dismiss:
      animateDismissal(using: transitionContext)
    }
  }
  
  private func animatePresentation(using transitionContext: UIViewControllerContextTransitioning) {
    let presentedViewController = transitionContext.viewController(forKey: .to).unsafelyUnwrapped
    transitionContext.containerView.addSubview(presentedViewController.view)
    
    let initialFrame: CGRect = DynamicIslandSize.startFrame
    presentedViewController.view.frame = initialFrame
    presentedViewController.view.layer.cornerRadius = initialFrame.height / 2
    
    let duration = transitionDuration(using: transitionContext)
    let targetFrame = transitionContext.finalFrame(for: presentedViewController)
    let animator = UIViewPropertyAnimator(duration: duration, dampingRatio: 0.75) {
      presentedViewController.view.frame = targetFrame
    }

    animator.addCompletion { _ in
      transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
    }

    animator.startAnimation()
  }
  
  private func animateDismissal(using transitionContext: UIViewControllerContextTransitioning) {
    let presentedViewController = transitionContext.viewController(forKey: .from).unsafelyUnwrapped
    let presentingViewController = transitionContext.viewController(forKey: .to).unsafelyUnwrapped
  
    let presentingFrame: CGRect = transitionContext.containerView.bounds
    let endFrame: CGRect = DynamicIslandSize.startFrame
    let duration = transitionDuration(using: transitionContext)
//    let animator = UIViewPropertyAnimator(duration: duration, dampingRatio: 0.75) {
//      presentingViewController.view.frame = presentingFrame
//      presentedViewController.view.frame = endFrame
//    }
//    
//    animator.addCompletion { _ in
//      transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
//    }
//    
//    animator.startAnimation()
    
    UIView.animate(springDuration: duration) {
      presentingViewController.view.frame = presentingFrame
      presentedViewController.view.frame = endFrame
    } completion: { _ in
      transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
    }
  }
  
}
