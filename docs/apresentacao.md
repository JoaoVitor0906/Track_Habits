# Apresentação da entrega

Este documento descreve a entrega feita a partir do enunciado da atividade.

Resumo
- Foram propostas e esboçadas duas features conforme solicitado:
  1. Progress Overview — widget que apresenta um resumo do progresso diário/semana.
  2. Smart Suggestions — serviço e widget que sugerem hábitos iniciais (implementação local,
     preparada para futura troca por IA).

O que está incluído
- `prompts/especificacoes.md` — enunciado e especificações de alto nível.
- `docs/apresentacao.md` — este documento.
- `lib/features/progress_overview/` — stub do widget `ProgressOverview`.
- `lib/features/smart_suggestions/` — stub do serviço `SmartSuggestionService` e widget.

Como rodar localmente
1. Instale dependências:

```powershell
flutter pub get
```

2. Rode o analisador:

```powershell
flutter analyze
```

3. Rode o app em emulador/dispositivo:

```powershell
flutter run
```

Decisões de implementação
- Mantive contratos públicos existentes inalterados. Novos componentes estão sob
  `lib/features/*` para facilitar manutenção.
- A feature de sugestões foi implementada como um stub local que devolve uma lista fixa —
  essa implementação é suficientemente simples para testes e pode ser trocada por chamadas a
  um serviço IA no futuro.

Próximos passos e melhorias
- Implementar a lógica real de cálculo de progresso (usar histórico de marcações diária).
- Implementar persistência mais rica (ex.: SQLite ou arquivo JSON) para armazenar histórico
  de conclusão e permitir cálculo de streaks reais.
- Substituir o stub de Smart Suggestions por integração com um endpoint de IA (se desejar).
