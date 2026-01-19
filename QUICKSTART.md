# Quick Start Guide 🚀

## ⚡ Quick Setup (5 minutes)

### 1. Setup Firebase

**Create Project:**
```
1. Go to: https://console.firebase.google.com/
2. Click "Add project" → Name it "cute-todo"
3. Click "Create project"
```

**Enable Google Sign-In:**
```
1. Go to Authentication → Get started
2. Click "Google" → Enable → Save
```

**Create Firestore:**
```
1. Go to Firestore Database → Create database
2. Choose "Start in test mode" → Select location → Enable
```

**Get Web Config:**
```
1. Project Overview ( gear icon) → Project settings
2. Scroll down → Click Web icon (</>)
3. Register app → Copy the config
```

### 2. Update Config

Open `lib/main.dart` and paste your Firebase config:

```dart
await Firebase.initializeApp(
  options: const FirebaseOptions(
    apiKey: "paste-here",
    authDomain: "paste-here",
    projectId: "paste-here",
    storageBucket: "paste-here",
    messagingSenderId: "paste-here",
    appId: "paste-here",
  ),
);
```

### 3. Run the App

```bash
# In the cute_todo directory
flutter pub get
flutter run -d chrome
```

🎉 **Done!** Your app should open in Chrome.

---

## 📝 What You Can Do Now

✅ Sign in with your Google account  
✅ Create todos with priority and due dates  
✅ Earn XP by completing tasks  
✅ Level up and track your streak  
✅ View your progress and stats  

---

## 🌐 Deploy to Vercel (Optional)

```bash
# Build
flutter build web --release

# Deploy
npm install -g vercel
vercel
```

Your app will be live at: `https://your-project.vercel.app`

---

## ⚙️ Add Firestore Security Rules

In Firebase Console → Firestore → Rules, paste:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /todos/{todoId} {
      allow read, write: if request.auth != null && resource.data.userId == request.auth.uid;
      allow create: if request.auth != null;
    }
  }
}
```

Click "Publish"

---

## 🆘 Troubleshooting

**App won't run?**
- Run: `flutter clean && flutter pub get`

**Can't sign in?**
- Check Firebase Authentication is enabled
- Verify config in `main.dart`

**Firestore errors?**
- Add security rules (see above)
- Check Firestore is created

---

Need help? Check the full [README.md](README.md) for detailed instructions.
