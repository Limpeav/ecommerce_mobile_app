import 'package:shared_preferences/shared_preferences.dart';

/// Service managing persistent recent search keywords in SharedPreferences,
/// along with curated trending search tags.
class SearchHistoryService {
  static const String _key = 'recent_search_history';
  static const int maxRecentItems = 10;

  final SharedPreferences _preferences;

  SearchHistoryService({required SharedPreferences preferences})
      : _preferences = preferences;

  /// Default curated trending search tags for Cherish Baby Store
  static const List<String> trendingSearches = [
    'Organic Cotton Romper',
    'Convertible Crib',
    'Silicone Feeding Set',
    'Baby Stroller',
    'Toddler Sneakers',
    'Baby Bath Tub',
    'Anti-Colic Bottle',
    'Wooden Play Gym',
    'Swaddle Blanket',
  ];

  /// Get current recent searches (most recent first)
  List<String> getHistory() {
    return _preferences.getStringList(_key) ?? [];
  }

  /// Add a new query to recent history (deduplicated, moving to top)
  Future<List<String>> addSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return getHistory();

    final current = getHistory().where((item) => item.toLowerCase() != clean.toLowerCase()).toList();
    current.insert(0, clean);

    if (current.length > maxRecentItems) {
      current.removeRange(maxRecentItems, current.length);
    }

    await _preferences.setStringList(_key, current);
    return current;
  }

  /// Remove a specific query from recent history
  Future<List<String>> removeSearch(String query) async {
    final current = getHistory().where((item) => item != query).toList();
    await _preferences.setStringList(_key, current);
    return current;
  }

  /// Clear all search history
  Future<void> clearHistory() async {
    await _preferences.remove(_key);
  }
}
