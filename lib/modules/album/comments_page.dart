import 'dart:io';

import 'package:flutter/material.dart';
import 'package:eventify/database/database_helper.dart';
import 'package:eventify/services/auth_service.dart';
import 'package:eventify/models/user.dart';
import 'package:eventify/services/comment_service.dart';

// Note: This page now persists comments in the local SQLite database (comments table).

class PhotoCommentsPage extends StatefulWidget {
  final Map<String, dynamic> photo;

  const PhotoCommentsPage({super.key, required this.photo});

  @override
  State<PhotoCommentsPage> createState() => _PhotoCommentsPageState();
}

class _PhotoCommentsPageState extends State<PhotoCommentsPage> {
  final TextEditingController _commentController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final CommentService _commentService = CommentService();

  List<Map<String, dynamic>> comments = [];
  bool _changed = false; // whether we added/removed comments
  User? _currentUser;
  // enrichment cache: sentiment, summary, etc.
  final Map<int, Map<String, dynamic>> _enriched = {};
  final Map<int, bool> _expanded = {};
  final Map<int, String> _translated = {};

  @override
  void initState() {
    super.initState();
    _loadComments();
    _resolveCurrentUser();
  }

  Future<void> _resolveCurrentUser() async {
    final u = await AuthService().getCurrentUser();
    setState(() => _currentUser = u);
  }

  Future<void> _loadComments() async {
    final photoId = widget.photo['id'] as int?;
    if (photoId == null) return;
    final rows = await _dbHelper.getCommentsByPhotoId(photoId);
    setState(() {
      comments = rows;
    });

    // Kick off async enrichment tasks (non-blocking)
    for (final c in rows) {
      _enrichComment(c);
    }
  }

  Future<void> _enrichComment(Map<String, dynamic> c) async {
    final id = c['id'] as int?;
    if (id == null) return;
    try {
      final text = c['text'] as String? ?? '';
      // Avoid duplicate enrichment
      if (_enriched.containsKey(id)) return;
      // Do sentiment always
      final sentiment = await _commentService.analyzeSentiment(text);
      String? summary;
      if (text.length > 220) {
        summary = await _commentService.summarizeText(text);
      }
      setState(() {
        _enriched[id] = {
          'sentiment': sentiment,
          if (summary != null) 'summary': summary,
        };
      });
    } catch (e) {
      // ignore enrichment failures for prototype
      print('🔍 Enrichment failed for comment $id: $e');
    }
  }

  Future<void> _translateComment(int commentId, String targetLang) async {
    try {
      if (_translated.containsKey(commentId)) {
        setState(() => _translated.remove(commentId));
        return;
      }
      final row = comments.firstWhere((r) => r['id'] == commentId, orElse: () => {});
      final text = row['text'] as String? ?? '';
      final translated = await _commentService.translateText(text, targetLang);
      setState(() {
        _translated[commentId] = translated;
      });
    } catch (e) {
      print('🌐 Translation failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Translation failed: $e')));
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    final photoId = widget.photo['id'] as int?;
    if (photoId == null) return;

    final comment = {
      'photoId': photoId,
      'user': _currentUser?.name ?? 'Moi',
      'text': text,
      'createdAt': DateTime.now().toIso8601String(),
    };

