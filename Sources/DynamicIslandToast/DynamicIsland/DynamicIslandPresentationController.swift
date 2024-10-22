//
//  DynamicIslandPresentationController.swift
//  DIToastExample
//
//  Created by Suykorng on 22/10/24.
//

import UIKit

@available(iOS 17.0, *)
final class DynamicIslandPresentationController: UIPresentationController {
  
  // MARK: - Properties
  
  private lazy var passthroughView: DynamicIslandPassthroughView = {
    let view = DynamicIslandPassthroughView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear
    view.onHitTest = { [weak self] _ in
      self?.presentedViewController.dismiss(animated: true)
    }
    return view
  }()
  
  override var frameOfPresentedViewInContainerView: CGRect {
    guard let containerView, let presentedView else {
      return .zero
    }
    
    let safeAreaFrame = containerView.bounds
    let targetWidth = safeAreaFrame.width
    let fittingSize = CGSize(width: targetWidth, height: UIView.layoutFittingCompressedSize.height)
    let targetHeight = presentedView.systemLayoutSizeFitting(fittingSize,
                                                             withHorizontalFittingPriority: .required,
                                                             verticalFittingPriority: .defaultLow).height
    
    var frame = safeAreaFrame
    frame.origin.y = DynamicIslandSize.originY
    frame.origin.x = DynamicIslandSize.originY
    frame.size.width = targetWidth - DynamicIslandSize.originY*2
    frame.size.height = max(DynamicIslandSize.radius*2, targetHeight)
    return frame
  }
  
  override func presentationTransitionWillBegin() {
    super.presentationTransitionWillBegin()
    
    guard let containerView else {
      return
    }
    
    passthroughView.touchForwardTargetViews = [presentingViewController.view]
    containerView.addSubview(passthroughView)
    passthroughView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
    passthroughView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
    passthroughView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
    passthroughView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
    
    presentedViewController.transitionCoordinator?.animate(alongsideTransition: { [weak self] _ in
      self?.presentedView?.layer.cornerRadius = DynamicIslandSize.radius
    })
  }
  
  override func dismissalTransitionWillBegin() {
    super.dismissalTransitionWillBegin()
    
    presentedViewController.transitionCoordinator?.animate(alongsideTransition: { [weak self] _ in
      self?.presentedView?.layer.cornerRadius = 37/2
    })
  }
}
