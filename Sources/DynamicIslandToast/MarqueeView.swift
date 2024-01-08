//
//  MarqueeView.swift
//
//
//  Created by Suykorng on 7/1/24.
//

import UIKit

public final class MarqueeView: UIView {
  
  public var contentViewFrameConfigWhenCantMarquee: ((UIView)->())?
  
  /// Begin scrolling behavior automatically. Default is false.
  public var autoScroll: Bool = false
  
  /// The margin between marquee view
  public var contentMargin: CGFloat = 8
  
  /// Framerate for the animation.
  public var preferredFramesPerSecond: Int = 0
  
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
    
    let targetX = -(self.contentView!.bounds.size.width + self.contentMargin)
    if frame.origin.x <= targetX {
      frame.origin.x = 0
      self.containerView.frame = frame
    }else {
      frame.origin.x -= speed
      if frame.origin.x < targetX {
        frame.origin.x = targetX
      }
      self.containerView.frame = frame
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
    
    containerView.frame = CGRect(
      x: 0,
      y: 0,
      width: validContentView.bounds.size.width*2 + contentMargin,
      height: self.bounds.size.height
    )
    
    if validContentView.bounds.size.width > self.bounds.size.width {
      validContentView.frame = CGRect(
        x: 0,
        y: 0,
        width: validContentView.bounds.size.width,
        height: self.bounds.size.height
      )
      
      let otherContentView = validContentView.copyMarqueeView()
      otherContentView.frame = CGRect(
        x: validContentView.bounds.size.width + contentMargin,
        y: 0,
        width: validContentView.bounds.size.width,
        height: self.bounds.size.height
      )
      containerView.addSubview(otherContentView)
      
      if self.bounds.size.width != 0, autoScroll {
        self.startMarquee()
      }
    } else {
      if contentViewFrameConfigWhenCantMarquee != nil {
        contentViewFrameConfigWhenCantMarquee?(validContentView)
      } else {
        validContentView.frame = CGRect(
          x: 0,
          y: 0,
          width: validContentView.bounds.size.width,
          height: self.bounds.size.height
        )
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
