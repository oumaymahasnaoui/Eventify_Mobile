import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:eventify/models/user.dart';
import 'package:eventify/services/auth_service.dart';
import 'package:eventify/modules/auth/pages/login_page.dart';
import 'package:eventify/modules/auth/pages/edit_profile_page.dart';
import 'package:eventify/modules/auth/pages/change_password_page.dart';

class ProfilePage extends StatefulWidget {
  final User user;

  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();
  File? _profileImage;
  int _selectedIndex = 0;
  bool _isLoading = false;

  // Données simulées pour les statistiques
  final Map<String, dynamic> _userStats = {
    'friends': 42,
    'events': 15,
    'groups': 5,
    'badges': 8,
  };

  // Badges de l'utilisateur
  final List<Map<String, dynamic>> _userBadges = [
    {'name': 'Explorateur', 'icon': Icons.explore, 'color': Colors.blue, 'unlocked': true},
    {'name': 'Social', 'icon': Icons.people, 'color': Colors.green, 'unlocked': true},
    {'name': 'Organisateur', 'icon': Icons.event, 'color': Colors.orange, 'unlocked': true},
    {'name': 'VIP', 'icon': Icons.star, 'color': Colors.purple, 'unlocked': false},
    {'name': 'Voyageur', 'icon': Icons.flight, 'color': Colors.red, 'unlocked': false},
  ];

