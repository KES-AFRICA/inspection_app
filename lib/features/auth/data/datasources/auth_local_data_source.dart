// lib/features/auth/data/datasources/auth_local_data_source.dart
import 'package:hive/hive.dart';
import 'package:inspec_app/models/verificateur.dart';

abstract class AuthLocalDataSource {
  bool isUserLoggedIn();
  Verificateur? getCurrentUser();
  Future<void> saveCurrentUser(Verificateur user);
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const String _verificateurBox = 'verificateurs';
  static const String _currentUserKey = 'current_user';

  @override
  bool isUserLoggedIn() {
    final currentBox = Hive.box(_currentUserKey);
    return currentBox.get('isLoggedIn', defaultValue: false);
  }

  @override
  Verificateur? getCurrentUser() {
    final currentBox = Hive.box(_currentUserKey);
    final email = currentBox.get('email');
    final isLoggedIn = currentBox.get('isLoggedIn', defaultValue: false);

    if (email == null || email is! String || !isLoggedIn) return null;

    final box = Hive.box<Verificateur>(_verificateurBox);
    return box.get(email);
  }

  @override
  Future<void> saveCurrentUser(Verificateur user) async {
    final box = Hive.box<Verificateur>(_verificateurBox);
    await box.put(user.email.toLowerCase(), user);

    final currentBox = Hive.box(_currentUserKey);
    await currentBox.put('email', user.email.toLowerCase());
    await currentBox.put('isLoggedIn', true);
  }
}
