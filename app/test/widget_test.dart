import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:app/core/network/websocket_service.dart';
import 'package:app/features/connection/providers/connection_provider.dart';
import 'package:app/features/deck/providers/deck_provider.dart';
import 'package:app/main.dart';

void main() {
  testWidgets('GoDeck app smoke test', (WidgetTester tester) async {
    final wsService = WebSocketService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ConnectionProvider(wsService)),
          ChangeNotifierProvider(create: (_) => DeckProvider(wsService)),
        ],
        child: const GoDeckApp(),
      ),
    );

    expect(find.text('GoDeck'), findsOneWidget);
    expect(find.text('Macro Deck'), findsOneWidget);
    expect(find.text('Trackpad'), findsOneWidget);
  });
}
