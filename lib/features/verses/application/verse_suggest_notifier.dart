import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/verse.dart';
import '../domain/verse_suggester.dart';

class VerseSuggestState {
  const VerseSuggestState({
    this.suggestions = const [],
    this.isLoading = false,
    this.query = '',
  });

  final List<Verse> suggestions;
  final bool isLoading;
  final String query;

  VerseSuggestState copyWith({
    List<Verse>? suggestions,
    bool? isLoading,
    String? query,
  }) {
    return VerseSuggestState(
      suggestions: suggestions ?? this.suggestions,
      isLoading: isLoading ?? this.isLoading,
      query: query ?? this.query,
    );
  }
}

final verseSuggestProvider =
    StateNotifierProvider.autoDispose<VerseSuggestNotifier, VerseSuggestState>(
  (ref) => VerseSuggestNotifier(ref.watch(verseSuggesterProvider)),
);

class VerseSuggestNotifier extends StateNotifier<VerseSuggestState> {
  VerseSuggestNotifier(this._suggester) : super(const VerseSuggestState());

  final VerseSuggester _suggester;
  Timer? _debounce;
  int _generation = 0;

  void onRequestChanged(String text) {
    _debounce?.cancel();
    final trimmed = text.trim();
    if (trimmed.length < 8) {
      state = state.copyWith(suggestions: [], isLoading: false, query: trimmed);
      return;
    }
    state = state.copyWith(isLoading: true, query: trimmed);
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _run(trimmed);
    });
  }

  Future<void> refresh([String? text]) async {
    _debounce?.cancel();
    final query = (text ?? state.query).trim();
    if (query.length < 8) {
      state = state.copyWith(suggestions: [], isLoading: false);
      return;
    }
    state = state.copyWith(isLoading: true, query: query);
    await _run(query);
  }

  Future<void> _run(String query) async {
    final gen = ++_generation;
    final results = await _suggester.suggest(query);
    if (!mounted || gen != _generation) return;
    state = state.copyWith(suggestions: results, isLoading: false);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
