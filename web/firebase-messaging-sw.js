importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyDy8Av3HcsiX-ZY5suKmpbyuZOX8q4HDC0",
  authDomain: "inptiq.web.app",
  projectId: "inpt-app-20260108022659",
  storageBucket: "inpt-app-20260108022659.firebasestorage.app",
  messagingSenderId: "527094263196",
  appId: "1:527094263196:web:82b37722b7c66bd8a4ec59",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('Received background message ', payload);
  const notificationTitle = payload.notification?.title || 'إشعار جديد';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icon.png',
    badge: '/badge.png',
    data: payload.data,
  };
  self.registration.showNotification(notificationTitle, notificationOptions);
});