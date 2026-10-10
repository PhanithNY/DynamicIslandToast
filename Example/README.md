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

The island shape uses UIKit's spring animation, with the original 0.75 damping ratio and 0.6-second duration for presentation, and a non-bouncy 0.35-second spring for dismissal. Content keeps its expanded layout while scale, opacity, and Gaussian blur share a display-synchronized timeline. Seven Gaussian samples are prepared on a worker queue and blended continuously; shape and content start together once preparation finishes. The samples are reused for dismissal when snapshot pixels match, then released when the presentation ends. Presentation fades and sharpens across the full duration. Dismissal reverses the content effect during its first 25%, then finishes collapsing the empty pill. The transition waits for both shape and content to finish before returning the live view. The icon stays vertically centered through the spring. Reduce Motion uses a simple fade without shape motion, scale, or blur.

`ToastViewController.swift` shows the required integration: set `.custom` presentation, constrain `DynamicIslandMessageView` to the controller's view, and configure its content. The package owns the content transition; existing calls to `setAlphaForSubviews(to:)` during the transition remain compatible. The example navigation controller hides the status bar before expansion and holds it hidden until dismissal finishes, keeping the clock and indicators clear of the animated content. `ExamplesViewController.swift` presents it using `presentDynamicIsland(_:dismissAfterDelayed:completion:)`. Passing `nil` disables automatic dismissal. Manual dismissal cancels the pending deadline, so reusing the controller cannot trigger an earlier presentation’s timer. Geometry follows the current container and window; custom geometry should use `DynamicIslandSize.startFrame(in:)` and `radius(for:)`.

## Regenerate the project

The project is generated from `project.yml` using [XcodeGen](https://github.com/yonaskolb/XcodeGen). XcodeGen is only needed when changing the project configuration:

```sh
cd Example
xcodegen generate
```

## Tests

Select the `DynamicIslandToastExample` scheme and use Product → Test (⌘U).
The app hosts the regression tests in `../Tests/DynamicIslandToastTests`, including
the Objective-C exception fixture used to verify the safe corner-radius fallback.

From the repository root, run the same command used by GitHub Actions:

```sh
./scripts/test-ios.sh
# Optionally choose an installed iPhone simulator:
./scripts/test-ios.sh <simulator-UDID>
```

The script chooses an available iPhone simulator, preferring a booted one, and
writes the `.xcresult` bundle to `TestResults/`. It requires Xcode and an installed
iOS 17+ simulator runtime. The checked-in project can run tests without XcodeGen.
CI runs the tests and a Release simulator build on pushes and pull requests,
and uploads test results for inspection.
