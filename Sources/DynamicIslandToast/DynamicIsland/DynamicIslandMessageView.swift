//
//  DynamicIslandMessageView.swift
//  DIToastExample
//
//  Created by Suykorng on 21/10/24.
//

import UIKit

@available(iOS 17.0, *)
public final class DynamicIslandMessageView: UIView {
  
  // MARK: - Properties
  
  private let externalBorderWidth: CGFloat = 0.66
  
  private lazy var iconContainerView = UIView().config {
    $0.backgroundColor = .clear
    $0.layer.masksToBounds = true
  }
  
  private lazy var iconView = UIImageView().config {
    $0.image = UIImage(systemName: "info")?.applyingSymbolConfiguration(.init(font: UIFont.systemFont(ofSize: 32, weight: .semibold)))
    $0.contentMode = .center
    $0.tintColor = .white
  }
  
  private lazy var titleLabel = UILabel().config {
    $0.font = UIFont.footnote(.regular)
    $0.textAlignment = .left
    $0.textColor = .white.withAlphaComponent(0.75)
  }
  
  private lazy var messageLabel = UILabel().config {
    $0.font = UIFont.callout(.medium)
    $0.textAlignment = .left
    $0.textColor = .white
    $0.numberOfLines = 2
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
    
    iconContainerView.layer.cornerRadius = iconContainerView.bounds.height / 2.0
    iconView.layer.cornerRadius = iconView.bounds.height / 2.0
  }
  
  // MARK: - Actions
  
  public final func setAlphaForSubviews(to alpha: CGFloat) {
    titleLabel.alpha = alpha
    iconContainerView.alpha = alpha
    iconView.alpha = alpha
    messageLabel.alpha = alpha
  }
  
  public final func setTitle(_ title: String, message: String, style: DynamicIslandMessageStyle = .default) {
    titleLabel.text = title
    
    let attributedText = NSMutableAttributedString(string: message, attributes: [.font: UIFont.callout(.medium), .foregroundColor: UIColor.white])
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = 2
    paragraphStyle.lineBreakMode = .byTruncatingTail
    attributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedText.length))
    messageLabel.attributedText = attributedText
    
    switch style {
    case .default:
      break
      
    case .leadingIcon(let image, let backgroundColor, let foregroundColor, let contentMode, let preferredBouncyEffect):
      iconContainerView.backgroundColor = backgroundColor
      iconView.contentMode = contentMode
      iconView.tintColor = foregroundColor
      iconView.image = image
      if preferredBouncyEffect {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) { [weak self] in
          self?.iconView.addSymbolEffect(.bounce)
        }
      }
      
    case .animate(let sourceSFSymbol, let targetSFSymbol, let tintColor):
      iconView.tintColor = tintColor
      iconView.image = sourceSFSymbol
      if let targetSFSymbol {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) { [self] in
          iconView.setSymbolImage(targetSFSymbol, contentTransition: .replace, options: .default, completion: nil)
        }
      }
    }
  }
  
  // MARK: - Prepare layouts
  
  private func prepareLayouts() {
    backgroundColor = .clear
    let inset: CGFloat = 18//DynamicIslandSize.originY
    let size: CGFloat = (DynamicIslandSize.radius - inset) * 2
    
    // Icon Container
    iconContainerView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(iconContainerView)
    iconContainerView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    iconContainerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset).isActive = true
    
    let iconContainerViewWidthConstraint = iconContainerView.widthAnchor.constraint(equalToConstant: size)
    iconContainerViewWidthConstraint.priority = .required
    iconContainerViewWidthConstraint.isActive = true
    
    let iconContainerViewHeightConstraint = iconContainerView.heightAnchor.constraint(equalToConstant: size)
    iconContainerViewHeightConstraint.priority = .required
    iconContainerViewHeightConstraint.isActive = true
    
    // Icon View
    iconView.translatesAutoresizingMaskIntoConstraints = false
    iconContainerView.addSubview(iconView)
    iconView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor).isActive = true
    iconView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor).isActive = true
    iconView.widthAnchor.constraint(equalToConstant: size).isActive = true
    iconView.heightAnchor.constraint(equalToConstant: size).isActive = true
    
    // Title
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    addSubview(titleLabel)
    titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: inset-4).isActive = true
    titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DynamicIslandSize.originY).isActive = true
    titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: titleLabel.font.lineHeight+3).isActive = true
    
    let titleLabelTopConstraint: NSLayoutConstraint = titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 32)//37)
    titleLabelTopConstraint.priority = .required
    titleLabelTopConstraint.isActive = true
    
    // Message
    messageLabel.translatesAutoresizingMaskIntoConstraints = false
    addSubview(messageLabel)
    messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 0).isActive = true
    messageLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: inset-4).isActive = true
    messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset).isActive = true
    messageLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: messageLabel.font.lineHeight+3).isActive = true
    
    let bottomConstraint: NSLayoutConstraint = messageLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -DynamicIslandSize.originY)
    bottomConstraint.priority = .defaultHigh
    bottomConstraint.isActive = true
    
    setAlphaForSubviews(to: 0.0)
  }
}
