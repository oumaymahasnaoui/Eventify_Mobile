import 'package:flutter/material.dart';
import 'database/database_helper.dart';
import 'models/reclamation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final dbHelper = DatabaseHelper();
  
  print('═══════════════════════════════════════');
  print('📋 VIEWING ALL RECLAMATIONS IN DATABASE');
  print('═══════════════════════════════════════\n');
  
  try {
    // Get database path
    final path = await dbHelper.getDatabasePath();
    print('📍 Database location: $path\n');
    
    // Get all reclamations
    final reclamations = await dbHelper.getAllReclamations();
    
    print('📊 Total reclamations: ${reclamations.length}\n');
    
    if (reclamations.isEmpty) {
      print('❌ No reclamations found in database!');
      print('💡 Create one using the ReclamationScreen first.\n');
    } else {
      print('─────────────────────────────────────\n');
      
      for (var i = 0; i < reclamations.length; i++) {
        final rec = reclamations[i];
        print('Reclamation #${i + 1}');
        print('─────────────────────────────────────');
        print('ID: ${rec.id}');
        print('Title: ${rec.title}');
        print('Description: ${rec.description}');
        print('Status: ${rec.statusText} (${rec.status})');
        print('Image: ${rec.imagePath ?? "No image"}');
        print('Created: ${rec.timeAgo}');
        print('Created at: ${rec.createdAt}');
        print('User ID: ${rec.userId ?? "None"}');
        print('─────────────────────────────────────\n');
      }
      
      // Get counts by status
      final pendingCount = await dbHelper.getReclamationsCountByStatus('pending');
      final inProgressCount = await dbHelper.getReclamationsCountByStatus('in_progress');
      final resolvedCount = await dbHelper.getReclamationsCountByStatus('resolved');
      final rejectedCount = await dbHelper.getReclamationsCountByStatus('rejected');
      
      print('📈 STATISTICS BY STATUS:');
      print('─────────────────────────────────────');
      print('🟠 Pending: $pendingCount');
      print('🔵 In Progress: $inProgressCount');
      print('🟢 Resolved: $resolvedCount');
      print('🔴 Rejected: $rejectedCount');
      print('─────────────────────────────────────\n');
    }
    
    print('✅ Database inspection complete!\n');
    print('To view in UI, run:');
    print('flutter run -t lib/reclamation_example.dart');
    print('Then click "Voir mes Réclamations"');
    
  } catch (e) {
    print('❌ ERROR: $e');
  }
}
