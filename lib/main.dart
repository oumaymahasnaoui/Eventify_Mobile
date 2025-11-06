import 'package:flutter/material.dart';
import 'database/database_helper.dart';
import 'modules/auth/pages/signup_page.dart';

void main() async {
  // Required when doing async work before runApp()
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the database (lightweight — does NOT print tables)
  await DatabaseHelper().database;

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eventify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFFCE1126),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Color(0xFFCE1126),
          secondary: Color(0xFFCE1126),
        ),
      ),
      home: SignUpPage(),
    );
  }
}
