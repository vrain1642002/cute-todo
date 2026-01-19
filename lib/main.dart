import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/constants/themes.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAisigUiy0Z6SuYAUCVDYuIkyCM1_0ydiY",
      authDomain: "cute-todo-691d5.firebaseapp.com",
      projectId: "cute-todo-691d5",
      storageBucket: "cute-todo-691d5.firebasestorage.app",
      messagingSenderId: "1001696534148",
      appId: "1:1001696534148:web:a1d528f1975dc4802aacd1",
      measurementId: "G-SXGS2Z9EPN",
    ),
  );

  runApp(const CuteTodoApp());
}

class CuteTodoApp extends StatelessWidget {
  const CuteTodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
      ],
      child: MaterialApp(
        title: 'Cute Todo',
        debugShowCheckedModeBanner: false,
        theme: AppThemes.lightTheme,
        darkTheme: AppThemes.darkTheme,
        themeMode: ThemeMode.light,
        home: const SplashScreen(),
      ),
    );
  }
}
