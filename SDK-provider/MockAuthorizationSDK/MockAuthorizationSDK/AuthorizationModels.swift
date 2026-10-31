import Foundation

public struct AuthorizationRequest: Sendable {
    public let requestID: UUID
    public let recipient: String
    public let amountPaise: Int

    public init(
        requestID: UUID = UUID(),
        recipient: String,
        amountPaise: Int
    ) {
        self.requestID = requestID
        self.recipient = recipient
        self.amountPaise = amountPaise
    }
}

public enum AuthorizationResult: Sendable {
    case authorized(UUID)
    case failed(UUID, String)
    case cancelled(UUID)
}

public enum SDKError: Error, Equatable {
    case invalidRequest
    case alreadyPresenting
    case presenterUnavailable
}
