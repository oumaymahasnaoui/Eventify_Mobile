import 'package:eventify/models/user.dart';
import 'package:flutter/material.dart';
import 'modules/auth/pages/profile_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required User user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventify'),
        centerTitle: false,
        backgroundColor: const Color(0xFFCE1126),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                color: Color(0xFFCE1126),
                size: 20,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WelcomeSection(),
            SizedBox(height: 24),
            _QuickActionsSection(),
            SizedBox(height: 24),
            _RecentEventsSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Create new event
        },
        backgroundColor: const Color(0xFFCE1126),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _WelcomeSection extends StatelessWidget {
  const _WelcomeSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFCE1126), Color(0xFF007A3D)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bienvenue !',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Organisez votre prochain événement entre amis',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions rapides',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildActionCard(
              icon: Icons.add_circle_outline,
              title: 'Créer un événement',
              color: const Color(0xFFCE1126),
              onTap: () {},
            ),
            _buildActionCard(
              icon: Icons.group,
              title: 'Mes groupes',
              color: Colors.blue,
              onTap: () {},
            ),
            _buildActionCard(
              icon: Icons.photo_album,
              title: 'Albums photos',
              color: Colors.green,
              onTap: () {},
            ),
            _buildActionCard(
              icon: Icons.attach_money,
              title: 'Dépenses',
              color: Colors.orange,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  static Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentEventsSection extends StatelessWidget {
  const _RecentEventsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Événements récents',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _EventCard(
          title: 'Weekend à la montagne',
          date: '15-17 Nov 2024',
          participants: 8,
        ),
        _EventCard(
          title: 'Soirée jeux',
          date: '25 Nov 2024',
          participants: 6,
        ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  final String title;
  final String date;
  final int participants;

  const _EventCard({
    required this.title,
    required this.date,
    required this.participants,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFCE1126).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.celebration_outlined,
                color: Color(0xFFCE1126),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$participants participants',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: () {
                // TODO: Navigate to event details
              },
            ),
          ],
        ),
      ),
    );
  }
}