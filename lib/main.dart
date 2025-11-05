import 'package:flutter/material.dart';
import 'database/database_helper.dart';
import 'modules/auth/pages/signup_page.dart';
import 'services/stripe_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Stripe
  await StripeService.init();

  // Initialiser la base de données
  final dbHelper = DatabaseHelper();
  await dbHelper.getDatabasePath();
  await dbHelper.debugTableSchema();
  await dbHelper.debugAllUsers();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eventify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFCE1126),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFFCE1126),
          secondary: const Color(0xFFCE1126),
        ),
      ),
      home: const SignUpPage(), // ou votre page d'accueil
    );
  }
}
