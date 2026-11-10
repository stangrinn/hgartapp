import UIKit

/// Full-screen launch loader: brand mark, wordmark and an indeterminate progress bar.
final class LaunchLoaderView: UIView {

    private enum Style {
        static let background = UIColor(red: 15 / 255, green: 15 / 255, blue: 16 / 255, alpha: 1)
        static let primary = UIColor(red: 247 / 255, green: 247 / 255, blue: 245 / 255, alpha: 1)
        static let track = UIColor(white: 1, alpha: 0.3)
        static let markSize = CGSize(width: 75.245, height: 34.876)
        static let barSize = CGSize(width: 120, height: 3)
        static let barFillWidth: CGFloat = 54
    }

    private let fillLayer = CALayer()
    private let barContainer = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = Style.background
        isAccessibilityElement = true
        accessibilityLabel = "Loading"

        let mark = UIImageView(image: UIImage(named: "LogoMark"))
        mark.tintColor = Style.primary
        mark.contentMode = .scaleAspectFit

        let wordmark = makeLabel(text: "helena grinshpun art", size: 14.4, kern: 4)

        let logo = UIStackView(arrangedSubviews: [mark, wordmark])
        logo.axis = .vertical
        logo.alignment = .center
        logo.spacing = 16.8

        let overline = makeLabel(text: "augmented art", size: 10, kern: 2.5)

        barContainer.backgroundColor = Style.track
        barContainer.layer.cornerRadius = Style.barSize.height / 2
        barContainer.clipsToBounds = true

        fillLayer.backgroundColor = Style.primary.cgColor
        fillLayer.cornerRadius = Style.barSize.height / 2
        fillLayer.frame = CGRect(x: -Style.barFillWidth, y: 0, width: Style.barFillWidth, height: Style.barSize.height)
        barContainer.layer.addSublayer(fillLayer)

        let content = UIStackView(arrangedSubviews: [logo, overline, barContainer])
        content.axis = .vertical
        content.alignment = .center
        content.spacing = 26
        content.setCustomSpacing(26, after: logo)
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)

        NSLayoutConstraint.activate([
            mark.widthAnchor.constraint(equalToConstant: Style.markSize.width),
            mark.heightAnchor.constraint(equalToConstant: Style.markSize.height),
            barContainer.widthAnchor.constraint(equalToConstant: Style.barSize.width),
            barContainer.heightAnchor.constraint(equalToConstant: Style.barSize.height),
            content.centerXAnchor.constraint(equalTo: centerXAnchor),
            content.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -16)
        ])

        NotificationCenter.default.addObserver(self, selector: #selector(startAnimating),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    private func makeLabel(text: String, size: CGFloat, kern: CGFloat) -> UILabel {
        let font = UIFont(name: "Orbitron-Regular", size: size)
            ?? UIFont(name: "Orbitron", size: size)
            ?? UIFont.systemFont(ofSize: size)

        let label = UILabel()
        label.attributedText = NSAttributedString(string: text.uppercased(), attributes: [
            .font: font,
            .foregroundColor: Style.primary,
            .kern: kern
        ])
        label.isAccessibilityElement = false

        return label
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil { startAnimating() }
    }

    @objc private func startAnimating() {
        guard window != nil else { return }

        fillLayer.removeAnimation(forKey: "slide")

        let slide = CABasicAnimation(keyPath: "position.x")
        slide.fromValue = -Style.barFillWidth / 2
        slide.toValue = Style.barSize.width + Style.barFillWidth / 2
        slide.duration = 1.2
        slide.repeatCount = .infinity
        slide.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        fillLayer.add(slide, forKey: "slide")
    }

    func dismiss(minimumVisibleSince start: Date, minimumDuration: TimeInterval = 0.8) {
        let delay = max(0, minimumDuration - Date().timeIntervalSince(start))

        UIView.animate(withDuration: 0.3, delay: delay, options: [], animations: {
            self.alpha = 0
        }, completion: { _ in
            self.removeFromSuperview()
        })
    }

    deinit { NotificationCenter.default.removeObserver(self) }
}
