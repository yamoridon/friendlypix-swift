//
//  AppDelegate.swift
//  FriendlyPix-Swift
//
//  Created by Kazuki Ohara on 2017/11/08.
//  Copyright © 2017年 Kazuki Ohara. All rights reserved.
//

import UIKit
import UserNotifications
import Firebase
import FirebaseAuthUI

// Implement UNUserNotificationCenterDelegate to receive display notification
// via APNS for devices running iOS 10 and above. Implement FIRMessagingDelegate
// to receive data message via FCM for devices running iOS 10 and above.
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?

    // MARK: - UIApplicationDelegate

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Use Firebase library to configure APIs
        FirebaseApp.configure()

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        // For iOS 10 display notification (sent via APNS)
        UNUserNotificationCenter.current().delegate = self

        UIApplication.shared.registerForRemoteNotifications()

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        let sourceApplication = options[.sourceApplication] as? String
        if let authUI = FUIAuth.defaultAuthUI(), authUI.handleOpen(url, sourceApplication: sourceApplication) {
            return true
        }
        return false
    }

    // MARK: - UNUserNotificationCenterDelegate
    // Receive displayed notifications for iOS 10 devices.

    // Handle incoming notification messages while app is in the foreground.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Print message ID.
        let userInfo = notification.request.content.userInfo
        showAlert(userInfo)

        // Change this to your preferred presentation option
        completionHandler([])
    }

    // Handle notification messages after display notification is tapped by the user.
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        showAlert(userInfo)

        completionHandler()
    }

    // MARK: -
    func showAlert(_ userInfo: [AnyHashable: Any]) {
        let apsKey = "aps"
        let gcmMessage = "alert"
        let gcmLabel = "google.c.a.c_l"

        if let aps = userInfo[apsKey] as? [AnyHashable: Any] {
            if let message = aps[gcmMessage] as? String {
                DispatchQueue.main.async { [weak self] in
                    let title = userInfo[gcmLabel] as? String
                    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                    let dismissAction = UIAlertAction(title: "Dismiss", style: .destructive)
                    alert.addAction(dismissAction)
                    self?.window?.rootViewController?.presentedViewController?.present(alert, animated: true)
                }
            }
        }
    }
}

