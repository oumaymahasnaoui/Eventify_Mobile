import 'package:flutter/material.dart';
import 'database/database_helper.dart';

/// Quick script to fix the existing réclamation by linking it to user #1
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final dbHelper = DatabaseHelper();
  
  print('🔧 Fixing existing réclamation...');
  
  // Update réclamation #6 to link it to user #1 (Oumayma)
  final db = await dbHelper.database;
  
  final result = await db.update(
    'reclamations',
    {'userId': 1},
    where: 'id = ?',
    whereArgs: [6],
  );
  
  if (result > 0) {
    print('✅ Successfully linked réclamation #6 to user #1 (Oumayma Ben Ahmed)');
  } else {
    print('❌ Failed to update réclamation');
  }
  
  // Verify the update
  final reclamations = await dbHelper.getAllReclamations();
  print('\n📊 All réclamations:');
  for (final rec in reclamations) {
    final user = rec.userId != null ? await dbHelper.getUserById(rec.userId!) : null;
    print('  - Réclamation #${rec.id}: ${rec.title}');
    print('    User ID: ${rec.userId}');
    print('    User Name: ${user?.name ?? "No user"}');
  }
  
  print('\n✅ Fix complete! You can now close this and run the admin dashboard.');
}
