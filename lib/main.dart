import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/theme_service.dart';
import 'services/voice_service.dart';
import 'services/localization_service.dart';
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
        ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService()),
        ChangeNotifierProvider<VoiceService>(create: (_) => VoiceService()),
        ChangeNotifierProvider<LocalizationService>(
            create: (_) => LocalizationService()), // Add Provider
      ],
      child: Consumer2<ThemeService, LocalizationService>(
        builder: (context, themeService, localizationService, child) {
          final palette = themeService.currentPalette;

          return MaterialApp(
            title: 'Cute Todo',
            debugShowCheckedModeBanner: false,
            locale: localizationService.locale, // Set locale
            supportedLocales: const [
              Locale('en', ''),
              Locale('vi', ''),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            // Dynamically build theme from current palette
            theme: ThemeData(
              useMaterial3: true,
              primaryColor: palette.primary,
              scaffoldBackgroundColor: palette.background,
              colorScheme: ColorScheme.fromSeed(
                seedColor: palette.primary,
                primary: palette.primary,
                secondary: palette.secondary,
                surface: palette.surface,
                onSurface: palette.text,
                brightness: themeService.currentMode == AppThemeMode.night
                    ? Brightness.dark
                    : Brightness.light,
              ),
              textTheme: TextTheme(
                bodyLarge: TextStyle(color: palette.text),
                bodyMedium: TextStyle(color: palette.text),
                titleLarge: TextStyle(color: palette.text),
              ),
            ),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
