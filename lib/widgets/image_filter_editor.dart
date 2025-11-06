import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/image_filters.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ImageFilterEditor extends StatefulWidget {
  final String imagePath;
  final Function(String) onImageFiltered;

  const ImageFilterEditor({
    Key? key,
    required this.imagePath,
    required this.onImageFiltered,
  }) : super(key: key);

  @override
  State<ImageFilterEditor> createState() => _ImageFilterEditorState();
}

class _ImageFilterEditorState extends State<ImageFilterEditor> {
  late String _currentImagePath;
  ImageFilter _selectedFilter = ImageFilter.none;
  double _intensity = 1.0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.imagePath;
  }

  Future<void> _applyFilter(ImageFilter filter, {double? intensity}) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // Apply filter to the current image path instead of the original
      final filteredPath = await ImageFilterUtils.applyFilter(
        _currentImagePath,
        filter,
        intensity: intensity ?? 1.0,
      );

      setState(() {
        _currentImagePath = filteredPath;
        _selectedFilter = filter;
        if (intensity != null) _intensity = intensity;
      });

      widget.onImageFiltered(filteredPath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'application du filtre: $e')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Image preview
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.file(
                File(_currentImagePath),
                fit: BoxFit.contain,
              ),
              if (_isProcessing)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Filter intensity slider
        if (_selectedFilter != ImageFilter.none &&
            ImageFilterUtils.getFilterPreviews()
                .firstWhere((f) => f.filter == _selectedFilter)
                .hasSlider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.tune),
                Expanded(
                  child: Slider(
                    value: _intensity,
                    min: 0.0,
                    max: 2.0,
                    divisions: 100,
                    label: _intensity.toStringAsFixed(2),
                    onChanged: (value) {
                      setState(() => _intensity = value);
                    },
                    onChangeEnd: (value) {
                      _applyFilter(_selectedFilter, intensity: value);
                    },
                  ),
                ),
              ],
            ),
          ),

        // Filter options
        Container(
          height: 100,
          color: Colors.black87,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            children: ImageFilterUtils.getFilterPreviews().map((preview) {
              final isSelected = _selectedFilter == preview.filter;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.white24,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: () => _applyFilter(preview.filter),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 50,
                          height: 50,
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            preview.icon,
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview.name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Clean up temporary files
    if (_currentImagePath != widget.imagePath) {
      File(_currentImagePath).delete().ignore();
    }
    super.dispose();
  }
}