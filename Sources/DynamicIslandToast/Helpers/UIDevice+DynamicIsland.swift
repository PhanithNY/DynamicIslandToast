//
//  UIDevice+DynamicIsland.swift
//  
//
//  Created by Suykorng on 10/12/23.
//

import UIKit

public extension UIDevice {
  
  // Get this value after sceneDidBecomeActive
  var hasDynamicIsland: Bool {
    // Dynamic Island only available from iPhone 14 Pro/Pro max
    // from iOS 16 and up
    guard #available(iOS 17.0, *) else {
      return false
    }
    
    // Dynamic Island only support iPhone
    guard userInterfaceIdiom == .phone else {
      return false
    }
    
    guard let window = (UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow}
    ) else {
      return false
    }
    
    // It works properly when the device orientation is portrait
    return window.safeAreaInsets.top >= 51
  }
}
