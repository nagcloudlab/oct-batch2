
import UIKit

@MainActor
final class AuthorizationViewController: UIViewController {

    private let request: AuthorizationRequest

    var onFinish: ((AuthorizationResult) -> Void)?

    private var hasCompleted = false

    init(request: AuthorizationRequest) {
        self.request = request
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Use init(request:)")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemGroupedBackground

        setupUI()
    }

    private func setupUI() {

        let titleLabel = UILabel()
        titleLabel.text = "Mock Authorization SDK"
        titleLabel.font = .preferredFont(
            forTextStyle: .title2
        )
        titleLabel.textAlignment = .center

        let amountLabel = UILabel()

        amountLabel.text = (
            Decimal(request.amountPaise) / 100
        ).formatted(
            .currency(code: "INR")
                .locale(Locale(identifier: "en_IN"))
        )

        amountLabel.font = .preferredFont(
            forTextStyle: .largeTitle
        )
        amountLabel.textAlignment = .center

        let recipientLabel = UILabel()
        recipientLabel.text = "Paying \(request.recipient)"
        recipientLabel.textAlignment = .center
        recipientLabel.numberOfLines = 0

        let warningLabel = UILabel()
        warningLabel.text =
            "TRAINING ONLY — No real UPI PIN is collected"
        warningLabel.textColor = .secondaryLabel
        warningLabel.textAlignment = .center
        warningLabel.numberOfLines = 0

        let authorizeButton = makeButton(
            title: "Simulate Authorization",
            action: #selector(authorizeTapped)
        )

        let failButton = makeButton(
            title: "Simulate Failure",
            action: #selector(failTapped)
        )

        let cancelButton = makeButton(
            title: "Cancel",
            action: #selector(cancelTapped)
        )

        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            amountLabel,
            recipientLabel,
            warningLabel,
            authorizeButton,
            failButton,
            cancelButton
        ])

        stack.axis = .vertical
        stack.spacing = 18
        stack.alignment = .fill

        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: 24
            ),

            stack.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -24
            ),

            stack.centerYAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.centerYAnchor
            )
        ])
    }

    private func makeButton(
        title: String,
        action: Selector
    ) -> UIButton {

        let button = UIButton(type: .system)

        button.setTitle(title, for: .normal)

        button.titleLabel?.font = .preferredFont(
            forTextStyle: .headline
        )

        button.heightAnchor.constraint(
            greaterThanOrEqualToConstant: 48
        ).isActive = true

        button.addTarget(
            self,
            action: action,
            for: .touchUpInside
        )

        return button
    }

    private func finish(_ result: AuthorizationResult) {

        guard !hasCompleted else { return }

        hasCompleted = true

        onFinish?(result)
    }

    
    @objc private func authorizeTapped() {
        finish(
            .authorized(request.requestID)
        )
    }

    @objc private func failTapped() {
        finish(
            .failed(
                request.requestID,
                "Simulated authorization failure"
            )
        )
    }

    @objc private func cancelTapped() {
        finish(
            .cancelled(request.requestID)
        )
    }

}

