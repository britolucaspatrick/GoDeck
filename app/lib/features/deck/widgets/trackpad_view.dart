import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/deck_provider.dart';

class TrackpadViewWidget extends StatefulWidget {
  const TrackpadViewWidget({super.key});

  @override
  State<TrackpadViewWidget> createState() => _TrackpadViewWidgetState();
}

class _TrackpadViewWidgetState extends State<TrackpadViewWidget> {
  Offset? _lastPanOffset;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<DeckProvider>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onPanStart: (details) {
                _lastPanOffset = details.localPosition;
              },
              onPanUpdate: (details) {
                if (_lastPanOffset != null) {
                  final dx = details.localPosition.dx - _lastPanOffset!.dx;
                  final dy = details.localPosition.dy - _lastPanOffset!.dy;

                  provider.sendTrackpadMove(dx * 1.5, dy * 1.5);
                }
                _lastPanOffset = details.localPosition;
              },
              onPanEnd: (_) {
                _lastPanOffset = null;
              },
              onTap: () {
                provider.sendTrackpadClick('left');
              },
              onDoubleTap: () {
                provider.sendTrackpadClick('right');
              },
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.primaryNeon.withAlpha(100), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryNeon.withAlpha(20),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.touch_app_rounded,
                        size: 56,
                        color: AppTheme.primaryNeon.withAlpha(150),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Área do Trackpad',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Arraste para mover o cursor • Toque para Clique Esquerdo • Toque Duplo para Clique Direito',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surface,
                      foregroundColor: AppTheme.textPrimary,
                      side: const BorderSide(color: AppTheme.surfaceLight),
                    ),
                    onPressed: () {
                      provider.sendTrackpadClick('left');
                    },
                    icon: const Icon(Icons.mouse_rounded, color: AppTheme.primaryNeon),
                    label: const Text('Clique Esquerdo'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surface,
                      foregroundColor: AppTheme.textPrimary,
                      side: const BorderSide(color: AppTheme.surfaceLight),
                    ),
                    onPressed: () {
                      provider.sendTrackpadClick('right');
                    },
                    icon: const Icon(Icons.mouse_outlined, color: AppTheme.accentPurple),
                    label: const Text('Clique Direito'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
