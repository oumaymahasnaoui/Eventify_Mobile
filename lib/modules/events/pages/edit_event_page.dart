// lib/modules/events/pages/edit_event_page.dart - MODIFICATIONS
import 'package:flutter/material.dart';

import '../../../models/event.dart';
import '../../../services/event_service.dart';
import '../widgets/category_selector.dart';
import '../widgets/location_picker.dart';

class EditEventPage extends StatefulWidget {
  final Event event;
  final int currentUserId;

  const EditEventPage({
    Key? key,
    required this.event,
    required this.currentUserId,
  }) : super(key: key);

  @override
  _EditEventPageState createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  final _formKey = GlobalKey<FormState>();
  final EventService _eventService = EventService();

  late TextEditingController _titleController;
  late TextEditingController _dateController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late TextEditingController _maxParticipantsController; // NOUVEAU

  late String _selectedCategory;
  late DateTime _selectedDate;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    // Initialiser les contrôleurs avec les valeurs existantes
    _titleController = TextEditingController(text: widget.event.title);
    _dateController = TextEditingController(text: _formatDate(widget.event.date));
    _locationController = TextEditingController(text: widget.event.location);
    _descriptionController = TextEditingController(text: widget.event.description);
    _maxParticipantsController = TextEditingController(text: widget.event.maxParticipants.toString()); // NOUVEAU

    _selectedCategory = widget.event.category;
    _selectedDate = widget.event.date;
    _latitude = widget.event.latitude;
    _longitude = widget.event.longitude;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Modifier l\'Événement'),
        backgroundColor: Color(0xFFCE1126),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _updateEvent,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Champ Titre
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Titre de l\'événement',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Titre requis';
                  if (value.length < 3) return 'Minimum 3 caractères';
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Sélecteur de date
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'Date de l\'événement',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Date requise';
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Sélecteur de catégorie
              CategorySelector(
                selectedCategory: _selectedCategory,
                onCategoryChanged: (category) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
              ),
              SizedBox(height: 16),

              // Sélecteur de localisation
              LocationPicker(
                locationController: _locationController,
                onLocationPicked: (location, lat, lng) {
                  setState(() {
                    _latitude = lat;
                    _longitude = lng;
                  });
                },
              ),
              SizedBox(height: 16),

              // NOUVEAU: Champ nombre maximum de participants
              TextFormField(
                controller: _maxParticipantsController,
                decoration: InputDecoration(
                  labelText: 'Nombre maximum de participants',
                  border: OutlineInputBorder(),
                  helperText: '0 = illimité. Actuellement: ${widget.event.participants.length} participant(s)',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.info),
                    onPressed: () {
                      _showMaxParticipantsInfo();
                    },
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nombre';
                  }
                  final number = int.tryParse(value);
                  if (number == null || number < 0) {
                    return 'Veuillez entrer un nombre positif ou 0';
                  }

                  // Validation supplémentaire: ne pas permettre de réduire en dessous du nombre actuel de participants
                  final currentParticipantsCount = widget.event.participants.length;
                  if (number > 0 && number < currentParticipantsCount) {
                    return 'Impossible: vous avez déjà $currentParticipantsCount participant(s)';
                  }

                  return null;
                },
              ),
              SizedBox(height: 16),

              // Champ Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Description requise';
                  if (value.length < 10) return 'Minimum 10 caractères';
                  return null;
                },
              ),

              // Section d'information sur les participants actuels
              SizedBox(height: 20),
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📊 Statut actuel des participants',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('• Participants actuels: ${widget.event.participants.length}'),
                      Text('• Limite actuelle: ${widget.event.maxParticipants == 0 ? 'Illimité' : widget.event.maxParticipants}'),
                      if (widget.event.isFull)
                        Text(
                          '• Statut: COMPLET',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMaxParticipantsInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nombre maximum de participants'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Entrez 0 pour un nombre illimité de participants'),
            SizedBox(height: 8),
            Text('• Le nombre ne peut pas être inférieur au nombre actuel de participants'),
            SizedBox(height: 8),
            Text('• Actuellement: ${widget.event.participants.length} participant(s)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = _selectedDate.isBefore(now) ? now : _selectedDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _updateEvent() async {
    if (_formKey.currentState!.validate()) {
      final maxParticipants = int.parse(_maxParticipantsController.text);

      // Validation finale pour s'assurer qu'on ne dépasse pas la limite
      if (maxParticipants > 0 && maxParticipants < widget.event.participants.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de réduire la limite en dessous du nombre actuel de participants')),
        );
        return;
      }

      final updatedEvent = Event(
        id: widget.event.id,
        title: _titleController.text,
        date: _selectedDate,
        location: _locationController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        latitude: _latitude,
        longitude: _longitude,
        participants: widget.event.participants, // Garder les participants existants
        createdBy: widget.event.createdBy, // Garder le créateur original
        createdAt: widget.event.createdAt, // Garder la date de création originale
        maxParticipants: maxParticipants, // NOUVEAU CHAMP
      );

      try {
        await _eventService.updateEvent(updatedEvent);

        // Afficher un message de confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Événement modifié avec succès'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true); // Retour avec succès
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la modification: $e')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _maxParticipantsController.dispose(); // NOUVEAU
    super.dispose();
  }
}