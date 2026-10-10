import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/services/haptic_service.dart';
import '../models/deck_action.dart';
import '../models/deck_item.dart';

class DeckProvider extends ChangeNotifier {
  final WebSocketService _wsService;
  late StreamSubscription _messageSubscription;

  List<DeckPageModel> _pages = [];
  int _activePageIndex = 0;
  int _activeViewTab = 0; // 0 = Deck Grid, 1 = Trackpad

  List<DeckPageModel> get pages => _pages;
  DeckPageModel? get currentPage => _pages.isNotEmpty ? _pages[_activePageIndex] : null;
  int get activePageIndex => _activePageIndex;
  int get activeViewTab => _activeViewTab;

  DeckProvider(this._wsService) {
    _loadDefaultMockDeck();

    _messageSubscription = _wsService.messageStream.listen((msg) {
      if (msg.eventType == 'layout_update' && msg.payload != null) {
        _handleLayoutUpdate(msg.payload!);
      }
    });
  }

  void setActiveTab(int index) {
    _activeViewTab = index;
    HapticService.selection();
    notifyListeners();
  }

  void setActivePage(int index) {
    if (index >= 0 && index < _pages.length) {
      _activePageIndex = index;
      HapticService.selection();
      notifyListeners();
    }
  }

  void executeAction(DeckAction action) {
    HapticService.medium();
    _wsService.sendAction(action.toJson());
  }

  void sendTrackpadMove(double dx, double dy) {
    _wsService.sendAction({
      'type': 'trackpad_move',
      'dx': dx,
      'dy': dy,
    });
  }

  void sendTrackpadClick(String button) {
    HapticService.light();
    _wsService.sendAction({
      'type': 'trackpad_click',
      'button': button,
    });
  }

  void sendTrackpadScroll(double dx, double dy) {
    _wsService.sendAction({
      'type': 'trackpad_scroll',
      'dx': dx,
      'dy': dy,
    });
  }

  void addDeckItem(DeckItem item) {
    if (currentPage == null) return;

    final updatedItems = List<DeckItem>.from(currentPage!.items)..add(item);
    _updateCurrentPageItems(updatedItems);
  }

  void updateDeckItem(DeckItem item) {
    if (currentPage == null) return;

    final updatedItems = currentPage!.items.map((i) => i.id == item.id ? item : i).toList();
    _updateCurrentPageItems(updatedItems);
  }

  void deleteDeckItem(String itemId) {
    if (currentPage == null) return;

    final updatedItems = currentPage!.items.where((i) => i.id != itemId).toList();
    _updateCurrentPageItems(updatedItems);
  }

  void saveLayoutToServer() {
    HapticService.heavy();
    final layoutPayload = {
      'pages': _pages.map((p) => {
        'id': p.id,
        'title': p.title,
        'columns': p.columns,
        'items': p.items.map((i) => i.toJson()).toList(),
      }).toList(),
    };

    _wsService.saveLayout(layoutPayload);
  }

  void _updateCurrentPageItems(List<DeckItem> items) {
    if (currentPage == null) return;

    final updatedPage = DeckPageModel(
      id: currentPage!.id,
      title: currentPage!.title,
      columns: currentPage!.columns,
      items: items,
    );

    _pages[_activePageIndex] = updatedPage;
    notifyListeners();
    saveLayoutToServer();
  }

  void _handleLayoutUpdate(Map<String, dynamic> payload) {
    try {
      final rawPages = payload['pages'] as List? ?? [];
      _pages = rawPages.map((p) => DeckPageModel.fromJson(Map<String, dynamic>.from(p))).toList();
      if (_activePageIndex >= _pages.length) {
        _activePageIndex = 0;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[DeckProvider] Error parsing layout update: $e');
    }
  }

  void _loadDefaultMockDeck() {
    _pages = [
      DeckPageModel(
        id: 'page_dev_media',
        title: 'Desenvolvimento & Mídia',
        columns: 3,
        items: [
          DeckItem(
            id: 'btn_copy',
            title: 'Copiar',
            icon: 'copy',
            color: const Color(0xFF00E5FF),
            action: DeckAction(type: 'key_combination', key: 'c', modifiers: ['cmd'], label: 'Copiar Texto'),
          ),
          DeckItem(
            id: 'btn_paste',
            title: 'Colar',
            icon: 'paste',
            color: const Color(0xFF7C4DFF),
            action: DeckAction(type: 'key_combination', key: 'v', modifiers: ['cmd'], label: 'Colar Conteúdo'),
          ),
          DeckItem(
            id: 'btn_terminal',
            title: 'Terminal',
            icon: 'terminal',
            color: const Color(0xFF00E676),
            action: DeckAction(type: 'system_command', command: 'open -a Terminal', label: 'Abrir Terminal'),
          ),
          DeckItem(
            id: 'btn_vscode',
            title: 'VS Code',
            icon: 'code',
            color: const Color(0xFFFF9100),
            action: DeckAction(type: 'system_command', command: 'open -a "Visual Studio Code"', label: 'Abrir VS Code'),
          ),
          DeckItem(
            id: 'btn_play',
            title: 'Play/Pause',
            icon: 'play_pause',
            color: const Color(0xFFFF3D00),
            action: DeckAction(type: 'key_tap', key: 'space', label: 'Mídia Play/Pause'),
          ),
          DeckItem(
            id: 'btn_screenshot',
            title: 'Print Screen',
            icon: 'desktop',
            color: const Color(0xFFE91E63),
            action: DeckAction(type: 'key_combination', key: '4', modifiers: ['cmd', 'shift'], label: 'Captura de Tela'),
          ),
        ],
      ),
    ];
  }

  @override
  void dispose() {
    _messageSubscription.cancel();
    super.dispose();
  }
}
