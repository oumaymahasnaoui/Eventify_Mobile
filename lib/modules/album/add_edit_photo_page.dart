import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:eventify/models/photo.dart';
import 'package:eventify/database/database_helper.dart';
import 'package:eventify/services/auth_service.dart';
import 'package:eventify/models/user.dart';
import 'package:eventify/widgets/image_filter_editor.dart';
import 'package:eventify/widgets/ai_legend_suggestions.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';


class AddEditPhotoPage extends StatefulWidget {
  final Photo? photo;
  final int? eventId;

  const AddEditPhotoPage({super.key, this.photo, this.eventId});

  @override
  State<AddEditPhotoPage> createState() => _AddEditPhotoPageState();
}

class _AddEditPhotoPageState extends State<AddEditPhotoPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _legendController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ImagePicker _picker = ImagePicker();
  String? _localImagePath;
  User? _currentUser;
  bool _isSaving = false;
  List<Map<String, dynamic>> _events = [];
  int? _selectedEventId;

  Future<void> _loadEvents() async {
    try {
      final events = await _dbHelper.getAllEvents();
      print('🎉 Loaded ${events.length} events');
      setState(() {
        _events = events;
        // If we have a preset eventId from widget, select it
        _selectedEventId = widget.eventId ?? widget.photo?.eventId;
      });
    } catch (e) {
      print('❌ Error loading events: $e');
    }
  }

  @override
  void initState() {
    _loadEvents();
    super.initState();
    final p = widget.photo;
    if (p != null) {
      _urlController.text = p.url;
      // If url is a local file path, keep it in _localImagePath for preview
      if (!p.url.startsWith('http')) {
        _localImagePath = p.url;
      } else {
        // For network images, we need to download them first to apply filters
        _downloadNetworkImage(p.url);
      }
      _legendController.text = p.legend;
      _userController.text = p.user;
    }
    _resolveCurrentUser();
  }

  Future<void> _resolveCurrentUser() async {
    final u = await AuthService().getCurrentUser();
    if (u != null && widget.photo == null) {
      // only auto-fill for new photos
      setState(() => _userController.text = u.name);
    }
    setState(() => _currentUser = u);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _legendController.dispose();
    _userController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final photo = Photo(
      id: widget.photo?.id,
      url: _localImagePath ?? _urlController.text.trim(),
      legend: _legendController.text.trim(),
      user: _userController.text.trim().isEmpty ? 'Unknown' : _userController.text.trim(),
      createdAt: widget.photo?.createdAt ?? DateTime.now(),
      eventId: widget.eventId ?? _selectedEventId ?? widget.photo?.eventId,
    );

    try {
      if (widget.photo == null) {
        final id = await _dbHelper.insertPhoto(photo.toMap());
        photo.id = id;
      } else {
        await _dbHelper.updatePhoto(photo.id!, photo.toMap());
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo saved')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.photo != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier la photo' : 'Ajouter une photo'),
        backgroundColor: const Color(0xFFFF5A3C),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Image preview + picker
                if (_localImagePath == null || _localImagePath!.isEmpty)
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[200],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _urlController.text.trim().isNotEmpty && _urlController.text.trim().startsWith('http')
                          ? Image.network(_urlController.text.trim(), fit: BoxFit.cover)
                          : Center(child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.image, size: 48),
                                SizedBox(height: 8),
                                Text('Appuyez pour choisir une image')
                              ],
                            )),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 400,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ImageFilterEditor(
                        imagePath: _localImagePath!,
                        onImageFiltered: (String filteredPath) {
                          setState(() {
                            _localImagePath = filteredPath;
                            _urlController.text = filteredPath;
                          });
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                if (_localImagePath != null)
                  AILegendSuggestions(
                    imagePath: _localImagePath!,
                    eventContext: _events
                        .where((e) => e['id'] == (_selectedEventId ?? widget.eventId))
                        .map((e) => e['title'] as String)
                        .firstOrNull,
                    onLegendSelected: (legend) {
                      setState(() => _legendController.text = legend);
                    },
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _legendController,
                  decoration: const InputDecoration(labelText: 'Légende'),
                ),
                const SizedBox(height: 12),
                // Auteur - auto-filled from current user and read-only
                TextFormField(
                  controller: _userController,
                  decoration: const InputDecoration(labelText: 'Auteur'),
                  readOnly: true,
                ),
                const SizedBox(height: 12),
                // Event dropdown
                DropdownButtonFormField<int?>(
                  value: _selectedEventId,
                  decoration: const InputDecoration(
                    labelText: 'Événement',
                    hintText: 'Sélectionnez un événement',
                  ),
                  items: [
                    if (widget.eventId == null) // Only show "No event" if not preselected
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Aucun événement'),
                      ),
                    ..._events.map((e) => DropdownMenuItem(
                      value: e['id'] as int,
                      child: Text('${e['title']} (${DateTime.parse(e['date']).day}/${DateTime.parse(e['date']).month}/${DateTime.parse(e['date']).year})'),
                    )),
                  ],
                  onChanged: widget.eventId != null ? null : (value) {
                    setState(() => _selectedEventId = value);
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5A3C)),
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(isEditing ? 'Mettre à jour' : 'Ajouter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) return;
      setState(() {
        _localImagePath = picked.path;
        _urlController.text = picked.path; // keep controller in sync for possible network fallback
      });
    } catch (e) {
      // ignore errors for now
    }
  }

  Future<void> _downloadNetworkImage(String url) async {
    try {
      setState(() => _isSaving = true);
      final file = await DefaultCacheManager().getSingleFile(url);
      if (mounted) {
        setState(() {
          _localImagePath = file.path;
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading image: $e')),
        );
        setState(() => _isSaving = false);
      }
    }
  }
}
