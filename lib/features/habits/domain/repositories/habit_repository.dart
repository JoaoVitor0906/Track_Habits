import '../../../../domain/entities/habit_entities.dart';

/// Interface de repositório para a entidade Habit.
///
/// O repositório define as operações de acesso e sincronização de dados,
/// separando a lógica de persistência da lógica de negócio.
/// Utilizar interfaces facilita a troca de implementações (ex.: local, remota)
/// e torna o código mais testável e modular.
///
/// ⚠️ Dicas práticas para evitar erros comuns:
/// - Certifique-se de que a entidade `Habit` possui métodos de conversão robustos (ex: aceitar id como int/string, datas como `DateTime` ou `String`).
/// - Ao implementar esta interface, adicione logs (ex: usando `kDebugMode`) nos métodos principais para facilitar diagnóstico de cache e sync.
/// - Em chamadas assíncronas que atualizam a UI, verifique se o widget está `mounted` antes de chamar `setState`.
/// - A entidade `Habit` está definida em `lib/domain/entities/habit_entities.dart`.
abstract class HabitsRepository {
  // --- Render inicial a partir do cache ---
  /// Render inicial rápido a partir do cache local.
  ///
  /// Uso e boas práticas:
  /// - Deve retornar rapidamente (ex: leitura de um DAO local) para permitir um primeiro paint responsivo.
  /// - Não faça chamadas de rede aqui; esta função é pensada para leitura de cache/local.
  Future<List<Habit>> loadFromCache();

  // --- Sincronização com servidor ---
  /// Sincronização incremental (>= lastSync). Retorna quantos registros mudaram.
  ///
  /// Uso e boas práticas:
  /// - Deve sincronizar apenas delta (desde `lastSync`) quando possível para reduzir uso de banda.
  /// - Retornar o número de registros alterados permite sinais para a UI atualizar listas ou mostrar notificações.
  Future<int> syncFromServer();

  // --- Listagens ---
  /// Listagem completa (normalmente do cache após sync).
  ///
  /// Uso e boas práticas:
  /// - Geralmente combina resultados do cache local, já atualizados após `syncFromServer`.
  /// - Evite operações pesadas nesta função; prefira paginar quando a coleção for grande.
  Future<List<Habit>> listAll();

  /// Destaques (filtrados do cache por `featured`).
  ///
  /// Uso e boas práticas:
  /// - Retorne apenas os hábitos marcados como destaque/localmente filtrados.
  /// - Caso a propriedade `featured` não exista na entidade, implemente o filtro no DAO ou transforme o dado em DTO apropriado.
  Future<List<Habit>> listFeatured();

  // --- Acesso por id ---
  /// Opcional: busca direta por ID no cache.
  ///
  /// Uso e boas práticas:
  /// - Deve procurar apenas na fonte local (cache/DAO) para ser rápido.
  /// - Retorna `null` quando não encontrado; o chamador decide comportamento (ex: fetch remoto ou mostrar vazio).
  Future<Habit?> getById(int id);
}

/*
// Exemplo de uso:
// final repo = MinhaImplementacaoDeHabitsRepository();
// final lista = await repo.listAll();
// final destaque = await repo.listFeatured();
// final cached = await repo.loadFromCache();
// final item = await repo.getById(123);

// Dicas de implementação:
// - Implemente esta interface usando um DAO local (SQLite/Drift/SharedPreferences) e um datasource remoto (Supabase/REST).
// - Para sincronização, mantenha um campo `lastSync` e execute apenas delta updates quando disponível.
// - Em testes, crie um mock de `HabitsRepository` que retorne dados controlados.

// Checklist de erros comuns e como evitar:
// - Erro de conversão de tipos (ex: id como string): ajuste os métodos de conversão da entidade/DTO para aceitar múltiplos formatos.
// - Falha ao atualizar UI após sync: verifique se o widget está `mounted` antes de chamar `setState`.
// - Dados não aparecem após sync: adicione logs para inspecionar o conteúdo do cache e o fluxo de conversão.
// - Problemas com Supabase (RLS, inicialização): consulte a documentação e arquivos de debug do projeto.
*/
