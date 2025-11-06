import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

enum ImageFilter {
  none,
  sepia,
  grayscale,
  vintage,
  brightness,
  saturation,
  contrast,
  warmth,
}

class ImageFilterUtils {
  static Future<String> applyFilter(String imagePath, ImageFilter filter, {double intensity = 1.0}) async {
    // Read the image file
    final File imageFile = File(imagePath);
    final List<int> imageBytes = await imageFile.readAsBytes();
    final img.Image? originalImage = img.decodeImage(imageBytes);

    if (originalImage == null) throw Exception('Could not decode image');

    late img.Image filteredImage;

    switch (filter) {
      case ImageFilter.none:
        return imagePath;
      
      case ImageFilter.sepia:
        filteredImage = _applySepiaEffect(originalImage, intensity);
        break;
      
      case ImageFilter.grayscale:
        filteredImage = img.grayscale(originalImage);
        break;
      
      case ImageFilter.vintage:
        filteredImage = _applyVintageEffect(originalImage, intensity);
        break;
      
      case ImageFilter.brightness:
        final brightened = img.brightness(originalImage, (intensity * 100).round());
        if (brightened == null) throw Exception('Failed to adjust brightness');
        filteredImage = brightened;
        break;
      
      case ImageFilter.saturation:
        filteredImage = _adjustSaturation(originalImage, intensity);
        break;
      
      case ImageFilter.contrast:
        final contrasted = img.contrast(originalImage, (intensity * 100).round());
        if (contrasted == null) throw Exception('Failed to adjust contrast');
        filteredImage = contrasted;
        break;
      
      case ImageFilter.warmth:
        filteredImage = _adjustWarmth(originalImage, intensity);
        break;
    }

    // Save the filtered image
    final String newPath = await _saveFilteredImage(filteredImage, imagePath, filter.name);
    return newPath;
  }

  static img.Image _applySepiaEffect(img.Image original, double intensity) {
    return img.colorOffset(original,
      red: (20 * intensity).round(),
      green: (-15 * intensity).round(),
      blue: (-40 * intensity).round());
  }

  static img.Image _applyVintageEffect(img.Image original, double intensity) {
    var filtered = original.clone();
    filtered = img.sepia(filtered);
    
    final contrasted = img.contrast(filtered, (20 * intensity).round());
    if (contrasted == null) throw Exception('Failed to adjust vintage contrast');
    filtered = contrasted;
    
    filtered = img.vignette(filtered);
    return filtered;
  }

  static img.Image _adjustSaturation(img.Image original, double intensity) {
    return img.adjustColor(original,
      saturation: intensity,
      gamma: 1.0);
  }

  static img.Image _adjustWarmth(img.Image original, double intensity) {
    return img.colorOffset(original,
      red: (10 * intensity).round(),
      blue: (-10 * intensity).round());
  }

  static Future<String> _saveFilteredImage(img.Image filteredImage, String originalPath, String filterName) async {
    final directory = await getTemporaryDirectory();
    final fileName = path.basenameWithoutExtension(originalPath);
    final extension = path.extension(originalPath);
    final newPath = path.join(directory.path, '${fileName}_$filterName$extension');
    
    final File filteredFile = File(newPath);
    await filteredFile.writeAsBytes(img.encodeJpg(filteredImage, quality: 90));
    
    return newPath;
  }

  static List<FilterPreview> getFilterPreviews() {
    return [
      FilterPreview(
        name: 'Original',
        filter: ImageFilter.none,
        icon: Icons.refresh,
      ),
      FilterPreview(
        name: 'Sépia',
        filter: ImageFilter.sepia,
        icon: Icons.filter_vintage,
      ),
      FilterPreview(
        name: 'Noir & Blanc',
        filter: ImageFilter.grayscale,
        icon: Icons.monochrome_photos,
      ),
      FilterPreview(
        name: 'Vintage',
        filter: ImageFilter.vintage,
        icon: Icons.camera_roll,
      ),
      FilterPreview(
        name: 'Luminosité',
        filter: ImageFilter.brightness,
        icon: Icons.brightness_6,
        hasSlider: true,
      ),
      FilterPreview(
        name: 'Saturation',
        filter: ImageFilter.saturation,
        icon: Icons.palette,
        hasSlider: true,
      ),
      FilterPreview(
        name: 'Contraste',
        filter: ImageFilter.contrast,
        icon: Icons.contrast,
        hasSlider: true,
      ),
      FilterPreview(
        name: 'Chaleur',
        filter: ImageFilter.warmth,
        icon: Icons.wb_sunny,
        hasSlider: true,
      ),
    ];
  }
}

class FilterPreview {
  final String name;
  final ImageFilter filter;
  final IconData icon;
  final bool hasSlider;

  FilterPreview({
    required this.name,
    required this.filter,
    required this.icon,
    this.hasSlider = false,
  });
}