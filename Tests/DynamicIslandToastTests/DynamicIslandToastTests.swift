import XCTest
import UIKit
import DynamicIslandToastObjC
import DynamicIslandToastObjCTestSupport
@testable import DynamicIslandToast

@available(iOS 17.0, *)
@MainActor
final class DynamicIslandToastTests: XCTestCase {
  func testReconfigurationClearsEffectQueuedDuringContentTransition() async throws {
    let message = DynamicIslandMessageView()
    let source = try XCTUnwrap(UIImage(systemName: "arrow.down.circle"))
    let target = try XCTUnwrap(UIImage(systemName: "checkmark.circle"))
    let newest = try XCTUnwrap(UIImage(systemName: "bell.fill"))
    message.prepareContentTransition()
    message.setTitle("Old", message: "Old", style: .animate(sourceSFSymbolImage: source, targetSFSymbolImage: target, tintColor: .white))
    let delayed = expectation(description: "Old effect is queued behind the transition")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { delayed.fulfill() }
    await fulfillment(of: [delayed], timeout: 2)
    message.setTitle("New", message: "New", style: .leadingIcon(newest, backgroundColor: .clear, foregroundColor: .white, contentMode: .center, preferredBouncyEffect: false))
    message.finishContentTransition(isPresenting: true, isCancelled: false)
    XCTAssertTrue(message.transitionIconView.image === newest)
  }

  func testAnimatedStyleClearsPreviousBadgeAppearance() throws {
    let message = DynamicIslandMessageView(frame: CGRect(x: 0, y: 0, width: 412, height: 96))
    message.setTitle("Old", message: "Old", style: .leadingIcon(UIImage(systemName: "bell.fill"), backgroundColor: .orange, foregroundColor: .black, contentMode: .scaleAspectFit, preferredBouncyEffect: false))
    let source = try XCTUnwrap(UIImage(systemName: "arrow.down.circle"))
    message.setTitle("New", message: "New", style: .animate(sourceSFSymbolImage: source, targetSFSymbolImage: nil, tintColor: .green))
    XCTAssertTrue(message.transitionIconView.image === source)
    XCTAssertEqual(message.transitionIconView.tintColor, .green)
    XCTAssertEqual(message.transitionIconView.contentMode, .center)
    XCTAssertEqual(message.transitionIconView.superview?.backgroundColor, .clear)
  }

  func testHitTestQueriesDoNotDismissAndOutsideRecognizerIsRemoved() async throws {
    guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else {
      throw XCTSkip("This presentation integration test needs the app-hosted Example scheme.")
    }
    let previousKeyWindow = scene.windows.first { $0.isKeyWindow }
    let window = UIWindow(windowScene: scene)
    let root = UIViewController()
    window.rootViewController = root
    window.makeKeyAndVisible()
    defer {
      window.isHidden = true
      previousKeyWindow?.makeKey()
    }
    let toast = UIViewController()
    toast.modalPresentationStyle = .custom
    toast.transitioningDelegate = DynamicIslandSize.delegate
    let presented = expectation(description: "Toast presented")
    root.present(toast, animated: false) { presented.fulfill() }
    await fulfillment(of: [presented], timeout: 3)
    XCTAssertTrue(toast.presentationController is DynamicIslandPresentationController)
    let recognizer = try XCTUnwrap(root.view.gestureRecognizers?.first { $0 is UITapGestureRecognizer })
    XCTAssertFalse(recognizer.cancelsTouchesInView)
    XCTAssertFalse(recognizer.delaysTouchesBegan)
    XCTAssertFalse(recognizer.delaysTouchesEnded)
    XCTAssertNotNil(window.hitTest(CGPoint(x: 200, y: 800), with: nil))
    XCTAssertFalse(toast.isBeingDismissed)
    XCTAssertTrue(root.presentedViewController === toast)
    let dismissed = expectation(description: "Toast dismissed")
    root.dismiss(animated: false) { dismissed.fulfill() }
    await fulfillment(of: [dismissed], timeout: 3)
    XCTAssertNil(recognizer.view)
  }

  func testReconfiguredMessageKeepsNewestIcon() async throws {
    let message = DynamicIslandMessageView()
    let source = try XCTUnwrap(UIImage(systemName: "arrow.down.circle"))
    let oldTarget = try XCTUnwrap(UIImage(systemName: "checkmark.circle"))
    let newIcon = try XCTUnwrap(UIImage(systemName: "bell.fill"))
    message.setTitle("Old", message: "Old", style: .animate(sourceSFSymbolImage: source, targetSFSymbolImage: oldTarget, tintColor: .white))
    message.setTitle("New", message: "New", style: .leadingIcon(newIcon, backgroundColor: .orange, foregroundColor: .black, contentMode: .center, preferredBouncyEffect: false))
    XCTAssertTrue(message.transitionIconView.image === newIcon)
    let delayed = expectation(description: "Previous icon callback elapsed")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { delayed.fulfill() }
    await fulfillment(of: [delayed], timeout: 2)
    XCTAssertTrue(message.transitionIconView.image === newIcon, "The previous configuration must not overwrite the new icon")
  }

  func testDefaultStyleResetsPreviousBadgeAppearance() throws {
    let message = DynamicIslandMessageView()
    let bell = try XCTUnwrap(UIImage(systemName: "bell.fill"))
    message.setTitle("Old", message: "Old", style: .leadingIcon(bell, backgroundColor: .orange, foregroundColor: .black, contentMode: .scaleAspectFit, preferredBouncyEffect: false))
    message.setTitle("New", message: "New", style: .default)
    XCTAssertEqual(message.transitionIconView.tintColor, .white)
    XCTAssertEqual(message.transitionIconView.contentMode, .center)
    XCTAssertEqual(message.transitionIconView.superview?.backgroundColor, .clear)
    XCTAssertFalse(message.transitionIconView.image === bell)
  }

  func testCollapsedToastKeepsTitleAndMessageInOrder() throws {
    let originalOriginY = DynamicIslandSize.originY
    DynamicIslandSize.originY = 20
    defer { DynamicIslandSize.originY = originalOriginY }

    let host = UIView(frame: CGRect(x: 0, y: 0, width: 126, height: 37))
    let messageView = makeMessageView(in: host)
    messageView.setTitle("Reminder", message: "Time to take a short break.")
    host.layoutIfNeeded()

    let labels = messageView.subviews.compactMap { $0 as? UILabel }
    let title = try XCTUnwrap(labels.first)
    let message = try XCTUnwrap(labels.last)
    XCTAssertEqual(labels.count, 2)
    XCTAssertEqual(title.frame.minY, 32, accuracy: 0.5)
    XCTAssertGreaterThanOrEqual(message.frame.minY, title.frame.maxY - 0.5)
    XCTAssertGreaterThanOrEqual(message.frame.height, message.font.lineHeight)
  }

  func testCornerRadiusReaderAcceptsValidCGFloatResults() {
    let fixture = CornerRadiusFixture()
    for radius: CGFloat in [0, 37, 62.5] {
      fixture.radius = radius
      XCTAssertEqual(DynamicIslandToastPrivateCornerRadiusReader.displayCornerRadius(for: fixture)?.doubleValue, Double(radius))
    }
  }

  func testCornerRadiusReaderRejectsInvalidNumbers() {
    let fixture = CornerRadiusFixture()
    for radius: CGFloat in [-1, .nan, .infinity, -.infinity] {
      fixture.radius = radius
      XCTAssertNil(DynamicIslandToastPrivateCornerRadiusReader.displayCornerRadius(for: fixture))
    }
  }

  func testCornerRadiusReaderHandlesUnavailableGetter() {
    XCTAssertNil(DynamicIslandToastPrivateCornerRadiusReader.displayCornerRadius(for: NSObject()))
  }

  func testCornerRadiusReaderCatchesObjectiveCExceptions() {
    XCTAssertNil(DynamicIslandToastPrivateCornerRadiusReader.displayCornerRadius(for: DITThrowingCornerRadiusFixture()))
  }

  func testCornerRadiusReaderRejectsIncompatibleReturnTypesWithoutCallingThem() {
    let objectFixture = ObjectCornerRadiusFixture()
    let integerFixture = IntegerCornerRadiusFixture()
    XCTAssertNil(DynamicIslandToastPrivateCornerRadiusReader.displayCornerRadius(for: objectFixture))
    XCTAssertNil(DynamicIslandToastPrivateCornerRadiusReader.displayCornerRadius(for: integerFixture))
    XCTAssertFalse(objectFixture.wasCalled)
    XCTAssertFalse(integerFixture.wasCalled)
  }

