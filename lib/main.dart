
import 'package:flutter/material.dart';
import 'package:eventify/database/database_helper.dart';
import 'package:eventify/modules/auth/pages/signup_page.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Réinitialiser la base pour corriger le schéma
  final dbHelper = DatabaseHelper();
  await dbHelper.createPasswordResetsTable();

  // 1. Afficher les infos actuelles
  await dbHelper.debugDatabaseInfo();

  // 2. Tester le système de hashage
  await dbHelper.testHashSystem();

  // 3. Forcer la migration si nécessaire
  await dbHelper.forcePasswordHashingMigration();
  // Afficher les infos de debug
  await dbHelper.getDatabasePath();
  await dbHelper.debugTableSchema();
  await dbHelper.debugAllUsers();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eventify',
      theme: ThemeData(
        primaryColor: Color(0xFFCE1126),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Color(0xFFCE1126),
          secondary: Color(0xFFCE1126),
        ),
      ),
      home: SignUpPage(), // ou votre page d'accueil
    );
  }
  final dbHelper = DatabaseHelper();

  // Afficher les infos de debug

}