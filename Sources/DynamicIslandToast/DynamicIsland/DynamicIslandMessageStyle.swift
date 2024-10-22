//
//  DynamicIslandMessageStyle.swift
//  DIToastExample
//
//  Created by Suykorng on 22/10/24.
//

import UIKit

@available(iOS 17.0, *)
public enum DynamicIslandMessageStyle {
  case `default`
  case leadingIcon(UIImage?, backgroundColor: UIColor?, foregroundColor: UIColor?, contentMode: UIView.ContentMode, preferredBouncyEffect: Bool)
  case animate(sourceSFSymbolImage: UIImage?, targetSFSymbolImage: UIImage?, tintColor: UIColor?)
}
