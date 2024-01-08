//
//  DynamicIslandMessageBarSmall.swift
//
//
//  Created by Suykorng on 1/1/24.
//

import UIKit

public final class DynamicIslandMessageBarSmall: UIView {
  
  // MARK: - Properties
  
  private let externalBorderWidth: CGFloat = 0.66
  private var isBeingRemoved: Bool = false
  
  private lazy var iconView = UIImageView().config {
    $0.image = DynamicIslandToast.Configuration.icon
    $0.contentMode = .scaleAspectFill
    $0.clipsToBounds = true
    if #available(iOS 13.0, *) {
      $0.layer.cornerCurve = .continuous
      $0.layer.borderColor = UIColor.separator.cgColor
    }
    $0.layer.borderWidth = 1.0
  }
  
  private lazy var titleLabel = UILabel().config {
    $0.font = UIFont.footnote(.regular)
    $0.textAlignment = .left
    $0.textColor = .white.withAlphaComponent(0.75)
  }
  
  private lazy var messageContainerView = MarqueeView().config {
    $0.contentView = messageLabel
    $0.autoScroll = false
  }
  
  private lazy var messageLabel = UILabel().config {
    $0.font = UIFont.callout(.medium)
    $0.textAlignment = .left
    $0.textColor = .white
//    $0.numberOfLines = 0
  }
  
  private lazy var externalBorderView = UIView().config {
    if #available(iOS 16.0, *) {
      $0.layer.borderColor = UIColor(dynamicProvider: { trait in
        return trait.userInterfaceStyle == .dark ? .separator : .clear
      }).cgColor
      $0.layer.cornerCurve = .continuous
    }
    $0.layer.borderWidth = externalBorderWidth
  }
  
  // MARK: - Init
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    prepareLayouts()
  }
  
  required init?(coder: NSCoder) {
    fatalError()
  }
  
  public override func layoutSubviews() {
    super.layoutSubviews()
    
    iconView.layer.cornerRadius = iconView.bounds.height / 2.0
    if #available(iOS 16.0, *), traitCollection.userInterfaceStyle == .dark {
      externalBorderView.frame = isBeingRemoved ? bounds.insetBy(dx: 1, dy: 1) : bounds.insetBy(dx: -externalBorderWidth, dy: -externalBorderWidth)
      externalBorderView.layer.cornerRadius = externalBorderView.bounds.height / 2.0
    }
  }
  
  // MARK: - Actions
  
  public final func setAlphaForSubviews(to alpha: CGFloat) {
    externalBorderView.alpha = alpha
    titleLabel.alpha = alpha
    iconView.alpha = alpha
    messageLabel.alpha = alpha
  }
  
  public final func setTitle(_ title: String, message: String) {
    titleLabel.text = title
    messageLabel.text = message
    
    MainThread.delay(after: .now() + .seconds(1)) { [weak self] in
      guard let self else { return }
      let contentWidth: CGFloat = self.messageLabel.bounds.width
      let maxWidth: CGFloat = self.messageContainerView.bounds.width
      if contentWidth > maxWidth {
        self.messageContainerView.startMarquee()
      }
    }
  }
  
  public final func remove() {
    isBeingRemoved = true
    
    if let window = UIApplication.shared.currentWindow {
      let width: CGFloat = 126
      let x: CGFloat = window.bounds.width/2 - 126/2
      let y: CGFloat = self.frame.origin.y
      let height: CGFloat = 37
      let frame = CGRect(x: x, y: y, width: width, height: height)
      let transform: CGAffineTransform = .init(scaleX: 0.25, y: 0.25)

      let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 0.85) { [self] in
        setAlphaForSubviews(to: 0.0)
        titleLabel.transform = transform
        iconView.transform = transform
        messageLabel.transform = transform
        messageLabel.isHidden = true
        
        layer.shadowOpacity = 0.0
        self.frame = frame
        layer.cornerRadius = height / 2
        layoutIfNeeded()
      }
      
      animator.addCompletion { [weak self] _ in
        self?.removeFromSuperview()
      }
      
      animator.startAnimation()
    }
  }
  
  // MARK: - Prepare layouts
  
  private func prepareLayouts() {
    backgroundColor = .black
    addSubview(externalBorderView)
    
    let inset: CGFloat = 14
    let size: CGFloat = 83 - inset*2
    iconView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(iconView)
    iconView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset).isActive = true
    iconView.widthAnchor.constraint(equalToConstant: size).isActive = true
    iconView.heightAnchor.constraint(equalToConstant: size).isActive = true
    
    messageContainerView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(messageContainerView)
    messageContainerView.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: inset - 4).isActive = true
    messageContainerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -(inset+8)).isActive = true
    messageContainerView.bottomAnchor.constraint(equalTo: iconView.bottomAnchor, constant: -2).isActive = true
    messageContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: messageLabel.font.lineHeight + 4).isActive = true
    
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    addSubview(titleLabel)
    titleLabel.bottomAnchor.constraint(equalTo: messageContainerView.topAnchor, constant: -4).isActive = true
    titleLabel.leadingAnchor.constraint(equalTo: messageContainerView.leadingAnchor).isActive = true
    titleLabel.trailingAnchor.constraint(equalTo: messageContainerView.trailingAnchor).isActive = true
    
    [titleLabel, messageContainerView].forEach {
      addSubview($0)
    }
    
    setAlphaForSubviews(to: 0.0)
    
    layer.shadowColor = UIColor.black.withAlphaComponent(0.35).cgColor
    layer.shadowOffset = CGSize(width: 0, height: 5)
    layer.shadowOpacity = 1.0
    layer.shadowRadius = 5*2.5
  }
}
