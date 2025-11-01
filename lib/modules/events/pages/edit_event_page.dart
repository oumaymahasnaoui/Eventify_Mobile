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

              CategorySelector(
                selectedCategory: _selectedCategory,
                onCategoryChanged: (category) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
              ),
              SizedBox(height: 16),

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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();

    // CORRECTION : S'assurer que la date initiale n'est pas dans le passé
    final DateTime initialDate = _selectedDate.isBefore(now) ? now : _selectedDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate, // Utiliser la date corrigée
      firstDate: now, // Date minimale = aujourd'hui
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
      );

      try {
        await _eventService.updateEvent(updatedEvent);
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
    super.dispose();
  }
}