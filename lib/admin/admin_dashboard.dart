import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'models/reclamation_model.dart';
import 'widgets/sidebar.dart';
import 'widgets/reclamations_table.dart';
import 'widgets/status_chart.dart';
import 'widgets/reclamation_detail_modal.dart';
import '../database/database_helper.dart';
import '../models/reclamation.dart';
import '../models/user.dart';

void main() {
  runApp(const AdminDashboardApp());
}

class AdminDashboardApp extends StatelessWidget {
  const AdminDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eventify Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFCE1126),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFCE1126),
        ),
        useMaterial3: true,
      ),
      home: const AdminDashboard(),
    );
  }
}

/// Admin Dashboard for managing user complaints (réclamations)
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // Current selected page
  String _selectedPage = 'Réclamations';
  
  // Search controller
  final TextEditingController _searchController = TextEditingController();
  
  // Database helper (only for mobile/desktop)
  DatabaseHelper? _dbHelper;
  
  // Real data from database
  List<ReclamationModel> _allReclamations = [];
  List<ReclamationModel> _filteredReclamations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialize database helper only if not on web
    if (!kIsWeb) {
      _dbHelper = DatabaseHelper();
    }
    _loadRealData();
  }

  /// Load real data from database
  Future<void> _loadRealData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if running on web - sqflite doesn't work on web!
      if (kIsWeb) {
        print('⚠️ Running on web - SQLite not supported. Using fallback data.');
        
        // Load some demo data so the UI is not empty
        setState(() {
          _allReclamations = [
            ReclamationModel(
              id: 1,
              userName: 'Demo User',
              sujet: 'Example Complaint',
              description: 'This is demo data. Run on Windows or Mobile to see real database data.',
              statut: ReclamationStatus.enAttente,
              date: DateTime.now(),
              reponseAdmin: null,
            ),
          ];
          _filteredReclamations = List.from(_allReclamations);
          _isLoading = false;
        });
        return;
      }
      
      // Get all reclamations from database (mobile/desktop only)
      final reclamations = await _dbHelper!.getAllReclamations();
      
      print('📊 Loaded ${reclamations.length} reclamations from database');
      
      // DEBUG: Check what users exist in database
      final allUsers = await _dbHelper!.getAllUsers();
      print('👥 Found ${allUsers.length} users in database:');
      for (final user in allUsers) {
        print('   - User #${user.id}: ${user.name} (${user.email})');
      }
      
      // Convert to ReclamationModel with user names
      final List<ReclamationModel> models = [];
      for (final reclamation in reclamations) {
        String userName = 'Utilisateur inconnu';
        
        print('🔍 Réclamation #${reclamation.id} - userId: ${reclamation.userId}');
        
        // Get user name if userId exists
        if (reclamation.userId != null) {
          print('   Looking up user #${reclamation.userId}...');
          final user = await _dbHelper!.getUserById(reclamation.userId!);
          if (user != null) {
            userName = user.name;
            print('   ✅ Found user: ${user.name}');
          } else {
            print('   ❌ User not found');
          }
        } else {
          print('   ⚠️ No userId linked to this reclamation');
        }
        
        print('  ✅ Réclamation #${reclamation.id}: ${reclamation.title} by $userName');
        
        models.add(ReclamationModel(
          id: reclamation.id ?? 0,
          userName: userName,
          sujet: reclamation.title,
          description: reclamation.description,
          statut: _mapStatusToEnum(reclamation.status),
          date: reclamation.createdAt,
          reponseAdmin: reclamation.reponseAdmin,
        ));
      }
      
      setState(() {
        _allReclamations = models;
        _filteredReclamations = List.from(models);
        _isLoading = false;
      });
      
      print('✅ Dashboard loaded with ${models.length} réclamations');
    } catch (e, stackTrace) {
      print('❌ Error loading reclamations: $e');
      print('Stack trace: $stackTrace');
      
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Map database status to enum
  ReclamationStatus _mapStatusToEnum(String status) {
    switch (status) {
      case 'pending':
        return ReclamationStatus.enAttente;
      case 'in_progress':
        return ReclamationStatus.enCours;
      case 'resolved':
      case 'rejected':
        return ReclamationStatus.resolue;
      default:
        return ReclamationStatus.enAttente;
    }
  }

  /// Map enum to database status
  String _mapEnumToStatus(ReclamationStatus status) {
    switch (status) {
      case ReclamationStatus.enAttente:
        return 'pending';
      case ReclamationStatus.enCours:
        return 'in_progress';
      case ReclamationStatus.resolue:
        return 'resolved';
    }
  }

  /// Filter réclamations based on search query
  void _filterReclamations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredReclamations = List.from(_allReclamations);
      } else {
        _filteredReclamations = _allReclamations.where((reclamation) {
          final searchLower = query.toLowerCase();
          return reclamation.userName.toLowerCase().contains(searchLower) ||
                 reclamation.sujet.toLowerCase().contains(searchLower) ||
                 reclamation.description.toLowerCase().contains(searchLower);
        }).toList();
      }
    });
  }

  /// Show réclamation detail modal
  void _showReclamationDetail(ReclamationModel reclamation) {
    showDialog(
      context: context,
      builder: (context) => ReclamationDetailModal(
        reclamation: reclamation,
        onUpdate: (updatedReclamation) async {
          // Update reclamation in database (status AND reponseAdmin)
          try {
            // Get the original reclamation from database
            final allReclamations = await _dbHelper!.getAllReclamations();
            final originalReclamation = allReclamations.firstWhere(
              (r) => r.id == updatedReclamation.id,
            );
            
            // Create updated reclamation with new status and response
            final updatedDbReclamation = originalReclamation.copyWith(
              status: _mapEnumToStatus(updatedReclamation.statut),
              reponseAdmin: updatedReclamation.reponseAdmin,
            );
            
            // Save to database
            await _dbHelper!.updateReclamation(updatedDbReclamation);
            
            // Reload data from database
            await _loadRealData();
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Réclamation mise à jour avec succès'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  /// Delete réclamation
  void _deleteReclamation(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette réclamation ?'),
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
    
    if (confirmed == true) {
      try {
        await _dbHelper!.deleteReclamation(id);
        await _loadRealData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Réclamation supprimée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Get statistics for the chart
  Map<ReclamationStatus, int> _getStatistics() {
    final stats = <ReclamationStatus, int>{
      ReclamationStatus.enAttente: 0,
      ReclamationStatus.enCours: 0,
      ReclamationStatus.resolue: 0,
    };
    
    for (var reclamation in _allReclamations) {
      stats[reclamation.statut] = (stats[reclamation.statut] ?? 0) + 1;
    }
    
    return stats;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard - Eventify'),
        backgroundColor: const Color(0xFFCE1126),
        elevation: 0,
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadRealData,
            tooltip: 'Actualiser les données',
          ),
          // User profile icon
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color(0xFFCE1126)),
              ),
              onPressed: () {
                // Show user menu
              },
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar (only show on desktop)
          if (isDesktop)
            AdminSidebar(
              selectedPage: _selectedPage,
              onPageSelected: (page) {
                setState(() {
                  _selectedPage = page;
                });
              },
            ),
          
          // Main content
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: _buildMainContent(isDesktop),
            ),
          ),
        ],
      ),
      // Drawer for mobile/tablet
      drawer: !isDesktop
          ? Drawer(
              child: AdminSidebar(
                selectedPage: _selectedPage,
                onPageSelected: (page) {
                  setState(() {
                    _selectedPage = page;
                  });
                  Navigator.pop(context); // Close drawer
                },
              ),
            )
          : null,
    );
  }

  /// Build main content based on selected page
  Widget _buildMainContent(bool isDesktop) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFCE1126)),
            ),
            SizedBox(height: 16),
            Text('Chargement des réclamations...'),
          ],
        ),
      );
    }
    
    switch (_selectedPage) {
      case 'Dashboard':
        return _buildDashboardContent();
      case 'Réclamations':
        return _buildReclamationsContent(isDesktop);
      case 'Utilisateurs':
        return _buildUtilisateursContent(isDesktop);
      default:
        return _buildReclamationsContent(isDesktop);
    }
  }

  /// Build dashboard with statistics
  Widget _buildDashboardContent() {
    final stats = _getStatistics();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tableau de bord',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 24),
          
          // Statistics Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildStatCard(
                    'En Attente',
                    stats[ReclamationStatus.enAttente]!,
                    Colors.orange,
                    Icons.pending,
                    width: isWide ? constraints.maxWidth / 3 - 16 : constraints.maxWidth,
                  ),
                  _buildStatCard(
                    'En Cours',
                    stats[ReclamationStatus.enCours]!,
                    Colors.blue,
                    Icons.autorenew,
                    width: isWide ? constraints.maxWidth / 3 - 16 : constraints.maxWidth,
                  ),
                  _buildStatCard(
                    'Résolues',
                    stats[ReclamationStatus.resolue]!,
                    Colors.green,
                    Icons.check_circle,
                    width: isWide ? constraints.maxWidth / 3 - 16 : constraints.maxWidth,
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 32),
          
          // Chart
          StatusChart(statistics: stats),
          
          const SizedBox(height: 32),
          
          // Recent réclamations
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Réclamations récentes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._allReclamations.take(5).map((reclamation) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(reclamation.statut).withOpacity(0.2),
                        child: Icon(
                          _getStatusIcon(reclamation.statut),
                          color: _getStatusColor(reclamation.statut),
                        ),
                      ),
                      title: Text(reclamation.sujet),
                      subtitle: Text(reclamation.userName),
                      trailing: _buildStatusBadge(reclamation.statut),
                      onTap: () => _showReclamationDetail(reclamation),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build statistics card
  Widget _buildStatCard(String title, int count, Color color, IconData icon, {required double width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build réclamations content
  Widget _buildReclamationsContent(bool isDesktop) {
    return Column(
      children: [
        // Header with search
        Container(
          padding: const EdgeInsets.all(24),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gestion des Réclamations',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 16),
              
              // Search bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher par sujet ou nom d\'utilisateur...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterReclamations('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onChanged: _filterReclamations,
              ),
            ],
          ),
        ),
        
        // Table
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ReclamationsTable(
              reclamations: _filteredReclamations,
              onView: _showReclamationDetail,
              onDelete: _deleteReclamation,
              isDesktop: isDesktop,
            ),
          ),
        ),
      ],
    );
  }

  /// Build Utilisateurs page content
  Widget _buildUtilisateursContent(bool isDesktop) {
    return FutureBuilder<List<User>>(
      future: kIsWeb ? Future.value([]) : _dbHelper!.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data ?? [];

        if (kIsWeb) {
          return _buildWebPlaceholder();
        }

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Aucun utilisateur trouvé',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.people, size: 32, color: Color(0xFFCE1126)),
                  const SizedBox(width: 12),
                  const Text(
                    'Liste des Utilisateurs',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCE1126).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${users.length} utilisateur${users.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: Color(0xFFCE1126),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Users list
              if (isDesktop)
                _buildUsersTable(users)
              else
                _buildUsersCards(users),
            ],
          ),
        );
      },
    );
  }

  /// Build users table for desktop
  Widget _buildUsersTable(List<User> users) {
    return Card(
      elevation: 2,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            const Color(0xFFCE1126).withOpacity(0.1),
          ),
          columns: const [
            DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Nom', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Téléphone', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Localisation', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Date d\'inscription', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: users.map((user) {
            return DataRow(
              cells: [
                DataCell(Text('#${user.id}')),
                DataCell(
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFCE1126),
                        child: Text(
                          user.name[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(user.name),
                    ],
                  ),
                ),
                DataCell(Text(user.email)),
                DataCell(Text(user.phone)),
                DataCell(Text(user.location ?? 'Non spécifié')),
                DataCell(Text(_formatDate(user.joinDate))),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: user.isActive == 1
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user.isActive == 1 ? 'Actif' : 'Inactif',
                      style: TextStyle(
                        color: user.isActive == 1 ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Build users cards for mobile
  Widget _buildUsersCards(List<User> users) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFFCE1126),
                      child: Text(
                        user.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: user.isActive == 1
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user.isActive == 1 ? 'Actif' : 'Inactif',
                        style: TextStyle(
                          color: user.isActive == 1 ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                _buildUserInfoRow(Icons.phone, user.phone),
                const SizedBox(height: 8),
                _buildUserInfoRow(Icons.location_on, user.location ?? 'Non spécifié'),
                const SizedBox(height: 8),
                _buildUserInfoRow(Icons.calendar_today, 'Inscrit le ${_formatDate(user.joinDate)}'),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build user info row
  Widget _buildUserInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  /// Build web placeholder
  Widget _buildWebPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.web, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Fonctionnalité non disponible sur Web',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Utilisez l\'application mobile ou desktop pour voir les utilisateurs',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  /// Format date
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Build status badge
  Widget _buildStatusBadge(ReclamationStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Get status color
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

  /// Get status icon
  IconData _getStatusIcon(ReclamationStatus status) {
    switch (status) {
      case ReclamationStatus.enAttente:
        return Icons.pending;
      case ReclamationStatus.enCours:
        return Icons.autorenew;
      case ReclamationStatus.resolue:
        return Icons.check_circle;
    }
  }

  /// Get status text
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
