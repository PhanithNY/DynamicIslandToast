//
//  File.swift
//  
//
//  Created by Suykorng on 1/1/24.
//

import UIKit

extension UIApplication {
  var currentWindow: UIWindow? {
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
