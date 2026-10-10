import UIKit

/// A temporary surface: only the pill changes size; content bounds stay fixed.
@available(iOS 17.0, *)
final class DynamicIslandTransitionView: UIView {
  let shapeView = UIView()
  let contentView = UIImageView()
  let blendedContentView = UIImageView()
  private let expandedFrame: CGRect
  private let collapsedFrame: CGRect
  private let expandedCornerRadius: CGFloat
  private let reducedMotion: Bool
  private var blurFrames: [UIImage] = []
  private(set) var blurFrameIndex = 0

  init(image: UIImage, expandedFrame: CGRect, collapsedFrame: CGRect,
       cornerRadius: CGFloat, backgroundColor: UIColor, reducedMotion: Bool) {
    self.expandedFrame = expandedFrame
    self.collapsedFrame = collapsedFrame
    self.expandedCornerRadius = min(cornerRadius, min(expandedFrame.width, expandedFrame.height) / 2)
    self.reducedMotion = reducedMotion
    super.init(frame: .zero)
    isUserInteractionEnabled = false
    accessibilityElementsHidden = true
    shapeView.backgroundColor = backgroundColor
    shapeView.layer.cornerCurve = .continuous
    shapeView.layer.masksToBounds = true
    addSubview(shapeView)
    contentView.image = image
    contentView.bounds = CGRect(origin: .zero, size: expandedFrame.size)
    shapeView.addSubview(contentView)
    blendedContentView.frame = contentView.bounds
    contentView.addSubview(blendedContentView)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func prepare(isPresenting: Bool, blurFrames: [UIImage] = []) {
    self.blurFrames = reducedMotion ? [] : blurFrames
    UIView.performWithoutAnimation {
      setShape(expanded: reducedMotion || !isPresenting)
      render(progress: 0, isPresenting: isPresenting)
    }
  }

  func shapeAnimator(duration: TimeInterval, isPresenting: Bool) -> UIViewPropertyAnimator {
    // Match the original UIKit springs: 0.75 damping on presentation and
    // the default, non-bouncy spring response on dismissal.
    UIViewPropertyAnimator(duration: duration, dampingRatio: isPresenting ? 0.75 : 1) {
      self.setShape(expanded: self.reducedMotion || isPresenting)
    }
  }

  private func setShape(expanded: Bool) {
    let frame = expanded ? expandedFrame : collapsedFrame
    shapeView.frame = frame
    shapeView.layer.cornerRadius = expanded ? expandedCornerRadius : collapsedFrame.height / 2
    // UIKit animates this center with the pill's bounds, keeping the icon
    // centered throughout the spring without resizing or reflowing content.
    contentView.center = CGPoint(x: frame.width / 2, y: frame.height / 2)
  }

  /// Updates content effects without changing geometry owned by UIKit's spring.
  func render(progress: CGFloat, isPresenting: Bool) {
    let time = min(1, max(0, progress))
    let contentTime = isPresenting ? time : min(1, time / 0.25)
    let contentProgress = Self.ease(contentTime)
    let visibility = isPresenting ? contentProgress : 1 - contentProgress

    CATransaction.begin()
    CATransaction.setDisableActions(true)
    contentView.alpha = visibility
    let scale = reducedMotion ? 1 : interpolate(0.86, 1, visibility)
    contentView.transform = CGAffineTransform(scaleX: scale, y: scale)
    if !blurFrames.isEmpty {
      let sample = (1 - visibility) * CGFloat(blurFrames.count - 1)
      blurFrameIndex = Int(sample)
      let nextIndex = min(blurFrameIndex + 1, blurFrames.count - 1)
      let lower = blurFrames[blurFrameIndex]
      let upper = blurFrames[nextIndex]
      if contentView.image !== lower { contentView.image = lower }
      if blendedContentView.image !== upper { blendedContentView.image = upper }
      blendedContentView.alpha = sample - CGFloat(blurFrameIndex)
    }
    CATransaction.commit()
  }

  func finish() {
    blurFrames.removeAll()
    contentView.image = nil
    blendedContentView.image = nil
    removeFromSuperview()
  }

  /// Normalized critically damped response: scale, alpha and blur share it.
  private static func ease(_ time: CGFloat) -> CGFloat {
    if time <= 0 { return 0 }
    if time >= 1 { return 1 }
    let response = 1 - (1 + 8 * time) * exp(-8 * time)
    let endpoint = 1 - 9 * exp(CGFloat(-8))
    return response / endpoint
  }

  private func interpolate(_ start: CGFloat, _ end: CGFloat, _ progress: CGFloat) -> CGFloat {
    start + (end - start) * progress
  }
}
