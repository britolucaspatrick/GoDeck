import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/services/haptic_service.dart';
import '../models/desktop_app.dart';

class AppsProvider extends ChangeNotifier {
  final WebSocketService _wsService;
  late StreamSubscription _messageSubscription;

  List<DesktopAppModel> _allApps = [];
  Set<String> _favoriteIds = {};
  String _searchQuery = '';
  bool _isLoading = false;

  List<DesktopAppModel> get allApps => _allApps;
  Set<String> get favoriteIds => _favoriteIds;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  List<DesktopAppModel> get filteredApps {
    if (_searchQuery.isEmpty) return _allApps;
    return _allApps
        .where((app) => app.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  List<DesktopAppModel> get favoriteApps {
    return _allApps.where((app) => app.isFavorite).toList();
  }

  AppsProvider(this._wsService) {
    _loadFavorites();

    _messageSubscription = _wsService.messageStream.listen((msg) {
      if (msg.eventType == 'apps_list' && msg.payload != null) {
        _handleAppsList(msg.payload!);
      }
    });
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('godeck_favorite_apps') ?? [];
    _favoriteIds = saved.toSet();
    _applyFavorites();
  }

  Future<void> toggleFavorite(String appId) async {
    HapticService.selection();
    if (_favoriteIds.contains(appId)) {
      _favoriteIds.remove(appId);
    } else {
      _favoriteIds.add(appId);
    }

    _applyFavorites();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('godeck_favorite_apps', _favoriteIds.toList());
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void fetchApps() {
    _isLoading = true;
    notifyListeners();
    _wsService.requestApps();
  }

  void launchApp(DesktopAppModel app) {
    HapticService.heavy();
    _wsService.launchApp(app.name, app.path);
  }

  void _handleAppsList(Map<String, dynamic> payload) {
    _isLoading = false;
    try {
      final rawApps = payload['apps'] as List? ?? [];
      _allApps = rawApps.map((a) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(a);
        final id = map['id'] ?? map['name'] ?? '';
        final isFav = _favoriteIds.contains(id);
        return DesktopAppModel.fromJson(map, isFavorite: isFav);
      }).toList();

      _allApps.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    } catch (e) {
      debugPrint('[AppsProvider] Error parsing apps list: $e');
    }
  }

  void _applyFavorites() {
    _allApps = _allApps.map((app) {
      return app.copyWith(isFavorite: _favoriteIds.contains(app.id));
    }).toList();
    notifyListeners();
  }

  @override
  void dispose() {
    _messageSubscription.cancel();
    super.dispose();
  }
}
