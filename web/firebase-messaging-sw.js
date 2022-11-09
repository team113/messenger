importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js");

//Using singleton breaks instantiating messaging()
// App firebase = FirebaseWeb.instance.app;

firebase.initializeApp({
  apiKey: "AIzaSyBbttYFbYjucn8BY-p5tlWomcd5V9h8zWc",
  authDomain: "messenger-3872c.firebaseapp.com",
  databaseURL: 'https://messenger-3872c.firebaseio.com',
  projectId: "messenger-3872c",
  storageBucket: "messenger-3872c.appspot.com",
  messagingSenderId: "985927661367",
  appId: "1:985927661367:web:f74cc9e76046c1c55c0cb2",
  measurementId: "G-8WK80QEL35"
});

const messaging = firebase.messaging();
//messaging.onBackgroundMessage(function (payload) {
//    console.log('messaging.setBackgroundMessageHandler');
//    new Notification("payload.notification.title", payload.notification);
//    const promiseChain = clients
//        .matchAll({
//            type: "window",
//            includeUncontrolled: true
//        })
//        .then(windowClients => {
//            for (let i = 0; i < windowClients.length; i++) {
//                const windowClient = windowClients[i];
//                windowClient.postMessage(payload);
//            }
//        })
//        .then(() => {
//            return registration.showNotification("New Message");
//        });
//    return promiseChain;
//});
//
////messaging.onMessage(function (msg) {
////                            console.log('window.messaging.onMessage');
////                        });
//
//self.addEventListener('notificationclick', function (event) {
//    console.log('notification received: ', event)
//});
