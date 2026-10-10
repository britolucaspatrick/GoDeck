class AppConstants {
  static const String appName = 'GoDeck';
  static const String appVersion = '1.0.0';
  
  // Default connection settings
  static const String defaultHost = '10.0.2.2';
  static const int defaultPort = 8080;
  static const String defaultEndpoint = '/ws';

  // SharedPreferences Keys
  static const String prefsHostKey = 'godeck_host';
  static const String prefsPortKey = 'godeck_port';
  static const String prefsHapticsKey = 'godeck_haptics_enabled';

  // WebSocket timing
  static const int pingIntervalSeconds = 3;
  static const int autoReconnectDelaySeconds = 2;
}
