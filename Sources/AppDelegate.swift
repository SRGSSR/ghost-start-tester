import ComScore
import UIKit
import UserNotifications
import os.log

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let configuration = SCORPublisherConfiguration { builder in
            guard let builder = builder else { return }
            builder.publisherId = "1234567"
            builder.secureTransmissionEnabled = true
        }
        
        if let launchOptions = launchOptions {
            Logger(subsystem: "app", category: "notif").info("--> Options: \(launchOptions, privacy: .public)")
        }
        else {
            Logger(subsystem: "app", category: "notif").info("--> No options")
        }
        
        SCORAnalytics.configuration().addClient(with: configuration)
        SCORAnalytics.start()
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device Token: \(token)")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        Logger(subsystem: "app", category: "notif").info("--> User info: \(userInfo, privacy: .public)")
        completionHandler(.noData)
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}

