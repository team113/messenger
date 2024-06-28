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

  override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {

    self.contentHandler = contentHandler
    bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

    if let bestAttemptContent = bestAttemptContent {
      let userInfo = request.content.userInfo;

      Task {
        // TODO: Use keychain here to retrieve Authorization token?
        //       Or perhaps invoke Dart somehow?
        await postRequest()
      }

      Messaging.serviceExtension().populateNotificationContent(bestAttemptContent, withContentHandler: contentHandler)
    }
  }

  override func serviceExtensionTimeWillExpire() {
    // Called just before the extension will be terminated by the system.
    //
    // Use this as an opportunity to deliver your "best attempt" at modified
    // content, otherwise the original push payload will be used.
    if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
      contentHandler(bestAttemptContent)
    }
  }

  let baseUrl = "https://gapopa.com"
  let endpoint = "/api/graphql"

  func postRequest() async {
    let db = try Connection("path/to/db.sqlite3")

    // TODO: Need to understand to who this notification was delivered to.
    let accounts = Table("accounts")
    let tokens = Table("tokens")

    let id = Expression<String>("id")
    let userId = Expression<String>("user_id")
    let credentials = Expression<String>("credentials")

    if let user = try db.pluck(accounts) {

    }

    let dataToSend: [String: Any] = [
      "query": "mutation qwe {postChatMessage(chatId:\"d6da74a0-bd98-40ed-8ec1-2aaa1a35baa9\", text:\"swift\", repliesTo:[], attachments:[]) { __typename }}",
      "variables": ["myVariable": "someValue" ],
    ]

    if let url = URL(string: baseUrl + endpoint) {
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.addValue("application/json", forHTTPHeaderField: "Content-Type")
      request.addValue("Bearer eyJpZCI6IjEyNjI3NjVjLTY0MDUtNGE2ZS1hNmEzLWJmYmMwZWJiNGZhMyIsInNlY3JldCI6IjE0U0hWeGZDa0t1am9peUhrTmVFaFRvTENwUUpJWkd3SkoxQ1hPQ2tuQzg9In0", forHTTPHeaderField: "Authorization")

      do {
        request.httpBody = try JSONSerialization.data(withJSONObject: dataToSend)
        let (data, _) = try await URLSession.shared.data(for: request)

        if let responseData = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
          print("POST Response:", responseData)
        }
      } catch {
        print("POST Request Failed:", error)
      }
    }
  }
}
