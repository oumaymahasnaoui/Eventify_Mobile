import 'dart:io';

import 'package:eventify/modules/album/comments_page.dart';
import 'package:eventify/modules/album/add_edit_photo_page.dart';
import 'package:eventify/database/database_helper.dart';
import 'package:eventify/models/photo.dart';
import 'package:eventify/services/auth_service.dart';
import 'package:eventify/models/user.dart';
import 'package:flutter/material.dart';

class AlbumGalleryPage extends StatefulWidget {
  final int? eventId;
  
  const AlbumGalleryPage({Key? key, this.eventId}) : super(key: key);

  @override
  State<AlbumGalleryPage> createState() => _AlbumGalleryPageState();
}

class _AlbumGalleryPageState extends State<AlbumGalleryPage> with SingleTickerProviderStateMixin {
  int? selectedEventId;
  List<Map<String, dynamic>> events = [];
  List<Photo> photos = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();
  User? _currentUser;
  Set<int> _likedPhotoIds = {};
  late final AnimationController _likeAnimController;
  // (no separate scale animation needed; controller value is used directly)
  int? _animatingPhotoId;

  Future<void> _loadEvents() async {
    final eventsList = await _dbHelper.getAllEvents();
    setState(() {
      events = eventsList;
    });
  }

  final Color primaryColor = const Color(0xFFFF5A3C); // red-orange
  final Color secondaryColor = const Color(0xFF4A4E69); // dark accent