  func testCornerRadiusReaderRejectsIncompatibleArgumentCount() throws {
    let name = "DITArgumentCountFixture_" + UUID().uuidString.replacingOccurrences(of: "-", with: "")
    let fixtureClass: AnyClass = try XCTUnwrap(objc_allocateClassPair(NSObject.self, name, 0))
    let getter: @convention(c) (AnyObject, Selector) -> CGFloat = { _, _ in 42 }
    let implementation = unsafeBitCast(getter, to: IMP.self)
    // Deliberately inconsistent metadata: the selector is a getter but its
    // runtime signature declares an extra argument. Never invoke this IMP.
    let returnType = MemoryLayout<CGFloat>.size == MemoryLayout<Double>.size ? "d" : "f"
    XCTAssertTrue(class_addMethod(fixtureClass, NSSelectorFromString("_displayCornerRadius"), implementation, returnType + "@:@"))
    objc_registerClassPair(fixtureClass)
    let fixture = try XCTUnwrap(class_createInstance(fixtureClass, 0) as? NSObject)
    XCTAssertNil(DynamicIslandToastPrivateCornerRadiusReader.displayCornerRadius(for: fixture))
  }

  func testFailedCornerRadiusReadsUseSafeFallback() {
    let previousOverride = DynamicIslandSize.radiusOverride
    let previousOrigin = DynamicIslandSize.originY
    defer {
      DynamicIslandSize.radiusOverride = previousOverride
      DynamicIslandSize.originY = previousOrigin
    }
    DynamicIslandSize.radiusOverride = nil
    DynamicIslandSize.originY = 20
    for radius: CGFloat? in [nil, -.infinity, .infinity, .nan, -1] {
      XCTAssertEqual(DynamicIslandSize.radius(forDisplayCornerRadius: radius), 37)
    }
    XCTAssertEqual(DynamicIslandSize.radius(for: UIView()), 37)
    XCTAssertEqual(DynamicIslandSize.radius(forDisplayCornerRadius: 62), 42)
    XCTAssertEqual(DynamicIslandSize.radius(forDisplayCornerRadius: 0), 0)
  }

  func testCornerRadiusOverrideWinsAndInvalidOverrideFallsBack() {
    let previousOverride = DynamicIslandSize.radiusOverride
    defer { DynamicIslandSize.radiusOverride = previousOverride }
    DynamicIslandSize.radiusOverride = 44
    XCTAssertEqual(DynamicIslandSize.radius(forDisplayCornerRadius: nil), 44)
    XCTAssertEqual(DynamicIslandSize.radius(forDisplayCornerRadius: 62), 44)
    for radius: CGFloat in [.nan, .infinity, -.infinity] {
      DynamicIslandSize.radiusOverride = radius
      XCTAssertEqual(DynamicIslandSize.radius(for: UIView()), 37)
    }
  }

  func testExpandedToastStillFitsMultilineTextAndCustomFonts() throws {
    let host = UIView()
    let messageView = makeMessageView(in: host)
    messageView.setFonts(
      title: .systemFont(ofSize: 12, weight: .bold),
      message: .systemFont(ofSize: 19, weight: .semibold)
    )
    messageView.setTitle("Update", message: "First line\nSecond line\nThird line")

    let size = host.systemLayoutSizeFitting(
      CGSize(width: 380, height: UIView.layoutFittingCompressedSize.height),
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .defaultLow
    )
    host.frame = CGRect(origin: .zero, size: size)
    host.layoutIfNeeded()

    let labels = messageView.subviews.compactMap { $0 as? UILabel }
    let title = try XCTUnwrap(labels.first)
    let message = try XCTUnwrap(labels.last)
    XCTAssertGreaterThan(size.height, 37)
    XCTAssertGreaterThanOrEqual(message.frame.minY, title.frame.maxY - 0.5)
    XCTAssertGreaterThanOrEqual(message.frame.height, message.font.lineHeight * 3)
    XCTAssertEqual(message.frame.maxY, size.height - DynamicIslandSize.originY, accuracy: 0.5)
  }

  func testWrappedMessageFitsActualContentWidth() throws {
    for width: CGFloat in [280, 334, 374, 400] {
      let host = UIView()
      let messageView = makeMessageView(in: host)
      messageView.setTitle(
        "New message",
        message: "Your team shared an update. The toast grows to fit a longer message, keeping the title and icon alongside the text."
      )
      layoutToFit(host, width: width)

      let message = try XCTUnwrap(messageView.subviews.compactMap { $0 as? UILabel }.last)
      let requiredSize = message.sizeThatFits(CGSize(width: message.bounds.width, height: .greatestFiniteMagnitude))
      XCTAssertGreaterThanOrEqual(message.bounds.height + 0.5, requiredSize.height, "Toast width: \(width)")
    }
  }

  func testMessageHeightIsLimitedToFiveLines() throws {
    let host = UIView()
    let messageView = makeMessageView(in: host)
    messageView.setTitle("Update", message: "One\nTwo\nThree\nFour\nFive\nSix\nSeven")
    layoutToFit(host, width: 374)

    let message = try XCTUnwrap(messageView.subviews.compactMap { $0 as? UILabel }.last)
    let requiredSize = message.sizeThatFits(CGSize(width: message.bounds.width, height: .greatestFiniteMagnitude))
    XCTAssertEqual(message.numberOfLines, 5)
    XCTAssertEqual(message.bounds.height, requiredSize.height, accuracy: 0.5)
  }

  func testPresentedToastFitsWrappedTextAtItsFinalWidth() throws {
    let host = UIView()
    let messageView = makeMessageView(in: host)
    messageView.setTitle(
      "New message",
      message: "Your team shared an update. The toast grows to fit a longer message, keeping the title and icon alongside the text."
    )
    let presentation = DynamicIslandPresentationController(
      presentedViewController: UIViewController(),
      presenting: UIViewController()
    )
    let frame = presentation.frameForPresentedView(host, in: CGRect(x: 0, y: 0, width: 402, height: 874))
    host.frame = frame
    host.layoutIfNeeded()

    let message = try XCTUnwrap(messageView.subviews.compactMap { $0 as? UILabel }.last)
    let requiredSize = message.sizeThatFits(CGSize(width: message.bounds.width, height: .greatestFiniteMagnitude))
    XCTAssertGreaterThanOrEqual(message.bounds.height + 0.5, requiredSize.height)
    XCTAssertLessThanOrEqual(message.frame.maxY, messageView.bounds.height - DynamicIslandSize.originY + 0.5)
  }

  func testPresentedToastFitsAllFiveLines() throws {
    let host = UIView()
    let messageView = makeMessageView(in: host)
    messageView.setTitle("Update", message: "One\nTwo\nThree\nFour\nFive")
    let presentation = DynamicIslandPresentationController(
      presentedViewController: UIViewController(),
      presenting: UIViewController()
    )
    let frame = presentation.frameForPresentedView(host, in: CGRect(x: 0, y: 0, width: 402, height: 874))
    host.frame = frame
    host.layoutIfNeeded()

    let message = try XCTUnwrap(messageView.subviews.compactMap { $0 as? UILabel }.last)
    let expectedHeight = message.sizeThatFits(CGSize(width: message.bounds.width, height: .greatestFiniteMagnitude)).height
    XCTAssertGreaterThanOrEqual(message.bounds.height + 0.5, expectedHeight)
    XCTAssertGreaterThanOrEqual(message.bounds.height, message.font.lineHeight * 5)
    XCTAssertLessThanOrEqual(message.frame.maxY, messageView.bounds.height - DynamicIslandSize.originY + 0.5)
  }

  func testContentSnapshotIsIndependentOfHostFade() throws {
    let host = UIView(frame: CGRect(x: 0, y: 0, width: 374, height: 110))
    let messageView = makeMessageView(in: host)
    host.layoutIfNeeded()
    let badge = try XCTUnwrap(messageView.subviews.first { !($0 is UILabel) })

    messageView.prepareContentTransition()
    messageView.setAlphaForSubviews(to: 1)
    XCTAssertEqual(badge.alpha, 1, "The snapshot needs fully visible content, independent of the host fade.")
    messageView.finishContentTransition(isPresenting: true, isCancelled: false)
    XCTAssertEqual(badge.alpha, 1)

    messageView.prepareContentTransition()
    messageView.setAlphaForSubviews(to: 0)
    XCTAssertEqual(badge.alpha, 1, "The host must not hide content while a transition snapshot is active.")
    messageView.finishContentTransition(isPresenting: false, isCancelled: false)
    XCTAssertEqual(badge.alpha, 0)

    messageView.setAlphaForSubviews(to: 1)
    XCTAssertEqual(badge.alpha, 1, "Normal content visibility must resume after the transition.")
  }

  func testCancelledContentTransitionRestoresPreviousVisibility() throws {
    let host = UIView(frame: CGRect(x: 0, y: 0, width: 374, height: 110))
    let messageView = makeMessageView(in: host)
    let badge = try XCTUnwrap(messageView.subviews.first { !($0 is UILabel) })
    messageView.setAlphaForSubviews(to: 0.7)
    messageView.prepareContentTransition()
    messageView.finishContentTransition(isPresenting: false, isCancelled: true)
    XCTAssertEqual(badge.alpha, 0.7, accuracy: 0.001)
  }

