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

importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-messaging.js");

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

messaging.onBackgroundMessage(async (payload) => {
  broadcastChannel.postMessage(payload);

  if (payload.notification?.title == null) {
    const notifications = await self.registration.getNotifications({
      tag: payload.data.tag
    });

    for (var notification of notifications) {
      notification.close();
    }
  }
});
