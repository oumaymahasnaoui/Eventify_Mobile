import 'package:flutter/material.dart';
import '../models/reclamation_model.dart';
import '../../services/chatgpt_service.dart';

/// Modal dialog showing full réclamation details
class ReclamationDetailModal extends StatefulWidget {
  final ReclamationModel reclamation;
  final Function(ReclamationModel) onUpdate;

  const ReclamationDetailModal({
    super.key,
    required this.reclamation,
    required this.onUpdate,
  });

  @override
  State<ReclamationDetailModal> createState() => _ReclamationDetailModalState();
}

class _ReclamationDetailModalState extends State<ReclamationDetailModal> {
  late ReclamationStatus _selectedStatus;
  final TextEditingController _responseController = TextEditingController();
  bool _isEditing = false;
  
  // ChatGPT service
  final ChatGPTService _chatGPTService = ChatGPTService();
  bool _isGeneratingResponse = false;
  bool _isGeneratingSummary = false;
  bool _isTranslating = false;
  String? _generatedSummary;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.reclamation.statut;
    _responseController.text = widget.reclamation.reponseAdmin ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Dialog(
      child: Container(
        width: isDesktop ? 600 : double.infinity,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFCE1126),
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.report_problem, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Détails de la Réclamation',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '#${widget.reclamation.id}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User info
                    _buildInfoSection(
                      'Utilisateur',
                      widget.reclamation.userName,
                      Icons.person,
                    ),
                    const SizedBox(height: 16),

                    // Date
                    _buildInfoSection(
                      'Date',
                      _formatDateTime(widget.reclamation.date),
                      Icons.calendar_today,
                    ),
                    const SizedBox(height: 16),

                    // Status
                    _buildStatusSection(),
                    const SizedBox(height: 24),

                    const Divider(),
                    const SizedBox(height: 24),

                    // Subject
                    const Text(
                      'Sujet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.reclamation.sujet,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),

                    // Description
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        widget.reclamation.description,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // AI Summary Section
                    _buildAISummarySection(),
                    const SizedBox(height: 24),

                    // Admin response
                    const Text(
                      'Réponse Admin',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // AI Action Buttons
                    _buildAIActionButtons(),
                    const SizedBox(height: 12),
                    
                    TextField(
                      controller: _responseController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Entrez votre réponse...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _isEditing = true;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Footer with actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isEditing || _selectedStatus != widget.reclamation.statut
                        ? _saveChanges
                        : null,
                    icon: const Icon(Icons.save),
                    label: const Text('Enregistrer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCE1126),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFCE1126).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFCE1126), size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statut',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: ReclamationStatus.values.map((status) {
            final isSelected = _selectedStatus == status;
            return ChoiceChip(
              label: Text(_getStatusText(status)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedStatus = status;
                  _isEditing = true;
                });
              },
              selectedColor: _getStatusColor(status),
              backgroundColor: _getStatusColor(status).withOpacity(0.1),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : _getStatusColor(status),
                fontWeight: FontWeight.bold,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _saveChanges() {
    final updatedReclamation = widget.reclamation.copyWith(
      statut: _selectedStatus,
      reponseAdmin: _responseController.text.isNotEmpty 
          ? _responseController.text 
          : null,
    );

    widget.onUpdate(updatedReclamation);
    Navigator.pop(context);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Réclamation mise à jour avec succès'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Color _getStatusColor(ReclamationStatus status) {
    switch (status) {
      case ReclamationStatus.enAttente:
        return Colors.orange;
      case ReclamationStatus.enCours:
        return Colors.blue;
      case ReclamationStatus.resolue:
        return Colors.green;
    }
  }

  String _getStatusText(ReclamationStatus status) {
    switch (status) {
      case ReclamationStatus.enAttente:
        return 'En Attente';
      case ReclamationStatus.enCours:
        return 'En Cours';
      case ReclamationStatus.resolue:
        return 'Résolue';
    }
  }

  String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year à $hour:$minute';
  }

  // ============ AI FEATURES ============

  /// Build AI action buttons (Generate, Translate)
  Widget _buildAIActionButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Generate Response Button
        ElevatedButton.icon(
          onPressed: _isGeneratingResponse ? null : _generateAdminResponse,
          icon: _isGeneratingResponse
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.auto_awesome, size: 18),
          label: Text(_isGeneratingResponse ? 'Génération...' : 'Générer Réponse'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9B59B6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),

        // Translate to Arabic Button
        ElevatedButton.icon(
          onPressed: _isTranslating ? null : () => _translateText('arabe'),
          icon: _isTranslating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.translate, size: 18),
          label: Text(_isTranslating ? 'Traduction...' : 'Traduire → AR'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3498DB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),

        // Translate to English Button
        ElevatedButton.icon(
          onPressed: _isTranslating ? null : () => _translateText('anglais'),
          icon: const Icon(Icons.g_translate, size: 18),
          label: const Text('Traduire → EN'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2ECC71),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ],
    );
  }

  /// Build AI Summary section
  Widget _buildAISummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.summarize, size: 20, color: Color(0xFF9B59B6)),
            const SizedBox(width: 8),
            const Text(
              'Résumé IA',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9B59B6),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _isGeneratingSummary ? null : _generateSummary,
              icon: _isGeneratingSummary
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9B59B6)),
                      ),
                    )
                  : const Icon(Icons.auto_awesome, size: 16),
              label: Text(_isGeneratingSummary ? 'Génération...' : 'Générer'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF9B59B6),
              ),
            ),
          ],
        ),
        if (_generatedSummary != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF9B59B6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF9B59B6).withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, 
                  size: 18, 
                  color: Color(0xFF9B59B6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _generatedSummary!,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Generate admin response using ChatGPT
  Future<void> _generateAdminResponse() async {
    setState(() => _isGeneratingResponse = true);

    try {
      final response = await _chatGPTService.generateAdminResponse(
        title: widget.reclamation.sujet,
        description: widget.reclamation.description,
      );

      if (mounted) {
        setState(() {
          _responseController.text = response;
          _isEditing = true;
          _isGeneratingResponse = false;
        });

        if (!response.startsWith('❌') && !response.startsWith('⚠️')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✨ Réponse générée avec succès !'),
              backgroundColor: Color(0xFF9B59B6),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingResponse = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Generate summary using ChatGPT
  Future<void> _generateSummary() async {
    setState(() => _isGeneratingSummary = true);

    try {
      final summary = await _chatGPTService.generateSummary(
        title: widget.reclamation.sujet,
        description: widget.reclamation.description,
      );

      if (mounted) {
        setState(() {
          _generatedSummary = summary;
          _isGeneratingSummary = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingSummary = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Translate response text
  Future<void> _translateText(String targetLanguage) async {
    final currentText = _responseController.text.trim();
    
    if (currentText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Veuillez d\'abord entrer ou générer une réponse'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isTranslating = true);

    try {
      final translated = await _chatGPTService.translateText(
        text: currentText,
        fromLanguage: 'français',
        toLanguage: targetLanguage,
      );

      if (mounted) {
        setState(() {
          _responseController.text = translated;
          _isEditing = true;
          _isTranslating = false;
        });

        if (!translated.startsWith('❌') && !translated.startsWith('⚠️')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✨ Traduit en $targetLanguage avec succès !'),
              backgroundColor: const Color(0xFF3498DB),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTranslating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }
}
