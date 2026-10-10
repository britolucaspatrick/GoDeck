class DeckAction {
  final String type; // key_combination, key_tap, text_input, trackpad_move, trackpad_click, trackpad_scroll, system_command
  final String? key;
  final List<String>? modifiers;
  final String? text;
  final double? dx;
  final double? dy;
  final String? button;
  final String? command;
  final String? label;

  DeckAction({
    required this.type,
    this.key,
    this.modifiers,
    this.text,
    this.dx,
    this.dy,
    this.button,
    this.command,
    this.label,
  });

  factory DeckAction.fromJson(Map<String, dynamic> json) {
    return DeckAction(
      type: json['type'] ?? 'key_tap',
      key: json['key'],
      modifiers: json['modifiers'] != null ? List<String>.from(json['modifiers']) : null,
      text: json['text'],
      dx: (json['dx'] as num?)?.toDouble(),
      dy: (json['dy'] as num?)?.toDouble(),
      button: json['button'],
      command: json['command'],
      label: json['label'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (key != null) 'key': key,
      if (modifiers != null) 'modifiers': modifiers,
      if (text != null) 'text': text,
      if (dx != null) 'dx': dx,
      if (dy != null) 'dy': dy,
      if (button != null) 'button': button,
      if (command != null) 'command': command,
      if (label != null) 'label': label,
    };
  }
}
