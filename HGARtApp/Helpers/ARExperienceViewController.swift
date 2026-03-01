import UIKit
import Combine

/// View controller displaying the AR experience UI and binding to the view model.
class ARExperienceViewController: UIViewController {
    private let viewModel: ARExperienceViewModel
    private var cancellables: Set<AnyCancellable> = []
    
    // UI elements (minimal for starter template)
    private let startButton = UIButton(type: .system)
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let statusLabel = UILabel()
    
    init(viewModel: ARExperienceViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        bindViewModel()
    }
    
    private func setupUI() {
        startButton.setTitle("Start AR Experience", for: .normal)
        startButton.addTarget(self, action: #selector(startTapped), for: .touchUpInside)
        statusLabel.textAlignment = .center
        statusLabel.textColor = .label
        statusLabel.numberOfLines = 0
        
        let stack = UIStackView(arrangedSubviews: [statusLabel, progressView, startButton])
        stack.axis = .vertical
        stack.spacing = 24
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])
    }
    
    private func bindViewModel() {
        viewModel.$progress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.progressView.progress = Float(progress)
            }
            .store(in: &cancellables)
        
        viewModel.$isSessionRunning
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRunning in
                self?.startButton.setTitle(isRunning ? "Stop AR Experience" : "Start AR Experience", for: .normal)
                self?.statusLabel.text = isRunning ? "Session Running..." : "Idle"
            }
            .store(in: &cancellables)
        
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.statusLabel.text = error ?? self?.statusLabel.text
                self?.statusLabel.textColor = error == nil ? .label : .systemRed
            }
            .store(in: &cancellables)
    }
    
    @objc private func startTapped() {
        if viewModel.isSessionRunning {
            viewModel.stopExperience()
        } else {
            viewModel.startExperience()
        }
    }
}
