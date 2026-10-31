import Foundation

@MainActor
public protocol AuthorizationDelegate: AnyObject {
    func authorizationDidFinish(_ result: AuthorizationResult)
}
