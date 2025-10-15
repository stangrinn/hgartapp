//
//  PreloaderScene.swift
//  HGArt
//
//  Created by Web TL AE Stanislav Grinshpun on 2025-10-14.
//
import SceneKit
import SpriteKit

class PreloaderScene {
    struct PreloaderUI {
        let scene: SKScene
        let track: SKShapeNode
        let fill: SKShapeNode
        let label: SKLabelNode
        let star: SKShapeNode
        let percent: SKLabelNode
        let trackRect: CGRect
    }
    
    var preloadersByAnchor: [UUID: PreloaderUI] = [:]
    var lastProgressByAnchor: [UUID: Double] = [:]
    var anchorID: UUID!
    var width: CGFloat!
    var height: CGFloat!
    
    init(anchorID: UUID, width: CGFloat = 1280, height: CGFloat = 720) {
        self.anchorID = anchorID
        self.width = width
        self.height = height
    }
    
    func getScene() -> SKScene {
        
        let sceneSize = CGSize(width: 720, height: 1280)
        
        let scene = SKScene(size: sceneSize)
        
        scene.name = "Preloader Scene for \(self.anchorID!)"
        
        scene.scaleMode = .aspectFill
        
        // Use visible background for debugging - dark gray to see white elements
        scene.backgroundColor = UIColor(white: 1.0, alpha: 0.65)

        // Title label - flip Y coordinate
        let label = SKLabelNode(text: "loading…")
        
        label.fontName = "Avenir-Heavy"
        
        label.fontColor = UIColor(red: 73/255, green: 43/255, blue: 128/255, alpha: 1)
        
        label.fontSize = 56
        
        label.position = CGPoint(x: sceneSize.width/2, y: sceneSize.height - (sceneSize.height/2 + 80))
        
        label.verticalAlignmentMode = .center
        
        label.horizontalAlignmentMode = .center
        
        label.yScale = -1.0  // Flip vertically
        
        scene.addChild(label)

        // Progress track - flip Y coordinate
        let trackWidth = sceneSize.width * 0.6
        let trackHeight: CGFloat = 33
        let trackRect = CGRect(x: (sceneSize.width - trackWidth)/2,
                               y: sceneSize.height - (sceneSize.height/2 - trackHeight/2 - 20) - trackHeight,
                               width: trackWidth,
                               height: trackHeight)

        let track = SKShapeNode(rect: trackRect, cornerRadius: trackHeight/2)
        track.fillColor = UIColor(red: 1.0, green: 0.95, blue: 0.8, alpha: 1.0) // creamy
        track.strokeColor = .clear
        
        scene.addChild(track)

        // Progress fill (start small) - flip Y coordinate
        let fillPath = UIBezierPath(roundedRect: CGRect(x: trackRect.minX, y: trackRect.minY, width: 1, height: trackRect.height), cornerRadius: trackRect.height/2).cgPath
        let fill = SKShapeNode(path: fillPath)
        fill.fillColor = UIColor(red: 115/255, green: 79/255, blue: 176/255, alpha: 1)
        fill.strokeColor = .clear
        scene.addChild(fill)

        // Star badge - flip Y coordinate
        let starRadius: CGFloat = 36
        let star = SKShapeNode(path: starPath(center: .zero, radius: starRadius))
        star.fillColor = UIColor(red: 1.0, green: 0.84, blue: 0.2, alpha: 1)
        star.strokeColor = UIColor(red: 0.95, green: 0.72, blue: 0.05, alpha: 1)
        star.lineWidth = 4
        star.position = CGPoint(x: trackRect.maxX, y: trackRect.midY)

        scene.addChild(star)

        let percent = SKLabelNode(text: "0")
        percent.fontName = "Avenir-Heavy"
        percent.fontSize = 28
        percent.fontColor = UIColor(red: 73/255, green: 43/255, blue: 128/255, alpha: 1)
        percent.verticalAlignmentMode = .center
        percent.horizontalAlignmentMode = .center
        percent.position = .zero
        percent.yScale = -1.0  // Flip vertically (relative to star)
        star.addChild(percent)

        let ui = PreloaderUI(scene: scene, track: track, fill: fill, label: label,star: star, percent: percent, trackRect: trackRect)
        
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
        let path = UIBezierPath(roundedRect: CGRect(x: ui.trackRect.minX, y: ui.trackRect.minY, width: max(1, width), height: ui.trackRect.height), cornerRadius: ui.trackRect.height/2).cgPath
        // Schedule mutations on the SpriteKit render loop to avoid thread races with SceneKit renderer
        ui.scene.run(SKAction.run {
            ui.fill.path = path
//            let x = ui.trackRect.minX + width
//            ui.star.position = CGPoint(x: x, y: ui.trackRect.midY)
            ui.percent.text = String(Int(round(clamped * 100)))
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

    // 5-point star path
    private func starPath(center: CGPoint, radius: CGFloat) -> CGPath {
        let points = 5
        let adjustment = -CGFloat.pi/2
        let path = UIBezierPath()
        for i in 0..<(points * 2) {
            let angle = (CGFloat(i) * .pi / CGFloat(points)) + adjustment
            let r = (i % 2 == 0) ? radius : radius * 0.45
            let pt = CGPoint(x: center.x + r * cos(angle), y: center.y + r * sin(angle))
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.close()
        return path.cgPath
    }
}
