import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/reclamation.dart';
import 'dart:io';
import '../../services/notification_service.dart';

class ReclamationsListScreen extends StatefulWidget {
  const ReclamationsListScreen({super.key});

  @override
  State<ReclamationsListScreen> createState() => _ReclamationsListScreenState();
}

class _ReclamationsListScreenState extends State<ReclamationsListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _searchController = TextEditingController();
  
  List<Reclamation> _reclamations = [];
  List<Reclamation> _filteredReclamations = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, pending, in_progress, resolved
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadReclamations();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applyFilters();
    });
  }

  void _applyFilters() {
    if (_searchQuery.isEmpty) {
      _filteredReclamations = _reclamations;
    } else {
      _filteredReclamations = _reclamations.where((reclamation) {
        final titleMatch = reclamation.title.toLowerCase().contains(_searchQuery);
        final descriptionMatch = reclamation.description.toLowerCase().contains(_searchQuery);
        final idMatch = reclamation.id.toString().contains(_searchQuery);
        return titleMatch || descriptionMatch || idMatch;
      }).toList();
    }
  }

  Future<void> _loadReclamations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Reclamation> reclamations;
      
      if (_selectedFilter == 'all') {
        reclamations = await _dbHelper.getAllReclamations();
      } else {
        reclamations = await _dbHelper.getReclamationsByStatus(_selectedFilter);
      }

      setState(() {
        _reclamations = reclamations;
        _filteredReclamations = reclamations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Erreur lors du chargement: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFFCE1126),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteReclamation(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette réclamation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.deleteReclamation(id);
      
      // Show success notification
      if (mounted) {
        showSuccessNotification(
          context,
          message: 'Réclamation #$id supprimée avec succès',
          showLocalNotification: false, // No local notification for deletion
        );
      }
      
      _loadReclamations();
    }
  }

  /// Update reclamation status with notification
  Future<void> _updateReclamationStatus(
    Reclamation reclamation,
    String newStatus,
  ) async {
    try {
      final oldStatus = reclamation.status;
      
      // Update in database
      await _dbHelper.updateReclamationStatus(reclamation.id!, newStatus);
      
      // Show notification
      if (mounted) {
        await notifyStatusChange(
          context,
          newStatus: newStatus,
          reclamationId: reclamation.id!,
          oldStatus: oldStatus,
        );
      }
      
      // Refresh list
      _loadReclamations();
    } catch (e) {
      if (mounted) {
        showErrorNotification(
          context,
          message: 'Erreur lors de la mise à jour: $e',
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'in_progress':
        return Icons.hourglass_empty;
      case 'resolved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Réclamations'),
        backgroundColor: const Color(0xFFCE1126),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReclamations,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par titre, description ou ID...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFFCE1126)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
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
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),

          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tous', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('En attente', 'pending'),
                  const SizedBox(width: 8),
                  _buildFilterChip('En cours', 'in_progress'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Résolus', 'resolved'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Rejetés', 'rejected'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Results count
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_filteredReclamations.length} résultat(s) trouvé(s)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 8),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredReclamations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isNotEmpty 
                                  ? Icons.search_off 
                                  : Icons.inbox_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Aucune réclamation trouvée'
                                  : 'Aucune réclamation',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (_searchQuery.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Essayez d\'autres termes de recherche',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadReclamations,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredReclamations.length,
                          itemBuilder: (context, index) {
                            return _buildReclamationCard(_filteredReclamations[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
        _loadReclamations();
      },
      selectedColor: const Color(0xFFCE1126),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildReclamationCard(Reclamation reclamation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(reclamation.status).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(reclamation.status),
                  color: _getStatusColor(reclamation.status),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reclamation.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    reclamation.statusText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: _getStatusColor(reclamation.status),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reclamation.description,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Image preview if exists
                if (reclamation.imagePath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildImagePreview(reclamation.imagePath!),
                  ),

                const SizedBox(height: 12),

                // Footer info
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      reclamation.timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'ID: #${reclamation.id}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          ButtonBar(
            alignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _showReclamationDetails(reclamation),
                icon: const Icon(Icons.visibility),
                label: const Text('Détails'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFCE1126),
                ),
              ),
              TextButton.icon(
                onPressed: () => _deleteReclamation(reclamation.id!),
                icon: const Icon(Icons.delete),
                label: const Text('Supprimer'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReclamationDetails(Reclamation reclamation) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                _getStatusIcon(reclamation.status),
                color: _getStatusColor(reclamation.status),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reclamation.title,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(reclamation.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    reclamation.statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // ID
                Row(
                  children: [
                    const Icon(Icons.tag, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'ID: #${reclamation.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Time
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(reclamation.timeAgo),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Date
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '${reclamation.createdAt.day}/${reclamation.createdAt.month}/${reclamation.createdAt.year}',
                    ),
                  ],
                ),
                
                const Divider(height: 24),
                
                // Description
                const Text(
                  'Description:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  reclamation.description,
                  style: const TextStyle(fontSize: 14),
                ),
                
                // Image (only if path exists)
                if (reclamation.imagePath != null && reclamation.imagePath!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Image:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSafeImage(reclamation.imagePath!),
                ],
                
                // Status update buttons
                const SizedBox(height: 16),
                const Divider(),
                const Text(
                  'Changer le statut:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (reclamation.status != 'pending')
                      _buildStatusButton(
                        context,
                        reclamation,
                        'pending',
                        'En attente',
                        Icons.schedule,
                        Colors.orange,
                      ),
                    if (reclamation.status != 'in_progress')
                      _buildStatusButton(
                        context,
                        reclamation,
                        'in_progress',
                        'En cours',
                        Icons.hourglass_empty,
                        Colors.blue,
                      ),
                    if (reclamation.status != 'resolved')
                      _buildStatusButton(
                        context,
                        reclamation,
                        'resolved',
                        'Résolu',
                        Icons.check_circle,
                        Colors.green,
                      ),
                    if (reclamation.status != 'rejected')
                      _buildStatusButton(
                        context,
                        reclamation,
                        'rejected',
                        'Rejeté',
                        Icons.cancel,
                        Colors.red,
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  /// Build status update button
  Widget _buildStatusButton(
    BuildContext context,
    Reclamation reclamation,
    String status,
    String label,
    IconData icon,
    Color color,
  ) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.pop(context);
        _updateReclamationStatus(reclamation, status);
      },
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  // Safe image builder that won't crash
  Widget _buildSafeImage(String imagePath) {
    try {
      final file = File(imagePath);
      
      if (!file.existsSync()) {
        return _buildImageError('Fichier introuvable');
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          file,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildImageError('Erreur de chargement');
          },
        ),
      );
    } catch (e) {
      return _buildImageError('Erreur: ${e.toString()}');
    }
  }

  Widget _buildImageError(String message) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  // Helper method to safely build image preview for cards
  Widget _buildImagePreview(String imagePath) {
    try {
      final file = File(imagePath);
      
      if (!file.existsSync()) {
        return Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 40, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'Image introuvable',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        );
      }

      return Image.file(
        file,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 40, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'Erreur de chargement',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'Erreur',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      );
    }
  }
}
