import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../config/app_config.dart';

class AILegendSuggestions extends StatefulWidget {
  final String imagePath;
  final String? eventContext;
  final Function(String) onLegendSelected;

  const AILegendSuggestions({
    Key? key,
    required this.imagePath,
    this.eventContext,
    required this.onLegendSelected,
  }) : super(key: key);

  @override
  State<AILegendSuggestions> createState() => _AILegendSuggestionsState();
}

class _AILegendSuggestionsState extends State<AILegendSuggestions> {
  final AIService _aiService = AIService(
    apiKey: AppConfig.openAIKey,
    hfApiKey: AppConfig.hfApiKey,
    hfImageModel: AppConfig.hfImageModel,
    hfPreferOnly: AppConfig.hfUseOnly,
  );
  LegendResult? _result;
  String? _error;
  bool _isLoading = false;
  int _currentIndex = 0;
  // (no local seed required; using time-based randomness for local fallback)

  Future<void> _generateSuggestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

        try {
      if (AppConfig.forceLocalFallback) {
        // pass null seed to enable time-based randomness for varied captions
        final local = await _aiService.localSuggestFromFeatures(
          widget.imagePath,
          eventContext: widget.eventContext,
          seed: null,
        );
        setState(() {
          _result = LegendResult(suggestions: local, usedLocalFallback: true);
          _currentIndex = 0;
          _isLoading = false;
        });
      } else {
        final res = await _aiService.suggestPhotoLegends(
          widget.imagePath,
          eventContext: widget.eventContext,
        );
        setState(() {
          _result = res;
          _currentIndex = 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _useLocalFallback() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // request a fresh randomized set
      final local = await _aiService.localSuggestFromFeatures(
        widget.imagePath,
        eventContext: widget.eventContext,
        seed: null,
      );
      setState(() {
        _result = LegendResult(suggestions: local, usedLocalFallback: true);
        _currentIndex = 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _selectLegend(String legend) {
    // Notify parent and hide suggestions
    try {
      widget.onLegendSelected(legend);
    } finally {
      setState(() {
        _result = null;
        _error = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'AI Caption Suggestions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if ((_result == null || (_result?.suggestions.isEmpty ?? true)) && !_isLoading)
                ElevatedButton.icon(
                  onPressed: _generateSuggestions,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Generate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5A3C),
                  ),
                ),
            ],
          ),
        ),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error: $_error',
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _generateSuggestions,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _useLocalFallback,
                      icon: const Icon(Icons.offline_bolt),
                      label: const Text('Use local fallback'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    ),
                  ],
                ),
              ],
            ),
          )
        else if (_result != null && (_result!.errorMessage != null && _result!.errorMessage!.isNotEmpty))
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error: ${_result!.errorMessage}',
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _generateSuggestions,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _useLocalFallback,
                      icon: const Icon(Icons.offline_bolt),
                      label: const Text('Use local fallback'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    ),
                  ],
                ),
              ],
            ),
          )
        else if (_result != null && _result!.suggestions.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    if (_result!.usedFallback)
                      const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: Chip(label: Text('server fallback')),
                      ),
                    if (_result!.usedLocalFallback)
                      const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: Chip(label: Text('local fallback')),
                      ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        // If we already have suggestions, show the next one in the list.
                        // When we reach the end of the current list, request a fresh set.
                        if (_result != null && _result!.suggestions.isNotEmpty) {
                          if (_currentIndex < _result!.suggestions.length - 1) {
                            setState(() => _currentIndex = _currentIndex + 1);
                            return;
                          }
                        }

                        // Otherwise (no suggestions yet, or at the end) request new suggestions.
                        if (_result?.usedLocalFallback ?? false) {
                          _useLocalFallback();
                        } else {
                          _generateSuggestions();
                        }
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Regenerate'),
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          _result!.suggestions[_currentIndex],
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () => _selectLegend(_result!.suggestions[_currentIndex]),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Use'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}