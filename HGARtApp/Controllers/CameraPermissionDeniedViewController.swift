//
//  CameraPermissionDeniedViewController.swift
//  HGArt
//
//  Created by Web TL AE Stanislav Grinshpun on 2025-09-01.
//

import UIKit

class CameraPermissionDeniedViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let logoImageView = UIImageView(image: UIImage(named: "LogoWhiteOnBlack"))
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        logoImageView.widthAnchor.constraint(equalToConstant: 100).isActive = true

        let label = PaddedLabelText()
        label.text = "Camera access is required to view AR content of Helena's Gallery Arts. \nPlease allow access in the app settings."
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16, weight: .light)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        label.textColor = .white
        label.numberOfLines = 0
        label.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 40

        let settingsButton = UIButton(type: .system)
        settingsButton.setTitle("Open Settings", for: .normal)
        
        settingsButton.setTitleColor(.white, for: .normal)
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false

        let exitButton = UIButton(type: .system)
        exitButton.setTitle("Exit App", for: .normal)
        exitButton.setTitleColor(.white, for: .normal)
        exitButton.addTarget(self, action: #selector(exitApp), for: .touchUpInside)
        exitButton.translatesAutoresizingMaskIntoConstraints = false
        

        let stack = UIStackView(arrangedSubviews: [logoImageView, label, settingsButton, exitButton])
        stack.axis = .vertical
        stack.spacing = 30
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            settingsButton.widthAnchor.constraint(equalToConstant: 200),
            exitButton.widthAnchor.constraint(equalToConstant: 200)
        ])
    }

    @objc func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }

    @objc func exitApp() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            exit(0)
        }
    }
}
