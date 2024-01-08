//
//  Font.swift
//
//
//  Created by Suykorng on 1/1/24.
//

import UIKit

extension UIFont {
  
  static func largeTitle(_ weight: Weight = .regular) -> UIFont {
    UIFont.preferredFont(forTextStyle: .largeTitle, weight: weight)
  }
  
  @available(iOS 17.0, *)
  static func extraLargeTitle(_ weight: Weight = .regular) -> UIFont {
    UIFont.preferredFont(forTextStyle: .extraLargeTitle, weight: weight)
  }
  
  @available(iOS 17.0, *)
  static func extraLargeTitle2(_ weight: Weight = .regular) -> UIFont {
    UIFont.preferredFont(forTextStyle: .extraLargeTitle2, weight: weight)
  }
  
  static func title1(_ weight: Weight = .regular) -> UIFont {
    UIFont.preferredFont(forTextStyle: .title1, weight: weight)
  }
  
  static func title2(_ weight: Weight = .regular) -> UIFont {
    UIFont.preferredFont(forTextStyle: .title2, weight: weight)
  }
  
  static func title3(_ weight: Weight = .regular) -> UIFont {
    UIFont.preferredFont(forTextStyle: .title3, weight: weight)
  }
  
  static func headline(_ weight: Weight = .regular) -> UIFont {
    UIFont.preferredFont(forTextStyle: .headline, weight: weight)
  }
  
  static func subheadline(_ weight: Weight = .regular) -> UIFont {
    UIFont.preferredFont(forTextStyle: .subheadline, weight: weight)
  }
  
  static func body(_ weight: Weight = .regular) -> UIFont {
    UIFont.preferredFont(forTextStyle: .body, weight: weight)
  }
  
  static func callout(_ weight: Weight = .regular) -> UIFont {
    UIFont.preferredFont(forTextStyle: .callout, weight: weight)
  }
  
  static func footnote(_ weight: Weight = .regular) -> UIFont {
    UIFont.preferredFont(forTextStyle: .footnote, weight: weight)
  }
  
  static func caption1(_ weight: Weight = .regular) -> UIFont {
    UIFont.preferredFont(forTextStyle: .caption1, weight: weight)
  }
  
  static func caption2(_ weight: Weight = .regular) -> UIFont {
    UIFont.preferredFont(forTextStyle: .caption2, weight: weight)
  }
  
}

extension UIFont {
  static func preferredFont(forTextStyle style: TextStyle, weight: Weight) -> UIFont {
    let metrics = UIFontMetrics(forTextStyle: style)
    let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
    let font = UIFont.systemFont(ofSize: descriptor.pointSize, weight: weight)
    return metrics.scaledFont(for: font)
  }
}
