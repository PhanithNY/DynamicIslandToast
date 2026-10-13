import UIKit

/// A temporary surface: only the pill changes size; content bounds stay fixed.
@available(iOS 17.0, *)
final class DynamicIslandTransitionView: UIView {
  let shapeView = UIView()
  let clippingView = UIView()
  let contentView = UIImageView()
  let blendedContentView = DynamicIslandBlendedImageView()
  let sharpIconView = UIImageView()
  private let expandedFrame: CGRect
  private let collapsedFrame: CGRect
  private let expandedCornerRadius: CGFloat
  private let reducedMotion: Bool
  private let originalImage: UIImage
  private let shadowOpacity: Float
  private var blurFrames: [UIImage] = []
  private(set) var blurFrameIndex = 0

  init(image: UIImage, iconImage: UIImage? = nil, expandedFrame: CGRect, collapsedFrame: CGRect,
       cornerRadius: CGFloat, backgroundColor: UIColor, reducedMotion: Bool,
       shadowLayer: CALayer? = nil) {
    self.expandedFrame = expandedFrame
    self.collapsedFrame = collapsedFrame
    self.expandedCornerRadius = min(cornerRadius, min(expandedFrame.width, expandedFrame.height) / 2)
    self.reducedMotion = reducedMotion
    self.originalImage = image
    self.shadowOpacity = shadowLayer?.masksToBounds == false ? shadowLayer?.shadowOpacity ?? 0 : 0
    super.init(frame: .zero)
    isUserInteractionEnabled = false
    accessibilityElementsHidden = true
    shapeView.backgroundColor = backgroundColor
    shapeView.layer.cornerCurve = .continuous
    // The shadow belongs to the same spring-driven silhouette as the pill.
    // Clip the content separately so the shadow can extend beyond that silhouette.
    shapeView.layer.shadowColor = shadowLayer?.shadowColor
    shapeView.layer.shadowRadius = shadowLayer?.shadowRadius ?? 0
    shapeView.layer.shadowOffset = shadowLayer?.shadowOffset ?? .zero
    addSubview(shapeView)
    clippingView.layer.cornerCurve = .continuous
    clippingView.layer.masksToBounds = true
    shapeView.addSubview(clippingView)
    contentView.image = image
    contentView.bounds = CGRect(origin: .zero, size: expandedFrame.size)
    clippingView.addSubview(contentView)
    blendedContentView.frame = contentView.bounds
    blendedContentView.isHidden = true
    blendedContentView.contentScaleFactor = image.scale
    contentView.addSubview(blendedContentView)
    sharpIconView.image = iconImage
    sharpIconView.frame = contentView.bounds
    // Inherit the content's center, scale and opacity; never sample its blur.
    contentView.addSubview(sharpIconView)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func prepare(isPresenting: Bool, blurFrames: [UIImage] = []) {
    self.blurFrames = reducedMotion ? [] : blurFrames
    contentView.image = self.blurFrames.isEmpty ? originalImage : nil
    blendedContentView.isHidden = self.blurFrames.isEmpty
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
    shapeView.layer.shadowOpacity = expanded ? shadowOpacity : 0
    clippingView.frame = shapeView.bounds
    clippingView.layer.cornerRadius = shapeView.layer.cornerRadius
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
    if reducedMotion {
      shapeView.layer.shadowOpacity = shadowOpacity * Float(visibility)
    }
    contentView.alpha = visibility
    let scale = reducedMotion ? 1 : interpolate(0.86, 1, visibility)
    contentView.transform = CGAffineTransform(scaleX: scale, y: scale)
    if !blurFrames.isEmpty {
      let sample = (1 - visibility) * CGFloat(blurFrames.count - 1)
      blurFrameIndex = Int(sample)
      let nextIndex = min(blurFrameIndex + 1, blurFrames.count - 1)
      let lower = blurFrames[blurFrameIndex]
      let upper = blurFrames[nextIndex]
      blendedContentView.setSamples(lower, upper, fraction: sample - CGFloat(blurFrameIndex))
    }
    CATransaction.commit()
  }

  func finish() {
    blurFrames.removeAll()
    contentView.image = nil
    blendedContentView.setSamples(nil, nil, fraction: 0)
    sharpIconView.image = nil
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

/// Interpolate premultiplied pixels in one backing store. Overlaying two image
/// views with source-over blending would accumulate alpha at transparent edges.
@available(iOS 17.0, *)
final class DynamicIslandBlendedImageView: UIView {
  private(set) var lowerImage: UIImage?
  private(set) var upperImage: UIImage?
  private(set) var fraction: CGFloat = 0

  override init(frame: CGRect) {
    super.init(frame: frame)
    isOpaque = false
    isUserInteractionEnabled = false
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setSamples(_ lower: UIImage?, _ upper: UIImage?, fraction: CGFloat) {
    lowerImage = lower
    upperImage = upper
    self.fraction = fraction
    setNeedsDisplay()
  }

  override func draw(_ rect: CGRect) {
    lowerImage?.draw(in: bounds, blendMode: .copy, alpha: 1 - fraction)
    upperImage?.draw(in: bounds, blendMode: .plusLighter, alpha: fraction)
  }
}
