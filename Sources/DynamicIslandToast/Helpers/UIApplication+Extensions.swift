//
//  UIApplication+Extensions.swift
//  DynamicIslandToast
//
//  Created by Phanith Ny on 21/5/26.
//

import UIKit

extension UIApplication {
  var currentWindow: UIWindow? {
    connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .filter { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive }
      .flatMap(\.windows)
      .first(where: \.isKeyWindow)
  }
}
