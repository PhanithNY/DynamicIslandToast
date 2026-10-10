import CoreImage.CIFilterBuiltins
import UIKit

@available(iOS 17.0, *)
enum DynamicIslandContentBlur {
  private static let context = CIContext(options: [.cacheIntermediates: false])
  private static let queue = DispatchQueue(label: "DynamicIslandToast.contentBlur", qos: .userInitiated)
  static let sampleCount = 7

  struct PreparedFrames {
    let source: UIImage
    let images: [UIImage]

    // Compare actual pixels on the worker, so updated text, tint, symbols or
    // geometry invalidate the presentation's cache before dismissal.
    func matches(_ image: UIImage) -> Bool {
      guard source.scale == image.scale, source.imageOrientation == image.imageOrientation,
            let lhs = source.cgImage, let rhs = image.cgImage,
            lhs.width == rhs.width, lhs.height == rhs.height,
            lhs.bytesPerRow == rhs.bytesPerRow, lhs.bitmapInfo == rhs.bitmapInfo,
            let lhsData = lhs.dataProvider?.data, let rhsData = rhs.dataProvider?.data else { return false }
      return CFEqual(lhsData, rhsData)
    }
  }

  final class Request {
    private let lock = NSLock()
    private var cancelled = false
    var isCancelled: Bool {
      lock.lock()
      defer { lock.unlock() }
      return cancelled
    }
    func cancel() {
      lock.lock()
      cancelled = true
      lock.unlock()
    }
  }

  /// UIView capture stays on main; filtering and cache validation never do.
  @discardableResult
  static func prepare(for image: UIImage, cached: PreparedFrames?,
                      completion: @escaping (PreparedFrames?) -> Void) -> Request {
    let request = Request()
    queue.async {
      let prepared: PreparedFrames? = autoreleasepool {
        guard !request.isCancelled else { return nil }
        if let cached, cached.matches(image) { return cached }
        guard let images = frames(for: image, count: sampleCount, isCancelled: { request.isCancelled }) else { return nil }
        return PreparedFrames(source: image, images: images)
      }
      DispatchQueue.main.async {
        completion(request.isCancelled ? nil : prepared)
      }
    }
    return request
  }

  /// Sparse Gaussian samples are blended by progress on the transition surface.
  static func frames(for image: UIImage, count: Int, radius: CGFloat = 10,
                     isCancelled: () -> Bool = { false }) -> [UIImage]? {
    guard count >= 2, let input = CIImage(image: image) else { return nil }
    let filter = CIFilter.gaussianBlur()
    filter.inputImage = input.clampedToExtent()
    var frames = [image]
    for index in 1..<count {
      guard !isCancelled() else { return nil }
      filter.radius = Float(radius * image.scale * CGFloat(index) / CGFloat(count - 1))
      guard let output = filter.outputImage,
            let cgImage = context.createCGImage(output, from: input.extent) else { return nil }
      frames.append(UIImage(cgImage: cgImage, scale: image.scale, orientation: .up))
    }
    return frames
  }
}
