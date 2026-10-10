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
        controller.dismiss(animated: true)
      }
    }
  }
}