  func testShapeMorphKeepsContentSizeAndVerticalCenterStable() {
    let expanded = CGRect(x: 20, y: 20, width: 374, height: 180)
    let collapsed = CGRect(x: 144, y: 20, width: 126, height: 37)
    let image = UIGraphicsImageRenderer(size: expanded.size).image { _ in }
    let surface = DynamicIslandTransitionView(
      image: image, expandedFrame: expanded, collapsedFrame: collapsed,
      cornerRadius: 48, backgroundColor: .black, reducedMotion: false
    )
    surface.prepare(isPresenting: true)
    XCTAssertEqual(surface.shapeView.frame, collapsed)
    XCTAssertEqual(surface.contentView.bounds.size, expanded.size)
    XCTAssertEqual(surface.contentView.center.y, collapsed.height / 2)

    surface.render(progress: 1, isPresenting: true)
    finishShapeAnimation(surface, isPresenting: true)
    XCTAssertEqual(surface.shapeView.frame, expanded)
    XCTAssertEqual(surface.contentView.bounds.size, expanded.size)
    XCTAssertEqual(surface.contentView.center.y, expanded.height / 2)

    surface.render(progress: 1, isPresenting: false)
    finishShapeAnimation(surface, isPresenting: false)
    XCTAssertEqual(surface.contentView.bounds.size, expanded.size)
    XCTAssertEqual(surface.contentView.center.y, collapsed.height / 2)
  }

  func testGaussianBlurSoftensContentInBothDirections() throws {
    let image = UIGraphicsImageRenderer(size: CGSize(width: 60, height: 60)).image { context in
      UIColor.black.setFill()
      context.fill(CGRect(x: 0, y: 0, width: 60, height: 60))
      UIColor.white.setFill()
      context.fill(CGRect(x: 26, y: 26, width: 8, height: 8))
    }
    let frames = try XCTUnwrap(DynamicIslandContentBlur.frames(for: image, count: 3))
    XCTAssertEqual(frames.count, 3)
    XCTAssertTrue(frames.allSatisfy { $0.size == image.size })
    XCTAssertEqual(try pixel(in: frames[0], at: CGPoint(x: 20, y: 30))[0], 0)
    XCTAssertGreaterThan(try pixel(in: frames[2], at: CGPoint(x: 20, y: 30))[0], 0)
    XCTAssertGreaterThan(try pixel(in: frames[2], at: CGPoint(x: 30, y: 20))[0], 0)
    let brightness = try frames.map { try pixel(in: $0, at: CGPoint(x: 30, y: 30))[0] }
    XCTAssertGreaterThan(brightness[0], brightness[1])
    XCTAssertGreaterThan(brightness[1], brightness[2])
  }

  func testReducedMotionUsesOnlyOpacityAndRemovesTransitionSurface() {
    let expanded = CGRect(x: 20, y: 20, width: 374, height: 100)
    let image = UIGraphicsImageRenderer(size: expanded.size).image { _ in }
    let surface = DynamicIslandTransitionView(
      image: image, expandedFrame: expanded,
      collapsedFrame: CGRect(x: 144, y: 20, width: 126, height: 37),
      cornerRadius: 48, backgroundColor: .black, reducedMotion: true
    )
    surface.prepare(isPresenting: true)
    XCTAssertEqual(surface.shapeView.frame, expanded)
    XCTAssertEqual(surface.contentView.transform, .identity)
    XCTAssertEqual(surface.contentView.alpha, 0)
    XCTAssertNil(surface.contentView.animationImages)
    surface.render(progress: 1, isPresenting: true)
    XCTAssertEqual(surface.contentView.alpha, 1)
    surface.render(progress: 1, isPresenting: false)
    XCTAssertEqual(surface.shapeView.frame, expanded)
    let container = UIView()
    container.addSubview(surface)
    surface.finish()
    XCTAssertNil(surface.superview)
    XCTAssertNil(surface.contentView.animationImages)
  }

  func testPresentationEffectsUseTheSameProgressEvenAfterSkippedFrames() {
    let expanded = CGRect(x: 20, y: 20, width: 374, height: 100)
    let collapsed = CGRect(x: 144, y: 20, width: 126, height: 37)
    let image = UIGraphicsImageRenderer(size: expanded.size).image { _ in }
    let surface = DynamicIslandTransitionView(
      image: image, expandedFrame: expanded, collapsedFrame: collapsed,
      cornerRadius: 48, backgroundColor: .black, reducedMotion: false
    )
    surface.prepare(isPresenting: true, blurFrames: Array(repeating: image, count: 7))
    XCTAssertEqual(surface.blurFrameIndex, 6)
    // Jump directly to the halfway timestamp as if intervening frames dropped.
    surface.render(progress: 0.5, isPresenting: true)
    let visibility = surface.contentView.alpha
    XCTAssertEqual(surface.contentView.transform.a, 0.86 + 0.14 * visibility, accuracy: 0.001)
    XCTAssertEqual(surface.blurFrameIndex, Int((1 - visibility) * 6))
    // Content updates must not overwrite geometry owned by UIKit's spring.
    XCTAssertEqual(surface.shapeView.frame, collapsed)
    XCTAssertEqual(surface.contentView.bounds.size, expanded.size)
    XCTAssertEqual(surface.contentView.center.y, surface.shapeView.bounds.midY)
    XCTAssertNil(surface.contentView.animationImages, "Blur must be sampled, never played on another clock.")
    surface.render(progress: 1, isPresenting: true)
    finishShapeAnimation(surface, isPresenting: true)
    XCTAssertEqual(surface.shapeView.frame, expanded)
    XCTAssertEqual(surface.contentView.alpha, 1)
    XCTAssertEqual(surface.contentView.transform, .identity)
    XCTAssertEqual(surface.blurFrameIndex, 0)
  }

  func testShapeUsesUIKitSpringWithoutChangingContentLayout() {
    let expanded = CGRect(x: 20, y: 20, width: 374, height: 100)
    let collapsed = CGRect(x: 144, y: 20, width: 126, height: 37)
    let image = UIGraphicsImageRenderer(size: expanded.size).image { _ in }
    let surface = DynamicIslandTransitionView(
      image: image, expandedFrame: expanded, collapsedFrame: collapsed,
      cornerRadius: 48, backgroundColor: .black, reducedMotion: false
    )
    surface.prepare(isPresenting: true)
    let presentation = surface.shapeAnimator(duration: 0.6, isPresenting: true)
    XCTAssertTrue(presentation.timingParameters is UISpringTimingParameters)
    XCTAssertEqual(presentation.duration, 0.6)
    presentation.startAnimation()
    presentation.stopAnimation(false)
    presentation.finishAnimation(at: .end)
    XCTAssertEqual(surface.shapeView.frame, expanded)
    surface.render(progress: 0.5, isPresenting: true)
    XCTAssertEqual(surface.shapeView.frame, expanded, "Content must leave the spring's geometry alone.")
    XCTAssertEqual(surface.contentView.bounds.size, expanded.size)
    XCTAssertEqual(surface.contentView.center.y, surface.shapeView.bounds.midY)
    let dismissal = surface.shapeAnimator(duration: 0.35, isPresenting: false)
    XCTAssertTrue(dismissal.timingParameters is UISpringTimingParameters)
    XCTAssertEqual(dismissal.duration, 0.35)
    dismissal.startAnimation()
    dismissal.stopAnimation(false)
    dismissal.finishAnimation(at: .end)
    XCTAssertEqual(surface.shapeView.frame, collapsed)
    XCTAssertEqual(surface.contentView.bounds.size, expanded.size)
    XCTAssertEqual(surface.contentView.center.y, collapsed.height / 2)
  }

  func testDefaultTransitionDurations() {
    XCTAssertEqual(DynamicIslandAnimatedTransitioning(transitionType: .present).transitionDuration(using: nil), 0.6)
    XCTAssertEqual(DynamicIslandAnimatedTransitioning(transitionType: .dismiss).transitionDuration(using: nil), 0.35)
  }

