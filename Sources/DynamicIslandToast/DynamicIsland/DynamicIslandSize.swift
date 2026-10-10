//
//  DynamicIslandSize.swift
//  DIToastExample
//
//  Created by Suykorng on 21/10/24.
//

import DeviceKit
import DynamicIslandToastObjC
import UIKit

@available(iOS 17.0, *)
public enum DynamicIslandSize {
  
  static let delegate = DynamicIslandTransitioningDelegate()
  
  public static var originY: CGFloat = {
    let originY: CGFloat

    let device = Device.current
    switch device {
    case .simulator(.iPhone16ProMax),
        .simulator(.iPhone16Pro),
        .iPhone16ProMax,
        .iPhone16Pro:
      originY = 13.5
      
    case .simulator(.iPhone18Pro),
        .simulator(.iPhone18ProMax),
        .iPhone18Pro,
        .iPhone18ProMax:
      originY = 14.0

    case .simulator(.iPhoneAir),
        .iPhoneAir:
      originY = 20

    default:
      originY = 11
    }
    
    return originY
  }()
  
  // Explicit overrides remain shared configuration; default geometry is
  // calculated for the current presentation instead of cached from a window.
  static var startFrameOverride: CGRect?
  static var radiusOverride: CGFloat?
  private static let islandHeight: CGFloat = 37

  @available(*, deprecated, message: "Use startFrame(in:) with the presentation container's bounds")
  public static var startFrame: CGRect {
    get { startFrame(in: UIScreen.main.bounds) }
    set { startFrameOverride = newValue }
  }

  public static func startFrame(in bounds: CGRect) -> CGRect {
    if let startFrameOverride {
      return startFrameOverride
    }

    // The first dynamic island width is 20.76mm -> 126.0
    // iPhone 18 series dynamic island width is 13.49 mm
    let defaultIslandWidth: CGFloat = 126.0
    let islandWidth: CGFloat

    let device = Device.current
    switch device {
    case .simulator(.iPhone18Pro),
        .simulator(.iPhone18ProMax),
        .iPhone18Pro,
        .iPhone18ProMax:
      islandWidth = defaultIslandWidth * (13.49 / 20.76)

    default:
      islandWidth = defaultIslandWidth
    }

    return CGRect(
      x: bounds.midX - islandWidth / 2,
      y: bounds.minY + originY,
      width: islandWidth,
      height: islandHeight
    )
  }

  @available(*, deprecated, message: "Use radius(for:) with a view in the presenting window")
  public static var radius: CGFloat {
    get { radius(for: UIScreen.main) }
    set { radiusOverride = newValue }
  }

  public static func radius(for view: UIView) -> CGFloat {
    radius(for: view.window?.windowScene?.screen)
  }

  private static func radius(for screen: UIScreen?) -> CGFloat {
    guard radiusOverride == nil, let screen else { return radius(forDisplayCornerRadius: nil) }
    let displayCornerRadius = DITPrivateCornerRadiusReader.displayCornerRadius(for: screen)
      .map { CGFloat(truncating: $0) }
    return radius(forDisplayCornerRadius: displayCornerRadius)
  }

  static func radius(forDisplayCornerRadius displayCornerRadius: CGFloat?) -> CGFloat {
    if let radiusOverride {
      return radiusOverride.isFinite ? max(0, radiusOverride) : islandHeight
    }
    guard let displayCornerRadius, displayCornerRadius.isFinite, displayCornerRadius >= 0 else {
      // Detached views and failed reads share the existing provisional radius.
      return islandHeight
    }
    return max(0, displayCornerRadius - originY)
  }
}
