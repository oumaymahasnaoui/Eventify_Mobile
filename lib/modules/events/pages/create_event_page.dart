// lib/modules/events/pages/create_event_page.dart
import 'package:flutter/material.dart';
import '../../../../models/event.dart';
import '../../../../services/event_service.dart';
import '../../../../utils/categories.dart';
import '../widgets/category_selector.dart';
import '../widgets/location_picker.dart';

class CreateEventPage extends StatefulWidget {
  final int currentUserId; // CHANGÉ de String à int

  const CreateEventPage({Key? key, required this.currentUserId}) : super(key: key);

  @override
  _CreateEventPageState createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final EventService _eventService = EventService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedCategory = EventCategories.categories.first;
  DateTime _selectedDate = DateTime.now();
  double? _latitude;
  double? _longitude;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Créer un Événement'),
        backgroundColor: Color(0xFFCE1126),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveEvent,
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
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un titre';
                  }
                  if (value.length < 3) {
                    return 'Le titre doit contenir au moins 3 caractères';
                  }
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
                  if (value == null || value.isEmpty) {
                    return 'Veuillez sélectionner une date';
                  }
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
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une description';
                  }
                  if (value.length < 10) {
                    return 'La description doit contenir au moins 10 caractères';
                  }
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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _saveEvent() async {
    if (_formKey.currentState!.validate()) {
      final newEvent = Event.createNew(
        title: _titleController.text,
        date: _selectedDate,
        location: _locationController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        latitude: _latitude,
        longitude: _longitude,
        createdBy: widget.currentUserId, // MAINTENANT int
      );

      try {
        await _eventService.addEvent(newEvent);
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la création: $e')),
        );
      }
    }
  }
}