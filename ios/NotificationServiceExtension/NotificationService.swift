// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
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
import SQLite
import UserNotifications

class NotificationService: UNNotificationServiceExtension {
  var contentHandler: ((UNNotificationContent) -> Void)?
  var bestAttemptContent: UNMutableNotificationContent?

  override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    let userInfo = request.content.userInfo

    Task {
      if let chatId = userInfo["chatId"] as? String {
        await acknowledgeDelivery(chatId: chatId)
      }
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
    if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.team113.messenger") {
      let db = try! Connection("\(containerURL)common.sqlite")

      // TODO: Need to understand to who this notification was delivered to.
      let accounts = Table("accounts")
      let tokens = Table("tokens")

      let userId = Expression<String>("user_id")
      let credentials = Expression<String>("credentials")

      if let user = try! db.pluck(accounts) {
        let accountId = user[userId]

        let query = tokens.select(credentials).where(userId == accountId).limit(1)
        let account = try! db.pluck(query)

        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.mmmZ"
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        decoder.dateDecodingStrategy = .formatted(dateFormatter)

        let creds = try! decoder.decode(
          Credentials.self,
          from: account![credentials].data(using: .utf8)!
        )

        var fresh = creds

       if Date() > creds.access.expireAt {
         if #available(iOS 12.0, macOS 12.0, *) {
           if let refreshed = await refreshToken(creds: creds) {
             fresh = refreshed

             let encoder = JSONEncoder()
             let dateFormatter = DateFormatter()
             dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.mmmZ"
             dateFormatter.locale = Locale(identifier: "en_US")
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
                      user {
                          id
                      }
                  }
              }
          }
      """
    ]

    let defaults = UserDefaults(suiteName: "group.com.team113.messenger");
    let baseUrl = defaults!.value(forKey: "url") as! String;
    let endpoint = defaults!.value(forKey: "endpoint") as! String;

    if let url = URL(string: baseUrl + endpoint) {
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.addValue("application/json", forHTTPHeaderField: "Content-Type")

      do {
        request.httpBody = try JSONSerialization.data(withJSONObject: dataToSend)
        let (data, _) = try await URLSession.shared.data(for: request)

        if let response = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
          NSLog("POST Response:", response)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let response = try decoder.decode(RefreshSessionResponse.self, from: data)
          as RefreshSessionResponse?
        {
          return Credentials(
            access: Token(
              secret: response.data.refreshSession.accessToken.secret,
              expireAt: response.data.refreshSession.accessToken.expiresAt
            ),
            refresh: Token(
              secret: response.data.refreshSession.refreshToken.secret,
              expireAt: response.data.refreshSession.refreshToken.expiresAt
            ),
            userId: response.data.refreshSession.user.id
          )
        }
        return creds
      } catch {
        print("POST Request Failed:", error)
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

    let defaults = UserDefaults(suiteName: "group.com.team113.messenger");
    let baseUrl = defaults!.value(forKey: "url") as! String;
    let endpoint = defaults!.value(forKey: "endpoint") as! String;

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
    let userId: String
  }

  struct Token: Codable {
    let secret: String
    let expireAt: Date
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
    let user: RefreshSessionResponseDataCredentialsUser
  }

  struct RefreshSessionResponseDataToken: Decodable {
    let secret: String
    let expiresAt: Date
  }

  struct RefreshSessionResponseDataCredentialsUser: Decodable {
    let id: String
  }
}
