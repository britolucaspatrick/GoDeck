import 'dart:convert';

class WebSocketMessage {
  final String eventType;
  final String? clientId;
  final int timestamp;
  final Map<String, dynamic>? payload;

  WebSocketMessage({
    required this.eventType,
    this.clientId,
    required this.timestamp,
    this.payload,
  });

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? parsedPayload;
    if (json['payload'] != null) {
      if (json['payload'] is Map) {
        parsedPayload = Map<String, dynamic>.from(json['payload']);
      } else if (json['payload'] is String) {
        parsedPayload = jsonDecode(json['payload']);
      }
    }

    return WebSocketMessage(
      eventType: json['event_type'] ?? 'unknown',
      clientId: json['client_id'],
      timestamp: json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      payload: parsedPayload,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_type': eventType,
      if (clientId != null) 'client_id': clientId,
      'timestamp': timestamp,
      if (payload != null) 'payload': payload,
    };
  }

  String toRawJson() => jsonEncode(toJson());
}
