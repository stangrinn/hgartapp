//
//  VideoPlayer.swift
//  HGArt
//
//  Created by  Stanislav Grinshpun on 2025-10-05.
//

import UIKit
import AVFoundation
import SceneKit
import ARKit

class ARVideoControls {
    
    private var playPauseButton: UIButton?
    private var muteButton: UIButton?
    
    func setup(view: UIView,
                              target: Any,
                              muteSelector: Selector,
                              isMuted: @escaping () -> Bool,
                              isPlaying: @escaping () -> Bool) {

        let muteButton = ToggledIconButton(
            defaultIconName: "speaker.wave.2.fill",
            toggledIconName: "speaker.slash.fill",
            backgroundColor: UIColor.black.withAlphaComponent(0.4),
            symbolSize: 14
        )

        muteButton.attach(to: view, target: target, action: muteSelector, toggled: isMuted(), xOffset: 32, yOffset: 32, alignRight: true)
        
        muteButton.isHidden = true

        self.muteButton = muteButton
    }

    func setControlsVisible(_ visible: Bool) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.5, animations: {
                self.muteButton?.alpha = visible ? 1.0 : 0.0
            }, completion: { _ in
                self.muteButton?.isHidden = !visible
            })
        }
    }

    func updatePlayPauseIcon(isPlaying: Bool) {
        let iconName: String = isPlaying ? "pause.fill" : "play.fill"

        DispatchQueue.main.async {
            if var config = self.playPauseButton?.configuration {
                config.image = UIImage(systemName: iconName)
                config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
                self.playPauseButton?.configuration = config
            }
        }
    }

    func updateMuteIcon(isMuted: Bool) {
        let icon: String = isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill"

        DispatchQueue.main.async {
            if var config = self.muteButton?.configuration {
                config.image = UIImage(systemName: icon)
                config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
                self.muteButton?.configuration = config
            }
        }
    }
    
}
