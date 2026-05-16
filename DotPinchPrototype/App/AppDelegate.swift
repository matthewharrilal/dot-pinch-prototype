//
//  AppDelegate.swift
//  DotPinchPrototype
//

import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)

        // --- Debug isolation hook (Task #3, m34 minimal repro) ---
        // Activated only when launched with arg "USE_MINIMAL_PERSPECTIVE_TEST".
        // No effect on normal app launch.
        let args = ProcessInfo.processInfo.arguments
        let env  = ProcessInfo.processInfo.environment
        if args.contains("USE_MINIMAL_PERSPECTIVE_TEST")
            || env["USE_MINIMAL_PERSPECTIVE_TEST"] != nil {
            let vc = MinimalPerspectiveTestVC()
            // Variant selection: --MIN_PERSP_VARIANT <name>  OR  env MIN_PERSP_VARIANT=<name>
            if let i = args.firstIndex(of: "--MIN_PERSP_VARIANT"),
               i + 1 < args.count {
                vc.variant = args[i + 1]
            } else if let v = env["MIN_PERSP_VARIANT"] {
                vc.variant = v
            }
            window.rootViewController = vc
        } else {
            window.rootViewController = DemoViewController()
        }

        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}
