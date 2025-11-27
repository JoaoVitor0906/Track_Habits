/// Interface de repositório para a entidade Habit.
///
/// O repositório define as operações de acesso e sincronização de dados
/// relacionadas a hábitos, separando a lógica de persistência da lógica de
/// negócio. Utilizar interfaces facilita a troca de implementações (ex.: local,
/// remota) e torna o código mais testável e modular.
///
/// ⚠️ Dicas práticas:
/// - Garanta que a entidade `Habit` possui métodos de conversão robustos
///   (`fromMap`/`toMap`) se a implementação local/remota depender de
///   serialização.
/// - Em implementações assíncronas usadas na UI, sempre verifique se o
///   `State` está `mounted` antes de chamar `setState`.
/// - Use logs (ex: `kDebugMode`) em `syncFromServer` para debugar problemas
///   de sincronização incremental.

import '../../../../domain/entities/habit_entities.dart';

/// Repositório abstrato (interface) parametrizado para operações com hábitos.
///
/// Somente declara assinaturas — implemente esta interface em classes
/// concretas (ex.: `HabitsLocalRepository`, `HabitsRemoteRepository`) e
/// combine-as em um orquestrador (ex.: `HabitsRepositoryImpl`) quando
/// precisar sincronizar cache + servidor.
abstract class HabitsRepository {
  /// Render inicial rápido a partir do cache local.
  ///
  /// Uso: carregue rapidamente a lista em telas que precisam de resposta
  /// imediata (ex.: `HomePage`) antes de iniciar uma sincronização remota.
  /// Boa prática: não bloqueie a UI esperando por esta chamada; trate-a como
  /// operação de leitura local e atualize a UI quando o resultado chegar.
  Future<List<Habit>> loadFromCache();

  /// Sincronização incremental (>= lastSync). Retorna quantos registros
  /// mudaram no processo de sincronização.
  ///
  /// Uso: chamada periódica (ex.: on resume, pull-to-refresh) para atualizar
  /// o cache local a partir do servidor. Boa prática: implemente lógica de
  /// conflito (último a gravar / timestamps) na implementação concreta e
  /// exponha métricas de quantas entidades mudaram para feedback ao usuário.
  Future<int> syncFromServer();

  /// Listagem completa (normalmente do cache após sync).
  ///
  /// Uso: retorna a coleção completa de hábitos que a UI pode iterar. Deve
  /// ser eficiente (ler do cache) e, se necessário, permitir paginação na
  /// implementação concreta.
  Future<List<Habit>> listAll();

  /// Destaques (filtrados do cache por `featured`).
  ///
  /// Uso: retorna somente hábitos marcados como destaque. A propriedade
  /// `featured` pode ser implementada como campo da entidade ou derivada na
  /// camada de persistência; documente essa decisão na implementação.
  Future<List<Habit>> listFeatured();

  /// Opcional: busca direta por ID no cache.
  ///
  /// Uso: recupera um hábito específico pelo seu identificador. Deve ser
  /// eficiente e retornar `null` quando o registro não existir no cache.
  Future<Habit?> getById(int id);
}

/*
// Exemplo de uso (comentado):
// final repo = MinhaImplementacaoDeHabitsRepository();
// final cache = await repo.loadFromCache();
// final changed = await repo.syncFromServer();
// final todos = await repo.listAll();

// Dica: implemente esta interface usando um DAO local (ex: SharedPreferences,
// arquivo JSON, sqlite) e um datasource remoto (ex: Supabase). Para testes,
// crie um mock que implementa `HabitsRepository` e retorna dados fixos.

// Checklist de erros comuns e como evitar:
// - Erro de conversão de tipos (ex: id como string): ajuste o fromMap/toMap
//   da entidade/DTO para aceitar múltiplos formatos.
// - Falha ao atualizar UI após sync: verifique se o widget está mounted antes
//   de chamar setState.
// - Dados não aparecem após sync: adicione logs para inspecionar o conteúdo do
//   cache e o fluxo de conversão.
// - Problemas com Supabase (RLS, inicialização): consulte os documentos de
//   debug do projeto.

// Referências úteis:
// - providers_cache_debug_prompt.md
// - supabase_init_debug_prompt.md
// - supabase_rls_remediation.md
*/
