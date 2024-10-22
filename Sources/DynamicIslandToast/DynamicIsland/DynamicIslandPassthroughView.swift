//
//  DynamicIslandPassthroughView.swift
//  DIToastExample
//
//  Created by Suykorng on 21/10/24.
//

import UIKit

// View that supports forwarding hit test touches to the provided array of views
final class DynamicIslandPassthroughView: UIView {
  
  var onHitTest: ((UIView) -> Void)?
  
  // Array of views that we want to forward touches to
  var touchForwardTargetViews = [UIView]()
  
  // Variable to quickly disable/enable touch forwarding functionality
  var touchForwardingEnabled = true
  
  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    // Get the hit test view
    let hitTestView = super.hitTest(point, with: event)
    
    // Make sure the hit test view is self and that touch forwarding is enabled
    if hitTestView == self && touchForwardingEnabled {
      // Iterate the hit test target views
      for targetView in touchForwardTargetViews {
        // Convert hit test point to the target view
        let convertedPoint = convert(point, to: targetView)
        // Verify that the target view can receive the touch
        if let hitTargetView = targetView.hitTest(convertedPoint, with: event) {
          // Forward the touch to the target view
          onHitTest?(hitTargetView)
          return hitTargetView
        }
      }
    }
    
    // Return the original hit test view - this is the super value - our implmentation didn't affect the hit test pass
    return hitTestView
  }
  
}
