import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        // Pre-empt the launch-screen white flash by painting the window
        // background before rootViewController's view loads.
        window.backgroundColor = Theme.Page.surface
        window.rootViewController = V2RootViewController()
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}
