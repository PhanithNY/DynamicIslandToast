//
//  DynamicIslandAnimatedTransitioning.swift
//  DIToastExample
//
//  Created by Suykorng on 21/10/24.
//

import UIKit

@available(iOS 17.0, *)
final class DynamicIslandAnimatedTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
  enum TransitionType {
    case dismiss
    case present
  }

  private var clock: DynamicIslandTransitionClock?
  private var animator: UIViewPropertyAnimator?
  private var blurRequest: DynamicIslandContentBlur.Request?
  private let duration: TimeInterval
  private let transitionType: TransitionType

  init(transitionType: TransitionType, duration: TimeInterval = 0.6) {
    self.transitionType = transitionType
    self.duration = duration
  }

  func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
    transitionType == .present ? duration : 0.35
  }

  func animateTransition(using context: UIViewControllerContextTransitioning) {
    let isPresenting = transitionType == .present
    guard let controller = context.viewController(forKey: isPresenting ? .to : .from),
          let view = context.view(forKey: isPresenting ? .to : .from) ?? controller.view else {
      context.completeTransition(false)
      return
    }
    let container = context.containerView
    let originalAlpha = view.alpha
    var expandedFrame = isPresenting ? context.finalFrame(for: controller) : view.frame
    let messages = messageViews(in: view)
    if isPresenting {
      container.addSubview(view)
      // Icon geometry acquires its actual screen when attached. Fit again
      // before capturing content so the provisional detached size cannot clip it.
      if let presentation = controller.presentationController as? DynamicIslandPresentationController {
        expandedFrame = presentation.frameForPresentedView(view, in: container.bounds)
      }
    }

    // Lay out once at the final width. Neither labels nor the real controller
    // are resized during the morph, so line wrapping stays stable.
    view.frame = expandedFrame
    view.layer.cornerRadius = min(DynamicIslandSize.radius(for: view), expandedFrame.height / 2)
    view.layer.cornerCurve = .continuous
    view.layoutIfNeeded()
    messages.forEach { $0.prepareContentTransition() }
    let image = DynamicIslandContentSnapshot.image(of: view, icons: messages.map { $0.transitionIconView })
    let reducedMotion = UIAccessibility.isReduceMotionEnabled
    let surface = DynamicIslandTransitionView(
      image: image,
      expandedFrame: expandedFrame,
      collapsedFrame: DynamicIslandSize.startFrame(in: container.bounds),
      cornerRadius: DynamicIslandSize.radius(for: view),
      backgroundColor: view.backgroundColor ?? .black,
      reducedMotion: reducedMotion
    )
    surface.frame = container.bounds
    surface.bounds = container.bounds
    container.addSubview(surface)
    surface.prepare(isPresenting: isPresenting)
    view.alpha = 0

    let duration = transitionDuration(using: context)
    var shapeFinished = false
    var contentFinished = false
    var transitionFinished = false
    let finishTransition: (Bool) -> Void = { [weak self] cancelled in
      guard let self, !transitionFinished, cancelled || (shapeFinished && contentFinished) else { return }
      transitionFinished = true
      if cancelled {
        if self.animator?.state == .active {
          self.animator?.stopAnimation(true)
        }
        self.clock?.cancel()
      }
      UIView.performWithoutAnimation {
        messages.forEach {
          $0.finishContentTransition(isPresenting: isPresenting, isCancelled: cancelled)
        }
        view.alpha = originalAlpha
        surface.finish()
        if isPresenting && cancelled {
          view.removeFromSuperview()
        }
      }
      self.blurRequest?.cancel()
      self.blurRequest = nil
      self.clock = nil
      self.animator = nil
      context.completeTransition(!cancelled)
    }

    let state = DynamicIslandPresentationState.state(for: controller)
    let generation = state.generation
    let start: (DynamicIslandContentBlur.PreparedFrames?) -> Void = { [weak self] prepared in
      guard let self else { return }
      self.blurRequest = nil
      guard !context.transitionWasCancelled else {
        finishTransition(true)
        return
      }
      if state.generation == generation { state.blurFrames = prepared }
      surface.prepare(isPresenting: isPresenting, blurFrames: prepared?.images ?? [])
      let animator = surface.shapeAnimator(duration: duration, isPresenting: isPresenting)
      animator.addCompletion { [weak self] position in
        shapeFinished = true
        let cancelled = position != .end || context.transitionWasCancelled
        if !cancelled {
          // Flush the final content frame at the spring endpoint rather than
          // waiting for another display tick before returning the live view.
          self?.clock?.advance(elapsed: duration)
        }
        finishTransition(cancelled)
      }
      let clock = DynamicIslandTransitionClock(duration: duration, update: { [weak self] progress in
        if context.transitionWasCancelled {
          self?.clock?.cancel()
        } else {
          surface.render(progress: progress, isPresenting: isPresenting)
        }
      }, completion: { cancelled in
        contentFinished = true
        let isCancelled = cancelled || context.transitionWasCancelled
        finishTransition(isCancelled)
      })
      self.animator = animator
      self.clock = clock
      animator.startAnimation()
      clock.start()
    }
    if reducedMotion {
      start(nil)
    } else {
      blurRequest = DynamicIslandContentBlur.prepare(for: image, cached: state.blurFrames, completion: start)
    }
  }

  private func messageViews(in view: UIView) -> [DynamicIslandMessageView] {
    if let message = view as? DynamicIslandMessageView {
      return [message]
    }
    return view.subviews.flatMap { messageViews(in: $0) }
  }
}