  func testDismissalFinishesAllContentEffectsAtQuarterDuration() {
    let expanded = CGRect(x: 20, y: 20, width: 374, height: 100)
    let collapsed = CGRect(x: 144, y: 20, width: 126, height: 37)
    let image = UIGraphicsImageRenderer(size: expanded.size).image { _ in }
    let surface = DynamicIslandTransitionView(
      image: image, expandedFrame: expanded, collapsedFrame: collapsed,
      cornerRadius: 48, backgroundColor: .black, reducedMotion: false
    )
    surface.prepare(isPresenting: false, blurFrames: Array(repeating: image, count: 7))
    XCTAssertEqual(surface.contentView.alpha, 1)
    XCTAssertEqual(surface.blurFrameIndex, 0)
    surface.render(progress: 0.125, isPresenting: false)
    let visibility = surface.contentView.alpha
    XCTAssertGreaterThan(visibility, 0)
    XCTAssertLessThan(visibility, 1)
    XCTAssertEqual(surface.contentView.transform.a, 0.86 + 0.14 * visibility, accuracy: 0.001)
    XCTAssertEqual(surface.blurFrameIndex, Int((1 - visibility) * 6))
    surface.render(progress: 0.25, isPresenting: false)
    XCTAssertEqual(surface.contentView.alpha, 0)
    XCTAssertEqual(surface.blurFrameIndex, 6)
    XCTAssertEqual(surface.contentView.transform.a, 0.86, accuracy: 0.001)
    XCTAssertGreaterThan(surface.shapeView.bounds.width, collapsed.width)
    surface.render(progress: 1, isPresenting: false)
    finishShapeAnimation(surface, isPresenting: false)
    XCTAssertEqual(surface.shapeView.frame, collapsed)
    XCTAssertEqual(surface.contentView.alpha, 0)
  }

  func testClockAdvancesFromAbsoluteTimeAndCompletesOnlyOnce() {
    var updates: [CGFloat] = []
    var completions: [Bool] = []
    let clock = DynamicIslandTransitionClock(duration: 0.6, update: {
      updates.append($0)
    }, completion: {
      completions.append($0)
    })
    clock.advance(elapsed: 0)
    clock.advance(elapsed: 0.3)
    clock.advance(elapsed: 0.6)
    clock.advance(elapsed: 0.9)
    clock.cancel()
    XCTAssertEqual(updates, [0, 0.5, 1])
    XCTAssertEqual(completions, [false])
  }

  func testBlurPreparationIsAsynchronousAndReusesOnlyMatchingPixels() async throws {
    let image = UIGraphicsImageRenderer(size: CGSize(width: 380, height: 191)).image { context in
      UIColor.white.setFill()
      context.fill(CGRect(x: 100, y: 70, width: 80, height: 40))
    }
    var mainQueueRan = false
    DispatchQueue.main.async { mainQueueRan = true }
    let prepared: DynamicIslandContentBlur.PreparedFrames? = await withCheckedContinuation { continuation in
      DynamicIslandContentBlur.prepare(for: image, cached: nil) { frames in
        XCTAssertTrue(Thread.isMainThread)
        XCTAssertTrue(mainQueueRan, "Filtering must allow other main-queue work to run.")
        continuation.resume(returning: frames)
      }
    }
    let frames = try XCTUnwrap(prepared)
    XCTAssertEqual(frames.images.count, 7)
    let reused: DynamicIslandContentBlur.PreparedFrames? = await withCheckedContinuation { continuation in
      DynamicIslandContentBlur.prepare(for: image, cached: frames) { continuation.resume(returning: $0) }
    }
    XCTAssertTrue(try XCTUnwrap(reused).images[6] === frames.images[6])
    let changed = UIGraphicsImageRenderer(size: image.size).image { context in
      UIColor.red.setFill()
      context.fill(CGRect(origin: .zero, size: image.size))
    }
    let refreshed: DynamicIslandContentBlur.PreparedFrames? = await withCheckedContinuation { continuation in
      DynamicIslandContentBlur.prepare(for: changed, cached: frames) { continuation.resume(returning: $0) }
    }
    XCTAssertFalse(try XCTUnwrap(refreshed).images[6] === frames.images[6])
  }

  func testCancelledBlurPreparationCannotDeliverImages() async {
    let image = UIGraphicsImageRenderer(size: CGSize(width: 380, height: 191)).image { _ in }
    let result: DynamicIslandContentBlur.PreparedFrames? = await withCheckedContinuation { continuation in
      let request = DynamicIslandContentBlur.prepare(for: image, cached: nil) { continuation.resume(returning: $0) }
      request.cancel()
    }
    XCTAssertNil(result)
  }

  func testSparseBlurSamplesBlendBetweenFrames() {
    let frame = CGRect(x: 20, y: 20, width: 100, height: 80)
    let images = [UIColor.red, .green, .blue].map { color in
      UIGraphicsImageRenderer(size: frame.size).image { context in
        color.setFill()
        context.fill(CGRect(origin: .zero, size: frame.size))
      }
    }
    let surface = DynamicIslandTransitionView(image: images[0], expandedFrame: frame,
      collapsedFrame: CGRect(x: 20, y: 20, width: 60, height: 37),
      cornerRadius: 37, backgroundColor: .black, reducedMotion: false)
    surface.prepare(isPresenting: true, blurFrames: images)
    surface.render(progress: 0.1, isPresenting: true)
    XCTAssertTrue(surface.blendedContentView.lowerImage === images[surface.blurFrameIndex])
    XCTAssertTrue(surface.blendedContentView.upperImage === images[surface.blurFrameIndex + 1])
    XCTAssertGreaterThan(surface.blendedContentView.fraction, 0)
    XCTAssertLessThan(surface.blendedContentView.fraction, 1)
    XCTAssertEqual(surface.blendedContentView.frame.size, surface.contentView.bounds.size)
  }

  func testAutoDismissCannotFireFromAnEarlierPresentation() {
    let state = DynamicIslandPresentationState()
    var dismissals = 0
    let old = state.begin()
    state.schedule(after: 10, generation: old) { dismissals += 1 }
    state.dismissalWillBegin()
    state.dismissalDidEnd(completed: true)
    let current = state.begin()
    state.schedule(after: 10, generation: current) { dismissals += 1 }
    state.fire(generation: old)
    XCTAssertEqual(dismissals, 0)
    state.fire(generation: current)
    state.fire(generation: current)
    XCTAssertEqual(dismissals, 1)
    state.invalidate()
  }

