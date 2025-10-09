import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        // Logo ou icône
        Icon(
          Icons.celebration_outlined,
          size: 80,
          color: Color(0xFFCE1126), // Rouge Tunisien
        ),
        SizedBox(height: 16),
        // Titre
        Text(
          'Eventify',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        // Sous-titre
        Text(
          'Organisez. Partager. Profitez.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}class EmailField extends StatelessWidget {
  const EmailField({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100, // Fond gris très clair
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Adresse e-mail',
          border: InputBorder.none, // Supprime la bordure par défaut
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          prefixIcon: const Icon(Icons.email_outlined),
        ),
        keyboardType: TextInputType.emailAddress,
      ),
    );
  }
}class LoginButton extends StatelessWidget {
  const LoginButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Logique de connexion
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFCE1126), // Rouge Tunisien
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Se connecter',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
