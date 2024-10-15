/*
 * Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
 *                       <https://github.com/team113>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License v3.0 as published by the
 * Free Software Foundation, either version 3 of the License, or (at your
 * option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License v3.0 for
 * more details.
 *
 * You should have received a copy of the GNU Affero General Public License v3.0
 * along with this program. If not, see
 * <https://www.gnu.org/licenses/agpl-3.0.html>.
 */

import Flutter
import Firebase
import FirebaseMessaging
import MachO
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let utilsChannel = FlutterMethodChannel(name: "team113.flutter.dev/ios_utils",
                                            binaryMessenger: controller.binaryMessenger)
    utilsChannel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if (call.method == "getArchitecture") {
        self?.getArchitecture(result: result)
      } else if (call.method == "cancelNotification") {
        let args = call.arguments as! [String: Any]
        self?.cancelNotification(tag: args["tag"] as! String)
        result(nil)
      } else if (call.method == "cancelNotificationsContaining") {
        let args = call.arguments as! [String: Any]
        self?.cancelNotificationsContaining(result: result, thread: args["thread"] as! String)
      } else if (call.method == "getSharedDirectory") {
        result(FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.team113.messenger")?.absoluteString);
      } else if (call.method == "writeDefaults") {
        let args = call.arguments as! [String: Any]
        if let defaults = UserDefaults(suiteName: "group.com.team113.messenger") {
          defaults.set(args["value"] as! String, forKey: args["key"] as! String)
        }
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }

    GeneratedPluginRegistrant.register(with: self)
    application.registerForRemoteNotifications()
    UIApplication.shared.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken;
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let userInfo = notification.request.content.userInfo

    Messaging.messaging().appDidReceiveMessage(userInfo)

    // Change this to your preferred presentation option
    completionHandler([[.alert, .sound]])
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo

    Messaging.messaging().appDidReceiveMessage(userInfo)

    completionHandler()
  }

  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable : Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    Messaging.messaging().appDidReceiveMessage(userInfo)

    if let thread = userInfo["thread"] as? String {
      cancelNotificationsContaining(result: nil, thread: thread)
    } else if let tag = userInfo["tag"] as? String {
      cancelNotification(tag: tag)
    }

    completionHandler(.noData)

    super.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
  }

  /// Return the architecture of this device.
  private func getArchitecture(result: FlutterResult) {
    let info = NXGetLocalArchInfo()
    let arch = NSString(utf8String: (info?.pointee.description)!);
    if (arch == nil) {
      result(FlutterError(code: "UNAVAILABLE",
                          message: "Architecture not available.",
                          details: nil))
    } else {
      result(String(arch!))
    }
  }

  /// Remove the delivered notification with the provided tag.
  private func cancelNotification(tag: String) {
    if #available(iOS 10.0, *) {
      let center = UNUserNotificationCenter.current();
      center.removeDeliveredNotifications(withIdentifiers: [tag]);
    }
  }

  /// Remove the delivered notifications containing the provided thread.
  private func cancelNotificationsContaining(result: FlutterResult?, thread: String) {
    if #available(iOS 10.0, *) {
      let center = UNUserNotificationCenter.current();
      center.getDeliveredNotifications { (notifications) in
        var found = false;

        for notification in notifications {
          if (notification.request.content.threadIdentifier.contains(thread) == true) {
            center.removeDeliveredNotifications(withIdentifiers: [notification.request.identifier]);
            found = true;
          }
        }

        if (result != nil) {
          result!(found);
        }
      }
    }
  }
}
