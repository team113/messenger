/*
 * Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
 *                       <https://github.com/team113>
 * Copyright © 2025 Ideas Networks Solutions S.A.,
 *                       <https://github.com/tapopa>
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
import UIKit
import flutter_callkit_incoming
import os
import sqlite3

@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let utilsChannel = FlutterMethodChannel(
      name: "tapopa.flutter.dev/ios_utils",
      binaryMessenger: controller.binaryMessenger)
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
            forSecurityApplicationGroupIdentifier: "group.com.tapopa.messenger")?.absoluteString)
      } else if call.method == "writeDefaults" {
        let args = call.arguments as! [String: Any]
        if let defaults = UserDefaults(suiteName: "group.com.tapopa.messenger") {
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
      forSecurityApplicationGroupIdentifier: "group.com.tapopa.messenger")
    {
      let dbPath = containerURL.appendingPathComponent("common.sqlite").path
      var db: OpaquePointer?

      if sqlite3_open(dbPath, &db) == SQLITE_OK {
        defer { sqlite3_close(db) }

        // First, check whether we have any authorization at all.
        var stmt1: OpaquePointer?
        let accountQuery = "SELECT user_id FROM accounts LIMIT 1;"

        if sqlite3_prepare_v2(db, accountQuery, -1, &stmt1, nil) == SQLITE_OK {
          defer { sqlite3_finalize(stmt1) }

          if sqlite3_step(stmt1) == SQLITE_ROW {
            if let accountIdCStr = sqlite3_column_text(stmt1, 0) {
              myId = String(cString: accountIdCStr)

              // Second, check if this VoIP is for a user we have credentials for.
              var stmt2: OpaquePointer?
              let tokenQuery = "SELECT credentials FROM tokens WHERE user_id = ? LIMIT 1;"

              if sqlite3_prepare_v2(db, tokenQuery, -1, &stmt2, nil) == SQLITE_OK {
                defer { sqlite3_finalize(stmt2) }

                if let text = recipientId {
                  text.withCString { cStr in
                    if sqlite3_bind_text(stmt2, 1, cStr, -1, nil) == SQLITE_OK {
                      let result = sqlite3_step(stmt2)

                      if result == SQLITE_ROW {
                        if let credentialsCStr = sqlite3_column_text(stmt2, 0) {
                          creds = String(cString: credentialsCStr)
                        }
                      } else if result != SQLITE_ROW {
                        isAuthorized = false
                      }
                    }
                  }
                } else {
                  if sqlite3_bind_text(stmt2, 1, myId, -1, nil) == SQLITE_OK {
                    if sqlite3_step(stmt2) != SQLITE_ROW {
                      isAuthorized = false
                    }
                  }
                }

              }

            }
          } else {
            isAuthorized = false
          }

          if isAuthorized {
            // Third, check if CallKit should be displayed at all (perhaps it
            // was already declined in the main app).
            var stmt3: OpaquePointer?
            let atQuery = "SELECT at FROM call_kit_calls WHERE id = ? LIMIT 1"

            if sqlite3_prepare_v2(db, atQuery, -1, &stmt3, nil) == SQLITE_OK {
              defer { sqlite3_finalize(stmt3) }

              id.withCString { cStr in
                if sqlite3_bind_text(stmt3, 1, cStr, -1, nil) == SQLITE_OK {
                  if sqlite3_step(stmt3) == SQLITE_ROW {
                    if let atCStr = sqlite3_column_text(stmt3, 0) {
                      let atStr = String(cString: atCStr)

                      if let atInt64 = Int64(atStr) {
                        // Convert microseconds -> seconds (Double).
                        let accountedAt = Date(
                          timeIntervalSince1970: Double(atInt64) / 1_000_000.0
                        )
                        let now = Date()

                        let diff = abs(accountedAt.timeIntervalSince(now))
                        doReport = diff >= 15
                      } else {
                        doReport = true
                      }
                    }
                  }
                }
              }
            }
          }

          if isAuthorized && doReport {
            // Forth, mark this call as the already accounted.
            var stmt: OpaquePointer?
            let query = """
                  INSERT INTO call_kit_calls (id, at)
                  VALUES (?, ?)
                  ON CONFLICT(id) DO UPDATE SET at = excluded.at;
              """

            if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
              defer { sqlite3_finalize(stmt) }

              // Bind ID.
              id.withCString { cStr in
                sqlite3_bind_text(stmt, 1, cStr, -1, nil)

                // Bind current time in microseconds.
                let nowMicros = Int64(Date().timeIntervalSince1970 * 1_000_000)
                sqlite3_bind_int64(stmt, 2, nowMicros)

                if sqlite3_step(stmt) != SQLITE_DONE {
                  print("UPSERT failed: \(String(cString: sqlite3_errmsg(db)))")
                }
              }
            } else {
              print("Prepare failed: \(String(cString: sqlite3_errmsg(db)))")
            }
          }
        }

        if isAuthorized && doReport {
          // Fifth, try fetching the current status of the call from GraphQL.
          Task {
            await acknowledgeVoip(
              creds: creds,
              callId: id,
              chatId: chatId,
              myId: myId,
              data: data,
              db: db,
            )
          }
        }

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
    db: OpaquePointer?
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

    let defaults = UserDefaults(suiteName: "group.com.tapopa.messenger")
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
