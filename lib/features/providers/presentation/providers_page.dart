import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../infrastructure/providers_local_dao_shared_prefs.dart';
import 'provider_list_item.dart';
import 'dialogs/provider_actions_dialog.dart';
import 'dialogs/provider_form_dialog.dart';

/// Página de listagem de Fornecedores (listing-only)
/// - Carrega via DAO `ProvidersLocalDaoSharedPrefs.listAll()`
/// - Mostra loading, lista, e tratamento de erros com SnackBar
class ProvidersPage extends StatefulWidget {
  const ProvidersPage({Key? key}) : super(key: key);

  @override
  State<ProvidersPage> createState() => _ProvidersPageState();
}

class _ProvidersPageState extends State<ProvidersPage> {
  late ProvidersLocalDaoSharedPrefs _dao;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initDaoAndLoad();
  }

  Future<void> _initDaoAndLoad() async {
    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final sp = await SharedPreferences.getInstance();
      _dao = ProvidersLocalDaoSharedPrefs(sp);
      await _loadItems();
    } catch (e) {
      // ignore: avoid_print
      print('ProvidersPage init error: $e');
      messenger.showSnackBar(
        SnackBar(content: Text('Erro ao inicializar a listagem: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadItems() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final list = await _dao.listAll();
      setState(() => _items = list);
    } catch (e) {
      // ignore: avoid_print
      print('ProvidersPage load error: $e');
      messenger.showSnackBar(
        SnackBar(content: Text('Erro ao carregar provedores: $e')),
      );
    }
  }

  String _maskTaxId(String? taxId) {
    if (taxId == null || taxId.isEmpty) return '';
    // Simple mask: keep first 6 and last 3 chars visible
    if (taxId.length <= 9) {
      return '${taxId.substring(0, 3)}***${taxId.substring(taxId.length - 3)}';
    }

    return '${taxId.substring(0, 6)}***${taxId.substring(taxId.length - 3)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fornecedores')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(child: Text('Nenhum fornecedor encontrado'))
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final it = _items[index];
                    final messenger = ScaffoldMessenger.of(context);
                    final id = it['id'] as String? ?? '';
                    final name = it['name'] as String? ?? '';
                    final rating = (it['rating'] is num)
                        ? (it['rating'] as num).toDouble()
                        : null;
                    final distanceKm = (it['distance_km'] is num)
                        ? (it['distance_km'] as num).toDouble()
                        : null;
                    final imageUrl = it['image_url'] as String?;
                    final taxId = _maskTaxId(it['taxId'] as String?);
                    final contact = it['contact'] as Map<String, dynamic>?;

                    return Dismissible(
                      key: Key('provider_$id'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red.shade600,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        // show non-dismissable confirmation dialog
                        final confirm = await showDialog<bool>(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Confirmar remoção'),
                            content: Text(
                                'Remover "$name"? Esta ação não pode ser desfeita.'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Cancelar')),
                              TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text('Remover')),
                            ],
                          ),
                        );

                        if (confirm != true) return false;

                        try {
                          final removed = await _dao.remove(id);
                          if (!removed) {
                            messenger.showSnackBar(const SnackBar(
                                content: Text(
                                    'Fornecedor não encontrado para remoção.')));
                            return false;
                          }
                          // success; allow dismissal animation
                          return true;
                        } catch (e) {
                          messenger.showSnackBar(
                              SnackBar(content: Text('Erro ao remover: $e')));
                          return false;
                        }
                      },
                      onDismissed: (direction) async {
                        // reload items after successful dismissal
                        await _loadItems();
                        messenger.showSnackBar(const SnackBar(
                            content: Text('Fornecedor removido.')));
                      },
                      child: ProviderListItem(
                        id: id,
                        name: name,
                        rating: rating,
                        distanceKm: distanceKm,
                        imageUrl: imageUrl,
                        taxIdMasked: taxId.isNotEmpty ? taxId : null,
                        contact: contact,
                        onLongPress: () async {
                          // abrir diálogo de ações e delegar edição/remoção
                          await showProviderActionsDialog(
                            context,
                            id: id,
                            name: name,
                            onEdit: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              // Abrir o formulário de edição
                              final result = await showProviderFormDialog(
                                  context,
                                  initial: it);
                              if (result != null) {
                                try {
                                  await _dao.upsert(result);
                                  await _loadItems();
                                  if (mounted) {
                                    messenger.showSnackBar(const SnackBar(
                                        content: Text(
                                            'Fornecedor salvo com sucesso.')));
                                  }
                                } catch (e) {
                                  messenger.showSnackBar(SnackBar(
                                      content: Text('Erro ao salvar: $e')));
                                }
                              }
                            },
                            onRemove: () async {
                              // Delegar remoção: aqui apenas atualizamos o armazenamento local
                              try {
                                final remaining = _items
                                    .where((e) => (e['id'] as String?) != id)
                                    .toList();
                                await _dao.upsertAll(remaining);
                                await _loadItems();
                              } catch (e) {
                                rethrow;
                              }
                            },
                          );
                        },
                        onEdit: () async {
                          // icon edit pressed: open form directly
                          final messenger = ScaffoldMessenger.of(context);
                          final result = await showProviderFormDialog(context,
                              initial: it);
                          if (result != null) {
                            try {
                              await _dao.upsert(result);
                              await _loadItems();
                              if (mounted) {
                                messenger.showSnackBar(const SnackBar(
                                    content:
                                        Text('Fornecedor salvo com sucesso.')));
                              }
                            } catch (e) {
                              messenger.showSnackBar(SnackBar(
                                  content: Text('Erro ao salvar: $e')));
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Abrir fluxo de adicionar/editar implementado separadamente
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content:
                  Text('Ação de adicionar implementada em arquivo separado')));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
