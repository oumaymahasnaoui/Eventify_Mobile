// lib/modules/events/pages/event_details_page.dart
import 'package:flutter/material.dart';
import '../../../../models/event.dart';
import '../../../../models/user.dart';
import '../../../../services/event_service.dart';
import '../../../../services/user_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../utils/categories.dart';
import 'edit_event_page.dart';

class EventDetailsPage extends StatefulWidget {
  final Event event;
  final int currentUserId;

  const EventDetailsPage({
    Key? key,
    required this.event,
    required this.currentUserId,
  }) : super(key: key);

  @override
  _EventDetailsPageState createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  final EventService _eventService = EventService();
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  late Event _event;
  List<User> _participants = [];
  bool _isLoading = true;
  User? _creator;
  User? _currentUser;
  bool _isJoining = false;
  bool _isLeaving = false;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Charger les participants
      final participants = await _userService.getUsersByIds(_event.participants);

      // Trouver le créateur
      final creator = await _userService.getUser(_event.createdBy);

      setState(() {
        _participants = participants;
        _creator = creator;
        _isLoading = false;
      });
    } catch (e) {
      print("❌ Erreur chargement données: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool get _isCreator => _event.createdBy == widget.currentUserId;
  bool get _isParticipating => _event.participants.contains(widget.currentUserId);
  bool get _canJoin => !_isCreator && !_isParticipating && _event.date.isAfter(DateTime.now());
  bool get _canLeave => !_isCreator && _isParticipating && _event.date.isAfter(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails de l\'événement'),
        backgroundColor: Color(0xFFCE1126),
        foregroundColor: Colors.white,
        actions: [
          if (_isCreator)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') _navigateToEdit();
                if (value == 'delete') _confirmDelete();
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'edit', child: Text('Modifier')),
                PopupMenuItem(value: 'delete', child: Text('Supprimer')),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec titre et catégorie
          _buildEventHeader(),
          SizedBox(height: 24),

          // Informations de base
          _buildEventInfo(),
          SizedBox(height: 24),

          // Description
          _buildDescription(),
          SizedBox(height: 24),

          // Participants
          _buildParticipantsSection(),
          SizedBox(height: 24),

          // Actions
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildEventHeader() {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: _getCategoryColor(_event.category),
          radius: 30,
          child: Text(
            EventCategories.categoryIcons[_event.category] ?? '📅',
            style: TextStyle(fontSize: 24),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _event.title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                _event.category,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventInfo() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow(Icons.calendar_today, 'Date',
                '${_formatDate(_event.date)}'),
            SizedBox(height: 12),
            _buildInfoRow(Icons.location_on, 'Lieu', _event.location),
            SizedBox(height: 12),
            _buildInfoRow(Icons.person, 'Créé par',
                _creator?.name ?? 'Utilisateur inconnu'),
            SizedBox(height: 12),
            _buildInfoRow(Icons.people, 'Participants',
                '${_participants.length} personne(s)'),
            if (_event.maxParticipants > 0) ...[
              SizedBox(height: 12),
              _buildInfoRow(Icons.group, 'Limite participants',
                  '${_participants.length}/${_event.maxParticipants}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              _event.description,
              style: TextStyle(fontSize: 16, height: 1.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Participants (${_participants.length})',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_participants.isNotEmpty)
              IconButton(
                icon: Icon(Icons.list),
                onPressed: _showParticipantsList,
                tooltip: 'Voir tous les participants',
              ),
          ],
        ),
        SizedBox(height: 12),
        _participants.isEmpty
            ? Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Aucun participant pour le moment',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        )
            : _buildParticipantsGrid(),
      ],
    );
  }

  Widget _buildParticipantsGrid() {
    final displayedParticipants = _participants.length > 6
        ? _participants.sublist(0, 6)
        : _participants;

    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: displayedParticipants.map((user) => Chip(
            avatar: CircleAvatar(
              backgroundColor: _getUserColor(user),
              child: Text(
                user.name.substring(0, 1).toUpperCase(),
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            label: Text(
              user.name,
              style: TextStyle(fontSize: 12),
            ),
            backgroundColor: Colors.grey[100],
          )).toList(),
        ),
        if (_participants.length > 6) ...[
          SizedBox(height: 8),
          TextButton(
            onPressed: _showParticipantsList,
            child: Text('+ ${_participants.length - 6} autres participants'),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    // Si l'événement est complet et l'utilisateur ne participe pas
    if (_event.isFull && !_isParticipating) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'Événement complet',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Si l'utilisateur participe déjà
    if (_isParticipating) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[50],
          border: Border.all(color: Colors.green),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            SizedBox(width: 12),
            Text(
              'Vous participez à cet événement',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Si c'est le créateur
    if (_isCreator) {
      return Column(
        children: [
          Text(
            '👑 Vous êtes le créateur de cet événement',
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(Icons.share),
                  label: Text('Partager'),
                  onPressed: _shareEvent,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.edit),
                  label: Text('Modifier'),
                  onPressed: _navigateToEdit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Si l'événement est passé
    if (_event.date.isBefore(DateTime.now())) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'Événement terminé',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // Bouton "Participer" normal
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isJoining ? null : _joinEvent,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFCE1126),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isJoining
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Rejoindre...'),
          ],
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add),
            SizedBox(width: 8),
            Text(
              'Participer',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  void _showParticipantsList() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Participants (${_participants.length})'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _participants.length,
            itemBuilder: (context, index) {
              final user = _participants[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getUserColor(user),
                  child: Text(
                    user.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(user.name),
                subtitle: Text(user.email),
                trailing: user.id == _event.createdBy
                    ? Chip(
                  label: Text('Créateur', style: TextStyle(fontSize: 10)),
                  backgroundColor: Colors.orange[100],
                )
                    : user.id == widget.currentUserId
                    ? Chip(
                  label: Text('Vous', style: TextStyle(fontSize: 10)),
                  backgroundColor: Colors.green[100],
                )
                    : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _joinEvent() async {
    setState(() {
      _isJoining = true;
    });

    try {
      await _eventService.addParticipant(_event.id, widget.currentUserId);

      // Recharger les données
      final updatedEvents = await _eventService.getEvents();
      final updatedEvent = updatedEvents.firstWhere((e) => e.id == _event.id);

      setState(() {
        _event = updatedEvent;
        _isJoining = false;
      });

      await _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Vous avez rejoint l\'événement !'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isJoining = false;
      });
    }
  }

  Future<void> _leaveEvent() async {
    setState(() {
      _isLeaving = true;
    });

    try {
      await _eventService.removeParticipant(_event.id, widget.currentUserId);

      // Recharger les données
      final updatedEvents = await _eventService.getEvents();
      final updatedEvent = updatedEvents.firstWhere((e) => e.id == _event.id);

      setState(() {
        _event = updatedEvent;
        _isLeaving = false;
      });

      await _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vous avez quitté l\'événement'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLeaving = false;
      });
    }
  }

  void _confirmLeave() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Se retirer de l\'événement'),
        content: Text('Êtes-vous sûr de vouloir vous retirer de "${_event.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _leaveEvent();
            },
            child: Text('Se retirer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _shareEvent() {
    // Simulation de partage
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lien de partage copié !'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _navigateToEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditEventPage(
          event: _event,
          currentUserId: widget.currentUserId,
        ),
      ),
    ).then((result) {
      if (result == true) {
        Navigator.pop(context, true);
      }
    });
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer l\'événement'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${_event.title}" ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: _deleteEvent,
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEvent() async {
    try {
      await _eventService.deleteEvent(_event.id);
      Navigator.pop(context); // Fermer la dialog
      Navigator.pop(context, true); // Retour à la liste avec rafraîchissement
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Événement supprimé avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression: $e')),
      );
    }
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

  Color _getUserColor(User user) {
    // Générer une couleur basée sur l'ID utilisateur pour la consistance
    final colors = [Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple];
    return colors[user.id! % colors.length];
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}