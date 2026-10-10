import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../apps/screens/apps_screen.dart';
import '../../connection/models/connection_state.dart';
import '../../connection/providers/connection_provider.dart';
import '../../connection/screens/connection_screen.dart';
import '../models/deck_item.dart';
import '../providers/deck_provider.dart';
import '../widgets/deck_grid.dart';
import '../widgets/trackpad_view.dart';
import 'shortcut_config_screen.dart';

class DeckScreen extends StatelessWidget {
  const DeckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ConnectionProvider, DeckProvider>(
      builder: (context, connProvider, deckProvider, child) {
        final connState = connProvider.state;
        final currentPage = deckProvider.currentPage;

        return Scaffold(
          appBar: AppBar(
            title: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.grid_view_rounded, color: AppTheme.primaryNeon),
                SizedBox(width: 8),
                Text('GoDeck'),
              ],
            ),
            actions: [
              _buildLatencyBadge(context, connState),
              IconButton(
                icon: const Icon(Icons.tune_rounded, color: AppTheme.primaryNeon),
                tooltip: 'Configurar Atalhos',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ShortcutConfigScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings_rounded, color: AppTheme.textSecondary),
                tooltip: 'Conexão',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ConnectionScreen()),
                  );
                },
              ),
            ],
          ),
          body: _buildActiveTabBody(deckProvider, currentPage),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: deckProvider.activeViewTab,
            onTap: (index) => deckProvider.setActiveTab(index),
            backgroundColor: AppTheme.surface,
            selectedItemColor: AppTheme.primaryNeon,
            unselectedItemColor: AppTheme.textSecondary,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.grid_view_rounded),
                label: 'Macro Deck',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.touch_app_rounded),
                label: 'Trackpad',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.computer_rounded),
                label: 'Programas PC',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveTabBody(DeckProvider deckProvider, DeckPageModel? currentPage) {
    switch (deckProvider.activeViewTab) {
      case 0:
        return currentPage != null
            ? DeckGridWidget(page: currentPage)
            : const Center(
                child: Text('Nenhuma página de macro carregada.', style: TextStyle(color: AppTheme.textSecondary)),
              );
      case 1:
        return const TrackpadViewWidget();
      case 2:
        return const AppsScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLatencyBadge(BuildContext context, GoDeckConnectionState connState) {
    final isConnected = connState.status == ConnectionStatus.connected;
    final color = isConnected
        ? (connState.latencyMs < 10 ? AppTheme.accentGreen : AppTheme.accentOrange)
        : AppTheme.accentRed;

    final text = isConnected ? '${connState.latencyMs.toStringAsFixed(1)} ms' : 'Off';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ConnectionScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
