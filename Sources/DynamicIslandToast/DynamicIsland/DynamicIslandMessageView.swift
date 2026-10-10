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
  private let defaultTitleFont = UIFont.systemFont(ofSize: 13, weight: .regular)
  private let defaultMessageFont = UIFont.systemFont(ofSize: 16, weight: .medium)
  private var titleFont: UIFont
  private var messageFont: UIFont
  private var titleLabelHeightConstraint: NSLayoutConstraint?
  private var messageLabelHeightConstraint: NSLayoutConstraint?
  private var isContentTransitionActive = false
  private var contentAlphaBeforeTransition: CGFloat = 0
  private var pendingIconEffect: (() -> Void)?
  private var scheduledIconEffect: DispatchWorkItem?
  private var iconConfiguration = UUID()
  private var iconSizeConstraints: [NSLayoutConstraint] = []
  private let iconInset: CGFloat = 18
  
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
    $0.font = titleFont
    $0.textAlignment = .left
    $0.textColor = .white.withAlphaComponent(0.75)
    $0.adjustsFontForContentSizeCategory = false
  }
  
  private lazy var messageLabel = UILabel().config {
    $0.font = messageFont
    $0.textAlignment = .left
    $0.textColor = .white
    $0.numberOfLines = 5
    $0.lineBreakMode = .byWordWrapping
    $0.adjustsFontForContentSizeCategory = false
  }
  
  // MARK: - Init
  
  override init(frame: CGRect) {
    titleFont = defaultTitleFont
    messageFont = defaultMessageFont
    super.init(frame: frame)
    
    prepareLayouts()
  }
  
  required init?(coder: NSCoder) {
    fatalError()
  }

  deinit {
    scheduledIconEffect?.cancel()
  }
  
  public override func didMoveToWindow() {
    super.didMoveToWindow()
    updateIconGeometry()
  }

  public override func layoutSubviews() {
    updateIconGeometry()
    super.layoutSubviews()
    
    iconContainerView.layer.cornerRadius = iconContainerView.bounds.height / 2.0
    iconView.layer.cornerRadius = iconView.bounds.height / 2.0
  }
  
  // MARK: - Actions

  var transitionIconView: UIImageView { iconView }
  
  public final func setAlphaForSubviews(to alpha: CGFloat) {
    // The transition renders fully visible content into its own surface and
    // owns the fade. Existing hosts may continue requesting their text fade.
    guard !isContentTransitionActive else { return }
    applyContentAlpha(alpha)
  }

  func prepareContentTransition() {
    guard !isContentTransitionActive else { return }
    contentAlphaBeforeTransition = iconContainerView.alpha
    isContentTransitionActive = true
    UIView.performWithoutAnimation {
      applyContentAlpha(1)
    }
  }

  func finishContentTransition(isPresenting: Bool, isCancelled: Bool) {
    guard isContentTransitionActive else { return }
    isContentTransitionActive = false
    applyContentAlpha(isCancelled ? contentAlphaBeforeTransition : (isPresenting ? 1 : 0))
    let effect = pendingIconEffect
    pendingIconEffect = nil
    if isPresenting || isCancelled {
      effect?()
    }
  }

  private func applyContentAlpha(_ alpha: CGFloat) {
    titleLabel.alpha = alpha
    messageLabel.alpha = alpha
    iconContainerView.alpha = alpha
  }

  private func performIconEffect(_ effect: @escaping () -> Void) {
    if isContentTransitionActive {
      pendingIconEffect = effect
    } else {
      effect()
    }
  }

  private func scheduleIconEffect(_ effect: @escaping (DynamicIslandMessageView) -> Void) {
    let configuration = iconConfiguration
    let work = DispatchWorkItem { [weak self] in
      guard let self, self.iconConfiguration == configuration else { return }
      self.scheduledIconEffect = nil
      self.performIconEffect { [weak self] in
        guard let self, self.iconConfiguration == configuration else { return }
        effect(self)
      }
    }
    scheduledIconEffect = work
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: work)
  }

  public final func setFonts(title titleFont: UIFont? = nil, message messageFont: UIFont? = nil) {
    self.titleFont = titleFont ?? defaultTitleFont
    self.messageFont = messageFont ?? defaultMessageFont
    
    titleLabel.font = self.titleFont
    messageLabel.font = self.messageFont
    titleLabelHeightConstraint?.constant = self.titleFont.lineHeight + 3
    messageLabelHeightConstraint?.constant = self.messageFont.lineHeight + 3
    
    if let message = messageLabel.attributedText?.string {
      applyMessageText(message)
    }
    
    invalidateIntrinsicContentSize()
    setNeedsLayout()
  }
  
  public final func setTitle(_ title: String, message: String, style: DynamicIslandMessageStyle = .default) {
    scheduledIconEffect?.cancel()
    scheduledIconEffect = nil
    pendingIconEffect = nil
    iconConfiguration = UUID()
    iconView.removeAllSymbolEffects()
    iconContainerView.backgroundColor = .clear
    iconView.contentMode = .center
    iconView.tintColor = .white
    iconView.image = UIImage(systemName: "info")?.applyingSymbolConfiguration(.init(font: UIFont.systemFont(ofSize: 32, weight: .semibold)))
    titleLabel.text = title
    applyMessageText(message)
    
    switch style {
    case .default:
      break
      
    case .leadingIcon(let image, let backgroundColor, let foregroundColor, let contentMode, let preferredBouncyEffect):
      iconContainerView.backgroundColor = backgroundColor
      iconView.contentMode = contentMode
      iconView.tintColor = foregroundColor
      iconView.image = image
      if preferredBouncyEffect {
        scheduleIconEffect { view in
          view.iconView.addSymbolEffect(.bounce)
        }
      }
      
    case .animate(let sourceSFSymbol, let targetSFSymbol, let tintColor):
      iconView.tintColor = tintColor
      iconView.image = sourceSFSymbol
      if let targetSFSymbol {
        scheduleIconEffect { view in
          view.iconView.setSymbolImage(targetSFSymbol, contentTransition: .replace, options: .default, completion: nil)
        }
      }
    }
  }
  
  // MARK: - Prepare layouts
  
  private func prepareLayouts() {
    backgroundColor = .clear
    let inset = iconInset
    let size = max(0, (DynamicIslandSize.radius(for: self) - inset) * 2)
    
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
    iconSizeConstraints = [iconContainerViewWidthConstraint, iconContainerViewHeightConstraint]
    
    // Icon View
    iconView.translatesAutoresizingMaskIntoConstraints = false
    iconContainerView.addSubview(iconView)
    iconView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor).isActive = true
    iconView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor).isActive = true
    let iconWidthConstraint = iconView.widthAnchor.constraint(equalToConstant: size)
    let iconHeightConstraint = iconView.heightAnchor.constraint(equalToConstant: size)
    NSLayoutConstraint.activate([iconWidthConstraint, iconHeightConstraint])
    iconSizeConstraints.append(contentsOf: [iconWidthConstraint, iconHeightConstraint])

    // Title
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    addSubview(titleLabel)
    titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: inset-4).isActive = true
    titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DynamicIslandSize.originY).isActive = true
    titleLabelHeightConstraint = titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: titleLabel.font.lineHeight + 3)
    titleLabelHeightConstraint?.isActive = true
    
    let titleLabelTopConstraint: NSLayoutConstraint = titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 32)//37)
    titleLabelTopConstraint.priority = .required
    titleLabelTopConstraint.isActive = true
    
    // Message
    messageLabel.translatesAutoresizingMaskIntoConstraints = false
    addSubview(messageLabel)
    messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 0).isActive = true
    messageLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: inset-4).isActive = true
    messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset).isActive = true
    messageLabelHeightConstraint = messageLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: messageLabel.font.lineHeight + 3)
    messageLabelHeightConstraint?.isActive = true
    
    let bottomConstraint: NSLayoutConstraint = messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -DynamicIslandSize.originY)
    // Let bottom padding yield in a compact host while preserving the
    // labels' size and order before the expanded content is measured.
    // This still participates in fitting the expanded height (priority 50).
    bottomConstraint.priority = UILayoutPriority(999)
    bottomConstraint.isActive = true
    
    registerForTraitChanges([UITraitDisplayScale.self]) { (view: DynamicIslandMessageView, _) in
      view.updateIconGeometry()
    }
    setAlphaForSubviews(to: 0.0)
  }

  private func updateIconGeometry() {
    let size = max(0, (DynamicIslandSize.radius(for: self) - iconInset) * 2)
    guard iconSizeConstraints.contains(where: { $0.constant != size }) else { return }
    iconSizeConstraints.forEach { $0.constant = size }
    invalidateIntrinsicContentSize()
    setNeedsLayout()
  }
  
  private func applyMessageText(_ message: String) {
    let attributedText = NSMutableAttributedString(
      string: message,
      attributes: [.font: messageFont, .foregroundColor: UIColor.white]
    )
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = 2
    paragraphStyle.lineBreakMode = .byWordWrapping
    attributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedText.length))
    messageLabel.attributedText = attributedText
  }
}
