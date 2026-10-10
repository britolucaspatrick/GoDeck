import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../models/connection_state.dart';
import '../providers/connection_provider.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _hostController;
  late TextEditingController _portController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ConnectionProvider>();
    _hostController = TextEditingController(text: provider.state.host);
    _portController = TextEditingController(text: provider.state.port.toString());
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionProvider>(
      builder: (context, provider, child) {
        final state = provider.state;
        final isConnecting = state.status == ConnectionStatus.connecting;

        return Scaffold(
          appBar: AppBar(
            title: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.hub_rounded, color: AppTheme.primaryNeon),
                SizedBox(width: 8),
                Text('Conexão GoDeck Server'),
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryNeon.withAlpha(50),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.phonelink_setup_rounded,
                        size: 64,
                        color: AppTheme.primaryNeon,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Conecte ao Servidor Desktop',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Digite o endereço IP exibido no terminal do GoDeck Server no seu computador.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _hostController,
                    decoration: InputDecoration(
                      labelText: 'Endereço IP do Host',
                      hintText: 'ex: 192.168.1.100',
                      prefixIcon: const Icon(Icons.wifi_rounded, color: AppTheme.primaryNeon),
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.surfaceLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primaryNeon, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (val) => (val == null || val.isEmpty) ? 'Informe o endereço IP' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _portController,
                    decoration: InputDecoration(
                      labelText: 'Porta',
                      hintText: '8080',
                      prefixIcon: const Icon(Icons.settings_ethernet_rounded, color: AppTheme.primaryNeon),
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.surfaceLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primaryNeon, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Informe a porta';
                      if (int.tryParse(val) == null) return 'Porta inválida';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  if (state.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.accentRed.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.accentRed),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppTheme.accentRed),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.errorMessage!,
                              style: const TextStyle(color: AppTheme.accentRed, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isConnecting
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                final host = _hostController.text.trim();
                                final port = int.parse(_portController.text.trim());
                                provider.connect(host: host, port: port).then((_) {
                                  if (provider.state.status == ConnectionStatus.connected && context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                });
                              }
                            },
                      child: isConnecting
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                            )
                          : const Text('Conectar ao GoDeck'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
