// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inspec_app/pages/missions/home_screen.dart';
import 'package:inspec_app/pages/register_screen.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/secure_password_service.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/pages/login_screen.dart';
import 'package:inspec_app/models/verificateur.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Hive
  await HiveService.init();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  
  FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint(details.toString());
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inspection App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = HiveService.isUserLoggedIn();
    final Verificateur? currentUser = HiveService.getCurrentUser();

    if (isLoggedIn && currentUser != null) {
      return HomeScreen(user: currentUser);
    } else {
      return const LoginScreen();
    }
  }
}