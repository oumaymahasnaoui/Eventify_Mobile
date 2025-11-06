import 'package:flutter/material.dart';
import 'examples/profanity_filter_demo.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification service
  await NotificationService().initialize();
  
  runApp(const ProfanityFilterTestApp());
}

class ProfanityFilterTestApp extends StatelessWidget {
  const ProfanityFilterTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Profanity Filter',
      theme: ThemeData(
        primaryColor: const Color(0xFFCE1126),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFFCE1126),
        ),
      ),
      home: const ProfanityFilterDemo(),
    );
  }
}
