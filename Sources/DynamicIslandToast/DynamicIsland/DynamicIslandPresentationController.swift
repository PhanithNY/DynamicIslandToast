//
//  DynamicIslandPresentationController.swift
//  DIToastExample
//
//  Created by Suykorng on 22/10/24.
//

import UIKit

@available(iOS 17.0, *)
final class DynamicIslandPresentationController: UIPresentationController, UIGestureRecognizerDelegate {
  
  // MARK: - Properties
  
  private var isDismissalRequested = false

  private lazy var outsideTapRecognizer: UITapGestureRecognizer = {
    let recognizer = UITapGestureRecognizer(target: self, action: #selector(dismissForOutsideTap(_:)))
    recognizer.cancelsTouchesInView = false
    recognizer.delaysTouchesBegan = false
    recognizer.delaysTouchesEnded = false
    recognizer.delegate = self
    return recognizer
  }()

  private lazy var passthroughView: DynamicIslandPassthroughView = {
    let view = DynamicIslandPassthroughView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear
    return view
  }()
  
  override var frameOfPresentedViewInContainerView: CGRect {
    guard let containerView, let presentedView else {
      return .zero
    }
    
    return frameForPresentedView(presentedView, in: containerView.bounds)
  }

  func frameForPresentedView(_ presentedView: UIView, in bounds: CGRect) -> CGRect {
    let safeAreaFrame = bounds
    let targetWidth = max(0, safeAreaFrame.width - DynamicIslandSize.originY * 2)
    let fittingSize = CGSize(width: targetWidth, height: UIView.layoutFittingCompressedSize.height)
    let targetHeight = presentedView.systemLayoutSizeFitting(fittingSize,
                                                             withHorizontalFittingPriority: .required,
                                                             verticalFittingPriority: .defaultLow).height
    
    var frame = safeAreaFrame
    frame.origin.y = bounds.minY + DynamicIslandSize.originY
    frame.origin.x = bounds.minX + DynamicIslandSize.originY
    frame.size.width = targetWidth
    frame.size.height = max(DynamicIslandSize.radius(for: presentedView) * 2, targetHeight)
    return frame
  }
  
  override func presentationTransitionWillBegin() {
    super.presentationTransitionWillBegin()
    isDismissalRequested = false
    let state = DynamicIslandPresentationState.state(for: presentedViewController)
    if !state.isActive { state.begin() }
    
    guard let containerView else {
      return
    }
    
    passthroughView.touchForwardTargetViews = [presentingViewController.view]
    presentingViewController.view.addGestureRecognizer(outsideTapRecognizer)
    containerView.addSubview(passthroughView)
    passthroughView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
    passthroughView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
    passthroughView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
    passthroughView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
  }

  override func containerViewWillLayoutSubviews() {
    super.containerViewWillLayoutSubviews()
    guard !presentedViewController.isBeingPresented, !presentedViewController.isBeingDismissed,
          presentedView != nil else { return }
    updatePresentedGeometry()
  }

  override func presentationTransitionDidEnd(_ completed: Bool) {
    super.presentationTransitionDidEnd(completed)
    if completed {
      updatePresentedGeometry()
    } else {
      DynamicIslandPresentationState.state(for: presentedViewController).invalidate()
      removePassthroughView()
    }
  }

  override func dismissalTransitionWillBegin() {
    super.dismissalTransitionWillBegin()
    isDismissalRequested = true
    DynamicIslandPresentationState.state(for: presentedViewController).dismissalWillBegin()
  }

  override func dismissalTransitionDidEnd(_ completed: Bool) {
    super.dismissalTransitionDidEnd(completed)
    DynamicIslandPresentationState.state(for: presentedViewController).dismissalDidEnd(completed: completed)
    isDismissalRequested = false
    if completed {
      removePassthroughView()
    } else {
      updatePresentedGeometry()
    }
  }

  private func updatePresentedGeometry() {
    guard let presentedView, containerView != nil else { return }
    presentedView.frame = frameOfPresentedViewInContainerView
    presentedView.layer.cornerRadius = min(DynamicIslandSize.radius(for: presentedView), presentedView.bounds.height / 2)
    presentedView.setNeedsLayout()
    presentedView.layoutIfNeeded()
  }

  private func removePassthroughView() {
    outsideTapRecognizer.view?.removeGestureRecognizer(outsideTapRecognizer)
    passthroughView.touchForwardTargetViews = []
    passthroughView.removeFromSuperview()
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    guard let containerView, let presentedView,
          !isDismissalRequested,
          !presentedViewController.isBeingPresented,
          !presentedViewController.isBeingDismissed else { return false }
    return !presentedView.frame.contains(touch.location(in: containerView))
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                         shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    true
  }

  @objc private func dismissForOutsideTap(_ recognizer: UITapGestureRecognizer) {
    guard recognizer.state == .ended, !isDismissalRequested,
          !presentedViewController.isBeingPresented,
          !presentedViewController.isBeingDismissed else { return }
    isDismissalRequested = true
    presentedViewController.dismiss(animated: true)
  }
}
