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
    guard presentedViewController == nil, !isBeingPresented, !isBeingDismissed,
          viewControllerToPresent.presentingViewController == nil,
          !viewControllerToPresent.isBeingPresented, !viewControllerToPresent.isBeingDismissed else { return }
    let state = DynamicIslandPresentationState.state(for: viewControllerToPresent)
    let generation = state.begin()
    viewControllerToPresent.transitioningDelegate = DynamicIslandSize.delegate
    present(viewControllerToPresent, animated: true) { [weak viewControllerToPresent] in
      completion?()
      guard let viewControllerToPresent, viewControllerToPresent.presentingViewController != nil,
            let duration else { return }
      state.schedule(after: duration, generation: generation) { [weak viewControllerToPresent] in
        guard let controller = viewControllerToPresent, controller.presentingViewController != nil,
              !controller.isBeingDismissed else { return }
        controller.dismissDynamicIslandPresentation(animated: true)
      }
    }
  }

  @available(iOS 17.0, *)
  func dismissDynamicIslandPresentation(animated: Bool) {
    guard let presenter = presentingViewController, !isBeingDismissed else { return }
    let state = DynamicIslandPresentationState.state(for: self)
    let generation = state.generation
    let dismissToast = { [weak self, weak presenter] in
      guard let self, let presenter, state.generation == generation,
            self.presentingViewController === presenter, !self.isBeingDismissed else { return }
      presenter.dismiss(animated: animated)
    }
    if presentedViewController != nil {
      // Clear child presentations before the custom toast transition begins.
      // Dismissing the whole stack at once can leave the alert's view attached.
      dismiss(animated: false, completion: dismissToast)
    } else {
      dismissToast()
    }
  }
}
