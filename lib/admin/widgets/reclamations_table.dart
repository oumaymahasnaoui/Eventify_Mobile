import 'package:flutter/material.dart';
import '../models/reclamation_model.dart';

/// Table displaying all réclamations
class ReclamationsTable extends StatelessWidget {
  final List<ReclamationModel> reclamations;
  final Function(ReclamationModel) onView;
  final Function(int) onDelete;
  final bool isDesktop;

  const ReclamationsTable({
    super.key,
    required this.reclamations,
    required this.onView,
    required this.onDelete,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    if (reclamations.isEmpty) {
      return Card(
        elevation: 2,
        child: Container(
          padding: const EdgeInsets.all(48),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Aucune réclamation trouvée',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: isDesktop ? _buildDesktopTable() : _buildMobileList(),
    );
  }

  /// Build table for desktop
  Widget _buildDesktopTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
        columns: const [
          DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Utilisateur', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Sujet', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: reclamations.map((reclamation) {
          return DataRow(
            cells: [
              DataCell(Text('#${reclamation.id}')),
              DataCell(
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFFCE1126).withOpacity(0.1),
                      child: Text(
                        reclamation.userName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFFCE1126),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(reclamation.userName),
                  ],
                ),
              ),
              DataCell(
                Container(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(
                    reclamation.sujet,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(_buildStatusBadge(reclamation.statut)),
              DataCell(Text(_formatDate(reclamation.date))),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility, color: Colors.blue),
                      tooltip: 'Voir',
                      onPressed: () => onView(reclamation),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Supprimer',
                      onPressed: () => onDelete(reclamation.id),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// Build list for mobile/tablet
  Widget _buildMobileList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reclamations.length,
      itemBuilder: (context, index) {
        final reclamation = reclamations[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: _getStatusColor(reclamation.statut).withOpacity(0.2),
            child: Icon(
              _getStatusIcon(reclamation.statut),
              color: _getStatusColor(reclamation.statut),
            ),
          ),
          title: Text(
            reclamation.sujet,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(reclamation.userName),
              const SizedBox(height: 4),
              Text(
                _formatDate(reclamation.date),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          trailing: _buildStatusBadge(reclamation.statut),
          onTap: () => onView(reclamation),
        );
      },
    );
  }

  /// Build status badge
  Widget _buildStatusBadge(ReclamationStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Get status color
  Color _getStatusColor(ReclamationStatus status) {
    switch (status) {
      case ReclamationStatus.enAttente:
        return Colors.orange;
      case ReclamationStatus.enCours:
        return Colors.blue;
      case ReclamationStatus.resolue:
        return Colors.green;
    }
  }

  /// Get status icon
  IconData _getStatusIcon(ReclamationStatus status) {
    switch (status) {
      case ReclamationStatus.enAttente:
        return Icons.pending;
      case ReclamationStatus.enCours:
        return Icons.autorenew;
      case ReclamationStatus.resolue:
        return Icons.check_circle;
    }
  }

  /// Get status text
  String _getStatusText(ReclamationStatus status) {
    switch (status) {
      case ReclamationStatus.enAttente:
        return 'En Attente';
      case ReclamationStatus.enCours:
        return 'En Cours';
      case ReclamationStatus.resolue:
        return 'Résolue';
    }
  }

  /// Format date
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      // Format as DD/MM/YYYY
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      return '$day/$month/$year';
    }
  }
}
