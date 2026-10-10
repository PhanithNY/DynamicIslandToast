import DynamicIslandToast
import UIKit

enum ToastExample: Int, CaseIterable {
  case basic
  case leadingIcon
  case animatedSymbol
  case multiline
  case customFonts

  var title: String {
    switch self {
    case .basic: return "Default message"
    case .leadingIcon: return "Bouncing icon"
    case .animatedSymbol: return "Animated symbol"
    case .multiline: return "Multiline message"
    case .customFonts: return "Custom fonts"
    }
  }

  var detail: String {
    switch self {
    case .basic: return "The built-in information style"
    case .leadingIcon: return "A colored SF Symbol with a bounce effect"
    case .animatedSymbol: return "Watch the arrow turn into a checkmark"
    case .multiline: return "Content determines the toast's height"
    case .customFonts: return "A bold title and larger message text"
    }
  }

  var symbolName: String {
    switch self {
    case .basic: return "info.circle"
    case .leadingIcon: return "bell.badge"
    case .animatedSymbol: return "arrow.down.circle"
    case .multiline: return "text.alignleft"
    case .customFonts: return "textformat.size"
    }
  }

  var toastTitle: String {
    switch self {
    case .basic: return "DynamicIslandToast"
    case .leadingIcon: return "Reminder"
    case .animatedSymbol: return "Download"
    case .multiline: return "New message"
    case .customFonts: return "LOOKING GOOD"
    }
  }

  var message: String {
    switch self {
    case .basic: return "Hello from the island!"
    case .leadingIcon: return "Time to take a short break."
    case .animatedSymbol: return "Your file is ready."
    case .multiline:
      return "Your team shared an update. The toast grows to fit a longer message, keeping the title and icon alongside the text."
    case .customFonts: return "Make the toast your own."
    }
  }

  var messageStyle: DynamicIslandMessageStyle {
    switch self {
    case .basic, .multiline, .customFonts:
      return .default
    case .leadingIcon:
      return .leadingIcon(
        UIImage(systemName: "bell.fill"),
        backgroundColor: .systemOrange,
        foregroundColor: .black,
        contentMode: .center,
        preferredBouncyEffect: true
      )
    case .animatedSymbol:
      return .animate(
        sourceSFSymbolImage: UIImage(systemName: "arrow.down.circle.fill"),
        targetSFSymbolImage: UIImage(systemName: "checkmark.circle.fill"),
        tintColor: .systemGreen
      )
    }
  }
}
