import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../deck/models/deck_action.dart';
import '../../deck/models/deck_item.dart';
import '../../deck/providers/deck_provider.dart';
import '../models/desktop_app.dart';
import '../providers/apps_provider.dart';

class AppsScreen extends StatefulWidget {
  const AppsScreen({super.key});

  @override
  State<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppsProvider>().fetchApps();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AppsProvider>(
        builder: (context, appsProvider, child) {
          final apps = appsProvider.filteredApps;
          final favorites = appsProvider.favoriteApps;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => appsProvider.setSearchQuery(val),
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Buscar programas no PC...',
                    hintStyle: const TextStyle(color: AppTheme.textSecondary),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryNeon),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: AppTheme.textSecondary),
                            onPressed: () {
                              _searchController.clear();
                              appsProvider.setSearchQuery('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primaryNeon,
                labelColor: AppTheme.primaryNeon,
                unselectedLabelColor: AppTheme.textSecondary,
                tabs: [
                  Tab(text: 'Todos os Programas (${appsProvider.allApps.length})'),
                  Tab(text: '⭐ Favoritos (${favorites.length})'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAllAppsList(context, appsProvider, apps),
                    _buildFavoritesGrid(context, appsProvider, favorites),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAllAppsList(
    BuildContext context,
    AppsProvider appsProvider,
    List<DesktopAppModel> apps,
  ) {
    if (appsProvider.isLoading && apps.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryNeon),
      );
    }

    if (apps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.apps_outage_rounded, size: 56, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            const Text(
              'Nenhum programa encontrado no PC.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => appsProvider.fetchApps(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Escanear Novamente'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final app = apps[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: app.isFavorite ? AppTheme.primaryNeon.withAlpha(120) : AppTheme.surfaceLight,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryNeon.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(app.getIconData(), color: AppTheme.primaryNeon, size: 24),
            ),
            title: Text(
              app.name,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            subtitle: Text(
              app.path,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    app.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                    color: app.isFavorite ? AppTheme.accentOrange : AppTheme.textSecondary,
                    size: 26,
                  ),
                  onPressed: () => appsProvider.toggleFavorite(app.id),
                ),
                const SizedBox(width: 4),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    backgroundColor: AppTheme.primaryNeon,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => appsProvider.launchApp(app),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Abrir'),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary),
                  color: AppTheme.surfaceLight,
                  onSelected: (value) {
                    if (value == 'add_to_deck') {
                      _addAppToDeckGrid(context, app);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'add_to_deck',
                      child: Row(
                        children: [
                          Icon(Icons.add_to_photos_rounded, color: AppTheme.primaryNeon, size: 20),
                          SizedBox(width: 8),
                          Text('Adicionar ao Deck', style: TextStyle(color: AppTheme.textPrimary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFavoritesGrid(
    BuildContext context,
    AppsProvider appsProvider,
    List<DesktopAppModel> favorites,
  ) {
    if (favorites.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_outline_rounded, size: 64, color: AppTheme.accentOrange),
            SizedBox(height: 12),
            Text(
              'Nenhum programa favorito.',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              'Toque na estrela ao lado de um programa para favoritá-lo aqui!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final app = favorites[index];
        return InkWell(
          onTap: () => appsProvider.launchApp(app),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accentOrange.withAlpha(140), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentOrange.withAlpha(30),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.star_rounded, color: AppTheme.accentOrange, size: 24),
                    onPressed: () => appsProvider.toggleFavorite(app.id),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(app.getIconData(), size: 40, color: AppTheme.primaryNeon),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          app.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _addAppToDeckGrid(BuildContext context, DesktopAppModel app) {
    final deckProvider = context.read<DeckProvider>();
    final deckItem = DeckItem(
      id: 'app_${app.id}',
      title: app.name,
      icon: app.icon,
      color: AppTheme.primaryNeon,
      action: DeckAction(
        type: 'system_command',
        command: app.path.isNotEmpty ? 'open "${app.path}"' : 'open -a "${app.name}"',
        label: 'Abrir ${app.name}',
      ),
    );

    deckProvider.addDeckItem(deckItem);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${app.name} adicionado ao Macro Deck!'),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }
}
