import 'package:flutter/material.dart';
import '../models/reclamation_model.dart';

/// Simple chart showing réclamation statistics
class StatusChart extends StatelessWidget {
  final Map<ReclamationStatus, int> statistics;

  const StatusChart({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    final total = statistics.values.reduce((a, b) => a + b);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiques des Réclamations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Bar chart
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBar(
                  'En Attente',
                  statistics[ReclamationStatus.enAttente]!,
                  total,
                  Colors.orange,
                ),
                _buildBar(
                  'En Cours',
                  statistics[ReclamationStatus.enCours]!,
                  total,
                  Colors.blue,
                ),
                _buildBar(
                  'Résolues',
                  statistics[ReclamationStatus.resolue]!,
                  total,
                  Colors.green,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Legend
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _buildLegendItem(
                  'En Attente',
                  statistics[ReclamationStatus.enAttente]!,
                  Colors.orange,
                ),
                _buildLegendItem(
                  'En Cours',
                  statistics[ReclamationStatus.enCours]!,
                  Colors.blue,
                ),
                _buildLegendItem(
                  'Résolues',
                  statistics[ReclamationStatus.resolue]!,
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total * 100).round() : 0;
    final maxHeight = 200.0;
    final barHeight = total > 0 ? (count / total * maxHeight) : 0.0;

    return Expanded(
      child: Column(
        children: [
          // Value on top
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          
          // Percentage
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          
          // Bar
          Container(
            height: maxHeight,
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 60,
              height: barHeight,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Label
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Text(
          count.toString(),
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }
}
