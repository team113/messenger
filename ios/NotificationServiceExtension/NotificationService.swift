// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License v3.0 as published by the
// Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License v3.0 for
// more details.
//
// You should have received a copy of the GNU Affero General Public License v3.0
// along with this program. If not, see
// <https://www.gnu.org/licenses/agpl-3.0.html>.

import FirebaseMessaging
import Foundation
import SQLite
import UserNotifications
import os

class NotificationService: UNNotificationServiceExtension {
  var contentHandler: ((UNNotificationContent) -> Void)?
  var bestAttemptContent: UNMutableNotificationContent?

  override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    Task {
      let userInfo = request.content.userInfo

      Task {
        if let chatId = userInfo["thread"] as? String {
          await acknowledgeDelivery(chatId: chatId)
        }
      }

      if let tag = userInfo["tag"] as? String {
        cancelNotification(tag: String(tag.asHash))
      }

      self.contentHandler = contentHandler
      bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

      if let bestAttemptContent = bestAttemptContent {
        Messaging.serviceExtension().populateNotificationContent(
          bestAttemptContent,
          withContentHandler: contentHandler
        )
      }
    }
  }

  override func serviceExtensionTimeWillExpire() {
    // Called just before the extension will be terminated by the system.
    //
    // Use this as an opportunity to deliver your "best attempt" at modified
    // content, otherwise the original push payload will be used.
    if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
      contentHandler(bestAttemptContent)
    }
  }

  func acknowledgeDelivery(chatId: String) async {
    if let containerURL = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: "group.com.tapopa.messenger")
    {
      let db = try! Connection("\(containerURL)common.sqlite")

      // TODO: Need to understand to who this notification was delivered to.
      let accounts = Table("accounts")
      let tokens = Table("tokens")

      let userId = SQLite.Expression<String>("user_id")
      let credentials = SQLite.Expression<String>("credentials")

      if let user = try! db.pluck(accounts) {
        let accountId = user[userId]

        let locks = LockProvider(db: db)
        let lock = await locks?.acquireLock(asOperation: "refreshSession(\(userId))")

        let query = tokens.select(credentials).where(userId == accountId).limit(1)
        let account = try! db.pluck(query)

        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSX"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        decoder.dateDecodingStrategy = .formatted(dateFormatter)

        let creds = try! decoder.decode(
          Credentials.self,
          from: account![credentials].data(using: .utf8)!
        )

        var fresh = creds

        if Date() > creds.access.expireAt.val {
          if #available(iOS 12.0, macOS 12.0, *) {
            if let refreshed = await refreshToken(creds: creds) {
              fresh = refreshed

              let encoder = JSONEncoder()
              let dateFormatter = DateFormatter()
              dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSX"
              dateFormatter.locale = Locale(identifier: "en_US_POSIX")
              dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
              encoder.dateEncodingStrategy = .formatted(dateFormatter)

              let jsonData = try! encoder.encode(refreshed)
              let json = String(data: jsonData, encoding: String.Encoding.utf8)

              try! db.run(tokens.insert(or: .replace, userId <- accountId, credentials <- json!))
            }
          }
        }

        if #available(iOS 12.0, macOS 12.0, *) {
          await sendDelivery(creds: fresh, chatId: chatId)
        }

        if lock != nil {
          await locks?.releaseLock(holder: lock!)
        }
      }
    }
  }

  @available(macOS 12.0, *)
  @available(iOS 12.0, *)
  func refreshToken(creds: Credentials) async -> Credentials? {
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

    let defaults = UserDefaults(suiteName: "group.com.tapopa.messenger")
    let baseUrl = defaults!.value(forKey: "url") as! String
    let endpoint = defaults!.value(forKey: "endpoint") as! String

    if let url = URL(string: baseUrl + endpoint) {
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.addValue("application/json", forHTTPHeaderField: "Content-Type")

      if let agent = defaults!.value(forKey: "agent") as? String {
        request.setValue(agent, forHTTPHeaderField: "User-Agent")
      }

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
              userAgent: response.data.refreshSession.session.userAgent,
              ip: response.data.refreshSession.session.ip,
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

  @available(macOS 12.0, *)
  @available(iOS 12.0, *)
  func sendDelivery(creds: Credentials, chatId: String) async {
    let dataToSend: [String: Any] = [
      "query": """
          query chat {
              chat(id: "\(chatId)") {
                  items(first: 1) {
                      __typename
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
      request.addValue("Bearer \(creds.access.secret)", forHTTPHeaderField: "Authorization")

      do {
        request.httpBody = try JSONSerialization.data(withJSONObject: dataToSend)
        let (data, _) = try await URLSession.shared.data(for: request)

        if let response = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
          print("POST Response:", response)
        }
      } catch {
        print("POST Request Failed:", error)
      }
    }
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
    let userAgent: String
    let ip: String
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

  /// Remove the delivered notification with the provided tag.
  private func cancelNotification(tag: String) {
    if #available(iOS 10.0, *) {
      let center = UNUserNotificationCenter.current()
      center.removeDeliveredNotifications(withIdentifiers: [tag])
    }
  }

  class LockProvider {
    let db: Connection

    required init?(db: Connection) {
      self.db = db
    }

    func acquireLock(asOperation: String) async -> String {
      let identifier: String = UUID().uuidString

      // Time in microseconds to consider `lockedAt` value as being outdated
      // or stale, so it can be safely overwritten.
      let lockedAtTtl: Int = 30_000_000  // 30s

      let retryDelay = UInt64(0.2 * Double(NSEC_PER_SEC))  // 200ms

      var acquired: Bool = false
      while !acquired {
        let now: Date = Date()
        let now_timestamp: TimeInterval = now.timeIntervalSince1970
        let now_microseconds: Int = Int(now_timestamp * 1_000_000)

        // TODO: Replace with `SQLite.swift` statement methods when `RETURNING`
        //       and `DO UPDATE ... WHERE` are supported.
        let sql = """
          INSERT OR ROLLBACK INTO locks (operation, holder, locked_at)
          VALUES (?, ?, ?)
          ON CONFLICT(operation) DO UPDATE
          SET holder = excluded.holder,
              locked_at = excluded.locked_at
          WHERE IFNULL(locked_at, 0) <= excluded.locked_at - ?
          RETURNING *;
          """

        let statement = try? db.prepare(sql)
        if let rows = try? statement?.run(
          asOperation,
          identifier,
          now_microseconds,
          lockedAtTtl
        ) {
          for row in rows {
            let returnedHolder = row[1] as? String
            acquired = returnedHolder == identifier
          }
        }

        if !acquired {
          let locksTable = Table("locks")
          let holderColumn = SQLite.Expression<String>("holder")

          // Run `SELECT` to check if the lock is held by the identifier, since
          // the previous `INSERT OR ROLLBACK` might not return any rows even if
          // the query was successful, which seems like a bug in `SQLite.swift`.
          if let lockOrNil = try? db.pluck(
            locksTable.select(holderColumn).where(holderColumn == identifier))
          {
            if let returnedHolder = try? lockOrNil.get(holderColumn) {
              acquired = returnedHolder == identifier
            }
          }

          if !acquired {
            try? await Task.sleep(nanoseconds: retryDelay)
          }
        }
      }

      return identifier
    }

    func releaseLock(holder: String) async {
      let locksTable = Table("locks")
      let holderColumn = SQLite.Expression<String>("holder")

      try? db.run(locksTable.filter(holderColumn == holder).delete())
    }
  }
}

// Extension adding the simplest possible hash to a `String`.
//
// Currently uses the FNV-1a hash function.
//
// See: https://en.wikipedia.org/wiki/Fowler–Noll–Vo_hash_function
extension String {
  /// Returns a hash of this `String` in its simplest form.
  var asHash: UInt32 {
    var result: UInt32 = 0x811C_9DC5  // FNV offset basis.
    for unit in self.utf16 {
      result ^= UInt32(unit)
      result = (result &* 0x0100_0193) & 0xFFFF_FFFF  // 32-bit overflow.
    }
    return result
  }
}
