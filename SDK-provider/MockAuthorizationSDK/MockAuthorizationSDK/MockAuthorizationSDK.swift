
import UIKit

@MainActor
public final class AuthorizationSDK {

    public weak var delegate: (any AuthorizationDelegate)?

    private var isPresenting = false

    public init() {}

    public func present(
        _ request: AuthorizationRequest,
        from presenter: UIViewController
    ) throws {

        guard request.amountPaise > 0,
              !request.recipient.trimmingCharacters(
                  in: .whitespacesAndNewlines
              ).isEmpty else {
            throw SDKError.invalidRequest
        }

        guard !isPresenting else {
            throw SDKError.alreadyPresenting
        }

        guard presenter.isViewLoaded,
              presenter.view.window != nil,
              presenter.presentedViewController == nil else {
            throw SDKError.presenterUnavailable
        }

        isPresenting = true

        let screen = AuthorizationViewController(
            request: request
        )

        screen.modalPresentationStyle = .fullScreen
        screen.isModalInPresentation = true

        screen.onFinish = { [weak self, weak screen] result in

            guard let self, let screen else {
                return
            }

            screen.dismiss(animated: true) { [weak self] in

                guard let self else { return }

                self.isPresenting = false

                self.delegate?.authorizationDidFinish(
                    result
                )
            }
        }

        presenter.present(
            screen,
            animated: true
        )
    }
}

