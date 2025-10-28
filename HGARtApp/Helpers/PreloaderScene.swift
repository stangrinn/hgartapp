//
//  PreloaderScene.swift
//  HGArt
//
//  Created by Web TL AE Stanislav Grinshpun on 2025-10-14.
//
import SceneKit
import SpriteKit
import UIKit

class PreloaderScene {
    
    struct PreloaderUI {
        let scene: SKScene
        let track: SKShapeNode
        let fill: SKShapeNode
        let stripesCropNode: SKCropNode?  // Crop node with stripes inside
        let stripesMask: SKShapeNode?
        let label: SKLabelNode
        let trackRect: CGRect
    }
    
    private enum Palette {
        static let textPurple = UIColor(red: 73/255, green: 43/255, blue: 128/255, alpha: 1)
        static let trackCream = UIColor(red: 254/255, green: 249/255, blue: 235/255, alpha: 1)
        static let fillPurple = UIColor(red: 115/255, green: 79/255, blue: 176/255, alpha: 1)
        static let stripeDark = UIColor(red: 137/255, green: 97/255, blue: 217/255, alpha: 1)
        static let stripeLight = UIColor(red: 164/255, green: 133/255, blue: 226/255, alpha: 1)
    }
    
    var preloadersByAnchor: [UUID: PreloaderUI] = [:]
    var lastProgressByAnchor: [UUID: Double] = [:]
    var anchorID: UUID!
    var width: CGFloat!
    var height: CGFloat!
    
    init(anchorID: UUID, width: CGFloat, height: CGFloat) {
        self.anchorID = anchorID
        self.width = width
        self.height = height
    }
    
    func getFullScene() -> SKScene {
        
        // Use anchor's physical dimensions scaled to reasonable pixel size
        let scaleFactor: CGFloat = 2000  // 1 meter = 1000 pixels
        
        let sceneSize = CGSize(width: self.width * scaleFactor, height: self.height * scaleFactor)
        
        let scene = SKScene(size: sceneSize)
        
        scene.name = "Preloader Scene for \(self.anchorID!)"
        
        // Use visible background for debugging - dark gray to see white elements
        scene.backgroundColor = UIColor(white: 1.0, alpha: 0.3)

        let label = SKLabelNode(text: "loading…")
        
        label.fontName = "Arial"
        
        label.fontColor = .black
        
        label.fontSize = 54
        
        label.position = CGPoint(x: sceneSize.width/2, y: sceneSize.height - (sceneSize.height/2 + 80))
        
        label.verticalAlignmentMode = .center
        
        label.horizontalAlignmentMode = .center
        
        label.yScale = -1.0  // Flip vertically
        
        scene.addChild(label)

        // Progress track - flip Y coordinate
        let trackWidth = sceneSize.width * 0.7
        let trackHeight: CGFloat = 34
        
        let trackRect = CGRect(x: (sceneSize.width - trackWidth)/2,
                               y: sceneSize.height - (sceneSize.height/2 - trackHeight/2 - 20) - trackHeight,
                               width: trackWidth,
                               height: trackHeight)

        let track = SKShapeNode(rect: trackRect, cornerRadius: trackHeight/2)
        track.fillColor = Palette.trackCream
        track.strokeColor = UIColor(white: 1, alpha: 0.1)
        track.lineWidth = 4
        track.zPosition = 1
        scene.addChild(track)

        // Progress fill (start small) - flip Y coordinate
        let fillPath = UIBezierPath(roundedRect: CGRect(x: trackRect.minX,
                                                        y: trackRect.minY,
                                                        width: 1,
                                                        height: trackRect.height),
                                    cornerRadius: 0).cgPath
        
        let fill = SKShapeNode(path: fillPath)
        fill.fillColor = .black
        fill.strokeColor = .clear
        fill.zPosition = track.zPosition + 1
        
        scene.addChild(fill)
        
        let ui = PreloaderUI(scene: scene,
                             track: track,
                             fill: fill,
                             stripesCropNode: nil,
                             stripesMask: nil,
                             label: label,
                             trackRect: trackRect)
        
        preloadersByAnchor[anchorID] = ui

        return scene
    }
    
