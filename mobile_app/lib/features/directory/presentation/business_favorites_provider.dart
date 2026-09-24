import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String _favoritesKey = 'user_business_favorites_set';

class BusinessFavoritesNotifier extends Notifier<Set<int>> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Set<int> build() {
    _loadFavorites();
    return {};
  }

  Future<void> _loadFavorites() async {
    try {
      final jsonStr = await _storage.read(key: _favoritesKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr);
        state = list.map((e) => (e as num).toInt()).toSet();
      }
    } catch (_) {
      state = {};
    }
  }

  bool isFavorite(int businessId) {
    return state.contains(businessId);
  }

  Future<bool> toggleFavorite(int businessId) async {
    final updated = Set<int>.from(state);
    bool isNowFav;
    if (updated.contains(businessId)) {
      updated.remove(businessId);
      isNowFav = false;
    } else {
      updated.add(businessId);
      isNowFav = true;
    }
    state = updated;
    try {
      await _storage.write(key: _favoritesKey, value: jsonEncode(updated.toList()));
    } catch (_) {}
    return isNowFav;
  }
}

final businessFavoritesProvider =
    NotifierProvider<BusinessFavoritesNotifier, Set<int>>(BusinessFavoritesNotifier.new);
