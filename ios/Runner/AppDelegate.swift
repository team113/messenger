/*
 * Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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
      name: "team113.flutter.dev/ios_utils",
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

    // Check authorization asynchronously
    if let containerURL = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: "group.com.team113.messenger")
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
            // Third, check if CallKit should be displayed at all.
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
            request.addValue("Bearer \(decoded.access.secret)", forHTTPHeaderField: "Authorization")
            // if let refreshed = await refreshToken(db: db, creds: decoded) {
            //   request.addValue(
            //     "Bearer \(refreshed.access.secret)", forHTTPHeaderField: "Authorization")

            //   do {
            //     let encoder = JSONEncoder()
            //     let dateFormatter = DateFormatter()
            //     dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSX"
            //     dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            //     dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            //     encoder.dateEncodingStrategy = .formatted(dateFormatter)

            //     let jsonData = try! encoder.encode(refreshed)
            //     let json = String(data: jsonData, encoding: String.Encoding.utf8)

            //     let sql = """
            //           INSERT INTO tokens (user_id, credentials)
            //           VALUES (?, ?)
            //           ON CONFLICT(user_id) DO UPDATE SET credentials = excluded.credentials;
            //       """

            //     var stmt: OpaquePointer?
            //     if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            //       defer { sqlite3_finalize(stmt) }

            //       myId.withCString { myIdCStr in
            //         sqlite3_bind_text(stmt, 1, myIdCStr, -1, nil)

            //         if let jsonText = json {
            //           jsonText.withCString { jsonCStr in
            //             sqlite3_bind_text(stmt, 2, jsonCStr, -1, nil)

            //             if sqlite3_step(stmt) != SQLITE_DONE {
            //               let errmsg = String(cString: sqlite3_errmsg(db))
            //               print("Insert/Replace failed: \(errmsg)")
            //             }
            //           }
            //         }
            //       }
            //     }
            //   } catch {
            //     print("Error writing refreshed token:", error)
            //   }
            // }
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

  @available(macOS 12.0, *)
  @available(iOS 12.0, *)
  func refreshToken(db: OpaquePointer?, creds: Credentials) async -> Credentials? {
    let dataToSend: [String: Any] = [
      "query": """
          mutation refresh {
              refreshSession(secret:\"\(creds.refresh.secret)\") {
                  __typename
                  ... on CreateSessionOk {
                      accessToken {
                          secret
                          expiresAt
                      }
                      refreshToken {
                          secret
                          expiresAt
                      }
                      session {
                        id
                        userAgent
                        ip
                        lastActivatedAt
                      }
                      user {
                          id
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

      let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "network")

      do {
        request.httpBody = try JSONSerialization.data(withJSONObject: dataToSend)
        let (data, _) = try await URLSession.shared.data(for: request)

        if let response = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
          logger.log("refreshToken() response decoded -> \(response)")
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let response = try decoder.decode(RefreshSessionResponse.self, from: data)
          as RefreshSessionResponse?
        {
          return Credentials(
            access: Token(
              secret: response.data.refreshSession.accessToken.secret,
              expireAt: DateType(val: response.data.refreshSession.accessToken.expiresAt)
            ),
            refresh: Token(
              secret: response.data.refreshSession.refreshToken.secret,
              expireAt: DateType(val: response.data.refreshSession.refreshToken.expiresAt)
            ),
            session: Session(
              id: response.data.refreshSession.session.id,
              ip: response.data.refreshSession.session.ip,
              userAgent: response.data.refreshSession.session.userAgent,
              lastActivatedAt: DateType(val: response.data.refreshSession.session.lastActivatedAt)
            ),
            userId: response.data.refreshSession.user.id
          )
        }
        return creds
      } catch {
        logger.error("refreshToken() failed -> \(error)")
      }
    }

    return nil
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

  struct RefreshSessionResponse: Decodable {
    let data: RefreshSessionResponseData
  }

  struct RefreshSessionResponseData: Decodable {
    let refreshSession: RefreshSessionResponseDataCredentials
  }

  struct RefreshSessionResponseDataCredentials: Decodable {
    let accessToken: RefreshSessionResponseDataToken
    let refreshToken: RefreshSessionResponseDataToken
    let session: RefreshSessionResponseDataSession
    let user: RefreshSessionResponseDataCredentialsUser
  }

  struct RefreshSessionResponseDataToken: Decodable {
    let secret: String
    let expiresAt: Date
  }

  struct RefreshSessionResponseDataSession: Decodable {
    let id: String
    let userAgent: String
    let ip: String
    let lastActivatedAt: Date
  }

  struct RefreshSessionResponseDataCredentialsUser: Decodable {
    let id: String
  }
}
