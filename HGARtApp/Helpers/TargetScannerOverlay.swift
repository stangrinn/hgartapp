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
        
        NotificationCenter.default.addObserver(
                self,
                selector: #selector(appDidBecomeActive),
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil, !isHidden {
            startScanAnimation()
        } else {
            stopScanning()
        }
    }
    
    

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    func startScanAnimation() {
        guard scanLine.layer.animation(forKey: "scan") == nil else {
            return // already running
        }
        guard let path = borderLayer.path else { return }
        let rect = path.boundingBox

        // reset start position
        scanLine.frame = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: 2)

        let animation = CABasicAnimation(keyPath: "position.y")
        animation.fromValue = rect.minY + 1
        animation.toValue = rect.maxY - 1
        animation.duration = 1.0
        animation.repeatCount = .infinity
        animation.autoreverses = true
        scanAnimation = animation
        scanLine.layer.add(animation, forKey: "scan")
    }

    /// Stop only the scanning animation, keep overlay in the view hierarchy
    func stopScanning() {
        DispatchQueue.main.async {
            self.scanLine.layer.removeAnimation(forKey: "scan")
            self.scanAnimation = nil
        }
    }

    /// Hide scanner (overlay) and stop animation
    func hideScanner(animated: Bool = true) {
        DispatchQueue.main.async {
            self.stopScanning()
            let performHide = {
                self.isHidden = true
            }
            if animated {
                UIView.animate(withDuration: 0.2, animations: {
                    self.alpha = 0
                }, completion: { _ in
                    performHide()
                })
            } else {
                performHide()
            }
        }
    }

    /// Show scanner (overlay) and start animation
    func showScanner(animated: Bool = true) {
        DispatchQueue.main.async {
            self.isHidden = false
            let performShow = {
                self.alpha = 1
                self.startScanAnimation()
            }
            if animated {
                self.alpha = 0
                UIView.animate(withDuration: 0.2, animations: {
                    self.alpha = 1
                }, completion: { _ in
                    performShow()
                })
            } else {
                performShow()
            }
        }
    }
    
    @objc private func appDidBecomeActive() {
        if !isHidden {
            startScanAnimation()
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
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}


