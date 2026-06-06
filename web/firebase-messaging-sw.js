// Firebase Messaging Service Worker for Qanoon Buddy Web
// This file is required for firebase_messaging to work on web.

importScripts("https://www.gstatic.com/firebasejs/9.22.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.22.1/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyB0qW3QpJgUeaf5WOy1r1bVNKqTr_SF0Ag",
  authDomain: "qanoonbuddy-d60d4.firebaseapp.com",
  projectId: "qanoonbuddy-d60d4",
  storageBucket: "qanoonbuddy-d60d4.firebasestorage.app",
  messagingSenderId: "192169687988",
  appId: "1:192169687988:web:b1d8e70d2b799c555590e1"
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message:', payload);
  const notificationTitle = payload.notification?.title || 'Qanoon Buddy';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png'
  };
  self.registration.showNotification(notificationTitle, notificationOptions);
});
