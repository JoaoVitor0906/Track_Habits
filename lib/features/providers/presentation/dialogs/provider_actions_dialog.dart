import 'package:flutter/material.dart';

/// Mostra um diálogo de ações para um provider selecionado.
/// - Não-dismissable (barrierDismissible: false)
/// - Delegates: onEdit (open form), onRemove (async remove via DAO)
Future<void> showProviderActionsDialog(
  BuildContext context, {
  required String id,
  required String name,
  required Future<void> Function() onRemove,
  required VoidCallback onEdit,
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: Text('Ações — $name'),
        content: Text('Escolha uma ação para este fornecedor.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              try {
                onEdit();
              } catch (e) {
                // ignore: avoid_print
                print('Erro ao chamar onEdit: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Não foi possível abrir o formulário de edição.')),
                );
              }
            },
            child: const Text('Editar'),
          ),
          TextButton(
            onPressed: () async {
              // Abrir confirmação (não-dismissable)
              final confirm = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => AlertDialog(
                  title: const Text('Confirmar remoção'),
                  content: Text('Remover "$name"? Esta ação não pode ser desfeita.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Confirmar'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                Navigator.of(context).pop(); // fechar diálogo de ações
                try {
                  await onRemove();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Fornecedor removido com sucesso.')),
                  );
                } catch (e) {
                  // ignore: avoid_print
                  print('Erro ao remover provider: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao remover fornecedor: $e')),
                  );
                }
              }
            },
            child: const Text('Remover'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      );
    },
  );
}
