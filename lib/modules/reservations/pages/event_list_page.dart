import 'package:flutter/material.dart';
import '../../../models/event.dart';
import 'create_reservation_page.dart';

class EventListPage extends StatefulWidget {
  final int userId;

  const EventListPage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  // Liste d'événements de démonstration
  final List<Event> _events = [
    Event(
      id: 1,
      title: 'Concert Jazz sous les étoiles',
      date: DateTime(2025, 11, 15, 20, 0),
      location: 'Théâtre Municipal, Tunis',
      description: 'Une soirée magique avec les meilleurs artistes de jazz tunisiens.',
      category: 'Musique',
      latitude: 36.8065,
      longitude: 10.1815,
      participants: [1, 2, 3],
      price: 35.00,
      createdBy: 1,
      createdAt: DateTime.now(),
      maxParticipants: 20,
    ),
    Event(
      id: 2,
      title: 'Festival de Gastronomie',
      date: DateTime(2025, 11, 20, 18, 0),
      location: 'Marina de Sousse',
      description: 'Découvrez les saveurs de la cuisine méditerranéenne.',
      category: 'Gastronomie',
      latitude: 35.8256,
      longitude: 10.6369,
      participants: [1, 4, 5],
      price: 50.00,
      createdBy: 1,
      createdAt: DateTime.now(),
      maxParticipants: 20,
    ),
    Event(
      id: 3,
      title: 'Marathon de Carthage',
      date: DateTime(2025, 12, 1, 7, 0),
      location: 'Site archéologique de Carthage',
      description: 'Course de 21km à travers les ruines historiques.',
      category: 'Sport',
      latitude: 36.8531,
      longitude: 10.3231,
      participants: [2, 3, 6],
      price: 25.00,
      createdBy: 2,
      createdAt: DateTime.now(),
      maxParticipants: 30,
    ),
    Event(
      id: 4,
      title: 'Exposition d\'Art Contemporain',
      date: DateTime(2025, 11, 25, 10, 0),
      location: 'Galerie El Marsa, La Marsa',
      description: 'Œuvres d\'artistes tunisiens et internationaux.',
      category: 'Culture',
      latitude: 36.8785,
      longitude: 10.3251,
      participants: [1],
      price: 15.00,
      createdBy: 1,
      createdAt: DateTime.now(),
      maxParticipants: 40,
    ),
    Event(
      id: 5,
      title: 'Conférence Tech & Innovation',
      date: DateTime(2025, 12, 5, 9, 0),
      location: 'Centre de Conférences, Lac 2',
      description: 'Les dernières tendances en technologie et innovation.',
      category: 'Technologie',
      latitude: 36.8417,
      longitude: 10.2356,
      participants: [3, 5, 7],
      price: 40.00,
      createdBy: 2,
      createdAt: DateTime.now(),
      maxParticipants: 40,
    ),
  ];

  String _selectedCategory = 'Tous';
  final List<String> _categories = [
    'Tous',
    'Musique',
    'Gastronomie',
    'Sport',
    'Culture',
    'Technologie',
  ];

  List<Event> get _filteredEvents {
    if (_selectedCategory == 'Tous') {
      return _events;
    }
    return _events.where((e) => e.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Événements disponibles'),
        backgroundColor: const Color(0xFFCE1126),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filtres par catégorie
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: const Color(0xFFCE1126),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          // Liste des événements
          Expanded(
            child: _filteredEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun événement dans cette catégorie',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredEvents.length,
                    itemBuilder: (context, index) {
                      final event = _filteredEvents[index];
                      return _buildEventCard(event);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateReservationPage(
                event: event,
                userId: widget.userId,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(event.category),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      event.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${event.participants.length}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(event.date),
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.location,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                event.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCE1126).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.euro, size: 16, color: Color(0xFFCE1126)),
                        const SizedBox(width: 4),
                        Text(
                          '${event.price.toStringAsFixed(2)}€',
                          style: const TextStyle(
                            color: Color(0xFFCE1126),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Text(
                          ' / pers',
                          style: TextStyle(
                            color: Color(0xFFCE1126),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateReservationPage(
                            event: event,
                            userId: widget.userId,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCE1126),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.bookmark_add, size: 18),
                    label: const Text('Réserver'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Musique':
        return Colors.purple;
      case 'Gastronomie':
        return Colors.orange;
      case 'Sport':
        return Colors.green;
      case 'Culture':
        return Colors.blue;
      case 'Technologie':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year} à ${date.hour}h${date.minute.toString().padLeft(2, '0')}';
  }
}
