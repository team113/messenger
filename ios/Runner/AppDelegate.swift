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

import AVFAudio
import CallKit
import Firebase
import FirebaseMessaging
import Flutter
import flutter_callkit_incoming
import MachO
import PushKit
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate {
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

    FirebaseApp.configure()
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    GeneratedPluginRegistrant.register(with: self)
    application.registerForRemoteNotifications()
    UIApplication.shared.registerForRemoteNotifications()

    // Setup VOIP.
    let mainQueue = DispatchQueue.main
    let voipRegistry: PKPushRegistry = PKPushRegistry(queue: mainQueue)
    voipRegistry.delegate = self
    voipRegistry.desiredPushTypes = [PKPushType.voIP]

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    super.application(
      application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler
    )
  }

  // Handles updated VoIP push credentials.
  func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
    let deviceToken = credentials.token.map { String(format: "%02x", $0) }.joined()
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(deviceToken)
  }

  // Handles outdated VoIP push credentials.
  func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
  }

  // Handles incoming VoIP pushes.
  func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
    guard type == .voIP else { return }

    let id = payload.dictionaryPayload["id"] as? String ?? ""
    let nameCaller = payload.dictionaryPayload["nameCaller"] as? String ?? ""
    let handle = payload.dictionaryPayload["handle"] as? String ?? ""
    let isVideo = payload.dictionaryPayload["isVideo"] as? Bool ?? false
    let endedAt = payload.dictionaryPayload["endedAt"] as? String ?? ""

    let data = flutter_callkit_incoming.Data(
      id: id,
      nameCaller: nameCaller,
      handle: handle,
      type: isVideo ? 1 : 0
    );

    data.supportsHolding = false;
    data.supportsDTMF = false;
    data.supportsGrouping = false;
    data.supportsUngrouping = false;
    data.extra = payload.dictionaryPayload["extra"] as? NSDictionary ?? [:];

    if (endedAt != "") {
      SwiftFlutterCallkitIncomingPlugin.sharedInstance?.endCall(data)
    } else {
      SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(data, fromPushKit: true)
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        completion()
    }
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
  private func cancelNotificationsContaining(result: @escaping FlutterResult, thread: String) {
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

        result(found);
      }
    }
  }
}
