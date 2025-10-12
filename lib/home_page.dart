// lib/home_page.dart
import 'package:flutter/material.dart';
import './models/user.dart';
import 'package:eventify/modules/auth/pages/profile_page.dart';

class HomePage extends StatelessWidget {
  final User user;

  const HomePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Dans home_page.dart - Modifiez l'AppBar
      appBar: AppBar(
        title: const Text('Eventify - Accueil'),
        backgroundColor: const Color(0xFFCE1126),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(user: user),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de bienvenue
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFFCE1126),
                      child: Text(
                        user.name[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bonjour ${user.name} !',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Bienvenue sur votre compte Eventify',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Statistiques rapides
            const Text(
              'Votre activité',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildStatCard('Événements créés', '0', Icons.event),
                _buildStatCard('Participations', '0', Icons.people),
                _buildStatCard('Amis', '0', Icons.person),
                _buildStatCard('Badges', '0', Icons.emoji_events),
              ],
            ),

            const SizedBox(height: 20),

            // Actions rapides
            const Text(
              'Actions rapides',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.add, color: Color(0xFFCE1126)),
                  label: const Text('Créer un événement'),
                  onPressed: () {
                    // TODO: Naviguer vers création événement
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.search, color: Color(0xFFCE1126)),
                  label: const Text('Rechercher'),
                  onPressed: () {
                    // TODO: Naviguer vers recherche
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.person, color: Color(0xFFCE1126)),
                  label: const Text('Mon profil'),
                  onPressed: () {
                    // TODO: Naviguer vers profil
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFCE1126), size: 30),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}