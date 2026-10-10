enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

class GoDeckConnectionState {
  final ConnectionStatus status;
  final String host;
  final int port;
  final double latencyMs;
  final String? errorMessage;

  GoDeckConnectionState({
    required this.status,
    required this.host,
    required this.port,
    this.latencyMs = 0.0,
    this.errorMessage,
  });

  GoDeckConnectionState copyWith({
    ConnectionStatus? status,
    String? host,
    int? port,
    double? latencyMs,
    String? errorMessage,
  }) {
    return GoDeckConnectionState(
      status: status ?? this.status,
      host: host ?? this.host,
      port: port ?? this.port,
      latencyMs: latencyMs ?? this.latencyMs,
      errorMessage: errorMessage,
    );
  }

  String get wsUrl => 'ws://$host:$port/ws';
}
