# DynamicIslandToast Example

A UIKit iPhone app demonstrating the local package. Requires Xcode with an iOS 17+ SDK. Run it on an iPhone with Dynamic Island for the intended animation.

## Run

1. Open `DynamicIslandToastExample.xcodeproj` in this folder.
2. Select the `DynamicIslandToastExample` scheme and an iPhone simulator.
3. Run, choose a dismissal duration, then tap an example.

For a physical device, select your development team in the target's Signing & Capabilities settings.

The checked-in project references the package at `..`, so edits to `Sources/DynamicIslandToast` are included when you rebuild. No remote copy of the library is used. Swift Package Manager resolves the library's DeviceKit dependency on the first build.

## Examples

- Default message style
- Leading SF Symbol with colors and a bounce effect
- Animated SF Symbol replacement
- Multiline message with automatic height
- Custom title and message fonts
- Two- or four-second dismissal, or a persistent toast dismissed by tapping outside

`ToastViewController.swift` shows the required integration: set `.custom` presentation, constrain `DynamicIslandMessageView` to the controller's view, configure its content, and fade its initially hidden subviews in during the transition. The host captures status-bar appearance and hides it while the toast is expanded so the clock and indicators do not overlap the content. `ExamplesViewController.swift` presents it using `presentDynamicIsland(_:dismissAfterDelayed:completion:)`. Passing `nil` disables automatic dismissal.

## Regenerate the project

The project is generated from `project.yml` using [XcodeGen](https://github.com/yonaskolb/XcodeGen). XcodeGen is only needed when changing the project configuration:

```sh
cd Example
xcodegen generate
```
