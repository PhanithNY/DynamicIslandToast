//
//  File.swift
//  
//
//  Created by Suykorng on 1/1/24.
//

import Foundation

struct MainThread {
  static func run(_ block: @escaping (() -> Void)) {
    if Thread.isMainThread {
      block()
    } else {
      DispatchQueue.main.async {
        block()
      }
    }
  }
  
  static func delay(after deadline: DispatchTime, execute work: @escaping @convention(block) () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: deadline, execute: work)
  }
}