    func getScene() -> SKScene {
        
        // Use anchor's physical dimensions scaled to reasonable pixel size
        let scaleFactor: CGFloat = 2000  // 1 meter = 1000 pixels
        
        let sceneSize = CGSize(width: self.width * scaleFactor, height: self.height * scaleFactor)
        
        let scene = SKScene(size: sceneSize)
        
        scene.name = "Preloader Scene for \(self.anchorID!)"
        
        // Use visible background for debugging - dark gray to see white elements
        scene.backgroundColor = UIColor(white: 1.0, alpha: 0.3)

        let label = SKLabelNode(text: "loading…")
        
        label.fontName = "Baloo"
        
        label.fontColor = Palette.textPurple
        
        label.fontSize = 64
        
        label.position = CGPoint(x: sceneSize.width/2, y: sceneSize.height - (sceneSize.height/2 + 80))
        
        label.verticalAlignmentMode = .center
        
        label.horizontalAlignmentMode = .center
        
        label.yScale = -1.0  // Flip vertically
        
        scene.addChild(label)

        // Progress track - flip Y coordinate
        let trackWidth = sceneSize.width * 0.7
        let trackHeight: CGFloat = 74
        let trackRect = CGRect(x: (sceneSize.width - trackWidth)/2,
                               y: sceneSize.height - (sceneSize.height/2 - trackHeight/2 - 20) - trackHeight,
                               width: trackWidth,
                               height: trackHeight)

        let track = SKShapeNode(rect: trackRect, cornerRadius: trackHeight/2)
        track.fillColor = Palette.trackCream
        track.strokeColor = UIColor(white: 0.0, alpha: 0.05)
        track.lineWidth = 4
        track.zPosition = 1
        scene.addChild(track)

        // Progress fill (start small) - flip Y coordinate
        let fillPath = UIBezierPath(roundedRect: CGRect(x: trackRect.minX, y: trackRect.minY, width: 1, height: trackRect.height),
                                    cornerRadius: trackRect.height/2).cgPath
        
        let fill = SKShapeNode(path: fillPath)
        fill.fillColor = Palette.fillPurple
        fill.strokeColor = .clear
        fill.lineCap = .round
        fill.lineJoin = .round
        fill.zPosition = track.zPosition + 1
        scene.addChild(fill)
        
        // Create diagonal stripes pattern with crop node for clipping
        let stripesContainer = SKNode()
        let stripeWidth: CGFloat = 18  // Width of each stripe
        let stripeSpacing: CGFloat = 36  // Distance between stripes
        stripesContainer.position = CGPoint(x: -stripeSpacing, y: 0)
        stripesContainer.alpha = 0.85
        
        // Create multiple diagonal stripe lines
        let stripeColors = [Palette.stripeDark, Palette.stripeLight]
        let maxStripes = Int((trackWidth + trackHeight * 2) / stripeSpacing) + 5
        
        for i in 0..<maxStripes {
            let stripePath = UIBezierPath()
            // Diagonal lines from bottom-left to top-right
            let startX = CGFloat(i) * stripeSpacing - trackHeight * 2
            stripePath.move(to: CGPoint(x: startX, y: 0))
            stripePath.addLine(to: CGPoint(x: startX + trackHeight * 2, y: trackHeight))
            
            let stripe = SKShapeNode(path: stripePath.cgPath)
            stripe.strokeColor = stripeColors[i % stripeColors.count]
            stripe.lineWidth = stripeWidth
            stripe.lineCap = .round
            stripesContainer.addChild(stripe)
        }
        
        // Create crop node to clip stripes
        let cropNode = SKCropNode()
        cropNode.position = CGPoint(x: trackRect.minX, y: trackRect.minY)
        cropNode.zPosition = fill.zPosition + 0.5
        cropNode.addChild(stripesContainer)
        
        // Initial mask (very small)
        let maskPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 1, height: trackRect.height),
                                    cornerRadius: trackRect.height/2)
        let maskNode = SKShapeNode(path: maskPath.cgPath)
        maskNode.fillColor = .white
        maskNode.strokeColor = .clear
        maskNode.lineWidth = 0
        cropNode.maskNode = maskNode
        
        scene.addChild(cropNode)

        let ui = PreloaderUI(scene: scene,
                             track: track,
                             fill: fill,
                             stripesCropNode: cropNode,
                             stripesMask: maskNode,
                             label: label,
                             trackRect: trackRect)
        
        preloadersByAnchor[anchorID] = ui

        return scene
    }

    // Update progress UI for specific anchor
    func updatePreloaderProgress(for anchorID: UUID, progress: Double) {
        guard let ui = preloadersByAnchor[anchorID] else { return }
        
        let clamped = max(0.0, min(1.0, progress))

        // Throttle: update only when percent changes or delta > ~1%
        let prev = lastProgressByAnchor[anchorID] ?? -1
        
        let prevPercent = Int((prev * 100.0).rounded())
        
        let newPercent = Int((clamped * 100.0).rounded())
        
        if newPercent == prevPercent && abs(clamped - prev) < 0.01 { return }
        
        lastProgressByAnchor[anchorID] = clamped

        let width = CGFloat(clamped) * ui.trackRect.width
        
        let path = UIBezierPath(roundedRect: CGRect(x: ui.trackRect.minX, y: ui.trackRect.minY, width: max(1, width),
                                height: ui.trackRect.height),
                                cornerRadius: ui.trackRect.height/2).cgPath
        
        ui.scene.run(SKAction.run {
            ui.fill.path = path
                
            // Update crop mask to match fill width
            let maskPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: max(1, width),
                                        height: ui.trackRect.height),
                                        cornerRadius: ui.trackRect.height/2)
            
            ui.stripesMask?.path = maskPath.cgPath
            
            ui.stripesCropNode?.maskNode = ui.stripesMask
        })
    }

    // Fade and cleanup preloader on success
    func fadeOutPreloader(for anchorID: UUID) {
        guard let ui = preloadersByAnchor[anchorID] else { return }
        ui.scene.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.25),
            SKAction.run { [weak self] in self?.preloadersByAnchor.removeValue(forKey: anchorID) }
        ]))
    }

    // Failure state for preloader
    func setPreloaderFailed(for anchorID: UUID) {
        guard let ui = preloadersByAnchor[anchorID] else { return }
        ui.scene.run(SKAction.run {
            ui.label.text = "connection error"
            ui.label.fontColor = .red
        })
    }
}
