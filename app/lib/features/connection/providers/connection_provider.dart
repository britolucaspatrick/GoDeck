import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/websocket_service.dart';
import '../models/connection_state.dart';

class ConnectionProvider extends ChangeNotifier {
  final WebSocketService _wsService;
  late StreamSubscription _latencySubscription;

  GoDeckConnectionState _state = GoDeckConnectionState(
    status: ConnectionStatus.disconnected,
    host: AppConstants.defaultHost,
    port: AppConstants.defaultPort,
  );

  GoDeckConnectionState get state => _state;
  WebSocketService get wsService => _wsService;

  ConnectionProvider(this._wsService) {
    _loadSavedSettings();
    _latencySubscription = _wsService.latencyStream.listen((latency) {
      _state = _state.copyWith(latencyMs: latency);
      notifyListeners();
    });
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedHost = prefs.getString(AppConstants.prefsHostKey) ?? AppConstants.defaultHost;
    final savedPort = prefs.getInt(AppConstants.prefsPortKey) ?? AppConstants.defaultPort;

    _state = _state.copyWith(host: savedHost, port: savedPort);
    notifyListeners();
  }

  Future<void> connect({String? host, int? port}) async {
    final targetHost = host ?? _state.host;
    final targetPort = port ?? _state.port;

    _state = _state.copyWith(
      status: ConnectionStatus.connecting,
      host: targetHost,
      port: targetPort,
      errorMessage: null,
    );
    notifyListeners();

    try {
      await _wsService.connect(_state.wsUrl);
      _state = _state.copyWith(status: ConnectionStatus.connected);

      // Save valid connection config
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefsHostKey, targetHost);
      await prefs.setInt(AppConstants.prefsPortKey, targetPort);

      // Request deck layout and desktop apps list from host server
      _wsService.requestLayout();
      _wsService.requestApps();
    } catch (e) {
      _state = _state.copyWith(
        status: ConnectionStatus.error,
        errorMessage: 'Não foi possível conectar ao servidor. Verifique o IP e porta.',
      );
    }
    notifyListeners();
  }

  Future<void> disconnect() async {
    await _wsService.disconnect();
    _state = _state.copyWith(
      status: ConnectionStatus.disconnected,
      latencyMs: 0.0,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _latencySubscription.cancel();
    super.dispose();
  }
}
