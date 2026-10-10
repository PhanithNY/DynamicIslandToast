# DynamicIslandToast

A UIKit library for presenting messages with a Dynamic Island transition.

## Example app

Open [`Example/DynamicIslandToastExample.xcodeproj`](Example/DynamicIslandToastExample.xcodeproj) and run the `DynamicIslandToastExample` scheme on an iPhone simulator with iOS 17 or later. See the [example guide](Example/README.md) for the available demos and integration details.

## Installation

Add `https://github.com/PhanithNY/DynamicIslandToast.git` as a Swift Package Manager dependency and link the `DynamicIslandToast` product to your app target. The package declares iOS 13 support; its toast presentation APIs require iOS 17 or later.

## Usage

Create a `UIViewController` with `modalPresentationStyle = .custom`. Add a `DynamicIslandMessageView`, constrain it to all four edges of the controller's view, and configure its content:

```swift
import DynamicIslandToast
import UIKit

messageView.setTitle("Download", message: "Your file is ready.", style: .default)
presentDynamicIsland(toastViewController, dismissAfterDelayed: 4)
```

The message view starts with its subviews hidden. Call `messageView.setAlphaForSubviews(to: 1)` during the presentation transition to reveal them. The [example toast controller](Example/DynamicIslandToastExample/ToastViewController.swift) contains the complete setup, including custom fonts and transition handling.
