# 🎯 Cute Todo - A Delightful Todo List Web App

A beautiful, gamified todo list application built with Flutter Web and Firebase. Make productivity fun with XP, levels, streaks, and cute animations!

![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)
![Firebase](https://img.shields.io/badge/Firebase-Firestore-orange.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## ✨ Features

- 🔐 **Google Sign-In** - One-click authentication
- 🎮 **Gamification** - Earn XP, level up, and build streaks
- 📝 **Smart Todo Management** - Priority levels, due dates, categories
- 🏆 **Achievements** - Unlock badges for milestones
- ⏱️ **Pomodoro Timer** - Stay focused (coming soon)
- 📊 **Analytics** - Track your productivity
- 🌙 **Dark/Light Theme** - Easy on the eyes
- 💖 **Cute Animations** - Celebration effects and smooth transitions
- 🔔 **Smart Reminders** - Never miss a deadline
- 🌐 **Cross-device Sync** - Access from anywhere

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.0+)
- [Firebase Account](https://firebase.google.com/)
- A modern web browser

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/cute_todo.git
   cd cute_todo
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Setup Firebase** (See Firebase Setup section below)

4. **Run the app**
   ```bash
   flutter run -d chrome
   ```

## 🔥 Firebase Setup

### 1. Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: `cute-todo` (or your preferred name)
4. Enable Google Analytics (optional)
5. Click "Create project"

### 2. Enable Authentication

1. In Firebase Console, go to **Authentication**
2. Click "Get started"
3. Select **Google** from Sign-in providers
4. Enable Google Sign-In
5. Add your email as test user
6. Click "Save"

### 3. Create Firestore Database

1. Go to **Firestore Database**
2. Click "Create database"
3. Select "Start in test mode" (we'll add security rules later)
4. Choose a location close to your users
5. Click "Enable"

### 4. Setup Web App

1. In Project Overview, click the **Web** icon (`</>`)
2. Register app with nickname: "Cute Todo Web"
3. Enable Firebase Hosting (optional)
4. Click "Register app"
5. Copy the Firebase configuration

### 5. Update Firebase Config

Open `lib/main.dart` and replace the placeholder values:

```dart
await Firebase.initializeApp(
  options: const FirebaseOptions(
    apiKey: "YOUR_API_KEY",
    authDomain: "YOUR_PROJECT_ID.firebaseapp.com",
    projectId: "YOUR_PROJECT_ID",
    storageBucket: "YOUR_PROJECT_ID.appspot.com",
    messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
    appId: "YOUR_APP_ID",
  ),
);
```

### 6. Firestore Security Rules

Update Firestore security rules in Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Todos collection
    match /todos/{todoId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
      allow create: if request.auth != null;
    }
    
    // Habits collection
    match /habits/{habitId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
      allow create: if request.auth != null;
    }
    
    // Achievements collection
    match /achievements/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## 📦 Deploy to Vercel

### 1. Install Vercel CLI

```bash
npm install -g vercel
```

### 2. Build for Web

```bash
flutter build web --release
```

### 3. Deploy

```bash
vercel
```

Follow the prompts:
- Link to existing project or create new
- Choose project name
- Confirm settings

Your app will be live at `https://your-project.vercel.app` 🎉

### Alternative: Deploy via GitHub

1. Push code to GitHub
2. Import repository in [Vercel Dashboard](https://vercel.com)
3. Vercel will auto-detect `vercel.json` and deploy

## 🏗️ Project Structure

```
cute_todo/
├── lib/
│   ├── core/
│   │   ├── constants/      # Colors, themes, dimensions
│   │   ├── utils/          # Helper functions
│   │   └── widgets/        # Reusable widgets
│   ├── models/             # Data models
│   ├── services/           # Firebase & business logic
│   ├── screens/            # UI screens
│   └── main.dart           # App entry point
├── assets/                 # Images, animations, sounds
├── web/                    # Web-specific files
└── pubspec.yaml            # Dependencies
```

## 🎨 Customization

### Change Colors

Edit `lib/core/constants/colors.dart`:

```dart
static const Color lightPrimary = Color(0xFFFF6B9D); // Your color
```

### Change Fonts

Edit `lib/core/constants/themes.dart`:

```dart
textTheme: GoogleFonts.openSansTextTheme() // Your font
```

## 🐛 Troubleshooting

### "Firebase not initialized"
- Make sure you've replaced all Firebase config values
- Check that Firebase is initialized before `runApp()`

### "Google Sign-In failed"
- Verify Google Sign-In is enabled in Firebase Console
- Check that your domain is authorized

### "Firestore permission denied"
- Update Firestore security rules (see Firebase Setup)
- Ensure user is authenticated

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Google Fonts for beautiful typography

## 📞 Support

If you have any questions or need help, please open an issue on GitHub.

---

Made with ❤️ using Flutter
