/*
 * Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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
import MachO
import PushKit
import SQLite
import UIKit
import flutter_callkit_incoming
import os

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, PKPushRegistryDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    application.registerForRemoteNotifications()
    UIApplication.shared.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    let utilsChannel = FlutterMethodChannel(
      name: "team113.flutter.dev/ios_utils",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )

    utilsChannel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "getArchitecture" {
        self?.getArchitecture(result: result)
      } else if call.method == "cancelNotification" {
        let args = call.arguments as! [String: Any]
        self?.cancelNotification(tag: args["tag"] as! String)
        result(nil)
      } else if call.method == "cancelNotificationsContaining" {
        let args = call.arguments as! [String: Any]
        self?.cancelNotificationsContaining(result: result, thread: args["thread"] as! String)
      } else if call.method == "getSharedDirectory" {
        result(
          FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.team113.messenger")?.absoluteString)
      } else if call.method == "writeDefaults" {
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

    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Setup VOIP.
    let mainQueue = DispatchQueue.main
    let voipRegistry: PKPushRegistry = PKPushRegistry(queue: mainQueue)
    voipRegistry.delegate = self
    voipRegistry.desiredPushTypes = [PKPushType.voIP]
  }

  // This method handles background  data-only push notifications on iOS.
  //
  // If notification contains any visible content, then this method won't be
  // executed, since it's only for data-only notifications.
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    if #available(iOS 10.0, *) {
      if let thread = userInfo["thread"] as? String {
        let center = UNUserNotificationCenter.current()
        center.getDeliveredNotifications { (notifications) in
          for notification in notifications {
            if notification.request.content.threadIdentifier.contains(thread) == true {
              center.removeDeliveredNotifications(withIdentifiers: [notification.request.identifier]
              )
            }
          }
        }
      }
    }

    return super.application(
      application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler
    )
  }

  // Handles updated VoIP push credentials.
  func pushRegistry(
    _ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType
  ) {
    let deviceToken = credentials.token.map { String(format: "%02x", $0) }.joined()
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(deviceToken)
  }

  // Handles outdated VoIP push credentials.
  func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
  }

  // Handles incoming VoIP pushes.
  func pushRegistry(
    _ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload,
    for type: PKPushType, completion: @escaping () -> Void
  ) {
    guard type == .voIP else { return }

    let id = payload.dictionaryPayload["id"] as? String ?? UUID().uuidString
    let nameCaller = payload.dictionaryPayload["callerName"] as? String ?? ""
    let handle = payload.dictionaryPayload["handle"] as? String ?? ""
    let isVideo = payload.dictionaryPayload["isVideo"] as? Bool ?? false
    let endedAt = payload.dictionaryPayload["endedAt"] as? String ?? ""

    let extra = payload.dictionaryPayload["extra"] as? NSDictionary ?? [:]
    let recipientId = extra["recipientId"] as? String ?? nil
    let chatId = extra["chatId"] as? String ?? ""

    let data = flutter_callkit_incoming.Data(
      id: id,
      nameCaller: nameCaller,
      handle: handle,
      type: isVideo ? 1 : 0
    )

    data.supportsHolding = false
    data.supportsDTMF = false
    data.supportsGrouping = false
    data.supportsUngrouping = false
    data.extra = extra

    var isAuthorized: Bool = true
    var doReport: Bool = true
    var myId: String = ""
    var creds: String = ""

    // Check authorization.
    if let containerURL = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: "group.com.team113.messenger")
    {
      let dbPath = containerURL.appendingPathComponent("common.sqlite").path

      do {
        let db = try Connection(dbPath)

        let accounts = Table("accounts")
        let userId = SQLite.Expression<String>("user_id")

        let tokens = Table("tokens")
        let credentials = SQLite.Expression<String>("credentials")

        let callKitCalls = Table("call_kit_calls")
        let callIdExp = SQLite.Expression<String>("id")
        let atExp = SQLite.Expression<Int64>("at")

        // Check if we have any account.
        if let account = try db.pluck(accounts.select(userId)) {
          myId = account[userId]

          // Check credentials.
          let targetId = recipientId ?? myId
          let tokenQuery =
            tokens
            .filter(userId == targetId)
            .select(credentials)

          if let tokenRow = try db.pluck(tokenQuery) {
            creds = tokenRow[credentials]
          } else {
            isAuthorized = false
          }
        } else {
          isAuthorized = false
        }

        // Check CallKit timing.
        if isAuthorized {
          let query =
            callKitCalls
            .filter(callIdExp == id)
            .select(atExp)

          if let row = try db.pluck(query) {
            let accountedAt = Date(
              timeIntervalSince1970: Double(row[atExp]) / 1_000_000.0
            )

            let diff = abs(accountedAt.timeIntervalSinceNow)
            doReport = diff >= 15
          } else {
            doReport = true
          }
        }

        // `UPSERT` call.
        if isAuthorized && doReport {
          let nowMicros = Int64(Date().timeIntervalSince1970 * 1_000_000)

          let insert = callKitCalls.insert(
            or: .replace,
            callIdExp <- id,
            atExp <- nowMicros
          )

          try db.run(insert)
        }

        // Call GraphQL.
        if isAuthorized && doReport {
          Task {
            await acknowledgeVoip(
              creds: creds,
              callId: id,
              chatId: chatId,
              myId: myId,
              data: data,
            )
          }
        }
      } catch {
        print("Database error: \(error)")
      }
    }

    // Finally, report the call.
    //
    // If call shouldn't be displayed, then the completer method will end the
    // call. Unfortunately, Apple kills application if VoIP notification doesn't
    // report a CallKit call when received, thus we must display it anyway.
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(
      data, fromPushKit: true
    ) {
      if isAuthorized {
        if endedAt != "" {
          SwiftFlutterCallkitIncomingPlugin.sharedInstance?.endCall(data)
          SwiftFlutterCallkitIncomingPlugin.sharedInstance?.saveEndCall(id, 3)
        } else {
          if doReport {
            // No-op.
          } else {
            SwiftFlutterCallkitIncomingPlugin.sharedInstance?.endCall(data)
            SwiftFlutterCallkitIncomingPlugin.sharedInstance?.saveEndCall(id, 4)
          }
        }
      } else {
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.endCall(data)
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.saveEndCall(id, 1)
      }
    }

    completion()
  }

  /// Return the architecture of this device.
  private func getArchitecture(result: FlutterResult) {
    let info = NXGetLocalArchInfo()
    let arch = NSString(utf8String: (info?.pointee.description)!)
    if arch == nil {
      result(
        FlutterError(
          code: "UNAVAILABLE",
          message: "Architecture not available.",
          details: nil))
    } else {
      result(String(arch!))
    }
  }

  /// Remove the delivered notification with the provided tag.
  private func cancelNotification(tag: String) {
    if #available(iOS 10.0, *) {
      let center = UNUserNotificationCenter.current()
      center.removeDeliveredNotifications(withIdentifiers: [tag])
    }
  }

  /// Remove the delivered notifications containing the provided thread.
  private func cancelNotificationsContaining(result: @escaping FlutterResult, thread: String) {
    if #available(iOS 10.0, *) {
      let center = UNUserNotificationCenter.current()
      center.getDeliveredNotifications { (notifications) in
        var found = false

        for notification in notifications {
          if notification.request.content.threadIdentifier.contains(thread) == true {
            center.removeDeliveredNotifications(withIdentifiers: [notification.request.identifier])
            found = true
          }
        }

        result(found)
      }
    }
  }

  @available(macOS 12.0, *)
  @available(iOS 12.0, *)
  private func acknowledgeVoip(
    creds: String,
    callId: String,
    chatId: String,
    myId: String,
    data: flutter_callkit_incoming.Data,
  ) async {
    let dataToSend: [String: Any] = [
      "query": """
          query chat {
              chat(id: "\(chatId)") {
                  ongoingCall {
                      id
                      members {
                        user {
                          id
                        }
                      }
                  }
              }
          }
      """
    ]

    let defaults = UserDefaults(suiteName: "group.com.team113.messenger")
    let baseUrl = defaults!.value(forKey: "url") as! String
    let endpoint = defaults!.value(forKey: "endpoint") as! String

    if let url = URL(string: baseUrl + endpoint) {
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.addValue("application/json", forHTTPHeaderField: "Content-Type")

      if let credsData = try creds.data(using: .utf8) {
        if let decoded = try? JSONDecoder().decode(Credentials.self, from: credsData) {
          if Date() > decoded.access.expireAt.val {
            // TODO: Should refresh the session:
            //       1. Acquire a lock from the `locks` table.
            //       2. Refresh the token via GraphQL POST request.
            //       3. UPSERT the token and release the `locks`.
            request.addValue("Bearer \(decoded.access.secret)", forHTTPHeaderField: "Authorization")
          } else {
            request.addValue("Bearer \(decoded.access.secret)", forHTTPHeaderField: "Authorization")
          }
        }
      }

      do {
        request.httpBody = try JSONSerialization.data(withJSONObject: dataToSend)
        let (result, _) = try await URLSession.shared.data(for: request)

        if let response = try JSONSerialization.jsonObject(with: result) as? [String: Any] {
          print("POST Response:", response)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let response = try decoder.decode(QueryChatResponse.self, from: result)
          as QueryChatResponse?
        {
          // TODO: Transform to UUID.
          // if response.data.chat.ongoingCall.id != callId {
          //   SwiftFlutterCallkitIncomingPlugin.sharedInstance?.endCall(data)
          //   SwiftFlutterCallkitIncomingPlugin.sharedInstance?.saveEndCall(callId, 3)
          //   return
          // }

          if response.data.chat.ongoingCall.members.contains(where: { $0.user.id == myId }) {
            SwiftFlutterCallkitIncomingPlugin.sharedInstance?.endCall(data)
            SwiftFlutterCallkitIncomingPlugin.sharedInstance?.saveEndCall(callId, 3)
            return
          }
        }
      } catch {
        print("POST Request Failed:", error)
      }
    }
  }

  struct QueryChatResponse: Decodable {
    let data: QueryChatResponseData
  }

  struct QueryChatResponseData: Decodable {
    let chat: QueryChatResponseDataChat
  }

  struct QueryChatResponseDataChat: Decodable {
    let ongoingCall: QueryChatResponseDataChatOngoingCall
  }

  struct QueryChatResponseDataChatOngoingCall: Decodable {
    let id: String
    let members: [QueryChatResponseDataChatMember]
  }

  struct QueryChatResponseDataChatMember: Decodable {
    let user: QueryChatResponseDataChatMemberUser
  }

  struct QueryChatResponseDataChatMemberUser: Decodable {
    let id: String
  }

  struct Credentials: Codable {
    let access: Token
    let refresh: Token
    let session: Session
    let userId: String
  }

  struct Token: Codable {
    let secret: String
    let expireAt: DateType
  }

  struct DateType: Codable {
    let val: Date
  }

  struct Session: Codable {
    let id: String
    let ip: String
    let userAgent: String
    let lastActivatedAt: DateType
  }
}
