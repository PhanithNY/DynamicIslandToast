import UIKit

@available(iOS 17.0, *)
enum DynamicIslandContentSnapshot {
  static func image(of view: UIView, icons: [UIImageView]) -> UIImage {
    let hiddenStates = icons.map { $0.isHidden }
    let format = UIGraphicsImageRendererFormat()
    // Bound memory for the short blur sequence; live content resumes afterward.
    format.scale = min(2, view.traitCollection.displayScale)
    var snapshot: UIImage!
    UIView.performWithoutAnimation {
      icons.forEach { $0.isHidden = true }
      snapshot = UIGraphicsImageRenderer(size: view.bounds.size, format: format).image { renderer in
        view.layer.render(in: renderer.cgContext)
        for (icon, wasHidden) in zip(icons, hiddenStates) where !wasHidden {
          draw(icon, in: view, context: renderer.cgContext)
        }
      }
      for (icon, wasHidden) in zip(icons, hiddenStates) {
        icon.isHidden = wasHidden
      }
    }
    return snapshot
  }

  private static func draw(_ icon: UIImageView, in view: UIView, context: CGContext) {
    guard var image = icon.image else { return }
    // Render the image itself, avoiding UIKit's animated SF Symbol surfaces.
    if let configuration = icon.preferredSymbolConfiguration {
      image = image.applyingSymbolConfiguration(configuration) ?? image
    }
    if image.renderingMode == .alwaysTemplate || (image.renderingMode == .automatic && image.isSymbolImage) {
      image = image.withTintColor(icon.tintColor, renderingMode: .alwaysOriginal)
    }
    let rect = icon.convert(icon.bounds, to: view)
    context.saveGState()
    if let badge = icon.superview, badge.layer.masksToBounds {
      let badgeRect = badge.convert(badge.bounds, to: view)
      UIBezierPath(roundedRect: badgeRect, cornerRadius: badge.layer.cornerRadius).addClip()
    }
    context.clip(to: rect)
    context.setAlpha(icon.alpha)
    context.translateBy(x: rect.minX, y: rect.minY)
    image.draw(in: drawingRect(for: image.size, in: rect.size, contentMode: icon.contentMode))
    context.restoreGState()
  }

  private static func drawingRect(for imageSize: CGSize, in size: CGSize, contentMode: UIView.ContentMode) -> CGRect {
    var drawingSize = imageSize
    switch contentMode {
    case .scaleToFill, .redraw:
      return CGRect(origin: .zero, size: size)
    case .scaleAspectFit, .scaleAspectFill:
      let widthScale = size.width / imageSize.width
      let heightScale = size.height / imageSize.height
      let scale = contentMode == .scaleAspectFit ? min(widthScale, heightScale) : max(widthScale, heightScale)
      drawingSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    default:
      break
    }
    var origin = CGPoint(x: (size.width - drawingSize.width) / 2, y: (size.height - drawingSize.height) / 2)
    switch contentMode {
    case .left, .topLeft, .bottomLeft: origin.x = 0
    case .right, .topRight, .bottomRight: origin.x = size.width - drawingSize.width
    default: break
    }
    switch contentMode {
    case .top, .topLeft, .topRight: origin.y = 0
    case .bottom, .bottomLeft, .bottomRight: origin.y = size.height - drawingSize.height
    default: break
    }
    return CGRect(origin: origin, size: drawingSize)
  }
}
