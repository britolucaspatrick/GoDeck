import 'package:flutter/material.dart';

class DesktopAppModel {
  final String id;
  final String name;
  final String path;
  final String icon;
  final bool isFavorite;

  DesktopAppModel({
    required this.id,
    required this.name,
    required this.path,
    required this.icon,
    this.isFavorite = false,
  });

  factory DesktopAppModel.fromJson(Map<String, dynamic> json, {bool isFavorite = false}) {
    return DesktopAppModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Programa',
      path: json['path'] ?? '',
      icon: json['icon'] ?? 'desktop',
      isFavorite: isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'icon': icon,
    };
  }

  DesktopAppModel copyWith({bool? isFavorite}) {
    return DesktopAppModel(
      id: id,
      name: name,
      path: path,
      icon: icon,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  IconData getIconData() {
    switch (icon) {
      case 'code':
        return Icons.code_rounded;
      case 'terminal':
        return Icons.terminal_rounded;
      case 'globe':
        return Icons.language_rounded;
      case 'music':
        return Icons.music_note_rounded;
      case 'folder':
        return Icons.folder_rounded;
      case 'calculator':
        return Icons.calculate_rounded;
      case 'edit':
        return Icons.edit_note_rounded;
      default:
        return Icons.desktop_windows_rounded;
    }
  }
}
