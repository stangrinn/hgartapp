//
//  TargetScanner.swift
//  ARKitVideoOverlay
//
//  Created by AE Stanislav Grinshpun on 2025-04-17.
//


import ARKit

final class TargetScannerOverlay: UIView {

    private let borderLayer = CAShapeLayer()
    private let scanLine = UIView()
    private var scanAnimation: CABasicAnimation?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBorder()
        setupScanLine()
        startScanAnimation()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupBorder() {
        let maxWidth = bounds.width * 0.8
        let width = maxWidth
        let height = width * 4 / 3

        let originX = (bounds.width - width) / 2
        let originY = (bounds.height - height) / 2
        let borderRect = CGRect(x: originX, y: originY, width: width, height: height)

        let path = UIBezierPath(rect: borderRect)
        borderLayer.path = path.cgPath
        borderLayer.strokeColor = UIColor.clear.cgColor
        borderLayer.fillColor = UIColor.clear.cgColor
        layer.addSublayer(borderLayer)
        addCornerIndicators(in: borderRect)
    }

    private func setupScanLine() {
        guard let path = borderLayer.path else { return }
        let rect = path.boundingBox

        scanLine.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        scanLine.frame = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: 2)
        addSubview(scanLine)
    }

    private func startScanAnimation() {
        guard let path = borderLayer.path else { return }
        let rect = path.boundingBox

        scanAnimation = CABasicAnimation(keyPath: "position.y")
        scanAnimation?.fromValue = rect.minY + 1
        scanAnimation?.toValue = rect.maxY - 1
        scanAnimation?.duration = 1.0
        scanAnimation?.repeatCount = .infinity
        scanAnimation?.autoreverses = true

        if let animation = scanAnimation {
            scanLine.layer.add(animation, forKey: "scan")
        }
    }

    func stopAndRemove() {
        DispatchQueue.main.async {
            self.scanLine.layer.removeAnimation(forKey: "scan")
            self.removeFromSuperview()
        }
    }

    private func addCornerIndicators(in rect: CGRect) {
        let length: CGFloat = 20.0
        let thickness: CGFloat = 2.0
        let color = UIColor.black.cgColor

        let positions: [(CGPoint, CGPoint)] = [
            // Top-left corner
            (CGPoint(x: rect.minX, y: rect.minY),
             CGPoint(x: rect.minX + length, y: rect.minY)),
            (CGPoint(x: rect.minX, y: rect.minY),
             CGPoint(x: rect.minX, y: rect.minY + length)),

            // Top-right corner
            (CGPoint(x: rect.maxX - length, y: rect.minY),
             CGPoint(x: rect.maxX, y: rect.minY)),
            (CGPoint(x: rect.maxX, y: rect.minY),
             CGPoint(x: rect.maxX, y: rect.minY + length)),

            // Bottom-left corner
            (CGPoint(x: rect.minX, y: rect.maxY - length),
             CGPoint(x: rect.minX, y: rect.maxY)),
            (CGPoint(x: rect.minX, y: rect.maxY),
             CGPoint(x: rect.minX + length, y: rect.maxY)),

            // Bottom-right corner
            (CGPoint(x: rect.maxX - length, y: rect.maxY),
             CGPoint(x: rect.maxX, y: rect.maxY)),
            (CGPoint(x: rect.maxX, y: rect.maxY - length),
             CGPoint(x: rect.maxX, y: rect.maxY))
        ]

        for (start, end) in positions {
            let line = CAShapeLayer()
            let path = UIBezierPath()
            path.move(to: start)
            path.addLine(to: end)

            line.path = path.cgPath
            line.strokeColor = color
            line.lineWidth = thickness
            layer.addSublayer(line)
        }
    }
}
