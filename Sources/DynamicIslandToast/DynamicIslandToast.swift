import UIKit

public enum DynamicIslandToast {
  
  public enum Configuration {
    public static var icon: UIImage?
    public static var infoTitle = "Info"
    public static var errorTitle = "Error"
    public static var warningTitle = "Warning"
  }
  
  public enum AlertType {
    case info
    case warning
    case error

    public var title: String? {
      switch self {
      case .info:
        return Configuration.infoTitle
        
      case .warning:
        return Configuration.warningTitle
        
      case .error:
        return Configuration.errorTitle
      }
    }
  }
  
  public static func show(_ type: AlertType, message: String) {
    MainThread.run {
      switch type {
      case .error:
        Haptic.notification(.error).generate()
        
      case .info:
        Haptic.notification(.success).generate()
        
      case .warning:
        Haptic.notification(.warning).generate()
      }
      
      MessageBar.shared.toast(type, message: message)
    }
  }
}
