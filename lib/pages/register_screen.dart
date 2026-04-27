// lib/pages/register_screen.dart
import 'package:flutter/material.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/constants/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _matriculeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _passwordError;
  List<int> _passwordStrength = [0, 0, 0, 0]; // Maj, min, chiffre, spécial

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    _matriculeCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _checkPasswordStrength(String password) {
    setState(() {
      _passwordStrength = [
        password.contains(RegExp(r'[A-Z]')) ? 1 : 0,
        password.contains(RegExp(r'[a-z]')) ? 1 : 0,
        password.contains(RegExp(r'[0-9]')) ? 1 : 0,
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')) ? 1 : 0,
      ];
    });
  }

  int _getPasswordStrengthScore() {
    return _passwordStrength.reduce((a, b) => a + b);
  }

  Widget _buildPasswordStrengthIndicator() {
    final score = _getPasswordStrengthScore();
    final width = MediaQuery.of(context).size.width;
    final itemWidth = (width - 80) / 4;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStrengthBar(
              width: itemWidth,
              color: _passwordStrength[0] == 1 ? Colors.green : Colors.grey.shade300,
              label: 'Maj',
            ),
            const SizedBox(width: 4),
            _buildStrengthBar(
              width: itemWidth,
              color: _passwordStrength[1] == 1 ? Colors.green : Colors.grey.shade300,
              label: 'Min',
            ),
            const SizedBox(width: 4),
            _buildStrengthBar(
              width: itemWidth,
              color: _passwordStrength[2] == 1 ? Colors.green : Colors.grey.shade300,
              label: '123',
            ),
            const SizedBox(width: 4),
            _buildStrengthBar(
              width: itemWidth,
              color: _passwordStrength[3] == 1 ? Colors.green : Colors.grey.shade300,
              label: '!@#',
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          score < 2 ? 'Faible' : (score < 4 ? 'Moyen' : 'Fort'),
          style: TextStyle(
            fontSize: 12,
            color: score < 2 ? Colors.red : (score < 4 ? Colors.orange : Colors.green),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStrengthBar({required double width, required Color color, required String label}) {
    return Column(
      children: [
        Container(
          width: width,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9)),
      ],
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les mots de passe ne correspondent pas'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Vérifier la force du mot de passe
    if (_getPasswordStrengthScore() < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le mot de passe est trop faible. Utilisez au moins 3 types de caractères.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final email = _emailCtrl.text.trim().toLowerCase();
    final matricule = _matriculeCtrl.text.trim().toUpperCase();

    // Vérifier si l'email existe déjà
    if (HiveService.emailExists(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cet email est déjà utilisé'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Vérifier si le matricule existe déjà
    if (HiveService.matriculeExists(matricule)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ce matricule existe déjà'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Création avec mot de passe sécurisé
    final success = await HiveService.createUserWithSecurePassword(
      email: email,
      password: _passwordCtrl.text,
      nom: _nomCtrl.text.trim(),
      prenom: _prenomCtrl.text.trim(),
      matricule: matricule,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compte créé avec succès ! Connectez-vous.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la création du compte'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppTheme.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset("assets/images/logo.png", height: isSmallScreen ? 70 : 80),
                    const SizedBox(height: 16),
                    Text(
                      'Créer un compte',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 22 : 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkBlue,
                      ),
                    ),
                    const SizedBox(height: 32),
      
                    // Nom
                    TextFormField(
                      controller: _nomCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nom *',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
                    ),
                    const SizedBox(height: 16),
      
                    // Prénom
                    TextFormField(
                      controller: _prenomCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Prénom *',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
                    ),
                    const SizedBox(height: 16),
      
                    // Email
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                        hintText: 'exemple@domaine.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textCapitalization: TextCapitalization.none,
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'Requis';
                        if (!v!.contains('@') || !v.contains('.')) return 'Email invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
      
                    // Matricule
                    TextFormField(
                      controller: _matriculeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Matricule *',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                        hintText: 'Ex: VER001',
                        helperText: 'Identifiant unique de l\'entreprise',
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'Requis';
                        if ((v?.length ?? 0) < 3) return 'Min 3 caractères';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
      
                    // Mot de passe
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      onChanged: (value) {
                        _checkPasswordStrength(value);
                      },
                      decoration: InputDecoration(
                        labelText: 'Mot de passe *',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: const OutlineInputBorder(),
                        helperText: '8 caractères minimum',
                      ),
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'Requis';
                        if ((v?.length ?? 0) < 8) return 'Minimum 8 caractères';
                        return null;
                      },
                    ),
                    
                    // Indicateur de force du mot de passe
                    _buildPasswordStrengthIndicator(),
                    const SizedBox(height: 16),
      
                    // Confirmation mot de passe
                    TextFormField(
                      controller: _confirmPasswordCtrl,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirmer le mot de passe *',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'Requis';
                        if (v != _passwordCtrl.text) return 'Ne correspond pas';
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
      
                    // Bouton d'inscription
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('S\'inscrire', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 16),
      
                    // Lien vers login
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                      child: Text(
                        'Déjà un compte ? Se connecter',
                        style: TextStyle(color: AppTheme.primaryBlue),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}