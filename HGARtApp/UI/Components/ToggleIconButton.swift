//
//  ToggleIconButton.swift
//  ARKitVideoOverlay
//
//  Created by Stanislav Grinshpun on 2025-04-13.
//

import UIKit

final class ToggledIconButton: UIButton {
    private let defaultIconName: String
    private let toggledIconName: String
    private var isToggled = false
    private let symbolSize: CGFloat
    
    init(defaultIconName: String,
         toggledIconName: String,
         backgroundColor: UIColor,
         symbolSize: CGFloat = 14) {
        
        self.defaultIconName = defaultIconName
        self.toggledIconName = toggledIconName
        self.symbolSize = symbolSize
        super.init(frame: .zero)
        
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: defaultIconName)
        config.baseForegroundColor = .white
        config.background.backgroundColor = backgroundColor
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: symbolSize, weight: .regular)
        self.configuration = config
        
        self.translatesAutoresizingMaskIntoConstraints = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func toggle() {
        isToggled.toggle()
        var config = self.configuration
        config?.image = UIImage(systemName: isToggled ? toggledIconName : defaultIconName)
        config?.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: symbolSize, weight: .regular)
        self.configuration = config
    }
    
    func setToggled(_ value: Bool) {
        isToggled = value
        var config = self.configuration
        config?.image = UIImage(systemName: value ? toggledIconName : defaultIconName)
        config?.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: symbolSize, weight: .regular)
        self.configuration = config
    }
    
    func getToggled() -> Bool {
        return isToggled
    }
    
    func attach(to view: UIView, target: Any, action: Selector, toggled: Bool, xOffset: CGFloat, yOffset: CGFloat, alignRight: Bool = false) {
        
        setToggled(toggled)
        
        addTarget(target, action: action, for: .touchUpInside)
        
        DispatchQueue.main.async {
            view.addSubview(self)

            NSLayoutConstraint.activate([
                alignRight
                    ? self.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -xOffset)
                    : self.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: xOffset),
                self.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -yOffset),
                self.widthAnchor.constraint(equalToConstant: 40),
                self.heightAnchor.constraint(equalToConstant: 40)
            ])
        }
    }
}
