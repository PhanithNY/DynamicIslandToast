import UIKit
import ObjectiveC

/// One cancellable deadline and blur cache for a single controller presentation.
@available(iOS 17.0, *)
final class DynamicIslandPresentationState {
  private static var associationKey: UInt8 = 0
  private(set) var generation: UInt64 = 0
  private(set) var isActive = false
  private var workItem: DispatchWorkItem?
  private var deadline: CFTimeInterval?
  private var dismiss: (() -> Void)?
  var blurFrames: DynamicIslandContentBlur.PreparedFrames?

  static func state(for controller: UIViewController) -> DynamicIslandPresentationState {
    if let state = objc_getAssociatedObject(controller, &associationKey) as? DynamicIslandPresentationState {
      return state
    }
    let state = DynamicIslandPresentationState()
    objc_setAssociatedObject(controller, &associationKey, state, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    return state
  }

  deinit { workItem?.cancel() }

  @discardableResult
  func begin() -> UInt64 {
    invalidate()
    isActive = true
    return generation
  }

  func schedule(after duration: TimeInterval, generation: UInt64, dismiss: @escaping () -> Void) {
    guard generation == self.generation, isActive, duration.isFinite else { return }
    workItem?.cancel()
    deadline = CACurrentMediaTime() + max(0, duration)
    self.dismiss = dismiss
    enqueue(after: max(0, duration))
  }

  private func enqueue(after delay: TimeInterval) {
    let expectedGeneration = generation
    let item = DispatchWorkItem { [weak self] in
      self?.fire(generation: expectedGeneration)
    }
    workItem = item
    DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
  }

  // Generation checking protects against an already enqueued stale callback.
  func fire(generation: UInt64) {
    guard generation == self.generation, isActive, let dismiss else { return }
    workItem?.cancel()
    workItem = nil
    deadline = nil
    self.dismiss = nil
    dismiss()
  }

  func dismissalWillBegin() {
    generation &+= 1
    isActive = false
    workItem?.cancel()
    workItem = nil
  }

  func dismissalDidEnd(completed: Bool) {
    if completed {
      invalidate()
    } else {
      isActive = true
      if let deadline, dismiss != nil { enqueue(after: max(0, deadline - CACurrentMediaTime())) }
    }
  }

  func invalidate() {
    generation &+= 1
    isActive = false
    workItem?.cancel()
    workItem = nil
    deadline = nil
    dismiss = nil
    blurFrames = nil
  }
}
