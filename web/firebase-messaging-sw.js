// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

importScripts('./firebase-credentials.js');

const routeChannel = new BroadcastChannel("route");

// Registers `notificationclick` handler for closing notification and navigating
// to the chat specified in the payload.
self.addEventListener('notificationclick', function (event) {
  async function handle() {
    // This is our payload from the showed notification.
    const payload = event.notification?.data;
    console.log('`notificationclick` triggered from ServiceWorker:', payload);

    const link = payload.webpush.link;

    event.notification.close();

    await self.clients.claim();
    let clientList = await self.clients.matchAll({
      type: 'window',
      includeUncontrolled: true
    });

    for (const client of clientList) {
      // Ignore separate windows of calls and galleries.
      if (!client.url.includes('/call') && !client.url.includes('/gallery')) {
        client.focus();

        if (link) {
          routeChannel.postMessage(link);
        }

        return;
      }
    }

    if (link) {
      await self.clients.openWindow(link);
    } else {
      await self.clients.openWindow('/');
    }
  }

  event.waitUntil(handle());
});

// Any `notificationclick` event listeners must must be registered before
// importing Firebase scripts.
//
// For more information see:
// https://firebase.google.com/docs/cloud-messaging/js/receive#setting_notification_options_in_the_service_worker
importScripts("https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js");

// Separate `credentials` variable is used for ability to change it easily.
firebase.initializeApp(credentials);

const messaging = firebase.messaging();
const broadcastChannel = new BroadcastChannel("fcm");

messaging.onMessage(async (payload) => {
  // If payload contains no title (it's a background notification), then check
  // whether its data contains any tag or thread, and cancel it, if any.
  //
  // This code is invoked from a service worker, thus the `getNotifications()`
  // method is available here.
  if (payload.notification?.title == null || (payload.notification?.title == 'Canceled' && payload.notification?.body == null)) {
    var tag = payload.data.tag;
    var thread = payload.data.thread;

    if (thread != null) {
      const notifications = await self.registration.getNotifications();
      for (var notification of notifications) {
        if (notification.tag.includes(thread)) {
          notification.close();
        }
      }
    } else if (tag != null) {
      const notifications = await self.registration.getNotifications({
        tag: payload.data.tag
      });

      for (var notification of notifications) {
        notification.close();
      }
    }
  }

  // Otherwise that's a normal push notification.
  else {
    // Try to set a badge, if available.
    if (navigator.setAppBadge) {
      let unreadCount = payload.data.badge ?? 1;

      if (unreadCount && unreadCount > 0) {
        navigator.setAppBadge(unreadCount);
      } else {
        navigator.clearAppBadge();
      }
    }
  }
});

messaging.onBackgroundMessage(async (payload) => {
  broadcastChannel.postMessage(payload);

  // If payload contains no title (it's a background notification), then check
  // whether its data contains any tag or thread, and cancel it, if any.
  //
  // This code is invoked from a service worker, thus the `getNotifications()`
  // method is available here.
  if (payload.notification?.title == null || (payload.notification?.title == 'Canceled' && payload.notification?.body == null)) {
    var tag = payload.data.tag;
    var thread = payload.data.thread;

    if (thread != null) {
      await new Promise(resolve => setTimeout(resolve, 16));

      const notifications = await self.registration.getNotifications();
      for (var notification of notifications) {
        if (notification.tag.includes(thread)) {
          notification.close();
        }
      }
    } else if (tag != null) {
      const notifications = await self.registration.getNotifications({
        tag: payload.data.tag
      });

      for (var notification of notifications) {
        notification.close();
      }
    }
  }

  // Otherwise that's a normal push notification.
  else {
    // Try to set a badge, if available.
    if (navigator.setAppBadge) {
      let unreadCount = 1;

      if (unreadCount && unreadCount > 0) {
        navigator.setAppBadge(unreadCount);
      } else {
        navigator.clearAppBadge();
      }
    }
  }
});

// Listens for messages from the main thread.
//
// This runs inside a background service worker, where the browser manages
// notifications independently of the page context. In other words,
// notifications shown here cannot be dismissed directly from the web page code.
self.addEventListener("message", async (event) => {
  try {
    const data = event?.data;

    // If we receive a command not starting with a `closeAll:` (this worker
    // doesn't support other commands), then return from execution.
    if (typeof data !== "string" || !data.startsWith("closeAll:")) return;

    // Parse `ChatId` part.
    const chatId = data.split("closeAll:")[1];

    const notifications = await self.registration.getNotifications();
    for (const notification of notifications) {
      if (notification?.data?.FCM_MSG?.data?.chatId === chatId || notification?.lang?.includes(chatId)) {
        console.log("Closing notification by `closeAll:` message from the ServiceWorker", data, JSON.stringify((notification.data)));
        notification.close();
      }
    }
  } catch (e) {
    console.error("Unable to perform `closeAll:` in ServiceWorker due to:", e);
  }
});
