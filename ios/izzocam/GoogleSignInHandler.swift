import Foundation
import UIKit
import GoogleSignIn
import FirebaseAuth

@MainActor
final class GoogleSignInHandler {
    static let shared = GoogleSignInHandler()

    private init() {}

    func handle(url: URL) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }

    func signIn() async throws -> AuthCredential {
        guard let rootController = UIApplication.shared.topMostViewController() else {
            throw SignInError.missingPresentingController
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootController)
        guard let idToken = result.user.idToken?.tokenString else {
            throw SignInError.missingIDToken
        }
        let accessToken = result.user.accessToken.tokenString
        return GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
    }

    enum SignInError: Error {
        case missingPresentingController
        case missingIDToken
    }
}

private extension UIApplication {
    func topMostViewController(base: UIViewController? = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first(where: { $0.isKeyWindow })?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topMostViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return topMostViewController(base: tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return topMostViewController(base: presented)
        }
        return base
    }
}
