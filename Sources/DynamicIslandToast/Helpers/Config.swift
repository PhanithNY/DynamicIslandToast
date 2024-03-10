//
//  Config.swift
//
//
//  Created by Suykorng on 1/1/24.
//

import UIKit

public protocol Config { }
extension NSObject: Config { }

extension Config where Self: NSObject {
  /// Makes it available to set properties with closures just after initializing.
  ///
  ///     let label = UILabel().decorate {
  ///       $0.textAlignment = .center
  ///       $0.textColor = .black
  ///       $0.text = "Hi There!"
  ///     }
  func decorate(_ closure: (Self) -> Void) -> Self {
    closure(self)
    return self
  }
  
  func config(_ closure: (Self) -> Void) -> Self {
    closure(self)
    return self
  }
}
