importScripts("https://www.gstatic.com/firebasejs/9.22.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.22.1/firebase-messaging-compat.js");

firebase.initializeApp({
    apiKey: "AIzaSyAisigUiy0Z6SuYAUCVDYuIkyCM1_0ydiY",
    authDomain: "cute-todo-691d5.firebaseapp.com",
    projectId: "cute-todo-691d5",
    storageBucket: "cute-todo-691d5.firebasestorage.app",
    messagingSenderId: "1001696534148",
    appId: "1:1001696534148:web:a1d528f1975dc4802aacd1",
    measurementId: "G-SXGS2Z9EPN",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
    console.log('[firebase-messaging-sw.js] Received background message ', payload);
    // Customize notification here
    const notificationTitle = payload.notification.title;
    const notificationOptions = {
        body: payload.notification.body,
        icon: '/favicon.png'
    };

    self.registration.showNotification(notificationTitle, notificationOptions);
});
