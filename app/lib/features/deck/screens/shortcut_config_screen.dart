import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../models/deck_action.dart';
import '../models/deck_item.dart';
import '../providers/deck_provider.dart';

class ShortcutConfigScreen extends StatelessWidget {
  const ShortcutConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Atalhos & Macros'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryNeon, size: 28),
            onPressed: () => _showShortcutEditorDialog(context),
          ),
        ],
      ),
      body: Consumer<DeckProvider>(
        builder: (context, provider, child) {
          final currentPage = provider.currentPage;
          final items = currentPage?.items ?? [];

          if (items.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum atalho configurado.\nToque no botão + para criar um novo!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              ),
            );
          }

          return ReorderableListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: items.length,
            // ignore: deprecated_member_use
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex -= 1;
              final list = List<DeckItem>.from(items);
              final movedItem = list.removeAt(oldIndex);
              list.insert(newIndex, movedItem);

              final updatedPage = DeckPageModel(
                id: currentPage!.id,
                title: currentPage.title,
                columns: currentPage.columns,
                items: list,
              );
              provider.pages[provider.activePageIndex] = updatedPage;
              provider.saveLayoutToServer();
            },
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                key: ValueKey(item.id),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: item.color.withAlpha(100), width: 1.5),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: item.color.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.getIconData(), color: item.color, size: 24),
                  ),
                  title: Text(
                    item.title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    _formatActionDescription(item.action),
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, color: AppTheme.primaryNeon),
                        onPressed: () => _showShortcutEditorDialog(context, existingItem: item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.accentRed),
                        onPressed: () {
                          provider.deleteDeckItem(item.id);
                        },
                      ),
                      const Icon(Icons.drag_handle_rounded, color: AppTheme.textSecondary),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryNeon,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () {
            context.read<DeckProvider>().saveLayoutToServer();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Atalhos salvos e sincronizados com o GoDeck Server!'),
                backgroundColor: AppTheme.accentGreen,
              ),
            );
          },
          icon: const Icon(Icons.cloud_upload_rounded),
          label: const Text('Salvar e Sincronizar com Servidor'),
        ),
      ),
    );
  }

  String _formatActionDescription(DeckAction action) {
    switch (action.type) {
      case 'key_combination':
        final mods = action.modifiers?.join('+') ?? '';
        return 'Combinação: ${mods.isNotEmpty ? '$mods+' : ''}${action.key ?? ''}';
      case 'key_tap':
        return 'Tecla: ${action.key ?? ''}';
      case 'text_input':
        return 'Texto: "${action.text ?? ''}"';
      case 'system_command':
        return 'Comando: ${action.command ?? ''}';
      default:
        return action.type;
    }
  }

  void _showShortcutEditorDialog(BuildContext context, {DeckItem? existingItem}) {
    showDialog(
      context: context,
      builder: (dialogContext) => ShortcutEditorDialog(existingItem: existingItem),
    );
  }
}

class ShortcutEditorDialog extends StatefulWidget {
  final DeckItem? existingItem;

  const ShortcutEditorDialog({super.key, this.existingItem});

  @override
  State<ShortcutEditorDialog> createState() => _ShortcutEditorDialogState();
}

