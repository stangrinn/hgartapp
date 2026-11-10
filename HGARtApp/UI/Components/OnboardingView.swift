import UIKit

/// Launch onboarding: brand sheet over a dimmed backdrop. Scanning starts only after "Start scanning".
final class OnboardingView: UIView {

    private enum Style {
        static let primary = UIColor(red: 247 / 255, green: 247 / 255, blue: 245 / 255, alpha: 1)
        static let onPrimary = UIColor(red: 15 / 255, green: 15 / 255, blue: 17 / 255, alpha: 1)
        static let secondary = UIColor(red: 247 / 255, green: 247 / 255, blue: 245 / 255, alpha: 0.62)
        static let glassFill = UIColor(white: 0, alpha: 0.55)
        static let stroke = UIColor(white: 1, alpha: 0.14)
        static let controlFill = UIColor(white: 1, alpha: 0.12)
        static let grabber = UIColor(white: 1, alpha: 0.3)
    }

    var onStartScanning: (() -> Void)?
    var onHowItWorks: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        addSubview(BackdropView(frame: bounds, autoresizing: true))

        let sheet = makeSheet()
        addSubview(sheet)

        NSLayoutConstraint.activate([
            sheet.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            sheet.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            sheet.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func makeSheet() -> UIView {
        let sheet = UIView()
        sheet.translatesAutoresizingMaskIntoConstraints = false
        sheet.layer.cornerRadius = 34
        sheet.layer.shadowColor = UIColor.black.cgColor
        sheet.layer.shadowOpacity = 0.35
        sheet.layer.shadowOffset = CGSize(width: 0, height: 4)
        sheet.layer.shadowRadius = 10

        let glass = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        glass.translatesAutoresizingMaskIntoConstraints = false
        glass.clipsToBounds = true
        glass.layer.cornerRadius = 34
        glass.layer.borderWidth = 1
        glass.layer.borderColor = Style.stroke.cgColor
        glass.contentView.backgroundColor = Style.glassFill
        sheet.addSubview(glass)

        let content = UIStackView(arrangedSubviews: [makeGrabber(), makeBody(), makeActions()])
        content.axis = .vertical
        content.spacing = 16
        content.translatesAutoresizingMaskIntoConstraints = false
        glass.contentView.addSubview(content)

        NSLayoutConstraint.activate([
            glass.topAnchor.constraint(equalTo: sheet.topAnchor),
            glass.bottomAnchor.constraint(equalTo: sheet.bottomAnchor),
            glass.leadingAnchor.constraint(equalTo: sheet.leadingAnchor),
            glass.trailingAnchor.constraint(equalTo: sheet.trailingAnchor),
            content.topAnchor.constraint(equalTo: glass.contentView.topAnchor, constant: 6),
            content.bottomAnchor.constraint(equalTo: glass.contentView.bottomAnchor, constant: -24),
            content.leadingAnchor.constraint(equalTo: glass.contentView.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: glass.contentView.trailingAnchor)
        ])

        return sheet
    }

    private func makeGrabber() -> UIView {
        let area = UIView()
        let grabber = UIView()
        grabber.backgroundColor = Style.grabber
        grabber.layer.cornerRadius = 2.5
        grabber.translatesAutoresizingMaskIntoConstraints = false
        area.addSubview(grabber)

        NSLayoutConstraint.activate([
            grabber.widthAnchor.constraint(equalToConstant: 36),
            grabber.heightAnchor.constraint(equalToConstant: 5),
            grabber.topAnchor.constraint(equalTo: area.topAnchor),
            grabber.bottomAnchor.constraint(equalTo: area.bottomAnchor, constant: -4),
            grabber.centerXAnchor.constraint(equalTo: area.centerXAnchor)
        ])

        return area
    }

    private func makeBody() -> UIView {
        let mark = UIImageView(image: UIImage(named: "LogoMark")?.withRenderingMode(.alwaysTemplate))
        mark.tintColor = Style.primary
        mark.contentMode = .scaleAspectFit

        let wordmark = label("HG ART", font: orbitron("Orbitron-Regular", size: 9.6), color: Style.primary, kern: 4)

        let logo = UIStackView(arrangedSubviews: [mark, wordmark])
        logo.axis = .vertical
        logo.alignment = .center
        logo.spacing = 11.2

        let illustration = UIView()
        illustration.backgroundColor = Style.controlFill
        illustration.layer.cornerRadius = 28
        illustration.layer.borderWidth = 1
        illustration.layer.borderColor = Style.stroke.cgColor

        let scan = UIImageView(image: UIImage(named: "IconScan")?.withRenderingMode(.alwaysTemplate))
        scan.tintColor = Style.primary
        scan.translatesAutoresizingMaskIntoConstraints = false
        illustration.addSubview(scan)

        let title = label("Bring the art to life",
                          font: UIFont(name: "CormorantGaramond-Medium", size: 30) ?? .systemFont(ofSize: 30, weight: .medium),
                          color: Style.primary, kern: 0)

        let message = label("Point your camera at any Helena Grinshpun painting. It will start moving and sound — you can record and share the moment.",
                            font: .systemFont(ofSize: 15), color: Style.secondary, kern: 0)
        message.numberOfLines = 0

        let body = UIStackView(arrangedSubviews: [logo, illustration, title, message, makeDots()])
        body.axis = .vertical
        body.alignment = .center
        body.spacing = 16
        body.isLayoutMarginsRelativeArrangement = true
        body.layoutMargins = UIEdgeInsets(top: 8, left: 24, bottom: 0, right: 24)

        NSLayoutConstraint.activate([
            mark.widthAnchor.constraint(equalToConstant: 50.164),
            mark.heightAnchor.constraint(equalToConstant: 23.251),
            illustration.widthAnchor.constraint(equalToConstant: 96),
            illustration.heightAnchor.constraint(equalToConstant: 96),
            scan.widthAnchor.constraint(equalToConstant: 48),
            scan.heightAnchor.constraint(equalToConstant: 48),
            scan.centerXAnchor.constraint(equalTo: illustration.centerXAnchor),
            scan.centerYAnchor.constraint(equalTo: illustration.centerYAnchor),
            message.widthAnchor.constraint(equalTo: body.widthAnchor, constant: -48)
        ])

        return body
    }

    private func makeDots() -> UIView {
        let active = UIView()
        active.backgroundColor = Style.primary
        let dots = [active, UIView(), UIView()]
        dots.dropFirst().forEach { $0.backgroundColor = Style.grabber }

        let stack = UIStackView(arrangedSubviews: dots)
        stack.spacing = 6

        for (index, dot) in dots.enumerated() {
            dot.layer.cornerRadius = 3
            dot.widthAnchor.constraint(equalToConstant: index == 0 ? 20 : 6).isActive = true
            dot.heightAnchor.constraint(equalToConstant: 6).isActive = true
        }

        return stack
    }

    private func makeActions() -> UIView {
        let start = UIButton(type: .custom)
        start.backgroundColor = Style.primary
        start.layer.cornerRadius = 25
        start.setAttributedTitle(buttonTitle("Start scanning", color: Style.onPrimary), for: .normal)
        start.setImage(UIImage(named: "IconScan")?.withRenderingMode(.alwaysTemplate), for: .normal)
        start.tintColor = Style.onPrimary
        start.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
        start.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
        start.addTarget(self, action: #selector(startTapped), for: .touchUpInside)

        let how = UIButton(type: .custom)
        how.setAttributedTitle(buttonTitle("How it works", color: Style.primary), for: .normal)
        how.addTarget(self, action: #selector(howTapped), for: .touchUpInside)

        let caption = label("Camera & microphone are used only while scanning.",
                            font: .systemFont(ofSize: 12), color: Style.secondary, kern: 0)
        caption.numberOfLines = 0

        let actions = UIStackView(arrangedSubviews: [start, how, caption])
        actions.axis = .vertical
        actions.spacing = 4
        actions.isLayoutMarginsRelativeArrangement = true
        actions.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        start.heightAnchor.constraint(equalToConstant: 50).isActive = true
        how.heightAnchor.constraint(equalToConstant: 50).isActive = true

        return actions
    }

    private func buttonTitle(_ text: String, color: UIColor) -> NSAttributedString {
        NSAttributedString(string: text.uppercased(), attributes: [
            .font: orbitron("Orbitron-Medium", size: 12),
            .foregroundColor: color,
            .kern: 2
        ])
    }

    private func orbitron(_ name: String, size: CGFloat) -> UIFont {
        UIFont(name: name, size: size) ?? UIFont(name: "Orbitron-Regular", size: size) ?? .systemFont(ofSize: size)
    }

    private func label(_ text: String, font: UIFont, color: UIColor, kern: CGFloat) -> UILabel {
        let label = UILabel()
        label.textAlignment = .center
        label.attributedText = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color, .kern: kern])

        return label
    }

    @objc private func startTapped() { onStartScanning?() }

    @objc private func howTapped() { onHowItWorks?() }

    func dismiss() {
        UIView.animate(withDuration: 0.3, animations: { self.alpha = 0 }, completion: { _ in
            self.removeFromSuperview()
        })
    }
}

/// Dark warm gradient plus scrim; stands in for the blurred camera feed because camera access is not granted yet.
private final class BackdropView: UIView {

    override class var layerClass: AnyClass { CAGradientLayer.self }

    init(frame: CGRect, autoresizing: Bool) {
        super.init(frame: frame)

        if autoresizing { autoresizingMask = [.flexibleWidth, .flexibleHeight] }

        let gradient = layer as! CAGradientLayer
        gradient.colors = [
            UIColor(red: 0x52 / 255, green: 0x4d / 255, blue: 0x47 / 255, alpha: 1).cgColor,
            UIColor(red: 0x33 / 255, green: 0x30 / 255, blue: 0x2e / 255, alpha: 1).cgColor,
            UIColor(red: 0x1f / 255, green: 0x1c / 255, blue: 0x1a / 255, alpha: 1).cgColor
        ]
        gradient.locations = [0, 0.7, 1]

        let scrim = UIView(frame: bounds)
        scrim.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrim.backgroundColor = UIColor(white: 0, alpha: 0.45)
        addSubview(scrim)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