  // 🔥 MÉTHODE POUR CHOISIR UNE PHOTO
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });

        _showSuccessSnackbar('Photo de profil mise à jour !');
      }
    } catch (e) {
      _showErrorSnackbar('Erreur lors de la sélection de la photo');
    }
  }

  // 🔥 MÉTHODE POUR PRENDRE UNE PHOTO AVEC LA CAMÉRA
  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });

        _showSuccessSnackbar('Photo prise avec succès !');
      }
    } catch (e) {
      _showErrorSnackbar('Erreur avec la caméra');
    }
  }

  // 🔥 MÉTHODE POUR DÉCONNEXION
  Future<void> _signOut() async {
    final bool confirm = await _showLogoutDialog();

    if (confirm) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _authService.signOut();

        // ✅ NAVIGATION VERS LOGIN AVEC IMPORT CORRECT
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackbar('Erreur lors de la déconnexion');
      }
    }
  }

  // 🔥 DIALOGUE DE CONFIRMATION DÉCONNEXION
  Future<bool> _showLogoutDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 8),
              Text('Déconnexion'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
              SizedBox(height: 8),
              Text(
                'Vous devrez vous reconnecter pour accéder à votre compte.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Déconnexion'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // 🔥 DIALOGUE CHOIX PHOTO
  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Changer la photo de profil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Galerie'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text('Caméra'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );
  }

  // MÉTHODES POUR LES SNACKBARS
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

  // 🔥 MÉTHODE UNIQUE _editProfile
  void _editProfile() async {
    final updatedUser = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(user: widget.user),
      ),
    );

    if (updatedUser != null && updatedUser is User) {
      // Mettre à jour l'interface si nécessaire
      setState(() {
        // Les données sont mises à jour via le callback
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: const Color(0xFFCE1126),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _goToSettings,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Déconnexion',
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
            Text('Déconnexion en cours...'),
          ],
        ),
      )
          : Column(
        children: [
          _buildProfileHeader(),
          _buildTabNavigation(),
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFCE1126), Color(0xFFE63946)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: _showImagePickerDialog,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _profileImage != null
                        ? Image.file(
                      _profileImage!,
                      fit: BoxFit.cover,
                      width: 120,
                      height: 120,
                    )
                        : Container(
                      color: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: GestureDetector(
                  onTap: _showImagePickerDialog,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFCE1126),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showImagePickerDialog,
                    borderRadius: BorderRadius.circular(60),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(60),
                        color: Colors.black.withOpacity(0.1),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.user.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.user.email,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                'Membre depuis ${_formatJoinDate(widget.user.joinDate)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _editProfile,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Modifier le profil'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabNavigation() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTabItem(0, Icons.bar_chart, 'Statistiques'),
          _buildTabItem(1, Icons.emoji_events, 'Badges'),
          _buildTabItem(2, Icons.history, 'Activité'),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedIndex = index),
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFCE1126).withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? const Color(0xFFCE1126) : Colors.grey,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? const Color(0xFFCE1126) : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildStatisticsTab();
      case 1:
        return _buildBadgesTab();
      case 2:
        return _buildActivityTab();
      default:
        return _buildStatisticsTab();
    }
  }

  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildStatCard('Amis', _userStats['friends'], Icons.people, Colors.blue),
              _buildStatCard('Événements', _userStats['events'], Icons.event, Colors.green),
              _buildStatCard('Groupes', _userStats['groups'], Icons.group, Colors.orange),
              _buildStatCard('Badges', _userStats['badges'], Icons.emoji_events, Colors.purple),
            ],
          ),
          const SizedBox(height: 24),
          _buildSignOutCard(),
          const SizedBox(height: 24),
          _buildMonthlyProgress(),
          const SizedBox(height: 24),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildSignOutCard() {
    return Card(
      color: Colors.red.withOpacity(0.05),
      child: ListTile(
        onTap: _signOut,
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.logout, color: Colors.red),
        ),
        title: const Text(
          'Déconnexion',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: const Text(
          'Se déconnecter de votre compte',
          style: TextStyle(color: Colors.red, fontSize: 12),
        ),
        trailing: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progression du mois',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: 0.7,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFCE1126)),
            borderRadius: BorderRadius.circular(10),
            minHeight: 12,
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '70% complété',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                '7/10 objectifs',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actions rapides',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.person_add, size: 18),
                label: const Text('Ajouter un ami'),
                onPressed: _addFriend,
              ),
              ActionChip(
                avatar: const Icon(Icons.event, size: 18),
                label: const Text('Créer événement'),
                onPressed: _createEvent,
              ),
              ActionChip(
                avatar: const Icon(Icons.share, size: 18),
                label: const Text('Partager profil'),
                onPressed: _shareProfile,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mes Badges',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Débloquez des badges en utilisant Eventify',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: _userBadges.length,
            itemBuilder: (context, index) {
              final badge = _userBadges[index];
              return _buildBadgeItem(badge);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(Map<String, dynamic> badge) {
    final isUnlocked = badge['unlocked'] as bool;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? (badge['color'] as Color).withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              badge['icon'] as IconData,
              color: isUnlocked ? badge['color'] as Color : Colors.grey,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            badge['name'] as String,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isUnlocked ? Colors.black87 : Colors.grey,
            ),
          ),
          if (!isUnlocked) ...[
            const SizedBox(height: 4),
            const Icon(Icons.lock, size: 12, color: Colors.grey),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    final List<Map<String, dynamic>> activities = [
      {
        'type': 'event',
        'title': 'Vous avez créé un événement',
        'time': 'Il y a 2 heures',
        'icon': Icons.event
      },
      {
        'type': 'friend',
        'title': 'Nouvel ami ajouté',
        'time': 'Il y a 1 jour',
        'icon': Icons.person_add
      },
      {
        'type': 'group',
        'title': 'Vous avez rejoint un groupe',
        'time': 'Il y a 3 jours',
        'icon': Icons.group
      },
      {
        'type': 'badge',
        'title': 'Nouveau badge débloqué',
        'time': 'Il y a 1 semaine',
        'icon': Icons.emoji_events
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFCE1126).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                activity['icon'] as IconData,
                color: const Color(0xFFCE1126),
                size: 20,
              ),
            ),
            title: Text(
              activity['title'] as String,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              activity['time'] as String,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ),
        );
      },
    );
  }

  String _formatJoinDate(DateTime joinDate) {
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${months[joinDate.month - 1]} ${joinDate.year}';
  }

  // Méthodes vides pour les fonctionnalités non implémentées
  void _goToSettings() {}
  void _addFriend() {}
  void _createEvent() {}
  void _shareProfile() {}
}