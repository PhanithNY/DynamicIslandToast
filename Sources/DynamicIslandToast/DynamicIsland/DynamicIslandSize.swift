//
//  DynamicIslandSize.swift
//  DIToastExample
//
//  Created by Suykorng on 21/10/24.
//

import DeviceKit
import UIKit

@available(iOS 17.0, *)
enum DynamicIslandSize {
  
  static let delegate = DynamicIslandTransitioningDelegate()
  
  static var window: UIWindow {
    if let window = UIApplication.shared._currentWindow {
      return window
    } else {
      return UIWindow(frame: UIScreen.main.bounds)
    }
  }
  
  static var originY: CGFloat = {
    var originY: CGFloat = 11
    
    let device = Device.current
    switch device {
    case .simulator(.iPhone16ProMax),
        .simulator(.iPhone16Pro):
      originY = 14
      
    case .iPhone16ProMax,
        .iPhone16Pro:
      originY = 14
      
    default:
      break
    }
    
    return originY
  }()
  
  static var startFrame: CGRect = {
    let islandWidth: CGFloat = 126
    let islandHeight: CGFloat = 37
    let x: CGFloat = min(window.bounds.width, window.bounds.height)/2 - 126/2
    
    let startFrame = CGRect(x: x, y: originY, width: islandWidth, height: islandHeight)
    return startFrame
  }()
  
  static var radius: CGFloat = {
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
    if #available(iOS 13.0, *) {
      return connectedScenes
        .filter({$0.activationState == .foregroundActive})
        .map({$0 as? UIWindowScene})
        .compactMap({$0})
        .first?.windows
        .filter({$0.isKeyWindow}).first
    } else {
      return keyWindow
    }
  }
}
