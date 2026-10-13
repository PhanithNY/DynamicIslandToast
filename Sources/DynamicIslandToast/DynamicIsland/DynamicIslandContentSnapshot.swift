import UIKit

@available(iOS 17.0, *)
enum DynamicIslandContentSnapshot {
  struct Layers {
    let content: UIImage
    let icons: UIImage?
  }

  /// Keep the icon and its badge outside the images used for Gaussian blur.
  static func layers(of view: UIView, iconContainers: [UIView], icons: [UIImageView]) -> Layers {
    guard !iconContainers.isEmpty else { return Layers(content: image(of: view, icons: []), icons: nil) }
    let containerHiddenStates = iconContainers.map { $0.isHidden }
    let iconHiddenStates = icons.map { $0.isHidden }
    let format = UIGraphicsImageRendererFormat()
    format.scale = min(2, view.traitCollection.displayScale)
    format.opaque = false
    let iconFormat = UIGraphicsImageRendererFormat()
    // Only the blur sequence needs the reduced resolution. Keep sharp edges
    // at the screen's scale while the snapshot is enlarged during the morph.
    iconFormat.scale = view.traitCollection.displayScale
    iconFormat.opaque = false
    var content: UIImage!
    var sharpIcons: UIImage!
    UIView.performWithoutAnimation {
      defer {
        for (container, wasHidden) in zip(iconContainers, containerHiddenStates) {
          container.isHidden = wasHidden
        }
        for (icon, wasHidden) in zip(icons, iconHiddenStates) {
          icon.isHidden = wasHidden
        }
      }
      iconContainers.forEach { $0.isHidden = true }
      content = UIGraphicsImageRenderer(size: view.bounds.size, format: format).image { renderer in
        view.layer.render(in: renderer.cgContext)
      }
      for (container, wasHidden) in zip(iconContainers, containerHiddenStates) {
        container.isHidden = wasHidden
      }
      // Capture the badge, then the symbol itself without its effect surfaces.
      icons.forEach { $0.isHidden = true }
      sharpIcons = UIGraphicsImageRenderer(size: view.bounds.size, format: iconFormat).image { renderer in
        let context = renderer.cgContext
        for container in iconContainers {
          let opacity = effectiveOpacity(of: container, through: view)
          guard opacity > 0 else { continue }
          // Composite the badge and its symbol first, then apply inherited
          // opacity once. Fading the two separately darkens their overlap.
          context.saveGState()
          context.setAlpha(opacity)
          context.beginTransparencyLayer(auxiliaryInfo: nil)
          let origin = container.convert(container.bounds.origin, to: view)
          context.saveGState()
          context.translateBy(x: origin.x, y: origin.y)
          let containerAlpha = container.alpha
          let backgroundColor = container.layer.backgroundColor
          // CALayer.render introduces seams at the four tangents of a fully
          // rounded background. Draw that background as one antialiased ellipse;
          // retain layer rendering for any other contents of the container.
          if container.bounds.width > 0,
             container.bounds.width == container.bounds.height,
             container.layer.cornerRadius >= container.bounds.width / 2,
             let backgroundColor {
            context.setFillColor(backgroundColor)
            context.fillEllipse(in: container.bounds)
            container.layer.backgroundColor = nil
          }
          container.alpha = 1
          container.layer.render(in: context)
          container.alpha = containerAlpha
          container.layer.backgroundColor = backgroundColor
          context.restoreGState()
          for (icon, wasHidden) in zip(icons, iconHiddenStates)
            where !wasHidden && icon.isDescendant(of: container) {
            guard let parent = icon.superview else { continue }
            let iconOpacity = icon.alpha * effectiveOpacity(
              of: parent, through: container, includingAncestor: false
            )
            if iconOpacity > 0 {
              draw(icon, in: view, context: context, opacity: iconOpacity)
            }
          }
          context.endTransparencyLayer()
          context.restoreGState()
        }
      }
    }
    return Layers(content: content, icons: sharpIcons)
  }

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

  private static func effectiveOpacity(of view: UIView, through ancestor: UIView,
                                       includingAncestor: Bool = true) -> CGFloat {
    var opacity: CGFloat = 1
    var current: UIView? = view
    while let node = current {
      if node === ancestor && !includingAncestor { return opacity }
      guard !node.isHidden else { return 0 }
      opacity *= node.alpha
      if node === ancestor { return opacity }
      current = node.superview
    }
    return 0
  }

  private static func draw(_ icon: UIImageView, in view: UIView, context: CGContext,
                           opacity: CGFloat? = nil) {
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
    context.setAlpha(opacity ?? icon.alpha)
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
