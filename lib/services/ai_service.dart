import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

// Simple data model for extracted image features used by the fallback
class ImageFeatures {
  final String fileName;
  final int width;
  final int height;
  final String dominantColorHex;

  ImageFeatures({required this.fileName, required this.width, required this.height, required this.dominantColorHex});
}

class LegendResult {
  final List<String> suggestions;
  final bool usedFallback; // true if we used server-side text fallback (gpt-3.5)
  final bool usedLocalFallback; // true if we used local deterministic fallback
  final String? errorCode;
  final String? errorMessage;

  LegendResult({
    required this.suggestions,
    this.usedFallback = false,
    this.usedLocalFallback = false,
    this.errorCode,
    this.errorMessage,
  });
}

class AIService {
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';
  static const int _maxImageSize = 20 * 1024 * 1024; // 20MB limit
  static const String _model = 'gpt-4-vision-preview'; // Latest stable vision model
  
  void _logError(String message, dynamic error) {
    print('🔴 AI Service Error: $message');
    print('🔍 Error details: $error');
    if (error is http.Response) {
      print('📡 Status code: ${error.statusCode}');
      print('💾 Response body: ${error.body}');
    }
  }


  Future<String> _processImage(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    if (bytes.length > _maxImageSize) {
      print('📸 Image size exceeds limit, compressing...');
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('Failed to decode image');
      
      // Calculate new dimensions while maintaining aspect ratio
      double scale = math.sqrt(_maxImageSize / bytes.length);
      int newWidth = (image.width * scale).round();
      int newHeight = (image.height * scale).round();
      
      // Resize image
      final resized = img.copyResize(image, width: newWidth, height: newHeight);
      final compressed = img.encodeJpg(resized, quality: 80);
      print('📸 Compressed image from ${bytes.length} to ${compressed.length} bytes');
      return base64Encode(compressed);
    }
    
    print('📸 Image size within limits: ${bytes.length} bytes');
    return base64Encode(bytes);
  }
  final String _apiKey;
  final String? _hfApiKey;
  final String _hfImageModel;
  final bool _hfPreferOnly;

  AIService({required String apiKey, String? hfApiKey, String? hfImageModel, bool hfPreferOnly = false})
      : _apiKey = apiKey,
        _hfApiKey = hfApiKey,
        _hfImageModel = hfImageModel ?? '',
        _hfPreferOnly = hfPreferOnly;

