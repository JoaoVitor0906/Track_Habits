import 'package:flutter/material.dart';

/// Form dialog to edit/create a provider. Returns the updated Map when saved, or null when cancelled.
Future<Map<String, dynamic>?> showProviderFormDialog(
  BuildContext context, {
  required Map<String, dynamic> initial,
}) {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController(text: initial['name'] as String? ?? '');
  final taxIdCtrl = TextEditingController(text: initial['taxId'] as String? ?? '');
  final imageCtrl = TextEditingController(text: initial['image_url'] as String? ?? '');
  final emailCtrl = TextEditingController(text: (initial['contact'] as Map<String,dynamic>?)?['email'] as String? ?? '');
  final phoneCtrl = TextEditingController(text: (initial['contact'] as Map<String,dynamic>?)?['phone'] as String? ?? '');
  final streetCtrl = TextEditingController(text: (initial['address'] as Map<String,dynamic>?)?['street'] as String? ?? '');
  final cityCtrl = TextEditingController(text: (initial['address'] as Map<String,dynamic>?)?['city'] as String? ?? '');
  final stateCtrl = TextEditingController(text: (initial['address'] as Map<String,dynamic>?)?['state'] as String? ?? '');
  final zipCtrl = TextEditingController(text: (initial['address'] as Map<String,dynamic>?)?['zip'] as String? ?? '');

  return showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: Text(initial['name'] != null && (initial['name'] as String).isNotEmpty ? 'Editar fornecedor' : 'Novo fornecedor'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nome é obrigatório' : null,
                ),
                TextFormField(
                  controller: taxIdCtrl,
                  decoration: const InputDecoration(labelText: 'CPF/CNPJ'),
                ),
                TextFormField(
                  controller: imageCtrl,
                  decoration: const InputDecoration(labelText: 'URL da imagem'),
                ),
                const SizedBox(height: 8),
                const Text('Contato', style: TextStyle(fontWeight: FontWeight.w600)),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Telefone'),
                ),
                const SizedBox(height: 8),
                const Text('Endereço', style: TextStyle(fontWeight: FontWeight.w600)),
                TextFormField(
                  controller: streetCtrl,
                  decoration: const InputDecoration(labelText: 'Rua'),
                ),
                TextFormField(
                  controller: cityCtrl,
                  decoration: const InputDecoration(labelText: 'Cidade'),
                ),
                TextFormField(
                  controller: stateCtrl,
                  decoration: const InputDecoration(labelText: 'Estado'),
                ),
                TextFormField(
                  controller: zipCtrl,
                  decoration: const InputDecoration(labelText: 'CEP'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (_formKey.currentState?.validate() != true) return;
              final updated = Map<String, dynamic>.from(initial);
              updated['name'] = nameCtrl.text.trim();
              updated['taxId'] = taxIdCtrl.text.trim();
              updated['image_url'] = imageCtrl.text.trim();
              updated['contact'] = {
                'email': emailCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
              };
              updated['address'] = {
                'street': streetCtrl.text.trim(),
                'city': cityCtrl.text.trim(),
                'state': stateCtrl.text.trim(),
                'zip': zipCtrl.text.trim(),
              };
              updated['updatedAt'] = DateTime.now().toIso8601String();

              Navigator.of(context).pop(updated);
            },
            child: const Text('Salvar'),
          ),
        ],
      );
    },
  );
}
