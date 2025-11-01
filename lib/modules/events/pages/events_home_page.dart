// lib/modules/events/pages/events_home_page.dart - CORRECTION
import 'package:flutter/material.dart';
import '../../../../models/event.dart';
import '../../../../services/event_service.dart';
import '../../../../utils/categories.dart';
import '../widgets/event_carousel.dart';
import '../widgets/category_filter.dart';
import 'create_event_page.dart';
import 'event_details_page.dart';
import 'edit_event_page.dart';
class EventsHomePage extends StatefulWidget {
  final int currentUserId;

  const EventsHomePage({Key? key, required this.currentUserId}) : super(key: key);

  @override
  _EventsHomePageState createState() => _EventsHomePageState();
}

class _EventsHomePageState extends State<EventsHomePage> {
  final EventService _eventService = EventService();
  List<Event> _allEvents = [];
  String _selectedCategory = 'Toutes';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print("🔍 DEBUG - Current User ID reçu: ${widget.currentUserId}"); // AJOUTEZ CE LOG

    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      print("🔄 Chargement des événements...");
      final events = await _eventService.getEvents();
      print("✅ Événements chargés: ${events.length}");

      setState(() {
        _allEvents = events;
        _isLoading = false;
      });
    } catch (e) {
      print("❌ Erreur chargement événements: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement: $e')),
      );
    }
  }

  List<Event> get _filteredEvents {
    if (_selectedCategory == 'Toutes') {
      return _allEvents;
    }
    return _allEvents
        .where((event) => event.category == _selectedCategory)
        .toList();
  }

  Map<String, List<Event>> get _eventsByCategory {
    Map<String, List<Event>> categorized = {};

    for (var category in EventCategories.categories) {
      categorized[category] =
          _allEvents.where((event) => event.category == category).toList();
    }

    categorized.removeWhere((key, value) => value.isEmpty);
    return categorized;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mes Événements'),
        backgroundColor: Color(0xFFCE1126),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadEvents, // Bouton de rafraîchissement manuel
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _allEvents.isEmpty
          ? _buildEmptyState()
          : _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateEvent,
        child: Icon(Icons.add),
        backgroundColor: Color(0xFFCE1126),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event, size: 80, color: Colors.grey[300]),
          SizedBox(height: 20),
          Text(
            'Aucun événement créé',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 10),
          ElevatedButton.icon(
            icon: Icon(Icons.add),
            label: Text('Créer un événement'),
            onPressed: _navigateToCreateEvent,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFCE1126),
              foregroundColor: Colors.white,
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            icon: Icon(Icons.refresh),
            label: Text('Rafraîchir'),
            onPressed: _loadEvents,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Header avec compteur
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_allEvents.length} événement(s)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: _loadEvents,
                tooltip: 'Rafraîchir',
              ),
            ],
          ),
        ),

        // Filtre par catégorie
        CategoryFilter(
          selectedCategory: _selectedCategory,
          onCategoryChanged: (category) {
            setState(() {
              _selectedCategory = category;
            });
          },
        ),

        Expanded(
          child: _selectedCategory == 'Toutes'
              ? _buildCarouselByCategory()
              : _buildListByCategory(),
        ),
      ],
    );
  }

  Widget _buildCarouselByCategory() {
    final categorizedEvents = _eventsByCategory;

    if (categorizedEvents.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadEvents, // Pull to refresh
      child: ListView.builder(
        itemCount: categorizedEvents.length,
        itemBuilder: (context, index) {
          final category = categorizedEvents.keys.elementAt(index);
          final events = categorizedEvents[category]!;

          return EventCarousel(
            category: category,
            events: events,
            currentUserId: widget.currentUserId, // AJOUTÉ
            onEventTap: _navigateToEventDetails,
            onEditEvent: _navigateToEditEvent,
          );
        },
      ),
    );
  }

  Widget _buildListByCategory() {
    if (_filteredEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 60, color: Colors.grey[300]),
            SizedBox(height: 16),
            Text(
              'Aucun événement dans cette catégorie',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text('Rafraîchir'),
              onPressed: _loadEvents,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents, // Pull to refresh
      child: ListView.builder(
        itemCount: _filteredEvents.length,
        itemBuilder: (context, index) {
          final event = _filteredEvents[index];
          return _buildEventCard(event);
        },
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(event.category),
          child: Text(
            EventCategories.categoryIcons[event.category] ?? '📅',
            style: TextStyle(fontSize: 16),
          ),
        ),
        title: Text(
          event.title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_formatDate(event.date)} - ${event.location}'),
            Text(
              event.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _navigateToEventDetails(event),
      ),
    );
  }

  void _navigateToCreateEvent() async {
    print("🔧 Navigation vers CreateEventPage...");

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CreateEventPage(currentUserId: widget.currentUserId),
      ),
    );

    // ✅ CORRECTION : Recharger les événements après création
    if (result == true) {
      print("✅ Événement créé, rechargement de la liste...");
      _loadEvents(); // C'EST CE QUI MANQUAIT !
    } else {
      print("❌ Création annulée ou échouée");
    }
  }

  void _navigateToEventDetails(Event event) {
    print("🔍 Navigation vers détails de: ${event.title}");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EventDetailsPage(
              event: event,
              currentUserId: widget.currentUserId,
            ),
      ),
    ).then((refreshed) {
      // Rafraîchir la liste si un événement a été modifié/supprimé
      if (refreshed == true) {
        print("🔄 Rafraîchissement de la liste après retour des détails");
        _loadEvents();
      }
    });
  }

// Ajoutez cette méthode pour l'édition
  void _navigateToEditEvent(Event event) {
    print("✏️ Navigation vers modification de: ${event.title}");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditEventPage(
              event: event,
              currentUserId: widget.currentUserId,
            ),
      ),
    ).then((result) {
      if (result == true) {
        print("✅ Événement modifié, rafraîchissement...");
        _loadEvents();
      }
    });
  }



  Color _getCategoryColor(String category) {
    final colors = {
      'Anniversaire': Colors.pink,
      'Réunion professionnelle': Colors.blue,
      'Conférence': Colors.purple,
      'Soirée': Colors.orange,
      'Mariage': Colors.red,
      'Sport': Colors.green,
      'Culture': Colors.amber,
      'Éducation': Colors.indigo,
      'Autre': Colors.grey,
    };
    return colors[category] ?? Colors.blue;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}