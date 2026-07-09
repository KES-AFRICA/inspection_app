// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inspec_app/pages/missions/home_screen.dart';
import 'package:inspec_app/pages/register_screen.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/pages/login_screen.dart';
import 'package:inspec_app/models/verificateur.dart';
import 'package:inspec_app/core/di/injection_container.dart' as di;
import 'package:inspec_app/features/auth/domain/repositories/verificateur_repository.dart';
import 'package:inspec_app/features/auth/data/mappers/verificateur_mapper.dart';
import 'package:inspec_app/features/auth/domain/usecases/check_login_status_use_case.dart';
import 'package:inspec_app/features/auth/domain/usecases/get_current_user_use_case.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Hive
  await HiveService.init();
  // Migration silencieuse des données existantes
  await HiveService.migratePointsVerificationPriorite();
  
  // Initialiser l'injection de dépendances
  await di.init();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: MyApp()));
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
    final isLoggedIn = di.sl<CheckLoginStatusUseCase>()();
    final verificateurEntity = di.sl<GetCurrentUserUseCase>()();

    if (isLoggedIn && verificateurEntity != null) {
      final currentUserModel = VerificateurMapper.toModel(verificateurEntity);
      return HomeScreen(user: currentUserModel);
    } else {
      return const LoginScreen();
    }
  }
}