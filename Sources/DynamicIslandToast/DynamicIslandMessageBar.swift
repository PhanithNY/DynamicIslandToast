//
//  DynamicIslandMessageBar.swift
//  
//
//  Created by Suykorng on 26/11/23.
//

//import UIKit
//
//public final class DynamicIslandMessageBar: UIView {
//  
//  // MARK: - Properties
//  
//  private lazy var iconView = UIImageView().config {
//    $0.image = DynamicIslandToast.Configuration.icon
//    $0.contentMode = .scaleAspectFill
//    $0.clipsToBounds = true
//    if #available(iOS 13.0, *) {
//      $0.layer.cornerCurve = .continuous
//    }
//  }
//  
//  private lazy var titleLabel = UILabel().config {
//    $0.font = UIFont.body(.medium)
//    $0.textAlignment = .left
//    $0.textColor = .white
//    $0.text = "Information"
//  }
//  
//  private lazy var messageLabel = UILabel().config {
//    $0.font = UIFont.callout()
//    $0.textAlignment = .left
//    $0.textColor = .white
//    $0.text = "An error occurred"
//    $0.numberOfLines = 0
//  }
//  
//  // MARK: - Init
//  
//  override init(frame: CGRect) {
//    super.init(frame: frame)
//    
//    prepareLayouts()
//  }
//  
//  required init?(coder: NSCoder) {
//    fatalError()
//  }
//  
//  public override func layoutSubviews() {
//    super.layoutSubviews()
//    
//    iconView.layer.cornerRadius = 16
//    
//    let horizontalLabelSpacing: CGFloat = 11
//    let labelOriginX: CGFloat = iconView.frame.maxX + horizontalLabelSpacing
//    let verticalSpacing: CGFloat = 28
//
//    titleLabel.frame = CGRect(x: labelOriginX,
//                              y: verticalSpacing,
//                              width: bounds.width - iconView.frame.maxX - horizontalLabelSpacing*2,
//                              height: titleLabel.font.lineHeight).integral
//    
//    messageLabel.frame = CGRect(x: titleLabel.frame.minX,
//                                y: titleLabel.frame.maxY + horizontalLabelSpacing/2,
//                                width: titleLabel.frame.width,
//                                height: bounds.height - titleLabel.frame.maxY - verticalSpacing).integral
//  }
//  
//  // MARK: - Actions
//  
//  public final func setAlphaForSubviews(to alpha: CGFloat) {
//    iconView.alpha = alpha
//    titleLabel.alpha = alpha
//    messageLabel.alpha = alpha
//    
//    
//    if #available(iOS 13.0, *) {
//      layer.borderWidth = 0.66
//      layer.borderColor = UIColor.separator.cgColor
//    }
//  }
//  
//  public final func setTitle(_ title: String, message: String) {
//    titleLabel.text = title
//    messageLabel.text = message
//  }
//  
//  public final func remove() {
//    if let window = UIApplication.shared.currentWindow {
//      let width: CGFloat = 126
//      let x: CGFloat = window.bounds.width/2 - 126/2
//      let y: CGFloat = 11
//      let height: CGFloat = 37
//      let frame = CGRect(x: x, y: y, width: width, height: height)
//      
//      let transform: CGAffineTransform = .init(scaleX: 0.25, y: 0.25)
//      
//      let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 0.75) { [self] in
//        self.setAlphaForSubviews(to: 0.0)
//        self.iconView.transform = transform
//        self.titleLabel.transform = transform
//        self.messageLabel.transform = transform
//        self.messageLabel.isHidden = true
//        
//        self.frame = frame
//        self.layer.cornerRadius = height / 2
//        self.layoutIfNeeded()
//      }
//      
//      animator.addCompletion { [weak self] _ in
//        self?.removeFromSuperview()
//      }
//      
//      animator.startAnimation()
//    }
//  }
//  
//  // MARK: - Prepare layouts
//  
//  private func prepareLayouts() {
//    backgroundColor = .black
//    let inset: CGFloat = 12
//    let size: CGFloat = 50 + 28 - inset*2
//    iconView.translatesAutoresizingMaskIntoConstraints = false
//    addSubview(iconView)
//    iconView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
//    iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset).isActive = true
//    iconView.widthAnchor.constraint(equalToConstant: size).isActive = true
//    iconView.heightAnchor.constraint(equalToConstant: size).isActive = true
//    
//    [titleLabel, messageLabel].forEach {
//      addSubview($0)
//    }
//    
//    setAlphaForSubviews(to: 0.0)
//  }
//}
