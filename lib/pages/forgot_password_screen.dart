// lib/pages/forgot_password_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';
import 'package:inspec_app/services/email_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  // Contrôleurs
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Animations
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // État
  int _currentStep = 0; // 0: email, 1: otp, 2: new password
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Timer OTP
  Timer? _resendTimer;
  int _resendSeconds = 0;
  bool _canResend = true;
  String? _generatedOtp;
  String? _userEmail;
  String? _userName;  // ✅ AJOUTÉ : stocker le nom de l'utilisateur

  // Gestion erreurs
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _resendTimer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ============================================================
  // 1. DEMANDE OTP
  // ============================================================

  Future<void> _requestOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim().toLowerCase();

    try {
      // Vérifier si l'email existe
      final user = HiveService.getUserByEmail(email);
      if (user == null) {
        setState(() {
          _errorMessage = 'Aucun compte associé à cet email';
          _isLoading = false;
        });
        return;
      }

      // Stocker le nom de l'utilisateur pour le renvoi
      _userName = '${user.prenom} ${user.nom}';

      // Générer OTP à 6 chiffres
      _generatedOtp = _generateOtp();
      _userEmail = email;

      // Envoyer OTP par email
      final emailSent = await EmailService.sendOtpEmail(
        toEmail: email,
        userName: _userName!,
        otpCode: _generatedOtp!,
      );

      if (!emailSent) {
        setState(() {
          _errorMessage = 'Erreur lors de l\'envoi de l\'email. Veuillez réessayer.';
          _isLoading = false;
        });
        return;
      }

      // Démarrer le timer
      _startResendTimer();

      // Passer à l'étape suivante
      setState(() {
        _currentStep = 1;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.email_outlined, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Code OTP envoyé à ${_maskEmail(email)}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Une erreur est survenue. Veuillez réessayer.';
        _isLoading = false;
      });
    }
  }

  String _generateOtp() {
    // Génère un code à 6 chiffres aléatoire
    final random = DateTime.now().millisecondsSinceEpoch % 1000000;
    return random.toString().padLeft(6, '0').substring(0, 6);
  }

  void _startResendTimer() {
    // ✅ ANNULER L'ANCIEN TIMER S'IL EXISTE
    _resendTimer?.cancel();
    
    _canResend = false;
    _resendSeconds = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _canResend = true;
            _resendSeconds = 0;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _resendSeconds--;
          });
        }
      }
    });
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final local = parts[0];
    if (local.length <= 3) return email;
    final masked = '${local.substring(0, 2)}***${local.substring(local.length - 2)}';
    return '$masked@${parts[1]}';
  }

  // ✅ MÉTHODE RENVOYER OTP CORRIGÉE
  Future<void> _resendOtp() async {
    if (!_canResend) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez patienter avant de renvoyer un code'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Vérifier que l'utilisateur existe toujours
      if (_userEmail == null) {
        setState(() {
          _errorMessage = 'Session expirée. Veuillez recommencer.';
          _isLoading = false;
        });
        return;
      }

      final user = HiveService.getUserByEmail(_userEmail!);
      if (user == null) {
        setState(() {
          _errorMessage = 'Utilisateur non trouvé';
          _isLoading = false;
        });
        return;
      }

      // Mettre à jour le nom de l'utilisateur
      _userName = '${user.prenom} ${user.nom}';

      // Générer un NOUVEAU code OTP
      _generatedOtp = _generateOtp();

      // Réinitialiser le contrôleur OTP pour éviter l'ancien code
      _otpController.clear();

      // Envoyer le nouveau code
      final emailSent = await EmailService.sendOtpEmail(
        toEmail: _userEmail!,
        userName: _userName!,
        otpCode: _generatedOtp!,
      );

      if (!mounted) return;

      if (emailSent) {
        // ✅ REDÉMARRER LE TIMER (CORRECTION IMPORTANTE)
        _startResendTimer();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nouveau code envoyé à ${_maskEmail(_userEmail!)}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        setState(() => _isLoading = false);
      } else {
        setState(() {
          _errorMessage = 'Erreur lors de l\'envoi. Veuillez réessayer.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erreur _resendOtp: $e');
      setState(() {
        _errorMessage = 'Une erreur est survenue. Veuillez réessayer.';
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // 2. VÉRIFICATION OTP
  // ============================================================

  void _verifyOtp() {
    final otp = _otpController.text.trim();

    if (otp.isEmpty) {
      setState(() => _errorMessage = 'Veuillez saisir le code OTP');
      return;
    }

    if (otp != _generatedOtp) {
      setState(() => _errorMessage = 'Code OTP invalide');
      return;
    }

    setState(() {
      _currentStep = 2;
      _errorMessage = null;
      _otpController.clear();
    });
  }

  // ============================================================
  // 3. RÉINITIALISATION MOT DE PASSE
  // ============================================================

  Future<void> _resetPassword() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password.isEmpty) {
      setState(() => _errorMessage = 'Veuillez saisir un mot de passe');
      return;
    }

    if (password.length < 8) {
      setState(() => _errorMessage = 'Le mot de passe doit contenir au moins 8 caractères');
      return;
    }

    if (password != confirmPassword) {
      setState(() => _errorMessage = 'Les mots de passe ne correspondent pas');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = HiveService.getUserByEmail(_userEmail!);
      if (user == null) {
        setState(() {
          _errorMessage = 'Utilisateur non trouvé';
          _isLoading = false;
        });
        return;
      }

      // Mettre à jour le mot de passe
      final success = await HiveService.updateUserPassword(
        email: _userEmail!,
        newPassword: password,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Mot de passe réinitialisé avec succès !'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        // Rediriger vers login
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors de la réinitialisation';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erreur _resetPassword: $e');
      setState(() {
        _errorMessage = 'Une erreur est survenue';
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _goBack() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _errorMessage = null;
      });
    } else {
      Navigator.pop(context);
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppTheme.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Image.asset(
                        'assets/images/logo.png',
                        height: isSmallScreen ? 80 : 100,
                      ),
                      const SizedBox(height: 16),

                      // Titre
                      Text(
                        _currentStep == 0
                            ? 'Mot de passe oublié ?'
                            : _currentStep == 1
                                ? 'Vérification'
                                : 'Nouveau mot de passe',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 22 : 26,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkBlue,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Sous-titre
                      Text(
                        _currentStep == 0
                            ? 'Entrez votre email pour recevoir un code'
                            : _currentStep == 1
                                ? 'Nous avons envoyé un code à votre email'
                                : 'Créez un nouveau mot de passe sécurisé',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 13 : 14,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // ÉTAPE 0 : Email
                      if (_currentStep == 0) ...[
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryBlue.withOpacity(0.05),
                                Colors.white,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: AppTheme.primaryBlue,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppTheme.primaryBlue,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: isSmallScreen ? 16 : 18,
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            textCapitalization: TextCapitalization.none,
                            autofocus: true,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Veuillez entrer votre email';
                              }
                              if (!value.contains('@') || !value.contains('.')) {
                                return 'Email invalide';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // ÉTAPE 1 : OTP
                      if (_currentStep == 1) ...[
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryBlue.withOpacity(0.05),
                                Colors.white,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextFormField(
                            controller: _otpController,
                            decoration: InputDecoration(
                              labelText: 'Code OTP',
                              prefixIcon: Icon(
                                Icons.security_outlined,
                                color: AppTheme.primaryBlue,
                              ),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_resendSeconds > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        '${_resendSeconds ~/ 60}:${(_resendSeconds % 60).toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ),
                                  if (_canResend && _resendSeconds == 0)
                                    TextButton(
                                      onPressed: _resendOtp,
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppTheme.primaryBlue,
                                      ),
                                      child: const Text('Renvoyer'),
                                    ),
                                ],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppTheme.primaryBlue,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: isSmallScreen ? 16 : 18,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              letterSpacing: 6,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Saisissez le code à 6 chiffres reçu par email',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // ÉTAPE 2 : Nouveau mot de passe
                      if (_currentStep == 2) ...[
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryBlue.withOpacity(0.05),
                                Colors.white,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Nouveau mot de passe',
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: AppTheme.primaryBlue,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppTheme.primaryBlue,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: isSmallScreen ? 16 : 18,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez saisir un mot de passe';
                              }
                              if (value.length < 8) {
                                return 'Minimum 8 caractères';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryBlue.withOpacity(0.05),
                                Colors.white,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Confirmer le mot de passe',
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: AppTheme.primaryBlue,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () => setState(
                                  () => _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppTheme.primaryBlue,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: isSmallScreen ? 16 : 18,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez confirmer le mot de passe';
                              }
                              if (value != _passwordController.text) {
                                return 'Les mots de passe ne correspondent pas';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Message d'erreur
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Bouton principal
                      SizedBox(
                        width: double.infinity,
                        height: isSmallScreen ? 50 : 55,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : _currentStep == 0
                                  ? _requestOtp
                                  : _currentStep == 1
                                      ? _verifyOtp
                                      : _resetPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 3,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  _currentStep == 0
                                      ? 'ENVOYER LE CODE'
                                      : _currentStep == 1
                                          ? 'VÉRIFIER LE CODE'
                                          : 'RÉINITIALISER LE MOT DE PASSE',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 15 : 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Bouton retour (sauf à l'étape 0)
                      if (_currentStep == 0)
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Retour à la connexion',
                            style: TextStyle(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 13 : 14,
                            ),
                          ),
                        )
                      else
                        TextButton(
                          onPressed: _goBack,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Étape précédente',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                  fontSize: isSmallScreen ? 13 : 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Indicateur d'étape
                      if (_currentStep >= 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (index) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: screenWidth * 0.05,
                              height: 3,
                              decoration: BoxDecoration(
                                color: _currentStep == index
                                    ? AppTheme.primaryBlue
                                    : (_currentStep > index
                                        ? Colors.green
                                        : Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}