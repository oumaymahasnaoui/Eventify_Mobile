import 'package:flutter/material.dart';
import 'package:eventify/models/user.dart';
import 'change_password_page.dart';

class EditProfilePage extends StatefulWidget {
  final User user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  DateTime? _selectedBirthDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialiser les contrôleurs avec les données actuelles
    _nameController.text = widget.user.name;
    _emailController.text = widget.user.email;
    _phoneController.text = widget.user.phone;
    _bioController.text = widget.user.bio ?? '';
    _locationController.text = widget.user.location ?? '';

    if (widget.user.birthDate != null) {
      _selectedBirthDate = widget.user.birthDate;
      _birthDateController.text = _formatDate(widget.user.birthDate!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateController.text = _formatDate(picked);
      });
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Simuler une sauvegarde
        await Future.delayed(const Duration(seconds: 2));

        // Créer l'utilisateur mis à jour
        final updatedUser = User(
          id: widget.user.id,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: widget.user.password,
          joinDate: widget.user.joinDate,
          birthDate: _selectedBirthDate,
          bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
          location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
          isActive: widget.user.isActive,
          isVerified: widget.user.isVerified,
          lastLogin: widget.user.lastLogin,
        );

        _showSuccessSnackbar('Profil mis à jour avec succès !');
        Navigator.pop(context, updatedUser);

      } catch (e) {
        _showErrorSnackbar('Erreur lors de la mise à jour du profil');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _navigateToChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangePasswordPage(user: widget.user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le Profil'),
        backgroundColor: const Color(0xFFCE1126),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
            tooltip: 'Sauvegarder',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFCE1126)),
            ),
            SizedBox(height: 16),
            Text('Sauvegarde en cours...'),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildSectionHeader('Informations Personnelles'),
              _buildTextField(
                controller: _nameController,
                label: 'Nom complet *',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le nom est obligatoire';
                  }
                  if (value.length < 2) {
                    return 'Le nom doit contenir au moins 2 caractères';
                  }
                  return null;
                },
              ),
              _buildTextField(
                controller: _emailController,
                label: 'Adresse email *',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'L\'email est obligatoire';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Format d\'email invalide';
                  }
                  return null;
                },
              ),
              _buildTextField(
                controller: _phoneController,
                label: 'Numéro de téléphone',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              _buildSectionHeader('Informations Supplémentaires'),
              _buildDateField(),
              _buildTextField(
                controller: _locationController,
                label: 'Ville / Localisation',
                icon: Icons.location_on,
                hintText: 'Ex: Tunis, Tunisie',
              ),
              _buildTextField(
                controller: _bioController,
                label: 'Bio / Description',
                icon: Icons.description,
                maxLines: 3,
                hintText: 'Décrivez-vous en quelques mots...',
              ),
              const SizedBox(height: 24),
              _buildChangePasswordButton(),
              const SizedBox(height: 32),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFFCE1126),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
    String? hintText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: Icon(icon, color: const Color(0xFFCE1126)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFCE1126)),
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDateField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _birthDateController,
        readOnly: true,
        onTap: _selectBirthDate,
        decoration: InputDecoration(
          labelText: 'Date de naissance',
          hintText: 'Sélectionnez votre date de naissance',
          prefixIcon: const Icon(Icons.cake, color: Color(0xFFCE1126)),
          suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFCE1126)),
          ),
        ),
      ),
    );
  }

  Widget _buildChangePasswordButton() {
    return Card(
      elevation: 2,
      child: ListTile(
        onTap: _navigateToChangePassword,
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock, color: Colors.blue),
        ),
        title: const Text(
          'Changer le mot de passe',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        subtitle: const Text(
          'Modifier votre mot de passe actuel',
          style: TextStyle(color: Colors.blue, fontSize: 12),
        ),
        trailing: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Annuler'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCE1126),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Sauvegarder'),
          ),
        ),
      ],
    );
  }
}