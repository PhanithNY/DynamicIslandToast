import UIKit

/// One elapsed-time source for content scale, opacity and pre-rendered blur.
@available(iOS 17.0, *)
final class DynamicIslandTransitionClock {
  private let duration: TimeInterval
  private let update: (CGFloat) -> Void
  private let completion: (Bool) -> Void
  private var displayLink: CADisplayLink?
  private var startTime: CFTimeInterval = 0
  private var isFinished = false
  private let target = DisplayLinkTarget()

  init(duration: TimeInterval, update: @escaping (CGFloat) -> Void,
       completion: @escaping (Bool) -> Void) {
    self.duration = duration
    self.update = update
    self.completion = completion
    target.clock = self
  }

  deinit { displayLink?.invalidate() }

  func start() {
    startTime = CACurrentMediaTime()
    advance(elapsed: 0)
    guard !isFinished else { return }
    let link = CADisplayLink(target: target, selector: #selector(DisplayLinkTarget.tick(_:)))
    displayLink = link
    link.add(to: .main, forMode: .common)
  }

  // Absolute elapsed time also handles skipped frames without effect drift.
  func advance(elapsed: TimeInterval) {
    guard !isFinished else { return }
    let progress = duration > 0 ? min(1, max(0, elapsed / duration)) : 1
    update(CGFloat(progress))
    if progress == 1 {
      finish(cancelled: false)
    }
  }

  func cancel() { finish(cancelled: true) }

  private func finish(cancelled: Bool) {
    guard !isFinished else { return }
    isFinished = true
    displayLink?.invalidate()
    displayLink = nil
    completion(cancelled)
  }

  private final class DisplayLinkTarget: NSObject {
    weak var clock: DynamicIslandTransitionClock?

    @objc func tick(_ link: CADisplayLink) {
      guard let clock else { return }
      clock.advance(elapsed: link.targetTimestamp - clock.startTime)
    }
  }
}