class _ShortcutEditorDialogState extends State<ShortcutEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _keyController;
  late TextEditingController _textOrCmdController;

  String _selectedActionType = 'key_combination';
  String _selectedIcon = 'copy';
  Color _selectedColor = const Color(0xFF00E5FF);

  final List<String> _selectedModifiers = ['cmd'];

  final List<Map<String, dynamic>> _iconPresets = [
    {'name': 'copy', 'icon': Icons.copy_rounded},
    {'name': 'paste', 'icon': Icons.content_paste_rounded},
    {'name': 'terminal', 'icon': Icons.terminal_rounded},
    {'name': 'code', 'icon': Icons.code_rounded},
    {'name': 'skip_previous', 'icon': Icons.skip_previous_rounded},
    {'name': 'play_pause', 'icon': Icons.play_arrow_rounded},
    {'name': 'skip_next', 'icon': Icons.skip_next_rounded},
    {'name': 'volume_up', 'icon': Icons.volume_up_rounded},
    {'name': 'desktop', 'icon': Icons.desktop_windows_rounded},
  ];

  final List<Color> _colorPresets = [
    const Color(0xFF00E5FF),
    const Color(0xFF7C4DFF),
    const Color(0xFF00E676),
    const Color(0xFFFF9100),
    const Color(0xFFFF3D00),
    const Color(0xFFE91E63),
    const Color(0xFFFFEB3B),
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    if (item != null) {
      _titleController = TextEditingController(text: item.title);
      _selectedActionType = item.action.type;
      _keyController = TextEditingController(text: item.action.key ?? '');
      _textOrCmdController = TextEditingController(
          text: item.action.type == 'system_command'
              ? (item.action.command ?? '')
              : (item.action.text ?? ''));
      _selectedIcon = item.icon;
      _selectedColor = item.color;
      if (item.action.modifiers != null) {
        _selectedModifiers.clear();
        _selectedModifiers.addAll(item.action.modifiers!);
      }
    } else {
      _titleController = TextEditingController();
      _keyController = TextEditingController(text: 'c');
      _textOrCmdController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _keyController.dispose();
    _textOrCmdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingItem != null;

    return AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        isEditing ? 'Editar Atalho' : 'Novo Atalho / Macro',
        style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Título do Botão',
                  hintText: 'ex: Copiar, Format Code',
                ),
                validator: (val) => (val == null || val.isEmpty) ? 'Informe um título' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedActionType,
                dropdownColor: AppTheme.surfaceLight,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Tipo de Ação'),
                items: const [
                  DropdownMenuItem(value: 'key_combination', child: Text('Combinação de Teclas')),
                  DropdownMenuItem(value: 'key_tap', child: Text('Tecla Única')),
                  DropdownMenuItem(value: 'text_input', child: Text('Digitar Texto')),
                  DropdownMenuItem(value: 'system_command', child: Text('Comando do Sistema')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedActionType = val);
                  }
                },
              ),
              const SizedBox(height: 16),
              if (_selectedActionType == 'key_combination') ...[
                const Text('Modificadores:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['cmd', 'ctrl', 'alt', 'shift'].map((mod) {
                    final isSelected = _selectedModifiers.contains(mod);
                    return FilterChip(
                      label: Text(mod.toUpperCase()),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryNeon,
                      checkmarkColor: Colors.black,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedModifiers.add(mod);
                          } else {
                            _selectedModifiers.remove(mod);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
              if (_selectedActionType == 'key_combination' || _selectedActionType == 'key_tap') ...[
                TextFormField(
                  controller: _keyController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Tecla',
                    hintText: 'ex: c, v, p, space, enter, escape, 4',
                  ),
                  validator: (val) => (val == null || val.isEmpty) ? 'Informe a tecla' : null,
                ),
                const SizedBox(height: 16),
              ],
              if (_selectedActionType == 'text_input' || _selectedActionType == 'system_command') ...[
                TextFormField(
                  controller: _textOrCmdController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: _selectedActionType == 'system_command' ? 'Comando do SO' : 'Texto a Digitar',
                    hintText: _selectedActionType == 'system_command' ? 'open -a Terminal' : 'Texto...',
                  ),
                  validator: (val) => (val == null || val.isEmpty) ? 'Informe o valor' : null,
                ),
                const SizedBox(height: 16),
              ],
              const Text('Ícone:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _iconPresets.map((preset) {
                  final name = preset['name'] as String;
                  final iconData = preset['icon'] as IconData;
                  final isSelected = _selectedIcon == name;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = name),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryNeon.withAlpha(40) : AppTheme.surfaceLight,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryNeon : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(iconData, color: isSelected ? AppTheme.primaryNeon : AppTheme.textSecondary, size: 22),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Cor Neon:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: _colorPresets.map((color) {
                  final isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final provider = context.read<DeckProvider>();
              final title = _titleController.text.trim();

              DeckAction action;
              if (_selectedActionType == 'key_combination') {
                action = DeckAction(
                  type: 'key_combination',
                  key: _keyController.text.trim(),
                  modifiers: List<String>.from(_selectedModifiers),
                  label: title,
                );
              } else if (_selectedActionType == 'key_tap') {
                action = DeckAction(
                  type: 'key_tap',
                  key: _keyController.text.trim(),
                  label: title,
                );
              } else if (_selectedActionType == 'text_input') {
                action = DeckAction(
                  type: 'text_input',
                  text: _textOrCmdController.text.trim(),
                  label: title,
                );
              } else {
                action = DeckAction(
                  type: 'system_command',
                  command: _textOrCmdController.text.trim(),
                  label: title,
                );
              }

              final item = DeckItem(
                id: widget.existingItem?.id ?? 'btn_${DateTime.now().millisecondsSinceEpoch}',
                title: title,
                icon: _selectedIcon,
                color: _selectedColor,
                action: action,
              );

              if (widget.existingItem != null) {
                provider.updateDeckItem(item);
              } else {
                provider.addDeckItem(item);
              }

              Navigator.of(context).pop();
            }
          },
          child: Text(isEditing ? 'Atualizar' : 'Criar'),
        ),
      ],
    );
  }
}
