import 'package:flutter/material.dart';
import 'deck_action.dart';

class DeckItem {
  final String id;
  final String title;
  final String icon;
  final Color color;
  final DeckAction action;

  DeckItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.action,
  });

  factory DeckItem.fromJson(Map<String, dynamic> json) {
    return DeckItem(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Macro',
      icon: json['icon'] ?? 'star',
      color: _parseHexColor(json['color']),
      action: DeckAction.fromJson(Map<String, dynamic>.from(json['action'] ?? {})),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'icon': icon,
      'color': '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
      'action': action.toJson(),
    };
  }

  static Color _parseHexColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) {
      return const Color(0xFF00E5FF);
    }
    try {
      final cleanHex = hexString.replaceFirst('#', '');
      return Color(int.parse('FF$cleanHex', radix: 16));
    } catch (_) {
      return const Color(0xFF00E5FF);
    }
  }

  IconData getIconData() {
    switch (icon) {
      case 'copy':
        return Icons.copy_rounded;
      case 'paste':
        return Icons.content_paste_rounded;
      case 'terminal':
        return Icons.terminal_rounded;
      case 'skip_previous':
        return Icons.skip_previous_rounded;
      case 'play_pause':
        return Icons.play_arrow_rounded;
      case 'skip_next':
        return Icons.skip_next_rounded;
      case 'volume_up':
        return Icons.volume_up_rounded;
      case 'volume_down':
        return Icons.volume_down_rounded;
      case 'code':
        return Icons.code_rounded;
      case 'desktop':
        return Icons.desktop_windows_rounded;
      default:
        return Icons.touch_app_rounded;
    }
  }
}

class DeckPageModel {
  final String id;
  final String title;
  final int columns;
  final List<DeckItem> items;

  DeckPageModel({
    required this.id,
    required this.title,
    required this.columns,
    required this.items,
  });

  factory DeckPageModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    final itemsList = rawItems.map((item) => DeckItem.fromJson(Map<String, dynamic>.from(item))).toList();

    return DeckPageModel(
      id: json['id'] ?? 'page_1',
      title: json['title'] ?? 'Deck',
      columns: json['columns'] ?? 3,
      items: itemsList,
    );
  }
}
