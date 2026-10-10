import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/websocket_message.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _pingTimer;

  final StreamController<WebSocketMessage> _messageController = StreamController<WebSocketMessage>.broadcast();
  final StreamController<double> _latencyController = StreamController<double>.broadcast();

  Stream<WebSocketMessage> get messageStream => _messageController.stream;
  Stream<double> get latencyStream => _latencyController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  int _lastPingTimestamp = 0;

  Future<void> connect(String url) async {
    await disconnect();

    try {
      final uri = Uri.parse(url);
      _channel = WebSocketChannel.connect(uri);

      await _channel!.ready;
      _isConnected = true;

      _subscription = _channel!.stream.listen(
        (data) => _onMessageReceived(data),
        onError: (error) {
          debugPrint('[WebSocketService] Error: $error');
          _handleDisconnect();
        },
        onDone: () {
          debugPrint('[WebSocketService] Connection closed');
          _handleDisconnect();
        },
      );

      _startPingTimer();
    } catch (e) {
      _isConnected = false;
      debugPrint('[WebSocketService] Connection failed: $e');
      rethrow;
    }
  }

  void sendAction(Map<String, dynamic> actionPayload) {
    if (!_isConnected || _channel == null) return;

    final message = WebSocketMessage(
      eventType: 'action',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      payload: actionPayload,
    );

    _channel!.sink.add(message.toRawJson());
  }

  void requestLayout() {
    if (!_isConnected || _channel == null) return;

    final message = WebSocketMessage(
      eventType: 'request_layout',
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    _channel!.sink.add(message.toRawJson());
  }

  void saveLayout(Map<String, dynamic> layoutPayload) {
    if (!_isConnected || _channel == null) return;

    final message = WebSocketMessage(
      eventType: 'save_layout',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      payload: layoutPayload,
    );

    _channel!.sink.add(message.toRawJson());
  }

  void _onMessageReceived(dynamic data) {
    try {
      final Map<String, dynamic> jsonMap = jsonDecode(data.toString());
      final message = WebSocketMessage.fromJson(jsonMap);

      if (message.eventType == 'pong') {
        final now = DateTime.now().millisecondsSinceEpoch;
        final rtt = (now - _lastPingTimestamp).toDouble();
        _latencyController.add(rtt > 0 ? rtt : 1.0);
      } else {
        _messageController.add(message);
      }
    } catch (e) {
      debugPrint('[WebSocketService] Failed to parse message: $e');
    }
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_isConnected || _channel == null) return;

      _lastPingTimestamp = DateTime.now().millisecondsSinceEpoch;
      final pingMsg = WebSocketMessage(
        eventType: 'ping',
        timestamp: _lastPingTimestamp,
      );

      _channel!.sink.add(pingMsg.toRawJson());
    });
  }

  void _handleDisconnect() {
    _isConnected = false;
    _pingTimer?.cancel();
    _subscription?.cancel();
  }

  Future<void> disconnect() async {
    _handleDisconnect();
    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _latencyController.close();
  }
}
