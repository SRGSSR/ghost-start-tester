import ComScore
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let configuration = SCORPublisherConfiguration { builder in
            guard let builder = builder else { return }
            builder.publisherId = "1234567"
            builder.secureTransmissionEnabled = true
        }
        SCORAnalytics.configuration().addClient(with: configuration)
        SCORAnalytics.start()
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}

