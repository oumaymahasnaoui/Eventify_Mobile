import 'package:flutter/material.dart';
import '../../../models/reservation.dart';
import '../../../database/database_helper.dart';

class ReservationStatisticsPage extends StatefulWidget {
  final int userId;

  const ReservationStatisticsPage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<ReservationStatisticsPage> createState() => _ReservationStatisticsPageState();
}

class _ReservationStatisticsPageState extends State<ReservationStatisticsPage> {
  final _dbHelper = DatabaseHelper();
  Map<String, int> _stats = {};
  List<Reservation> _reservations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await _dbHelper.getUserReservationStats(widget.userId);
      final reservations = await _dbHelper.getUserReservations(widget.userId);

      setState(() {
        _stats = stats;
        _reservations = reservations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double get _confirmationRate {
    final total = _stats['total'] ?? 0;
    if (total == 0) return 0;
    final confirmed = _stats['confirmed'] ?? 0;
    return (confirmed / total) * 100;
  }

  double get _cancellationRate {
    final total = _stats['total'] ?? 0;
    if (total == 0) return 0;
    final cancelled = _stats['cancelled'] ?? 0;
    return (cancelled / total) * 100;
  }

  int get _totalPeople {
    return _reservations.fold(0, (sum, reservation) => sum + reservation.numberOfPeople);
  }

  double get _averagePeople {
    if (_reservations.isEmpty) return 0;
    return _totalPeople / _reservations.length;
  }

  Map<String, int> get _reservationsByMonth {
    final Map<String, int> monthCount = {};
    
    for (var reservation in _reservations) {
      final month = '${reservation.reservationDate.month}/${reservation.reservationDate.year}';
      monthCount[month] = (monthCount[month] ?? 0) + 1;
    }
    
    return monthCount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques des réservations'),
        backgroundColor: const Color(0xFFCE1126),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vue d'ensemble
                    _buildSectionTitle('Vue d\'ensemble', Icons.dashboard),
                    const SizedBox(height: 12),
                    _buildOverviewCards(),
                    
                    const SizedBox(height: 24),
                    
                    // Statistiques par statut
                    _buildSectionTitle('Répartition par statut', Icons.pie_chart),
                    const SizedBox(height: 12),
                    _buildStatusDistribution(),
                    
                    const SizedBox(height: 24),
                    
                    // Taux et pourcentages
                    _buildSectionTitle('Taux de performance', Icons.trending_up),
                    const SizedBox(height: 12),
                    _buildRatesCards(),
                    
                    const SizedBox(height: 24),
                    
                    // Statistiques de participants
                    _buildSectionTitle('Participants', Icons.groups),
                    const SizedBox(height: 12),
                    _buildPeopleStats(),
                    
                    const SizedBox(height: 24),
                    
                    // Activité mensuelle
                    if (_reservationsByMonth.isNotEmpty) ...[
                      _buildSectionTitle('Activité mensuelle', Icons.calendar_month),
                      const SizedBox(height: 12),
                      _buildMonthlyActivity(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFCE1126)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCards() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Total',
            (_stats['total'] ?? 0).toString(),
            Icons.bookmark,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Participants',
            _totalPeople.toString(),
            Icons.people,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDistribution() {
    final total = _stats['total'] ?? 0;
    final pending = _stats['pending'] ?? 0;
    final confirmed = _stats['confirmed'] ?? 0;
    final cancelled = _stats['cancelled'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildStatusBar(pending, confirmed, cancelled, total),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusLegend('En attente', pending, Colors.orange),
              _buildStatusLegend('Confirmées', confirmed, Colors.green),
              _buildStatusLegend('Annulées', cancelled, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(int pending, int confirmed, int cancelled, int total) {
    if (total == 0) {
      return Container(
        height: 30,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Center(
          child: Text(
            'Aucune donnée',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      height: 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Row(
          children: [
            if (pending > 0)
              Expanded(
                flex: pending,
                child: Container(color: Colors.orange),
              ),
            if (confirmed > 0)
              Expanded(
                flex: confirmed,
                child: Container(color: Colors.green),
              ),
            if (cancelled > 0)
              Expanded(
                flex: cancelled,
                child: Container(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusLegend(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildRatesCards() {
    return Column(
      children: [
        _buildRateCard(
          'Taux de confirmation',
          _confirmationRate,
          Colors.green,
          Icons.check_circle,
        ),
        const SizedBox(height: 12),
        _buildRateCard(
          'Taux d\'annulation',
          _cancellationRate,
          Colors.red,
          Icons.cancel,
        ),
      ],
    );
  }

  Widget _buildRateCard(String title, double percentage, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(
                      value: percentage / 100,
                      strokeWidth: 6,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeopleStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPeopleMetric(
              'Total',
              _totalPeople.toString(),
              Icons.groups,
              Colors.purple,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.grey[300],
          ),
          Expanded(
            child: _buildPeopleMetric(
              'Moyenne',
              _averagePeople.toStringAsFixed(1),
              Icons.person,
              Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeopleMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyActivity() {
    final sortedMonths = _reservationsByMonth.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: sortedMonths.map((entry) {
          final parts = entry.key.split('/');
          final month = _getMonthName(int.parse(parts[0]));
          final year = parts[1];
          final count = entry.value;
          final maxCount = sortedMonths.map((e) => e.value).reduce((a, b) => a > b ? a : b);
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    '$month $year',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: count / maxCount,
                        child: Container(
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCE1126),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 30,
                  child: Text(
                    count.toString(),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return months[month - 1];
  }
}
