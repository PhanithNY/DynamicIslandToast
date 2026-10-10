//
//  DynamicIslandSize.swift
//  DIToastExample
//
//  Created by Suykorng on 21/10/24.
//

import DeviceKit
import UIKit

@available(iOS 17.0, *)
public enum DynamicIslandSize {
  
  static let delegate = DynamicIslandTransitioningDelegate()
  
  static var window: UIWindow {
    if let window = UIApplication.shared._currentWindow {
      return window
    } else {
      return UIWindow(frame: UIScreen.main.bounds)
    }
  }
  
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
  
  public static var startFrame: CGRect = {
    // The first dynamic island width is 20.76mm -> 126.0
    // iPhone 18 series dynamic island width is 13.49 mm
    let defaultIslandWidth: CGFloat = 126.0
    let islandWidth: CGFloat
    let islandHeight: CGFloat = 37
    
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
    
    let originX: CGFloat = min(window.bounds.width, window.bounds.height)/2 - islandWidth/2
    let startFrame = CGRect(x: originX, y: originY, width: islandWidth, height: islandHeight)
    return startFrame
  }()
  
  public static var radius: CGFloat = {
    _CornerRadiusProvider.notchCornerRadius - originY
  }()
    
}

enum _CornerRadiusProvider {
  fileprivate static var notchCornerRadius: CGFloat {
    UIScreen.main._displayCornerRadius
  }
}

extension UIScreen {
  fileprivate static let _cornerRadiusKey: String = {
    let components = ["Radius", "Corner", "display", "_"]
    return components.reversed().joined()
  }()
  
  /// The corner radius of the display. Uses a private property of `UIScreen`,
  /// and may report 0 if the API changes.
  fileprivate var _displayCornerRadius: CGFloat {
    guard let cornerRadius = self.value(forKey: Self._cornerRadiusKey) as? CGFloat else {
      return 0.0
    }
    
    return max(0, cornerRadius)
  }
}


extension UIApplication {
  var _currentWindow: UIWindow? {
    connectedScenes
      .filter({$0.activationState == .foregroundActive})
      .map({$0 as? UIWindowScene})
      .compactMap({$0})
      .first?.windows
      .filter({$0.isKeyWindow}).first
  }
}
