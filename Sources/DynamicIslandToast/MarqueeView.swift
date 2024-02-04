//
//  MarqueeView.swift
//
//
//  Created by Suykorng on 7/1/24.
//

import UIKit

public enum MarqueeType {
  case left
  case right
  case reverse
}

public final class MarqueeView: UIView {
  
  public var contentViewFrameConfigWhenCantMarquee: ((UIView)->())?
  
  /// Begin scrolling behavior automatically. Default is false.
  public var autoScroll: Bool = false
  
  /// The margin between marquee view
  public var contentMargin: CGFloat = 8
  
  /// Type of marquee. Default is left.
  public var marqueeType: MarqueeType = .left
  
  /// Framerate for the animation.
  public var preferredFramesPerSecond: Int = 0
  
  public var pointsPerFrame: CGFloat = 0.5
  
  /// The animation speed for marquee view
  public var speed: CGFloat = 1.0
  
  /// The marquee view
  public var contentView: UIView? {
    didSet {
      self.setNeedsLayout()
    }
  }
  
  private lazy var containerView = UIView()
  
  private var displayLink: CADisplayLink?
  private var isReversing = false
  
  // MARK: - Init
  
  public init() {
    super.init(frame: .zero)
    
    initializeViews()
  }
  
  override public init(frame: CGRect) {
    super.init(frame: frame)
    
    initializeViews()
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    
    initializeViews()
  }
  
  override public func willMove(toSuperview newSuperview: UIView?) {
    if newSuperview == nil {
      self.stopMarquee()
    }
  }
  
  override public func layoutSubviews() {
    super.layoutSubviews()
    
    layoutViews()
  }
  
  // MARK: - Actions
  
  public func reloadData() {
    self.setNeedsLayout()
  }
  
  public func startMarquee() {
    stopMarquee()
    
    if marqueeType == .right {
      var frame = containerView.frame
      frame.origin.x = self.bounds.size.width - frame.size.width
      containerView.frame = frame
    }
    
    displayLink = CADisplayLink(target: self, selector: #selector(processMarquee))
    if #available(iOS 15.0, *) {
      let frameRate = Float(preferredFramesPerSecond)
      displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: frameRate, maximum: frameRate, preferred: frameRate)
    } else {
      displayLink?.preferredFramesPerSecond = preferredFramesPerSecond
    }
    displayLink?.add(to: RunLoop.main, forMode: RunLoop.Mode.common)
  }
  
  public func stopMarquee() {
    displayLink?.invalidate()
    displayLink = nil
  }
  
  @objc
  private func processMarquee() {
    var frame = self.containerView.frame
    
    switch marqueeType {
    case .left:
      let targetX = -(self.contentView!.bounds.size.width + self.contentMargin)
      if frame.origin.x <= targetX {
        frame.origin.x = 0
        self.containerView.frame = frame
      }else {
        frame.origin.x -= pointsPerFrame
        if frame.origin.x < targetX {
          frame.origin.x = targetX
        }
        self.containerView.frame = frame
      }
      
    case .right:
      let targetX = self.bounds.size.width - self.contentView!.bounds.size.width
      if frame.origin.x >= targetX {
        frame.origin.x = self.bounds.size.width - self.containerView.bounds.size.width
        self.containerView.frame = frame
      }else {
        frame.origin.x += pointsPerFrame
        if frame.origin.x > targetX {
          frame.origin.x = targetX
        }
        self.containerView.frame = frame
      }
      
    case .reverse:
      if isReversing {
        let targetX: CGFloat = 0
        if frame.origin.x > targetX {
          frame.origin.x = 0
          self.containerView.frame = frame
          isReversing = false
        }else {
          frame.origin.x += pointsPerFrame
          if frame.origin.x > 0 {
            frame.origin.x = 0
            isReversing = false
          }
          self.containerView.frame = frame
        }
      } else {
        let targetX = self.bounds.size.width - self.containerView.bounds.size.width
        if frame.origin.x <= targetX {
          isReversing = true
        }else {
          frame.origin.x -= pointsPerFrame
          if frame.origin.x < targetX {
            frame.origin.x = targetX
            isReversing = true
          }
          self.containerView.frame = frame
        }
      }
    }
  }
  
  // MARK: - Layouts
  
  private func initializeViews() {
    self.backgroundColor = UIColor.clear
    self.clipsToBounds = true
    
    containerView.backgroundColor = UIColor.clear
    self.addSubview(containerView)
  }
  
  private func layoutViews() {
    guard let validContentView = contentView else {
      return
    }
    
    containerView.subviews.forEach {
      $0.removeFromSuperview()
    }
    
    validContentView.sizeToFit()
    containerView.addSubview(validContentView)
    
    if marqueeType == .reverse {
      containerView.frame = CGRect(x: 0, y: 0, width: validContentView.bounds.size.width, height: self.bounds.size.height)
    }else {
      containerView.frame = CGRect(x: 0, y: 0, width: validContentView.bounds.size.width*2 + contentMargin, height: self.bounds.size.height)
    }
    
    if validContentView.bounds.size.width > self.bounds.size.width {
      validContentView.frame = CGRect(x: 0, y: 0, width: validContentView.bounds.size.width, height: self.bounds.size.height)
      
      if marqueeType != .reverse {
        let otherContentView = validContentView.copyMarqueeView()
        otherContentView.frame = CGRect(x: validContentView.bounds.size.width + contentMargin, y: 0, width: validContentView.bounds.size.width, height: self.bounds.size.height)
        containerView.addSubview(otherContentView)
      }
      
      if self.bounds.size.width != 0, autoScroll {
        self.startMarquee()
      }
    } else {
      if contentViewFrameConfigWhenCantMarquee != nil {
        contentViewFrameConfigWhenCantMarquee?(validContentView)
      } else {
        validContentView.frame = CGRect(x: 0, y: 0, width: validContentView.bounds.size.width, height: self.bounds.size.height)
      }
    }
  }
}

fileprivate protocol MarqueeViewCopyable {
  func copyMarqueeView() -> UIView
}

extension UIView: MarqueeViewCopyable {
  @objc
  open func copyMarqueeView() -> UIView {
    if let copiedView = try? self.copyObject() {
      return copiedView
    } else {
      let archivedData = NSKeyedArchiver.archivedData(withRootObject: self)
      let copyView = NSKeyedUnarchiver.unarchiveObject(with: archivedData) as! UIView
      return copyView
    }
  }
}

extension UIView {
  func copyObject<T: UIView>() throws -> T? {
    let data = try NSKeyedArchiver.archivedData(withRootObject:self, requiringSecureCoding:false)
    return try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? T
  }
}
