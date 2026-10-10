import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/network/websocket_service.dart';
import 'core/theme/app_theme.dart';
import 'features/apps/providers/apps_provider.dart';
import 'features/connection/providers/connection_provider.dart';
import 'features/deck/providers/deck_provider.dart';
import 'features/deck/screens/deck_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final wsService = WebSocketService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectionProvider(wsService)),
        ChangeNotifierProvider(create: (_) => DeckProvider(wsService)),
        ChangeNotifierProvider(create: (_) => AppsProvider(wsService)),
      ],
      child: const GoDeckApp(),
    ),
  );
}

class GoDeckApp extends StatelessWidget {
  const GoDeckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoDeck',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const DeckScreen(),
    );
  }
}
