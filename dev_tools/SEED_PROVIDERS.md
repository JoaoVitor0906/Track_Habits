Seed de dados de teste para Fornecedores (SharedPreferences)

Como usar (modo rápido):

1) Abra `lib/main.dart` e, logo após obter `SharedPreferences.getInstance()`, cole temporariamente o trecho abaixo para popular alguns fornecedores de exemplo.

```dart
final sp = await SharedPreferences.getInstance();
await sp.setStringList('providers_list_v1', [
  jsonEncode({
    'id': 'b6f8c1f2-3d2a-4a9e-9f6b-1a2b3c4d5e6f',
    'name': 'Farmácia São José',
    'rating': 4.7,
    'distance_km': 1.4,
    'image_url': 'https://via.placeholder.com/150',
    'taxId': '12345678000199',
    'status': 'active',
    'createdAt': DateTime.now().toIso8601String(),
    'updatedAt': DateTime.now().toIso8601String(),
    'contact': { 'email': 'contato@fsj.com.br', 'phone': '+55 (11) 9****-1234' },
    'address': { 'street': 'Av. Brasil, 123', 'city': 'São Paulo', 'state': 'SP', 'zip': '01234-000' }
  })
]);
```

2) Rode o app (`flutter run -d chrome`), abra a rota `/providers` (ou use a rota adicionada no menu), verifique a listagem.
3) Remova o trecho do `main.dart` após testar para não poluir o armazenamento.

Observação: este é um passo manual intencionalmente para evitar executar código de seed automaticamente em ambientes de produção.