  Future<String> generatePhotoCaption(String imagePath, {String? eventContext}) async {
    try {
      print('📸 Processing image: $imagePath');
      final base64String = await _processImage(imagePath);
      print('📤 Image processed and encoded successfully');
      
      String prompt = 'You are an expert photo caption generator. Generate a natural, engaging caption for this event photo that captures its essence and mood.';
      if (eventContext != null) {
        prompt += ' Context: This photo was taken at $eventContext.';
      }
      prompt += ' Please provide a single, well-crafted caption.';

      print('🔄 Sending request to OpenAI API...');
      final requestBody = {
        'model': _model,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': prompt
              },
              {
                'type': 'image_url',
                'url': 'data:image/jpeg;base64,$base64String'
              }
            ]
          }
        ],
        'max_tokens': 300
      };
      
      print('📝 Request structure:');
      print(jsonEncode(requestBody));

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(requestBody),
      );

      print('📥 Received response with status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final caption = data['choices'][0]['message']['content'];
        print('✅ Caption generated successfully: $caption');
        return caption;
      } else {
        // Try to detect model-not-found and fallback
        try {
          final err = jsonDecode(response.body);
          final code = err['error']?['code'];
          if (code == 'model_not_found' || response.statusCode == 404) {
            print('⚠️ Vision model not available or not accessible. Falling back to text-only caption generation.');
            return await _generateFromFeatures(imagePath, eventContext: eventContext);
          }
        } catch (_) {}

        _logError('API request failed', response);
        throw Exception('Failed to generate caption - Status ${response.statusCode}');
      }
    } catch (e) {
      _logError('Caption generation failed', e);
      rethrow;
    }
  }

  Future<LegendResult> suggestPhotoLegends(String imagePath, {String? eventContext}) async {
    try {
      print('📸 Processing image for legends: $imagePath');

      // If Hugging Face credentials & model are provided, try HF image-captioning first
      if (_hfApiKey != null && _hfApiKey.isNotEmpty && _hfImageModel.isNotEmpty) {
        try {
          final hfSuggestions = await _suggestWithHuggingFace(imagePath, eventContext: eventContext);
          return LegendResult(suggestions: hfSuggestions, usedFallback: false);
        } catch (e) {
          // If HF is configured to be preferred-only, surface the HF error to the caller instead of falling back.
          _logError('Hugging Face suggestion failed', e);
          if (_hfPreferOnly) {
            String code = 'hf_error';
            String msg = e.toString();
            // If the exception is an http.Response encoded as a string, keep it simple
            return LegendResult(suggestions: [], usedFallback: false, errorCode: code, errorMessage: msg);
          }
          // else continue to OpenAI fallback
        }
      }

      final base64String = await _processImage(imagePath);
      print('📤 Image processed and encoded successfully');
      
      String prompt = 'You are an expert photo caption writer. Generate 3 different creative photo legends for this image with these styles:\n1. Descriptive and informative\n2. Creative and artistic\n3. Fun and casual\nSeparate each caption with a newline.';
      if (eventContext != null) {
        prompt += '\nContext: This photo was taken at $eventContext. Consider this setting in your captions.';
      }
      prompt += '\nMake each caption distinct and engaging.';

      print('🔄 Sending request to OpenAI API for legend suggestions...');
      final requestBody = {
        'model': _model,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': prompt
              },
              {
                'type': 'image_url',
                'url': 'data:image/jpeg;base64,$base64String'
              }
            ]
          }
        ],
        'max_tokens': 300
      };
      
      print('📝 Request structure:');
      print(jsonEncode(requestBody));

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(requestBody),
      );

      print('📥 Received response with status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        final legends = content.split('\n').where((line) => line.trim().isNotEmpty).toList();
        print('✅ Generated ${legends.length} legends successfully');
        print('📝 Legends: \n${legends.join('\n')}');
        return LegendResult(suggestions: legends, usedFallback: false);
      } else {
        // If model not found, fallback to text-only generation using extracted features
        try {
          final err = jsonDecode(response.body);
          final code = err['error']?['code'];
          if (code == 'model_not_found' || response.statusCode == 404) {
            print('⚠️ Vision model not available or not accessible. Attempting server text-only legend generation.');
            // Try server text fallback but catch quota errors there
            try {
              final serverLegends = await _suggestFromFeatures(imagePath, eventContext: eventContext);
              return LegendResult(suggestions: serverLegends, usedFallback: true);
            } catch (e) {
              // If server text fallback failed (quota or other), return error info
              if (e is http.Response) {
                try {
                  final err = jsonDecode(e.body);
                  final code2 = err['error']?['code'];
                  final msg2 = err['error']?['message'];
                  return LegendResult(suggestions: [], usedFallback: false, errorCode: code2, errorMessage: msg2);
                } catch (_) {
                  return LegendResult(suggestions: [], usedFallback: false, errorCode: 'server_fallback_failed', errorMessage: e.toString());
                }
              }
              return LegendResult(suggestions: [], usedFallback: false, errorCode: 'server_fallback_failed', errorMessage: e.toString());
            }
          }
        } catch (_) {}

        _logError('API request failed for legends', response);
        // Map quota and other errors to structured result
        try {
          final err = jsonDecode(response.body);
          final code2 = err['error']?['code'];
          final msg2 = err['error']?['message'];
          return LegendResult(suggestions: [], usedFallback: false, errorCode: code2, errorMessage: msg2);
        } catch (_) {
          return LegendResult(suggestions: [], usedFallback: false, errorCode: 'api_error', errorMessage: response.body);
        }
      }
    } catch (e) {
      _logError('Legend generation failed', e);
      return LegendResult(suggestions: [], usedFallback: false, errorCode: 'exception', errorMessage: e.toString());
    }
  }

  // Try Hugging Face image-captioning endpoint and produce 3 styled variants locally.
  Future<List<String>> _suggestWithHuggingFace(String imagePath, {String? eventContext}) async {
    if (_hfApiKey == null || _hfApiKey.isEmpty || _hfImageModel.isEmpty) {
      throw Exception('Hugging Face API Key or model not configured');
    }

    final rawBytes = await File(imagePath).readAsBytes();
    List<int> payload = rawBytes;

    // simple compression if too large
    if (payload.length > _maxImageSize) {
      final image = img.decodeImage(payload);
      if (image != null) {
        final scale = math.sqrt(_maxImageSize / payload.length);
        final newW = (image.width * scale).round();
        final newH = (image.height * scale).round();
        final resized = img.copyResize(image, width: newW, height: newH);
        payload = img.encodeJpg(resized, quality: 80);
        print('📸 Compressed image for HF from ${rawBytes.length} to ${payload.length} bytes');
      }
    }

    final uri = Uri.parse('https://api-inference.huggingface.co/models/$_hfImageModel');
    final resp = await http.post(uri, headers: {
      'Authorization': 'Bearer $_hfApiKey',
      'Content-Type': 'application/octet-stream'
    }, body: payload);

    if (resp.statusCode == 200) {
      try {
        final body = jsonDecode(resp.body);
        String caption = '';
        if (body is Map && body['generated_text'] != null) {
          caption = body['generated_text'];
        } else if (body is List && body.isNotEmpty && body[0]['generated_text'] != null) {
          caption = body[0]['generated_text'];
        } else if (body is String) {
          caption = body;
        } else {
          caption = resp.body;
        }

        // Clean model output to prefer short caption-style strings
        String cleaned = caption.trim();
        cleaned = cleaned.replaceAll(RegExp(r'(?i)scaled\s*\d+[:\-]?'), '');
        cleaned = cleaned.replaceAll(RegExp(r'\d+x\d+'), '');
        cleaned = cleaned.replaceAll(RegExp(r'\bphoto\b', caseSensitive: false), '');
        cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
        if (cleaned.isEmpty) cleaned = caption;

        final desc = _capitalize(cleaned);
        final creative = '$desc — a poetic capture.';
        final casual = '$desc — good times.';

        final suggestions = [desc, creative, casual];
        if (eventContext != null && eventContext.trim().isNotEmpty) {
          return suggestions.map((s) => '$s (at $eventContext)').toList();
        }
        return suggestions;
      } catch (e) {
        _logError('Failed to parse HF response', e);
        throw Exception('Failed to parse HF response');
      }
    }

    // Parse common HF error bodies to provide a clearer message
    String errMsg = 'Hugging Face inference failed - Status ${resp.statusCode}';
    try {
      final errBody = jsonDecode(resp.body);
      if (errBody is Map && errBody['error'] != null) {
        errMsg = '${errBody['error']}';
      } else if (errBody is Map && errBody['detail'] != null) {
        errMsg = '${errBody['detail']}';
      } else if (errBody is String) {
        errMsg = errBody;
      }
    } catch (_) {
      // leave default
    }

    _logError('Hugging Face inference failed', resp);
    throw Exception('$errMsg (status ${resp.statusCode})');
  }

  // Extract a few simple features from the image: filename, dimensions and an average color
  Future<ImageFeatures> _extractImageFeatures(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image for feature extraction');

    final width = image.width;
    final height = image.height;

    // Compute a simple average color sampling every Nth pixel to keep it fast
    int sampleStep = 10;
    int rSum = 0, gSum = 0, bSum = 0, count = 0;
    for (int y = 0; y < height; y += sampleStep) {
      for (int x = 0; x < width; x += sampleStep) {
        final p = image.getPixel(x, y);
        rSum += img.getRed(p);
        gSum += img.getGreen(p);
        bSum += img.getBlue(p);
        count++;
      }
    }
    if (count == 0) count = 1;
    final rAvg = (rSum / count).round();
    final gAvg = (gSum / count).round();
    final bAvg = (bSum / count).round();
    final hex = '#${rAvg.toRadixString(16).padLeft(2, '0')}${gAvg.toRadixString(16).padLeft(2, '0')}${bAvg.toRadixString(16).padLeft(2, '0')}'.toUpperCase();

    final fileName = path.basename(imagePath);
    return ImageFeatures(fileName: fileName, width: width, height: height, dominantColorHex: hex);
  }

  // Text-only fallback: generate a caption from image features using a text model
  Future<String> _generateFromFeatures(String imagePath, {String? eventContext}) async {
    final features = await _extractImageFeatures(imagePath);
    final prompt = StringBuffer();
    prompt.writeln('You are a helpful assistant that writes photo captions.');
    prompt.writeln('Image file: ${features.fileName}');
    prompt.writeln('Dimensions: ${features.width}x${features.height}');
    prompt.writeln('Dominant color (approx): ${features.dominantColorHex}');
    if (eventContext != null) prompt.writeln('Event context: $eventContext');
    prompt.writeln('\nGenerate a single natural, engaging caption for this photo.');

    final body = {
      'model': 'gpt-3.5-turbo',
      'messages': [
        {'role': 'user', 'content': prompt.toString()}
      ],
      'max_tokens': 150
    };

    final resp = await http.post(Uri.parse(_apiUrl), headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey'
    }, body: jsonEncode(body));

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return data['choices'][0]['message']['content'] as String;
    }
    _logError('Fallback text caption request failed', resp);
    throw Exception('Fallback caption generation failed - Status ${resp.statusCode}');
  }

  Future<List<String>> _suggestFromFeatures(String imagePath, {String? eventContext}) async {
    final features = await _extractImageFeatures(imagePath);
    final prompt = StringBuffer();
    prompt.writeln('You are a creative assistant that writes photo captions.');
    prompt.writeln('Image file: ${features.fileName}');
    prompt.writeln('Dimensions: ${features.width}x${features.height}');
    prompt.writeln('Dominant color (approx): ${features.dominantColorHex}');
    if (eventContext != null) prompt.writeln('Event context: $eventContext');
    prompt.writeln('\nGenerate 3 unique captions in different styles: descriptive, creative, and casual. Separate them with newlines.');

    final body = {
      'model': 'gpt-3.5-turbo',
      'messages': [
        {'role': 'user', 'content': prompt.toString()}
      ],
      'max_tokens': 250
    };

    final resp = await http.post(Uri.parse(_apiUrl), headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey'
    }, body: jsonEncode(body));

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final content = data['choices'][0]['message']['content'] as String;
      return content.split('\n').where((line) => line.trim().isNotEmpty).toList();
    }
    _logError('Fallback text legends request failed', resp);
    throw Exception('Fallback legends generation failed - Status ${resp.statusCode}');
  }

  // Local deterministic fallback: produce captions from simple image features without any network calls.
  Future<List<String>> localSuggestFromFeatures(String imagePath, {String? eventContext, int? seed}) async {
    try {
      final features = await _extractImageFeatures(imagePath);
      var titleBase = path.basenameWithoutExtension(features.fileName).replaceAll(RegExp(r'[_\-]'), ' ');
      // Clean noisy tokens (scaled markers, long numeric ids, dimensions)
      titleBase = titleBase.replaceAll(RegExp(r'(?i)scaled'), '');
      titleBase = titleBase.replaceAll(RegExp(r'\b\d{4,}\b'), '');
      titleBase = titleBase.replaceAll(RegExp(r'\d+x\d+'), '');
      titleBase = titleBase.replaceAll(RegExp(r'\s+'), ' ').trim();

      final base = titleBase.isNotEmpty ? _capitalize(titleBase) : 'A moment';
      final suffix = (eventContext != null && eventContext.trim().isNotEmpty) ? ' at $eventContext' : '';

  // Use seeded Random when seed provided, otherwise use time-based randomness
  final rnd = (seed == null) ? math.Random() : math.Random(seed ^ features.fileName.hashCode);

      // Larger pools for better variety
      final adjectives = [
        'golden', 'joyful', 'quiet', 'vibrant', 'serene', 'breezy', 'cozy', 'lively', 'sunlit', 'radiant', 'playful',
        'nostalgic', 'colorful', 'gentle', 'sparkling', 'warm', 'bold', 'soft', 'whimsical', 'calm'
      ];
      final actions = [
        'captured', 'remembered', 'shared', 'cherished', 'enjoyed', 'celebrated', 'savored', 'embraced', 'fleeting', 'found'
      ];
      final moods = ['vibes', 'moments', 'memories', 'times', 'scene', 'moment'];
      final nouns = ['moment', 'memory', 'scene', 'snapshot', 'afternoon', 'evening', 'gathering'];

      String pick(List<String> list) => list[rnd.nextInt(list.length)];

      // Build many candidate templates to improve shuffle variety. Also
      // include a pool of static example captions so users see a wider
      // range even when image metadata is sparse.
      final List<String> candidates = [];
      for (int i = 0; i < 40; i++) {
        final pattern = i % 6;
        switch (pattern) {
          case 0:
            candidates.add('$base ${pick(actions)}$suffix.');
            break;
          case 1:
            candidates.add('$base — ${pick(adjectives)} and ${pick(adjectives)}$suffix.');
            break;
          case 2:
            candidates.add('${_capitalize(pick(adjectives))} $base${suffix.isNotEmpty ? ' $suffix' : ''}.');
            break;
          case 3:
            candidates.add('${base.split(' ').first} ${pick(moods)}$suffix.');
            break;
          case 4:
            candidates.add('$base, ${pick(adjectives)} and bright$suffix.');
            break;
          default:
            candidates.add('A ${pick(adjectives)} ${pick(nouns)}${suffix.isNotEmpty ? ' at $eventContext' : ''}.');
        }
      }

      // Static examples to ensure more variety for users who want quick picks
      final staticExamples = [
        'Sunset hues and happy crowds.',
        'Caught in a candid moment of joy.',
        'When the music takes over.',
        'Laughter that fills the night.',
        'Tiny details, big memories.',
        'Good friends, good vibes.',
        'A snapshot of summer.',
        'Moments like these stay with you.',
        'Smiles that say it all.',
        'City lights and warm nights.',
        'Adventure captured in a frame.',
        'Dancing under the open sky.',
        'A golden hour to remember.',
        'Unexpected magic in the crowd.',
        'That feeling when everything clicks.'
      ];
      candidates.addAll(staticExamples);

      // Shuffle using a secure RNG when not seeded to reduce repetition
      if (seed == null) {
        try {
          candidates.shuffle(math.Random.secure());
        } catch (_) {
          candidates.shuffle(rnd);
        }
      } else {
        candidates.shuffle(rnd);
      }

      // Normalize and dedupe keeping order
      final seen = <String>{};
      final List<String> out = [];
      for (var c in candidates) {
        var s = c.replaceAll(RegExp(r'\s+'), ' ').trim();
        if (s.isEmpty) continue;
        if (!seen.contains(s)) {
          seen.add(s);
          out.add(s);
        }
      }

  // Return up to 6 suggestions so the UI can offer more variety.
  // The UI will show however many suggestions are returned.
  return out.take(6).toList();
    } catch (e) {
      _logError('Local suggestion generation failed', e);
      return ['A lovely moment', 'Captured memories', 'Good times'];
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}