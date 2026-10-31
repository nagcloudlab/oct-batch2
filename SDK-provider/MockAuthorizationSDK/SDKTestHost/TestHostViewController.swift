
import UIKit
import MockAuthorizationSDK

@MainActor
final class TestHostViewController:
    UIViewController,
    AuthorizationDelegate {

    private let sdk = AuthorizationSDK()

    private let statusLabel = UILabel()
    private let openButton = UIButton(type: .system)

    private var isBusy = false

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        sdk.delegate = self

        setupUI()
    }

    private func setupUI() {

        statusLabel.text = "SDK is ready"
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0

        openButton.setTitle(
            "Open SDK Authorization Screen",
            for: .normal
        )

        openButton.addTarget(
            self,
            action: #selector(openSDK),
            for: .touchUpInside
        )

        openButton.heightAnchor.constraint(
            greaterThanOrEqualToConstant: 52
        ).isActive = true

        let stack = UIStackView(arrangedSubviews: [
            statusLabel,
            openButton
        ])

        stack.axis = .vertical
        stack.spacing = 24

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

    @objc private func openSDK() {

        guard !isBusy else { return }

        isBusy = true
        openButton.isEnabled = false

        let request = AuthorizationRequest(
            recipient: "ravi@npay",
            amountPaise: 150_000
        )

        do {
            try sdk.present(
                request,
                from: self
            )

            statusLabel.text =
                "SDK opened: \(request.requestID)"

        } catch {
            statusLabel.text = "Error: \(error)"

            isBusy = false
            openButton.isEnabled = true
        }
    }

    func authorizationDidFinish(
        _ result: AuthorizationResult
    ) {

        switch result {

        case .authorized(let requestID):
            statusLabel.text =
                "AUTHORIZED (mock): \(requestID)"

        case .failed(let requestID, let message):
            statusLabel.text =
                "FAILED \(requestID): \(message)"

        case .cancelled(let requestID):
            statusLabel.text =
                "CANCELLED: \(requestID)"
        }

        isBusy = false
        openButton.isEnabled = true
    }
}

