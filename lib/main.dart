import 'package:flutter/material.dart';
import 'database/database_helper.dart';
import 'modules/auth/pages/signup_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Réinitialiser la base pour corriger le schéma
  final dbHelper = DatabaseHelper();


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