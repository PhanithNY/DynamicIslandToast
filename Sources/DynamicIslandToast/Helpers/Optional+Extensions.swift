//
//  File.swift
//  
//
//  Created by Suykorng on 1/1/24.
//

import Foundation

extension Optional where Wrapped == String {
  var orEmpty: String {
    switch self {
    case .some(let value):
      return value
    case .none:
      return ""
    }
  }
}

extension Optional {
  func or(_ value: Wrapped) -> Wrapped {
    switch self {
    case .some(let some):
      return some
    case .none:
      return value
    }
  }
}