  func testManualDismissalInvalidatesTimerAndReleasesBlurCache() {
    let state = DynamicIslandPresentationState()
    let image = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10)).image { _ in }
    let generation = state.begin()
    state.blurFrames = .init(source: image, images: [image])
    state.schedule(after: 10, generation: generation) { XCTFail("Old dismissal must be cancelled") }
    state.dismissalWillBegin()
    state.fire(generation: generation)
    state.dismissalDidEnd(completed: true)
    XCTAssertNil(state.blurFrames)
    XCTAssertFalse(state.isActive)
    state.fire(generation: generation)
  }

  func testCancelledDismissalResumesTimerWithNewGeneration() {
    let state = DynamicIslandPresentationState()
    var dismissals = 0
    let old = state.begin()
    state.schedule(after: 10, generation: old) { dismissals += 1 }
    state.dismissalWillBegin()
    state.dismissalDidEnd(completed: false)
    state.fire(generation: old)
    XCTAssertEqual(dismissals, 0)
    XCTAssertTrue(state.isActive)
    state.fire(generation: state.generation)
    XCTAssertEqual(dismissals, 1)
    state.invalidate()
  }

  func testCollapsedGeometryUsesCurrentBoundsAndConfiguration() {
    let originalOverride = DynamicIslandSize.startFrameOverride
    let originalOriginY = DynamicIslandSize.originY
    defer {
      DynamicIslandSize.startFrameOverride = originalOverride
      DynamicIslandSize.originY = originalOriginY
    }
    DynamicIslandSize.startFrameOverride = nil
    for bounds in [CGRect(x: 0, y: 0, width: 320, height: 700),
                   CGRect(x: 0, y: 0, width: 700, height: 320),
                   CGRect(x: 100, y: 50, width: 500, height: 800)] {
      let frame = DynamicIslandSize.startFrame(in: bounds)
      XCTAssertEqual(frame.midX, bounds.midX)
      XCTAssertEqual(frame.minY, bounds.minY + DynamicIslandSize.originY)
    }
    DynamicIslandSize.originY = 24
    XCTAssertEqual(DynamicIslandSize.startFrame(in: .zero).minY, 24)
    let custom = CGRect(x: 1, y: 2, width: 3, height: 4)
    DynamicIslandSize.startFrameOverride = custom
    XCTAssertEqual(DynamicIslandSize.startFrame(in: CGRect(x: 10, y: 20, width: 700, height: 300)), custom)
  }

  func testPresentationGeometryUsesContainerOriginAndRefreshesIconSize() {
    let original = DynamicIslandSize.radiusOverride
    defer { DynamicIslandSize.radiusOverride = original }
    let host = UIView()
    let message = makeMessageView(in: host)
    message.setTitle("Hello", message: "World")
    let presentation = DynamicIslandPresentationController(presentedViewController: UIViewController(), presenting: UIViewController())
    let bounds = CGRect(x: 100, y: 50, width: 402, height: 874)
    DynamicIslandSize.radiusOverride = 40
    let frame = presentation.frameForPresentedView(host, in: bounds)
    host.frame = frame
    host.layoutIfNeeded()
    XCTAssertEqual(frame.minX, bounds.minX + DynamicIslandSize.originY)
    XCTAssertEqual(frame.minY, bounds.minY + DynamicIslandSize.originY)
    XCTAssertGreaterThanOrEqual(frame.height, 80)
    XCTAssertEqual(message.transitionIconView.superview?.bounds.width, 44)
    DynamicIslandSize.radiusOverride = 18
    message.setNeedsLayout()
    message.layoutIfNeeded()
    host.layoutIfNeeded()
    XCTAssertEqual(message.transitionIconView.superview?.bounds.width, 0)
  }

  private func finishShapeAnimation(_ surface: DynamicIslandTransitionView, isPresenting: Bool) {
    let animator = surface.shapeAnimator(duration: isPresenting ? 0.6 : 0.35, isPresenting: isPresenting)
    animator.startAnimation()
    animator.stopAnimation(false)
    animator.finishAnimation(at: .end)
  }

  func testCancelledClockCannotApplyLateFramesOrFinishAgain() {
    var updates: [CGFloat] = []
    var completions: [Bool] = []
    let clock = DynamicIslandTransitionClock(duration: 0.6, update: {
      updates.append($0)
    }, completion: {
      completions.append($0)
    })
    clock.advance(elapsed: 0)
    clock.cancel()
    clock.advance(elapsed: 0.6)
    clock.cancel()
    XCTAssertEqual(updates, [0])
    XCTAssertEqual(completions, [true])
  }

  func testSnapshotPreservesSymbolTintAndBadgeWithoutEffectSurfaces() throws {
    let host = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
    host.backgroundColor = .orange
    let icon = UIImageView(frame: host.bounds)
    icon.image = UIImage(systemName: "bell.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 32))
    icon.contentMode = .center
    icon.tintColor = .black
    icon.addSymbolEffect(.bounce)
    host.addSubview(icon)
    let snapshot = DynamicIslandContentSnapshot.image(of: host, icons: [icon])
    let edge = try pixel(in: snapshot, at: CGPoint(x: 30, y: 6))
    let center = try pixel(in: snapshot, at: CGPoint(x: 30, y: 30))
    XCTAssertGreaterThan(edge[0], 240, "The badge must remain orange outside the symbol.")
    XCTAssertGreaterThan(edge[1], 100)
    XCTAssertLessThan(center[0], 20, "The symbol must retain its black template tint.")
    XCTAssertFalse(icon.isHidden, "Snapshot capture must restore live icon visibility.")
  }

  func testSnapshotSeparatesLeadingIconAndBadgeFromBlurContent() throws {
    let host = UIView(frame: CGRect(x: 0, y: 0, width: 140, height: 80))
    host.backgroundColor = .black
    let badge = UIView(frame: CGRect(x: 10, y: 10, width: 60, height: 60))
    badge.backgroundColor = .orange
    badge.layer.cornerRadius = 30
    badge.layer.masksToBounds = true
    host.addSubview(badge)
    let icon = UIImageView(frame: badge.bounds)
    icon.image = UIImage(systemName: "bell.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 32))
    icon.contentMode = .center
    icon.tintColor = .black
    icon.addSymbolEffect(.bounce)
    badge.addSubview(icon)
    let text = UILabel(frame: CGRect(x: 80, y: 20, width: 60, height: 40))
    text.text = "Text"
    text.textColor = .white
    host.addSubview(text)

    let layers = DynamicIslandContentSnapshot.layers(of: host, iconContainers: [badge], icons: [icon])
    let sharpIcon = try XCTUnwrap(layers.icons)
    let contentEdge = try pixel(in: layers.content, at: CGPoint(x: 20, y: 40))
    let iconEdge = try pixel(in: sharpIcon, at: CGPoint(x: 20, y: 40))
    let symbolCenter = try pixel(in: sharpIcon, at: CGPoint(x: 40, y: 40))
    XCTAssertEqual(contentEdge, [0, 0, 0, 255], "The blur input must not contain the icon's badge.")
    XCTAssertGreaterThan(iconEdge[0], 240)
    XCTAssertGreaterThan(iconEdge[1], 100)
    XCTAssertLessThan(symbolCenter[0], 20, "The sharp symbol retains its black tint.")
    XCTAssertEqual(try pixel(in: sharpIcon, at: CGPoint(x: 100, y: 40))[3], 0, "The icon overlay must not contain the text.")
    XCTAssertFalse(icon.isHidden)
    XCTAssertFalse(badge.isHidden)

    badge.isHidden = true
    icon.isHidden = true
    let hiddenLayers = DynamicIslandContentSnapshot.layers(of: host, iconContainers: [badge], icons: [icon])
    XCTAssertEqual(try pixel(in: XCTUnwrap(hiddenLayers.icons), at: CGPoint(x: 40, y: 40))[3], 0)
    XCTAssertTrue(icon.isHidden)
    XCTAssertTrue(badge.isHidden)
  }

  func testLeadingIconRemainsSharpWhileSharingContentFadeAndScale() throws {
    let expanded = CGRect(x: 20, y: 20, width: 140, height: 80)
    let content = UIGraphicsImageRenderer(size: expanded.size).image { context in
      UIColor.black.setFill()
      context.fill(CGRect(origin: .zero, size: expanded.size))
      UIColor.white.setFill()
      context.fill(CGRect(x: 90, y: 30, width: 8, height: 8))
    }
    let icon = UIGraphicsImageRenderer(size: expanded.size).image { context in
      UIColor.orange.setFill()
      context.fill(CGRect(x: 20, y: 30, width: 8, height: 8))
    }
    let frames = try XCTUnwrap(DynamicIslandContentBlur.frames(for: content, count: 3))
    let surface = DynamicIslandTransitionView(
      image: content, iconImage: icon, expandedFrame: expanded,
      collapsedFrame: CGRect(x: 27, y: 20, width: 126, height: 37),
      cornerRadius: 37, backgroundColor: .black, reducedMotion: false
    )
    for isPresenting in [true, false] {
      surface.prepare(isPresenting: isPresenting, blurFrames: frames)
      surface.render(progress: 0.125, isPresenting: isPresenting)
      XCTAssertFalse(surface.blendedContentView.lowerImage === content, "Text uses a blurred sample during both transitions.")
      XCTAssertTrue(surface.sharpIconView.image === icon, "The icon always uses its original sharp image.")
      XCTAssertTrue(surface.sharpIconView.superview === surface.contentView)
      XCTAssertEqual(surface.sharpIconView.frame, surface.contentView.bounds)
      XCTAssertGreaterThan(surface.contentView.alpha, 0)
      XCTAssertLessThan(surface.contentView.alpha, 1)
      XCTAssertLessThan(surface.contentView.transform.a, 1)
    }
    surface.finish()
    XCTAssertNil(surface.sharpIconView.image)
  }

  func testSnapshotOmitsIconsHiddenByAnAncestor() throws {
    let host = UIView(frame: CGRect(x: 0, y: 0, width: 120, height: 80))
    let ancestor = UIView(frame: host.bounds)
    host.addSubview(ancestor)
    let badge = UIView(frame: CGRect(x: 10, y: 10, width: 60, height: 60))
    badge.backgroundColor = .orange
    ancestor.addSubview(badge)
    let icon = UIImageView(frame: CGRect(x: 20, y: 20, width: 20, height: 20))
    icon.image = UIGraphicsImageRenderer(size: icon.bounds.size).image { renderer in
      UIColor.white.setFill()
      renderer.fill(icon.bounds)
    }
    badge.addSubview(icon)
    ancestor.isHidden = true

    let layers = DynamicIslandContentSnapshot.layers(of: host, iconContainers: [badge], icons: [icon])
    let sharp = try XCTUnwrap(layers.icons)
    XCTAssertEqual(try pixel(in: sharp, at: CGPoint(x: 15, y: 40))[3], 0)
    XCTAssertEqual(try pixel(in: sharp, at: CGPoint(x: 40, y: 40))[3], 0)
    XCTAssertTrue(ancestor.isHidden)
    XCTAssertFalse(badge.isHidden)
    XCTAssertFalse(icon.isHidden)
  }

  func testSnapshotAppliesInheritedOpacityOnceToBadgeAndSymbolGroup() throws {
    let host = UIView(frame: CGRect(x: 0, y: 0, width: 120, height: 80))
    host.alpha = 0.5
    let ancestor = UIView(frame: host.bounds)
    ancestor.alpha = 0.5
    host.addSubview(ancestor)
    let badge = UIView(frame: CGRect(x: 10, y: 10, width: 60, height: 60))
    badge.backgroundColor = .orange
    badge.alpha = 0.5
    ancestor.addSubview(badge)
    let icon = UIImageView(frame: CGRect(x: 20, y: 20, width: 20, height: 20))
    icon.image = UIGraphicsImageRenderer(size: icon.bounds.size).image { renderer in
      UIColor.white.setFill()
      renderer.fill(icon.bounds)
    }
    icon.alpha = 0.5
    badge.addSubview(icon)

    let layers = DynamicIslandContentSnapshot.layers(of: host, iconContainers: [badge], icons: [icon])
    let sharp = try XCTUnwrap(layers.icons)
    let badgePixel = try pixel(in: sharp, at: CGPoint(x: 15, y: 40))
    let symbolPixel = try pixel(in: sharp, at: CGPoint(x: 40, y: 40))
    XCTAssertEqual(Int(badgePixel[3]), 32, accuracy: 2)
    XCTAssertEqual(Int(symbolPixel[3]), 32, accuracy: 2,
                   "Overlapping symbol and badge must inherit opacity as one group.")
    XCTAssertGreaterThan(symbolPixel[2], badgePixel[2], "The symbol must still be included in the group.")
    XCTAssertEqual(host.alpha, 0.5)
    XCTAssertEqual(ancestor.alpha, 0.5)
    XCTAssertEqual(badge.alpha, 0.5)
    XCTAssertEqual(icon.alpha, 0.5)
    XCTAssertFalse(icon.isHidden)
  }

  func testOriginChangesRefreshExistingMessageBeforeFitting() throws {
    let originalOrigin = DynamicIslandSize.originY
    let originalRadius = DynamicIslandSize.radiusOverride
    defer {
      DynamicIslandSize.originY = originalOrigin
      DynamicIslandSize.radiusOverride = originalRadius
    }
    DynamicIslandSize.radiusOverride = 37
    DynamicIslandSize.originY = 11
    let reusedHost = UIView()
    let reusedMessage = makeMessageView(in: reusedHost)
    reusedMessage.setTitle("Reminder", message: "First line\nSecond line")
    layoutToFit(reusedHost, width: 320)

    for origin: CGFloat in [40, 20] {
      DynamicIslandSize.originY = origin
      let freshHost = UIView()
      let freshMessage = makeMessageView(in: freshHost)
      freshMessage.setTitle("Reminder", message: "First line\nSecond line")
      let fittingSize = CGSize(width: 320, height: UIView.layoutFittingCompressedSize.height)

      // Fit the parent immediately: refreshing in the child's layoutSubviews
      // would leave this measurement using the previous configuration.
      let reusedSize = reusedHost.systemLayoutSizeFitting(
        fittingSize, withHorizontalFittingPriority: .required,
        verticalFittingPriority: .defaultLow
      )
      let freshSize = freshHost.systemLayoutSizeFitting(
        fittingSize, withHorizontalFittingPriority: .required,
        verticalFittingPriority: .defaultLow
      )
      XCTAssertEqual(reusedSize.height, freshSize.height, accuracy: 0.5)
      reusedHost.frame = CGRect(origin: .zero, size: reusedSize)
      reusedHost.layoutIfNeeded()
      let labels = reusedMessage.subviews.compactMap { $0 as? UILabel }
      let title = try XCTUnwrap(labels.first)
      let message = try XCTUnwrap(labels.last)
      XCTAssertEqual(reusedMessage.bounds.maxX - title.frame.maxX, origin, accuracy: 0.5)
      XCTAssertEqual(reusedMessage.bounds.maxY - message.frame.maxY, origin, accuracy: 0.5)
    }
  }


  func testBlurInterpolationPreservesTranslucentPixelsAcrossSamples() throws {
    let frame = CGRect(x: 0, y: 0, width: 40, height: 40)
    let image = UIGraphicsImageRenderer(size: frame.size).image { context in
      UIColor.white.withAlphaComponent(0.5).setFill()
      context.fill(frame)
    }
    let surface = DynamicIslandTransitionView(image: image, expandedFrame: frame,
      collapsedFrame: frame, cornerRadius: 0, backgroundColor: .clear, reducedMotion: false)
    surface.prepare(isPresenting: true, blurFrames: [image, image, image])
    for progress: CGFloat in [0, 0.1, 0.2, 0.3, 0.5, 0.8, 1] {
      surface.render(progress: progress, isPresenting: true)
      // Isolate sampling from the intentional whole-content fade and scale.
      surface.contentView.alpha = 1
      surface.contentView.transform = .identity
      surface.blendedContentView.layer.displayIfNeeded()
      let snapshot = UIGraphicsImageRenderer(size: frame.size).image { context in
        surface.shapeView.layer.render(in: context.cgContext)
      }
      let rgba = try pixel(in: snapshot, at: CGPoint(x: 20, y: 20))
      XCTAssertEqual(Int(rgba[3]), 128, accuracy: 2, "Progress \(progress) changed sample alpha")
    }
  }

  func testBlurInterpolationWeightsColorAndAlphaTogether() throws {
    let frame = CGRect(x: 0, y: 0, width: 40, height: 40)
    let images = [UIColor.red.withAlphaComponent(0.25), UIColor.blue.withAlphaComponent(0.75)].map { color in
      UIGraphicsImageRenderer(size: frame.size).image { context in
        color.setFill()
        context.fill(frame)
      }
    }
    let blend = DynamicIslandBlendedImageView(frame: frame)
    blend.setSamples(images[0], images[1], fraction: 0.5)
    blend.layer.displayIfNeeded()
    let snapshot = UIGraphicsImageRenderer(size: frame.size).image { context in
      blend.layer.render(in: context.cgContext)
    }
    let rgba = try pixel(in: snapshot, at: CGPoint(x: 20, y: 20))
    XCTAssertEqual(Int(rgba[0]), 32, accuracy: 2)
    XCTAssertEqual(Int(rgba[2]), 96, accuracy: 2)
    XCTAssertEqual(Int(rgba[3]), 128, accuracy: 2)
  }


  func testShadowFollowsPillSpringWhileContentRemainsClipped() async throws {
    guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else {
      throw XCTSkip("Requires the app-hosted Example scheme.")
    }
    let previous = scene.windows.first { $0.isKeyWindow }
    let window = UIWindow(windowScene: scene)
    let host = UIViewController()
    window.rootViewController = host
    window.makeKeyAndVisible()
    defer { window.isHidden = true; previous?.makeKey() }
    let frame = CGRect(x: 20, y: 20, width: 374, height: 100)
    let image = UIGraphicsImageRenderer(size: frame.size).image { _ in }
    let layer = CALayer()
    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOpacity = 0.4
    layer.shadowRadius = 12
    layer.shadowOffset = CGSize(width: 0, height: 4)
    let surface = DynamicIslandTransitionView(image: image, expandedFrame: frame,
      collapsedFrame: CGRect(x: 144, y: 20, width: 126, height: 37),
      cornerRadius: 48, backgroundColor: .black, reducedMotion: false, shadowLayer: layer)
    surface.frame = host.view.bounds
    host.view.addSubview(surface)
    surface.prepare(isPresenting: true)
    XCTAssertEqual(surface.shapeView.layer.shadowOpacity, 0)
    XCTAssertFalse(surface.shapeView.clipsToBounds)
    XCTAssertTrue(surface.clippingView.clipsToBounds)
    XCTAssertEqual(surface.shapeView.layer.shadowRadius, layer.shadowRadius)
    XCTAssertEqual(surface.shapeView.layer.shadowOffset, layer.shadowOffset)
    let animator = surface.shapeAnimator(duration: 1, isPresenting: true)
    animator.startAnimation()
    let tick = expectation(description: "Spring is between endpoints")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { tick.fulfill() }
    await fulfillment(of: [tick], timeout: 3)
    let pill = try XCTUnwrap(surface.shapeView.layer.presentation())
    let clip = try XCTUnwrap(surface.clippingView.layer.presentation())
    XCTAssertGreaterThan(pill.shadowOpacity, 0)
    XCTAssertLessThan(pill.shadowOpacity, layer.shadowOpacity)
    XCTAssertEqual(pill.bounds.width, clip.bounds.width, accuracy: 0.5)
    XCTAssertEqual(pill.cornerRadius, clip.cornerRadius, accuracy: 0.5)
    animator.stopAnimation(false)
    animator.finishAnimation(at: .end)
    XCTAssertEqual(surface.shapeView.layer.shadowOpacity, layer.shadowOpacity)
    finishShapeAnimation(surface, isPresenting: false)
    XCTAssertEqual(surface.shapeView.layer.shadowOpacity, 0)
  }

  func testReducedMotionFadesShadowAndDoesNotInventClippedHostShadow() {
    let frame = CGRect(x: 20, y: 20, width: 100, height: 80)
    let image = UIGraphicsImageRenderer(size: frame.size).image { _ in }
    let layer = CALayer()
    layer.shadowOpacity = 0.4
    let surface = DynamicIslandTransitionView(image: image, expandedFrame: frame,
      collapsedFrame: .zero, cornerRadius: 20, backgroundColor: .black,
      reducedMotion: true, shadowLayer: layer)
    surface.prepare(isPresenting: true)
    XCTAssertEqual(surface.shapeView.layer.shadowOpacity, 0)
    surface.render(progress: 0.3, isPresenting: true)
    XCTAssertEqual(surface.shapeView.layer.shadowOpacity, 0.4 * Float(surface.contentView.alpha), accuracy: 0.001)
    surface.render(progress: 1, isPresenting: true)
    XCTAssertEqual(surface.shapeView.layer.shadowOpacity, 0.4)
    surface.render(progress: 1, isPresenting: false)
    XCTAssertEqual(surface.shapeView.layer.shadowOpacity, 0)
    layer.masksToBounds = true
    let clipped = DynamicIslandTransitionView(image: image, expandedFrame: frame,
      collapsedFrame: .zero, cornerRadius: 20, backgroundColor: .black,
      reducedMotion: false, shadowLayer: layer)
    clipped.prepare(isPresenting: false)
    XCTAssertEqual(clipped.shapeView.layer.shadowOpacity, 0)
  }


  func testTransitionSnapshotClipsBadgeAndFullBleedIconToCircle() throws {
    let host = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
    let badge = UIView(frame: CGRect(x: 10, y: 10, width: 60, height: 60))
    badge.backgroundColor = .orange
    badge.layer.cornerRadius = 30
    badge.layer.masksToBounds = true
    host.addSubview(badge)
    let icon = UIImageView(frame: badge.bounds)
    icon.image = UIGraphicsImageRenderer(size: badge.bounds.size).image { renderer in
      UIColor.red.setFill()
      renderer.fill(badge.bounds)
    }
    icon.contentMode = .scaleToFill
    badge.addSubview(icon)
    // Check both the colored badge by itself and an image filling its bounds.
    for hidden in [true, false] {
      icon.isHidden = hidden
      let layers = DynamicIslandContentSnapshot.layers(of: host, iconContainers: [badge], icons: [icon])
      let sharp = try XCTUnwrap(layers.icons)
      for point in [CGPoint(x: 11, y: 11), CGPoint(x: 68, y: 11), CGPoint(x: 11, y: 68), CGPoint(x: 68, y: 68)] {
        let rgba = try pixel(in: sharp, at: point)
        XCTAssertEqual(rgba[3], 0, "Square corner at \(point), icon hidden=\(hidden): \(rgba)")
      }
      XCTAssertGreaterThan(try pixel(in: sharp, at: CGPoint(x: 40, y: 40))[3], 240)
    }
  }


  func testSymbolIconBoundsMatchCircularBadgeForAllStyles() throws {
    let oldRadius = DynamicIslandSize.radiusOverride
    defer { DynamicIslandSize.radiusOverride = oldRadius }
    DynamicIslandSize.radiusOverride = 48
    let styles: [DynamicIslandMessageStyle] = [
      .default,
      .leadingIcon(UIImage(systemName: "bell.fill"), backgroundColor: .orange, foregroundColor: .black, contentMode: .center, preferredBouncyEffect: false),
      .animate(sourceSFSymbolImage: UIImage(systemName: "arrow.down.circle.fill"), targetSFSymbolImage: nil, tintColor: .green)
    ]
    for (index, style) in styles.enumerated() {
      let host = UIView(frame: CGRect(x: 0, y: 0, width: 412, height: 96))
      let message = makeMessageView(in: host)
      message.setTitle("Title", message: "Message", style: style)
      host.layoutIfNeeded()
      let badge = message.transitionIconContainerView
      let icon = message.transitionIconView
      XCTAssertEqual(icon.frame.minX, badge.bounds.minX, accuracy: 0.01, "Style \(index)")
      XCTAssertEqual(icon.frame.minY, badge.bounds.minY, accuracy: 0.01, "Style \(index)")
      XCTAssertEqual(icon.bounds.width, badge.bounds.width, accuracy: 0.01, "Style \(index)")
      XCTAssertEqual(icon.bounds.height, badge.bounds.height, accuracy: 0.01, "Style \(index)")
    }
  }


  func testLiveIconClipsFullBleedImageToRoundedBounds() throws {
    let oldRadius = DynamicIslandSize.radiusOverride
    defer { DynamicIslandSize.radiusOverride = oldRadius }
    DynamicIslandSize.radiusOverride = 48
    let host = UIView(frame: CGRect(x: 0, y: 0, width: 412, height: 96))
    let message = makeMessageView(in: host)
    let image = UIGraphicsImageRenderer(size: CGSize(width: 60, height: 60)).image { renderer in
      UIColor.red.setFill()
      renderer.fill(CGRect(x: 0, y: 0, width: 60, height: 60))
    }
    message.setTitle("Title", message: "Message", style: .leadingIcon(image,
      backgroundColor: .clear, foregroundColor: .white, contentMode: .scaleToFill,
      preferredBouncyEffect: false))
    message.setAlphaForSubviews(to: 1)
    host.layoutIfNeeded()
    let icon = message.transitionIconView
    let snapshot = UIGraphicsImageRenderer(size: icon.bounds.size).image { renderer in
      icon.layer.render(in: renderer.cgContext)
    }
    for point in [CGPoint(x: 1, y: 1), CGPoint(x: 58, y: 1), CGPoint(x: 1, y: 58), CGPoint(x: 58, y: 58)] {
      XCTAssertEqual(try pixel(in: snapshot, at: point)[3], 0, "The live image must not have a rectangular corner")
    }
    XCTAssertGreaterThan(try pixel(in: snapshot, at: CGPoint(x: 30, y: 30))[0], 240)
  }


  func testActiveBounceKeepsCircularBadgeAndIconBounds() async throws {
    guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else {
      throw XCTSkip("Requires the app-hosted Example scheme.")
    }
    let originalRadius = DynamicIslandSize.radiusOverride
    let previous = scene.windows.first { $0.isKeyWindow }
    DynamicIslandSize.radiusOverride = 48
    let window = UIWindow(windowScene: scene)
    let root = UIViewController()
    window.rootViewController = root
    window.makeKeyAndVisible()
    defer {
      window.isHidden = true
      previous?.makeKey()
      DynamicIslandSize.radiusOverride = originalRadius
    }
    let host = UIView(frame: CGRect(x: 0, y: 80, width: 412, height: 96))
    host.backgroundColor = .black
    root.view.addSubview(host)
    let message = makeMessageView(in: host)
    message.setTitle("Reminder", message: "Time to take a short break.", style: .leadingIcon(
      UIImage(systemName: "bell.fill"), backgroundColor: .systemOrange,
      foregroundColor: .black, contentMode: .center, preferredBouncyEffect: true))
    message.setAlphaForSubviews(to: 1)
    host.layoutIfNeeded()
    for delay in [0.55, 0.1, 0.15, 0.2, 0.4] {
      let tick = expectation(description: "Bounce sample")
      DispatchQueue.main.asyncAfter(deadline: .now() + delay) { tick.fulfill() }
      await fulfillment(of: [tick], timeout: 3)
      let badge = message.transitionIconContainerView
      let icon = message.transitionIconView
      XCTAssertEqual(icon.frame, badge.bounds)
      XCTAssertEqual(icon.layer.cornerRadius, 30, accuracy: 0.01)
      let snapshot = UIGraphicsImageRenderer(size: host.bounds.size).image { renderer in
        XCTAssertTrue(host.drawHierarchy(in: host.bounds, afterScreenUpdates: false))
      }
      for localPoint in [CGPoint(x: 1, y: 1), CGPoint(x: 58, y: 1), CGPoint(x: 1, y: 58), CGPoint(x: 58, y: 58)] {
        let point = badge.convert(localPoint, to: host)
        let rgba = try pixel(in: snapshot, at: point)
        XCTAssertLessThan(rgba[0], 10, "Active bounce painted a rectangular corner at \(localPoint): \(rgba)")
        XCTAssertLessThan(rgba[1], 10)
      }
    }
  }



  func testOrangeContainerRecalculatesRadiusInItsOwnLayout() throws {
    let originalRadius = DynamicIslandSize.radiusOverride
    defer { DynamicIslandSize.radiusOverride = originalRadius }
    DynamicIslandSize.radiusOverride = 48
    let host = UIView(frame: CGRect(x: 0, y: 0, width: 412, height: 96))
    let message = makeMessageView(in: host)
    message.setTitle("Reminder", message: "Message", style: .leadingIcon(nil,
      backgroundColor: .orange, foregroundColor: .black, contentMode: .center,
      preferredBouncyEffect: false))
    message.setAlphaForSubviews(to: 1)
    host.layoutIfNeeded()
    let badge = message.transitionIconContainerView
    XCTAssertEqual(badge.bounds.width, 60, accuracy: 0.01)
    XCTAssertEqual(badge.layer.cornerRadius, 30, accuracy: 0.01)

    // UIKit can update a child's bounds after its parent's layout callback.
    // The colored container must make itself circular in its own layout pass.
    badge.removeFromSuperview()
    NSLayoutConstraint.deactivate(badge.constraints.filter {
      ($0.firstItem as AnyObject?) === badge && $0.secondItem == nil
        && ($0.firstAttribute == .width || $0.firstAttribute == .height)
    })
    badge.bounds.size = CGSize(width: 80, height: 80)
    badge.setNeedsLayout()
    badge.layoutIfNeeded()
    XCTAssertEqual(badge.bounds.width, 80, accuracy: 0.01)
    XCTAssertEqual(badge.layer.cornerRadius, 40, accuracy: 0.01)
    let snapshot = UIGraphicsImageRenderer(size: badge.bounds.size).image { renderer in
      badge.layer.render(in: renderer.cgContext)
    }
    XCTAssertEqual(try pixel(in: snapshot, at: CGPoint(x: 2, y: 20))[3], 0,
                   "A stale radius leaves a rounded rectangle instead of an orange circle")
    XCTAssertGreaterThan(try pixel(in: snapshot, at: CGPoint(x: 40, y: 40))[3], 240)
  }

  func testOrangeContainerStaysCircularWhenScreenGeometryChanges() throws {
    let originalRadius = DynamicIslandSize.radiusOverride
    defer { DynamicIslandSize.radiusOverride = originalRadius }
    DynamicIslandSize.radiusOverride = 37
    let host = UIView(frame: CGRect(x: 0, y: 0, width: 412, height: 140))
    let message = makeMessageView(in: host)
    message.setTitle("Reminder", message: "Message", style: .leadingIcon(
      UIImage(systemName: "bell.fill"), backgroundColor: .orange,
      foregroundColor: .black, contentMode: .center, preferredBouncyEffect: true))
    host.layoutIfNeeded()
    let badge = message.transitionIconContainerView
    for radius: CGFloat in [48, 58, 40, 18] {
      DynamicIslandSize.radiusOverride = radius
      message.setNeedsLayout()
      message.layoutIfNeeded()
      host.setNeedsLayout()
      host.layoutIfNeeded()
      XCTAssertEqual(badge.bounds.width, max(0, (radius - 18) * 2), accuracy: 0.01)
      XCTAssertEqual(badge.layer.cornerRadius, badge.bounds.width / 2, accuracy: 0.01)
      XCTAssertEqual(message.transitionIconView.bounds.size, badge.bounds.size)
    }
  }

  func testTransitionBadgeHasSmoothCardinalEdges() throws {
    let host = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
    host.traitOverrides.displayScale = 3
    let badge = UIView(frame: CGRect(x: 10, y: 10, width: 60, height: 60))
    badge.backgroundColor = .systemOrange
    badge.layer.cornerRadius = 30
    badge.layer.masksToBounds = true
    host.addSubview(badge)
    let snapshot = try XCTUnwrap(DynamicIslandContentSnapshot.layers(
      of: host, iconContainers: [badge], icons: []).icons)
    XCTAssertEqual(snapshot.scale, 3, "Sharp edges must use the native display scale")
    XCTAssertEqual(badge.backgroundColor, .systemOrange, "Capture must restore the live badge")
    let format = UIGraphicsImageRendererFormat()
    format.scale = snapshot.scale
    format.opaque = false
    let reference = UIGraphicsImageRenderer(size: host.bounds.size, format: format).image { renderer in
      renderer.cgContext.setFillColor(UIColor.systemOrange.cgColor)
      renderer.cgContext.fillEllipse(in: badge.frame)
    }
    // Check the tangents at all four cardinal points, where layer snapshots
    // previously produced protruding pixels despite the correct corner radius.
    var largestDifference = 0
    for offset in -8...8 {
      for depth in 0...2 {
        let tangent = CGFloat(offset) / snapshot.scale
        let inset = CGFloat(depth) / snapshot.scale
        let points = [CGPoint(x: 40 + tangent, y: 10 + inset),
                      CGPoint(x: 40 + tangent, y: 70 - 1 / snapshot.scale - inset),
                      CGPoint(x: 10 + inset, y: 40 + tangent),
                      CGPoint(x: 70 - 1 / snapshot.scale - inset, y: 40 + tangent)]
        for point in points {
          let actual = try pixel(in: snapshot, at: point)[3]
          let expected = try pixel(in: reference, at: point)[3]
          largestDifference = max(largestDifference, abs(Int(actual) - Int(expected)))
        }
      }
    }
    XCTAssertLessThanOrEqual(largestDifference, 8,
                             "Circle tangents must match smooth antialiased ellipse coverage")
  }

  private func pixel(in image: UIImage, at point: CGPoint) throws -> [UInt8] {
    let cgImage = try XCTUnwrap(image.cgImage)
    var bytes = [UInt8](repeating: 0, count: 4)
    try bytes.withUnsafeMutableBytes { buffer in
      let context = try XCTUnwrap(CGContext(
        data: buffer.baseAddress, width: 1, height: 1, bitsPerComponent: 8,
        bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      ))
      context.draw(cgImage, in: CGRect(
        x: -point.x * image.scale, y: -point.y * image.scale,
        width: CGFloat(cgImage.width), height: CGFloat(cgImage.height)
      ))
    }
    return bytes
  }

  private func layoutToFit(_ host: UIView, width: CGFloat) {
    let size = host.systemLayoutSizeFitting(
      CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .defaultLow
    )
    host.frame = CGRect(origin: .zero, size: size)
    host.layoutIfNeeded()
  }

  private func makeMessageView(in host: UIView) -> DynamicIslandMessageView {
    let messageView = DynamicIslandMessageView()
    messageView.translatesAutoresizingMaskIntoConstraints = false
    host.addSubview(messageView)
    NSLayoutConstraint.activate([
      messageView.topAnchor.constraint(equalTo: host.topAnchor),
      messageView.leadingAnchor.constraint(equalTo: host.leadingAnchor),
      messageView.trailingAnchor.constraint(equalTo: host.trailingAnchor),
      messageView.bottomAnchor.constraint(equalTo: host.bottomAnchor)
    ])
    return messageView
  }
}

private final class CornerRadiusFixture: NSObject {
  var radius: CGFloat = 37
  @objc(_displayCornerRadius) dynamic func displayCornerRadius() -> CGFloat { radius }
}

private final class ObjectCornerRadiusFixture: NSObject {
  var wasCalled = false
  @objc(_displayCornerRadius) dynamic func displayCornerRadius() -> NSNumber {
    wasCalled = true
    return 37
  }
}

private final class IntegerCornerRadiusFixture: NSObject {
  var wasCalled = false
  @objc(_displayCornerRadius) dynamic func displayCornerRadius() -> Int {
    wasCalled = true
    return 37
  }
}


@available(iOS 17.0, *)
extension DynamicIslandToastTests {
  func testAutoDismissRemovesToastAndItsPresentedAlert() async throws {
    guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else {
      throw XCTSkip("This presentation integration test needs the app-hosted Example scheme.")
    }
    let previousKeyWindow = scene.windows.first { $0.isKeyWindow }
    let window = UIWindow(windowScene: scene)
    let root = AutoDismissRegressionPresenter()
    window.rootViewController = root
    window.makeKeyAndVisible()
    defer {
      root.dismiss(animated: false)
      window.isHidden = true
      previousKeyWindow?.makeKey()
    }

    let toast = UIViewController()
    toast.modalPresentationStyle = .custom
    let alert = UIAlertController(title: "Confirm", message: "A child modal", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    let presented = expectation(description: "Toast and alert presented")
    let dismissed = expectation(description: "Toast dismissed at its deadline")
    root.onDismiss = { dismissed.fulfill() }
    root.presentDynamicIsland(toast, dismissAfterDelayed: 0.5) {
      toast.present(alert, animated: false) { presented.fulfill() }
    }
    await fulfillment(of: [presented], timeout: 5)
    XCTAssertTrue(root.presentedViewController === toast)
    XCTAssertTrue(toast.presentedViewController === alert)
    XCTAssertNotNil(toast.view.window)
    XCTAssertNotNil(alert.view.window)

    await fulfillment(of: [dismissed], timeout: 5)
    XCTAssertNil(root.presentedViewController)
    XCTAssertNil(toast.presentedViewController)
    XCTAssertNil(alert.presentingViewController)
    XCTAssertNil(toast.viewIfLoaded?.window)
    XCTAssertNil(alert.viewIfLoaded?.window)
    XCTAssertFalse(DynamicIslandPresentationState.state(for: toast).isActive)
  }
}

@MainActor
private final class AutoDismissRegressionPresenter: UIViewController {
  var onDismiss: (() -> Void)?

  override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
    super.dismiss(animated: flag) { [weak self] in
      completion?()
      let callback = self?.onDismiss
      self?.onDismiss = nil
      callback?()
    }
  }
}
