import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/deck_item.dart';
import '../providers/deck_provider.dart';
import 'deck_button.dart';

class DeckGridWidget extends StatelessWidget {
  final DeckPageModel page;

  const DeckGridWidget({
    super.key,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<DeckProvider>();

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: page.columns,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 1.0,
      ),
      itemCount: page.items.length,
      itemBuilder: (context, index) {
        final item = page.items[index];
        return DeckButtonWidget(
          item: item,
          onTap: () {
            provider.executeAction(item.action);
          },
        );
      },
    );
  }
}
