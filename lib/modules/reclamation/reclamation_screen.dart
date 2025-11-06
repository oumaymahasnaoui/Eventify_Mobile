import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../database/database_helper.dart';
import '../../models/reclamation.dart';
import 'dart:developer' as developer;
import 'package:permission_handler/permission_handler.dart';
import '../../services/notification_service.dart';
import '../../services/content_moderation_service.dart';

class ReclamationScreen extends StatefulWidget {
  const ReclamationScreen({super.key});

  @override
  State<ReclamationScreen> createState() => _ReclamationScreenState();
}

class _ReclamationScreenState extends State<ReclamationScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  // Content moderation service - set to local-only to avoid ChatGPT rate limits
  final ContentModerationService _moderationService = ContentModerationService()
    ..strategy = ModerationStrategy.localOnly;
  
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage() async {
    // Show dialog to choose between camera and gallery
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choisir une source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFFCE1126)),
                title: const Text('Appareil photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFFCE1126)),
                title: const Text('Galerie'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    // Request permissions
    bool hasPermission = await _requestPermission(source);
    if (!hasPermission) {
      _showSnackBar(
        'Permission refusée. Veuillez autoriser l\'accès dans les paramètres.',
        isError: true,
      );
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showSnackBar('Erreur lors de la sélection de l\'image: $e', isError: true);
    }
  }

  Future<bool> _requestPermission(ImageSource source) async {
    if (source == ImageSource.camera) {
      final cameraStatus = await Permission.camera.request();
      return cameraStatus.isGranted;
    } else {
      // For gallery, check photos permission
      if (Platform.isAndroid) {
        final androidInfo = await Permission.photos.request();
        if (androidInfo.isGranted) return true;
        
        // Fallback to storage permission for older Android versions
        final storageStatus = await Permission.storage.request();
        return storageStatus.isGranted;
      } else if (Platform.isIOS) {
        final photosStatus = await Permission.photos.request();
        return photosStatus.isGranted;
      }
      return true;
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFFCE1126),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _submitReclamation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check for inappropriate content before submitting
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Validate title with hybrid moderation (local + AI)
      final titleResult = await _moderationService.validateText(
        title, 
        fieldName: 'Le titre',
      );
      
      if (!titleResult.isValid) {
        setState(() {
          _isLoading = false;
        });
        showErrorNotification(
          context, 
          message: '${titleResult.errorMessage}\n${titleResult.details}',
        );
        return;
      }
      
      // Validate description with hybrid moderation (local + AI)
      final descriptionResult = await _moderationService.validateText(
        description, 
        fieldName: 'La description',
      );
      
      if (!descriptionResult.isValid) {
        setState(() {
          _isLoading = false;
        });
        showErrorNotification(
          context, 
          message: '${descriptionResult.errorMessage}\n${descriptionResult.details}',
        );
        return;
      }

      developer.log('✅ Content validated (${titleResult.method}, confidence: ${(titleResult.confidence * 100).toStringAsFixed(0)}%)');

      // Get the first user from database (temporary solution until auth is implemented)
      final users = await _dbHelper.getAllUsers();
      final currentUserId = users.isNotEmpty ? users.first.id : null;
      
      if (currentUserId == null) {
        developer.log('⚠️ No users found in database');
      } else {
        developer.log('👤 Using user ID: $currentUserId (${users.first.name})');
      }

      // Create reclamation object
      final reclamation = Reclamation(
        title: title,
        description: description,
        imagePath: _selectedImage?.path,
        createdAt: DateTime.now(),
        status: 'pending',
        userId: currentUserId, // Link to current user
      );

      // Save to database
      final reclamationId = await _dbHelper.insertReclamation(reclamation);
      
      developer.log('✅ Reclamation saved with ID: $reclamationId');

      setState(() {
        _isLoading = false;
      });

      // Show success notification (SnackBar + Local Notification)
      if (mounted) {
        await showSuccessNotification(
          context,
          message: 'Votre réclamation #$reclamationId a été créée avec succès!',
          title: '✅ Réclamation créée',
          showLocalNotification: true,
        );
      }

      // Clear form after submission
      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedImage = null;
      });
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      developer.log('❌ Error saving reclamation: $e');
      
      // Show error notification
      if (mounted) {
        showErrorNotification(
          context,
          message: 'Erreur lors de l\'enregistrement: $e',
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Réclamation'),
        backgroundColor: const Color(0xFFCE1126),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Icon
                const Icon(
                  Icons.report_problem_outlined,
                  size: 60,
                  color: Color(0xFFCE1126),
                ),
                const SizedBox(height: 16),
                
                // Title
                const Text(
                  'Soumettre une réclamation',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                // Subtitle
                const Text(
                  'Décrivez votre problème et nous vous répondrons rapidement',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // Title Field
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Titre *',
                    hintText: 'Ex: Problème de paiement',
                    prefixIcon: const Icon(Icons.title, color: Color(0xFFCE1126)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFCE1126),
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un titre';
                    }
                    if (value.length < 5) {
                      return 'Le titre doit contenir au moins 5 caractères';
                    }
                    return null;
                  },
                  maxLength: 100,
                ),
                const SizedBox(height: 20),

                // Description Field
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description *',
                    hintText: 'Décrivez votre problème en détail...',
                    prefixIcon: const Icon(
                      Icons.description_outlined,
                      color: Color(0xFFCE1126),
                    ),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFCE1126),
                        width: 2,
                      ),
                    ),
                  ),
                  maxLines: 5,
                  maxLength: 500,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une description';
                    }
                    if (value.length < 20) {
                      return 'La description doit contenir au moins 20 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Image Section
                const Text(
                  'Image (optionnelle)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                // Image Preview or Picker Button
                if (_selectedImage != null)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            onPressed: _removeImage,
                            icon: const Icon(Icons.close),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFFCE1126),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Choisir une image'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFCE1126),
                      side: const BorderSide(color: Color(0xFFCE1126)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                const SizedBox(height: 30),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitReclamation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCE1126),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Soumettre la réclamation',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // Info Text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFFCE1126),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Nous traiterons votre réclamation dans les 24-48 heures.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
