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

importScripts("https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyBbttYFbYjucn8BY-p5tlWomcd5V9h8zWc",
  authDomain: "messenger-3872c.firebaseapp.com",
  databaseURL: 'https://messenger-3872c.firebaseio.com',
  projectId: "messenger-3872c",
  storageBucket: "messenger-3872c.appspot.com",
  messagingSenderId: "985927661367",
  appId: "1:985927661367:web:c604073ecefcacd15c0cb2",
  measurementId: "G-HVQ9H888X8"
});

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
      let unreadCount = 1;

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


/// Listens for messages from the main thread.
/// This runs inside a background service worker, where the browser 
/// manages notifications independently of the page context. 
/// In other words, notifications shown here cannot be dismissed 
/// directly from the web page code.
self.addEventListener("message", async (event) => {
  try {
    const data = event?.data;

    if (typeof data !== "string" || !data.startsWith("closeAll:")) return;
    // try getting chatId 
    const chatId = data.split("closeAll:")[1];

    const notifications = await self.registration.getNotifications();
    for (const notification of notifications) {
      if (notification?.data?.FCM_MSG?.data?.chatId=== chatId) {
        console.log("closed from message event", data, JSON.stringify((notification.data)));
        notification.close();
      }
    }
  } catch (e) {
    console.error("SW message closeAll error:", e);
  }
});