  @override
  Widget build(BuildContext context) {
  final filteredPhotos = selectedEventId == null
    ? photos
    : photos.where((p) => p.eventId == selectedEventId).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50], // Lighter background for depth
      // 1. Modernized AppBar
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1, // Subtle elevation for separation
        centerTitle: false,
        title: Text(
          'Album Collaboratif',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: secondaryColor,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 28),
            color: primaryColor,
            tooltip: 'Ajouter une photo',
            onPressed: () async {
              // Open the add photo page and reload after return
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddEditPhotoPage(eventId: widget.eventId)),
              );
              if (result == true) {
                await _loadPhotosFromDb();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // 🔸 Barre de filtrage (Enhanced Chip Style)
          _buildFilterChips(),

          const SizedBox(height: 16),

          // 🖼️ Galerie (Enhanced Grid View)
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Changed to 2 for larger, more engaging photos
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8, // Slightly taller cards
              ),
              itemCount: filteredPhotos.length,
              itemBuilder: (context, index) {
                final photo = filteredPhotos[index];
                return _buildPhotoCard(photo);
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- New Widget: Filter Chips for better UX ---
  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              label: const Text('Tous les photos'),
              backgroundColor: selectedEventId == null ? primaryColor : Colors.white,
              labelStyle: TextStyle(
                color: selectedEventId == null ? Colors.white : secondaryColor,
                fontWeight: selectedEventId == null ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
                side: BorderSide(
                  color: selectedEventId == null ? primaryColor : Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              onPressed: () {
                setState(() {
                  selectedEventId = null;
                });
              },
            ),
          ),
          ...events.map((event) {
            final isSelected = selectedEventId == event['id'];
            final eventDate = DateTime.parse(event['date']);
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ActionChip(
                label: Text('${event['title']} (${eventDate.day}/${eventDate.month})'),
                backgroundColor: isSelected ? primaryColor : Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : secondaryColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                  side: BorderSide(
                    color: isSelected ? primaryColor : Colors.grey[300]!,
                    width: 1.5,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    selectedEventId = event['id'] as int;
                  });
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // --- Photo Card (Detailed Overlay) ---
  Widget _buildPhotoCard(Photo photo) {
    return InkWell(
      onTap: () => _showPhotoModal(photo),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Builder(builder: (context) {
                final url = photo.url;

                // Build the image widget (network or file)
                Widget imageWidget;
                if (url.startsWith('http')) {
                  imageWidget = Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    },
                  );
                } else {
                  final file = File(url);
                  imageWidget = Image.file(
                    file,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                  );
                }

                // Wrap image with GestureDetector for double-tap like action
                imageWidget = GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onDoubleTap: () => _handleDoubleTapLike(photo),
                  child: imageWidget,
                );

                // If this photo is animating, show a centered heart with scale/opacity animation
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    imageWidget,
                    if (_animatingPhotoId == photo.id)
                      Center(
                        child: IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _likeAnimController,
                            builder: (context, child) {
                              final progress = _likeAnimController.value;
                              final scale = 0.6 + (0.55 * progress);
                              final opacity = progress <= 0.6 ? progress / 0.6 : (1 - progress) / 0.4;
                              return Opacity(
                                opacity: opacity.clamp(0.0, 1.0),
                                child: Transform.scale(
                                  scale: scale,
                                  child: child,
                                ),
                              );
                            },
                            child: const Icon(Icons.favorite, color: Colors.white, size: 120),
                          ),
                        ),
                      ),
                  ],
                );
              }),
              // Overlay with subtle gradient and user info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            photo.user,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (photo.eventId != null)
                            FutureBuilder<Map<String, dynamic>?>(
                              future: _dbHelper.getEventById(photo.eventId!),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return const SizedBox();
                                final event = snapshot.data!;
                                return Text(
                                  ' • ${event['title']}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                              child: Text(
                              photo.legend,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: [
                              // Like toggle (shows filled if current user liked this photo)
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: Icon(
                                  _likedPhotoIds.contains(photo.id) ? Icons.favorite : Icons.favorite_border,
                                  color: primaryColor,
                                  size: 14,
                                ),
                                onPressed: () async {
                                  if (_currentUser?.id == null || photo.id == null) return;
                                  final uid = _currentUser!.id!;
                                  final pid = photo.id!;
                                  try {
                                    if (_likedPhotoIds.contains(pid)) {
                                      await _dbHelper.unlikePhoto(pid, uid);
                                      setState(() {
                                        _likedPhotoIds.remove(pid);
                                        photo.likes = (photo.likes - 1).clamp(0, 999999);
                                      });
                                    } else {
                                      await _dbHelper.likePhoto(pid, uid);
                                      setState(() {
                                        _likedPhotoIds.add(pid);
                                        photo.likes = photo.likes + 1;
                                      });
                                    }
                                  } catch (e) {
                                    // Log and show feedback
                                    print('🔴 Like action failed: $e');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Action failed: $e')),
                                    );
                                  }
                                },
                              ),
                              Text(
                                ' ${photo.likes}',
                                style: const TextStyle(color: Colors.white, fontSize: 11),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.comment, color: Colors.white, size: 14),
                              Text(
                                ' ${photo.comments}',
                                style: const TextStyle(color: Colors.white, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
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

  // --- Photo Modal (Enhanced Bottom Sheet) ---
  void _showPhotoModal(Photo photo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Use transparent for custom shape
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          // Allow the modal to take up more screen space
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Builder(builder: (context) {
                            final url = photo.url;
                            if (url.startsWith('http')) {
                              return Image.network(url, fit: BoxFit.cover, width: double.infinity);
                            } else {
                              final file = File(url);
                              return Image.file(file, fit: BoxFit.cover, width: double.infinity);
                            }
                          }),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Photo Legend and User Info
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${photo.user} - ',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: secondaryColor,
                                      ),
                                    ),
                                    Flexible(
                                      child: Text(
                                        photo.legend,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (photo.eventId != null)
                                  FutureBuilder<Map<String, dynamic>?>(
                                    future: _dbHelper.getEventById(photo.eventId!),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) return const SizedBox();
                                      final event = snapshot.data!;
                                      final eventDate = DateTime.parse(event['date']);
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          '📅 ${event['title']} - ${eventDate.day}/${eventDate.month}/${eventDate.year}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: secondaryColor.withOpacity(0.8),
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                            const Divider(height: 24),
                            // Actions Row
                            Row(
                              children: [
                                // Like Button (toggle per-user)
                                IconButton(
                                  icon: Icon(
                                    _likedPhotoIds.contains(photo.id) ? Icons.favorite : Icons.favorite_border,
                                    size: 28,
                                  ),
                                  color: primaryColor,
                                  tooltip: 'J\'aime',
                                  onPressed: () async {
                                      if (_currentUser?.id == null || photo.id == null) return;
                                      final uid = _currentUser!.id!;
                                      final pid = photo.id!;
                                      try {
                                        if (_likedPhotoIds.contains(pid)) {
                                          await _dbHelper.unlikePhoto(pid, uid);
                                          setState(() {
                                            _likedPhotoIds.remove(pid);
                                            photo.likes = (photo.likes - 1).clamp(0, 999999);
                                          });
                                        } else {
                                          await _dbHelper.likePhoto(pid, uid);
                                          setState(() {
                                            _likedPhotoIds.add(pid);
                                            photo.likes = photo.likes + 1;
                                          });
                                        }
                                      } catch (e) {
                                        print('🔴 Like action failed: $e');
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Action failed: $e')),
                                        );
                                      }
                                    },
                                ),
                                Text('${photo.likes} J\'aimes', style: TextStyle(color: secondaryColor)),
                                const SizedBox(width: 24),
                                // Comment Button
                                IconButton(
                                  icon: const Icon(Icons.comment, size: 28),
                                  color: secondaryColor,
                                  tooltip: 'Commentaires',
                                  onPressed: () async {
                                    // Navigate to comments page
                                    Navigator.pop(context); // Close the modal first
                                    final result = await Navigator.push<bool?>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PhotoCommentsPage(photo: photo.toMap()),
                                      ),
                                    );
                                    if (result == true) {
                                      await _loadPhotosFromDb();
                                    }
                                  },
                                ),
                                Text('${photo.comments} Comm.', style: TextStyle(color: secondaryColor)),
                                const SizedBox(width: 12),
                                // Owner-only actions
                                if ((_currentUser?.name ?? '') == photo.user)
                                  PopupMenuButton<String>(
                                    onSelected: (v) async {
                                      if (v == 'edit') {
                                        Navigator.pop(context);
                                        final res = await Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => AddEditPhotoPage(photo: photo)),
                                        );
                                        if (res == true) await _loadPhotosFromDb();
                                      } else if (v == 'delete') {
                                        final confirm = await showDialog<bool?>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Supprimer la photo'),
                                            content: const Text('Voulez-vous supprimer cette photo ?'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
                                              ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Supprimer')),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await _dbHelper.deletePhoto(photo.id!);
                                          await _loadPhotosFromDb();
                                          Navigator.pop(context);
                                        }
                                      }
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(value: 'edit', child: Text('Modifier')),
                                      PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadPhotosFromDb();
    _loadEvents();
    _resolveCurrentUser();
  _likeAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  }

  @override
  void dispose() {
    _likeAnimController.dispose();
    super.dispose();
  }

  Future<void> _handleDoubleTapLike(Photo photo) async {
    if (_currentUser?.id == null || photo.id == null) return;
    final uid = _currentUser!.id!;
    final pid = photo.id!;

    // trigger animation for this photo
    setState(() {
      _animatingPhotoId = pid;
    });

    try {
      if (_likedPhotoIds.contains(pid)) {
        await _dbHelper.unlikePhoto(pid, uid);
        setState(() {
          _likedPhotoIds.remove(pid);
          photo.likes = (photo.likes - 1).clamp(0, 999999);
        });
      } else {
        await _dbHelper.likePhoto(pid, uid);
        setState(() {
          _likedPhotoIds.add(pid);
          photo.likes = photo.likes + 1;
        });
      }
    } catch (e) {
      print('🔴 Double-tap like failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action failed: $e')));
    }

    // play animation: forward then reverse; then clear animating id
    try {
      await _likeAnimController.forward();
      await _likeAnimController.reverse();
    } catch (_) {}

    setState(() {
      _animatingPhotoId = null;
    });
  }

  Future<void> _resolveCurrentUser() async {
    final u = await AuthService().getCurrentUser();
    setState(() => _currentUser = u);
    if (u?.id != null) {
      await _loadLikedPhotos(u!.id!);
    }
  }

  Future<void> _loadLikedPhotos(int userId) async {
    final ids = await _dbHelper.getLikedPhotoIdsForUser(userId);
    setState(() {
      _likedPhotoIds = ids.toSet();
    });
  }

  Future<void> _loadPhotosFromDb() async {
    final rows = await _dbHelper.getAllPhotosRaw(eventId: widget.eventId);
    
    // Only seed if we're in the global gallery (no eventId) and there are no photos
    if (rows.isEmpty && widget.eventId == null) {
      // seed sample photos
      final samples = [
        Photo(url: 'https://images.unsplash.com/photo-1653821355226-6def361cc7ab?q=80&w=870&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D', legend: 'Super soirée 🎉', user: 'Syrine', likes: 3, comments: 2, createdAt: DateTime.now()),
        Photo(url: 'https://images.unsplash.com/photo-1758275557784-39516582a05d?q=80&w=1032&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D', legend: 'Selfie en groupe 😎', user: 'Ahmed', likes: 5, comments: 1, createdAt: DateTime.now()),
        Photo(url: 'https://images.unsplash.com/photo-1524601500432-1e1a4c71d692?q=80&w=774&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D', legend: 'Souvenirs inoubliables 🌅', user: 'Mariem', likes: 8, comments: 3, createdAt: DateTime.now()),
        Photo(url: 'https://images.unsplash.com/photo-1588195538326-c5b1e9f80a1b?q=80&w=750&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D', legend: 'Le gâteau était délicieux 🎂', user: 'Syrine', likes: 10, comments: 5, createdAt: DateTime.now()),
      ];
      for (final s in samples) {
        final id = await _dbHelper.insertPhoto(s.toMap());
        s.id = id;
      }
      final rows2 = await _dbHelper.getAllPhotosRaw();
      setState(() {
        photos = rows2.map((r) => Photo.fromMap(r)).toList();
      });
      return;
    }
    setState(() {
      photos = rows.map((r) => Photo.fromMap(r)).toList();
    });
    // If we already know the current user, refresh their liked set to match loaded photos
    if (_currentUser?.id != null) {
      await _loadLikedPhotos(_currentUser!.id!);
    }
  }
}