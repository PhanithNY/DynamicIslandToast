//
//  File.swift
//  
//
//  Created by Suykorng on 1/1/24.
//

import UIKit

enum Haptic {
  case impact(HapticFeedbackStyle)
  case notification(HapticFeedbackType)
  case selection
  
  func generate() {
    switch self {
    case .impact(let style):
      let generator = UIImpactFeedbackGenerator(style: style.value)
      generator.prepare()
      generator.impactOccurred()
      
    case .notification(let type):
      let generator = UINotificationFeedbackGenerator()
      generator.prepare()
      generator.notificationOccurred(type.value)
      
    case .selection:
      let generator = UISelectionFeedbackGenerator()
      generator.prepare()
      generator.selectionChanged()
    }
  }
}

enum HapticFeedbackStyle: Int {
  case light, medium, heavy
  
  @available(iOS 13.0, *)
  case soft, rigid
}

@available(iOS 11.0, *)
extension HapticFeedbackStyle {
  var value: UIImpactFeedbackGenerator.FeedbackStyle {
    return UIImpactFeedbackGenerator.FeedbackStyle(rawValue: rawValue).unsafelyUnwrapped
  }
}

enum HapticFeedbackType: Int {
  case success
  case warning
  case error
}

@available(iOS 11.0, *)
extension HapticFeedbackType {
  var value: UINotificationFeedbackGenerator.FeedbackType {
    return UINotificationFeedbackGenerator.FeedbackType(rawValue: rawValue).unsafelyUnwrapped
  }
}