    await _dbHelper.insertComment(comment);
    _commentController.clear();
    _changed = true;
    await _loadComments();
    // Update the local photo map so parent UI can show updated count if it reads it
    final updatedPhoto = await _dbHelper.getPhotoById(photoId);
    if (updatedPhoto != null) {
      widget.photo['comments'] = updatedPhoto['comments'];
    }
  }

  Future<void> _editComment(int commentId, String currentText) async {
    final controller = TextEditingController(text: currentText);
    final res = await showDialog<bool?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le commentaire'),
        content: TextField(controller: controller, maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Enregistrer')),
        ],
      ),
    );
    if (res != true) return;
    final newText = controller.text.trim();
    if (newText.isEmpty) return;
    await _dbHelper.updateComment(commentId, {'text': newText});
    _changed = true;
    await _loadComments();
  }

  Future<void> _deleteCommentConfirmed(int commentId) async {
    await _dbHelper.deleteComment(commentId);
    _changed = true;
    await _loadComments();
  }

  Future<bool> _onWillPop() async {
    Navigator.of(context).pop(_changed);
    return false; // already popped
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photo;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('💬 Commentaires'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(_changed),
          ),
        ),
        body: Column(
          children: [
            // Aperçu photo
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 1.5,
                    child: _buildPhotoPreview(photo['url'] as String),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      photo['legend'] ?? '',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Liste des commentaires
            Expanded(
              child: comments.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucun commentaire pour le moment 📝',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final c = comments[index];
                        final isOwner = (_currentUser?.name ?? '') == (c['user'] as String? ?? '');
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.blue.shade200,
                                child: Text(
                                  (c['user'] as String?)?.isNotEmpty == true ? (c['user'] as String)[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            c['user'] ?? 'Inconnu',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ),
                                        if (isOwner)
                                          PopupMenuButton<String>(
                                            onSelected: (v) async {
                                              if (v == 'edit') {
                                                await _editComment(c['id'] as int, c['text'] as String);
                                              } else if (v == 'delete') {
                                                final confirm = await showDialog<bool?>(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: const Text('Supprimer le commentaire'),
                                                    content: const Text('Voulez-vous supprimer ce commentaire ?'),
                                                    actions: [
                                                      TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
                                                      ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Supprimer')),
                                                    ],
                                                  ),
                                                );
                                                if (confirm == true) await _deleteCommentConfirmed(c['id'] as int);
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                                              const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                                            ],
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    // Enriched UI: show sentiment chip, summary toggle and translation
                                    Builder(builder: (context) {
                                      final id = c['id'] as int?;
                                      final enriched = id != null ? _enriched[id] : null;
                                      final sentiment = enriched != null ? enriched['sentiment'] as Map<String, dynamic>? : null;
                                      final summary = enriched != null ? enriched['summary'] as String? : null;
                                      final isExpanded = (id != null && (_expanded[id] ?? false));
                                      final translated = (id != null) ? _translated[id] : null;

                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // sentiment chip
                                          if (sentiment != null)
                                            Padding(
                                              padding: const EdgeInsets.only(bottom: 6.0),
                                              child: Row(
                                                children: [
                                                  Chip(
                                                    label: Text(sentiment['label'] as String),
                                                    backgroundColor: (sentiment['label'] == 'positive')
                                                        ? Colors.green.shade100
                                                        : (sentiment['label'] == 'negative')
                                                            ? Colors.orange.shade100
                                                            : Colors.grey.shade200,
                                                  ),
                                                  const SizedBox(width: 8),
                                                ],
                                              ),
                                            ),

                                          // comment body (translated > summary > full)
                                          if (translated != null)
                                            Text(translated, style: const TextStyle(fontSize: 14))
                                          else if (summary != null && !isExpanded)
                                            Text(summary, style: const TextStyle(fontSize: 14))
                                          else
                                            Text(c['text'] ?? '', style: const TextStyle(fontSize: 14)),

                                          // action row: show full / translate
                                          Row(
                                            children: [
                                              if (summary != null)
                                                TextButton(
                                                  onPressed: () {
                                                    if (id == null) return;
                                                    setState(() => _expanded[id] = !isExpanded);
                                                  },
                                                  child: Text(isExpanded ? 'Afficher moins' : 'Voir le résumé'),
                                                ),
                                              const SizedBox(width: 8),
                                              TextButton.icon(
                                                onPressed: () {
                                                  if (id == null) return;
                                                  _translateComment(id, 'fr');
                                                },
                                                icon: const Icon(Icons.translate, size: 16),
                                                label: Text(_translated.containsKey(id) ? 'Original' : 'Traduire'),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // Champ de nouveau commentaire
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Écrire un commentaire...',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
                      onPressed: _addComment,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPreview(String url) {
    try {
      if (url.startsWith('http')) {
        return Image.network(url, fit: BoxFit.cover, width: double.infinity);
      } else {
        final file = File(url);
        return Image.file(file, fit: BoxFit.cover, width: double.infinity);
      }
    } catch (_) {
      return const Center(child: Icon(Icons.broken_image, color: Colors.grey));
    }
  }
}
