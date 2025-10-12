// lib/modules/auth/pages/signup_page.dart
import 'package:eventify/modules/auth/pages/verification_pending_page.dart'; import 'package:flutter/material.dart';
import 'login_page.dart';
import '../../../services/auth_service_verification.dart';
import '../../../models/user.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedBirthDate;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Dans _handleSignUp() - CORRECTION
  void _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorDialog('Les mots de passe ne correspondent pas');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newUser = User(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        joinDate: DateTime.now(),
        birthDate: _selectedBirthDate,
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        isActive: false, // ✅ IMPORTANT: false en attente de vérification
      );

      final authService = AuthServiceWithVerification();
      final result = await authService.registerWithVerification(newUser);

      setState(() => _isLoading = false);

      // Dans _handleSignUp - AJOUTER
      if (result['success'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationPendingPage(
              email: newUser.email,
              verificationToken: result['verificationToken'] ?? '',
              onResendEmail: () async {
                final resendResult = await authService.resendVerificationEmail(newUser.email);
                if (resendResult['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📧 Email renvoyé !'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  _showErrorDialog('Erreur: ${resendResult['message']}');
                }
              },
              isSimulatedMode: result['provider'] == 'Simulation', // ✅ NOUVEAU
            ),
          ),
        );
      }else {
        _showErrorDialog(result['message'] ?? 'Erreur inconnue');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Erreur: $e');
    }
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFCE1126),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFCE1126),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Erreur'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: Color(0xFFCE1126))),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(User user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Inscription Réussie !'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Votre compte a été créé avec succès !'),
                const SizedBox(height: 16),
                _buildUserInfo('🆔 ID', user.id?.toString() ?? 'N/A'),
                _buildUserInfo('👤 Nom', user.name),
                _buildUserInfo('📧 Email', user.email),
                _buildUserInfo('📞 Téléphone', user.phone),
                // ✅ CORRECTION: Conditions booléennes correctes
                if (user.birthDate != null) ...[
                  _buildUserInfo('🎂 Date de naissance',
                      '${user.birthDate!.day}/${user.birthDate!.month}/${user.birthDate!.year}'),
                ],
                if (user.age != null) ...[
                  _buildUserInfo('🎂 Âge', '${user.age} ans'),
                ],
                if (user.location != null) ...[
                  _buildUserInfo('📍 Localisation', user.location!),
                ],
                if (user.bio != null) ...[
                  _buildUserInfo('📝 Bio', user.bio!),
                ],
                _buildUserInfo('📅 Inscription', 'Il y a ${user.membershipDuration}'),
                const SizedBox(height: 10),
                const Text(
                  'Vous pouvez maintenant vous connecter et personnaliser votre profil.',
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: const Text('Se connecter', style: TextStyle(color: Color(0xFFCE1126))),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Format d\'email invalide';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un mot de passe';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit avoir au moins 6 caractères';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre numéro';
    }
    if (!RegExp(r'^\+?[\d\s-]{8,}$').hasMatch(value)) {
      return 'Numéro de téléphone invalide';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre nom';
    }
    if (value.length < 2) {
      return 'Le nom doit avoir au moins 2 caractères';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un compte Eventify'),
        backgroundColor: const Color(0xFFCE1126),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header avec icône
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCE1126).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1,
                    size: 40,
                    color: Color(0xFFCE1126),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Rejoignez Eventify',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                const Text(
                  'Créez votre profil et commencez à organiser des événements',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // Carte du formulaire
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        // Section Informations de base
                        const Row(
                          children: [
                            Icon(Icons.person_outline, color: Color(0xFFCE1126), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Informations de base',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Nom complet
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nom complet *',
                            hintText: 'Ex: Jean Dupont',
                            prefixIcon: Icon(Icons.person_outline, color: Color(0xFFCE1126)),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFCE1126)),
                            ),
                          ),
                          validator: _validateName,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),

                        // Email
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Adresse e-mail *',
                            hintText: 'exemple@eventify.com',
                            prefixIcon: Icon(Icons.email_outlined, color: Color(0xFFCE1126)),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFCE1126)),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),

                        // Téléphone
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Numéro de téléphone *',
                            hintText: 'Ex: +33 6 12 34 56 78',
                            prefixIcon: Icon(Icons.phone_outlined, color: Color(0xFFCE1126)),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFCE1126)),
                            ),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: _validatePhone,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),

                        // Date de naissance
                        InkWell(
                          onTap: _selectBirthDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date de naissance',
                              prefixIcon: Icon(Icons.cake_outlined, color: Color(0xFFCE1126)),
                              border: OutlineInputBorder(),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFFCE1126)),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedBirthDate == null
                                      ? 'Sélectionnez votre date de naissance'
                                      : '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}',
                                  style: TextStyle(
                                    color: _selectedBirthDate == null ? Colors.grey : Colors.black,
                                  ),
                                ),
                                Icon(
                                  Icons.calendar_today,
                                  color: _selectedBirthDate == null ? Colors.grey : const Color(0xFFCE1126),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section Informations supplémentaires
                        const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.grey, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Informations supplémentaires',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Localisation
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'Ville / Localisation',
                            hintText: 'Ex: Paris, France',
                            prefixIcon: Icon(Icons.location_on_outlined, color: Colors.grey),
                            border: OutlineInputBorder(),
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),

                        // Bio
                        TextFormField(
                          controller: _bioController,
                          decoration: const InputDecoration(
                            labelText: 'Bio / Description',
                            hintText: 'Parlez-nous de vous...',
                            prefixIcon: Icon(Icons.description_outlined, color: Colors.grey),
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 3,
                          maxLength: 200,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 20),

                        // Section Sécurité
                        const Row(
                          children: [
                            Icon(Icons.lock_outline, color: Color(0xFFCE1126), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Sécurité',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Mot de passe
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe *',
                            hintText: 'Au moins 6 caractères',
                            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFCE1126)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: const OutlineInputBorder(),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFCE1126)),
                            ),
                          ),
                          obscureText: _obscurePassword,
                          validator: _validatePassword,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),

                        // Confirmation mot de passe
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: InputDecoration(
                            labelText: 'Confirmer le mot de passe *',
                            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFCE1126)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                            border: const OutlineInputBorder(),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFCE1126)),
                            ),
                          ),
                          obscureText: _obscureConfirmPassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez confirmer votre mot de passe';
                            }
                            if (value != _passwordController.text) {
                              return 'Les mots de passe ne correspondent pas';
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: 30),

                        // Bouton d'inscription
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSignUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFCE1126),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              shadowColor: const Color(0xFFCE1126).withOpacity(0.3),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                                : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_add, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Créer mon compte Eventify',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Lien vers login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Déjà membre ?",
                      style: TextStyle(color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                        );
                      },
                      child: const Text(
                        "Se connecter",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFCE1126),
                        ),
                      ),
                    ),
                  ],
                ),

                // Conditions d'utilisation
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    'En créant un compte, vous acceptez nos conditions d\'utilisation',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}