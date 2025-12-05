import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/habit_completion_dto.dart';
import '../data/mappers/habit_completion_mapper.dart';
import '../domain/entities/habit_completion_entities.dart';
import '../data/models/goal_dto.dart';
import '../data/mappers/goal_mapper.dart';
import '../domain/entities/goal_entity.dart';

/// Serviço para integração com Supabase
/// Fornece métodos para operações CRUD com tabelas do backend
class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Cria um hábito no Supabase (opcionalmente sincroniza dados locais com o servidor)
  /// Retorna o mapa criado ou null
  Future<Map<String, dynamic>?> createHabit(Map<String, dynamic> habit) async {
    try {
      final row = <String, dynamic>{
        // IMPORTANTE: Usar o mesmo ID local para manter sincronia
        if (habit.containsKey('id') && habit['id'] != null) 'id': habit['id'],

        // Ensure we always send `title` (DB has NOT NULL constraint)
        'title': habit['title'] ?? habit['description'] ?? '',

        // Also send description when provided
        if (habit.containsKey('description'))
          'description': habit['description']
        else if (habit.containsKey('title'))
          'description': habit['title'],

        if (habit.containsKey('frequence_type'))
          'frequency_type': habit['frequence_type']
        else if (habit.containsKey('goal'))
          'frequency_type': habit['goal'],

        // Use the column name present in your table
        'target_count': habit['target_count'] ?? habit['target'] ?? 1,

        // Note: do not send optional UI-only fields (like `reminder` or
        // `enabled`) unless your Supabase `habits` table actually has those
        // columns. Sending unknown columns causes PostgREST PGRST204 errors.

        'created_at': DateTime.now().toIso8601String(),
      };

      print('💾 [createHabit] Criando hábito com dados: $row');
      final response = await _client.from('habits').insert(row).select();
      print('✅ [createHabit] Resposta do Supabase: $response');
      if ((response as List).isEmpty) return null;
      return Map<String, dynamic>.from(response.first);
    } catch (e) {
      print('❌ [createHabit] Erro ao criar habit no Supabase: $e');
      return null;
    }
  }

  /// Deleta um hábito no Supabase pelo ID
  /// Retorna true se bem-sucedido, false caso contrário
  Future<bool> deleteHabit(String habitId) async {
    print('🗑️ [deleteHabit] Tentando deletar hábito com ID: $habitId');
    try {
      // Primeiro, verificar se o hábito existe
      final existing = await _client.from('habits').select().eq('id', habitId);
      print(
          '🔍 [deleteHabit] Registros encontrados com este ID: ${(existing as List).length}');
      if ((existing as List).isEmpty) {
        print('⚠️ [deleteHabit] Nenhum hábito encontrado com ID: $habitId');
        return false;
      }

      final response =
          await _client.from('habits').delete().eq('id', habitId).select();
      print('✅ [deleteHabit] Resposta da exclusão: $response');
      return true;
    } catch (e) {
      print('❌ [deleteHabit] Erro ao deletar habit no Supabase: $e');
      return false;
    }
  }

  /// Registra a conclusão de um hábito no dia atual
  Future<bool> recordHabitCompletion({
    required String userId,
    required String habitId,
    required DateTime date,
  }) async {
    try {
      final dto = await createHabitCompletion(
        userId: userId,
        habitId: habitId,
        date: date,
      );

      return dto != null;
    } catch (e) {
      print('❌ Erro ao registrar conclusão de hábito: $e');
      return false;
    }
  }

  /// Cria uma nova conclusão de hábito e retorna o DTO criado
  Future<HabitCompletionDto?> createHabitCompletion({
    required String userId,
    required String habitId,
    DateTime? date,
  }) async {
    try {
      final today = (date ?? DateTime.now()).toIso8601String().split('T').first;

      final response = await _client.from('habit_completions').insert({
        'user_id': userId,
        'habit_id': habitId,
        'date': today,
        'completed_at': DateTime.now().toIso8601String(),
      }).select();

      if ((response as List).isEmpty) return null;
      return HabitCompletionDto.fromMap(response.first);
    } catch (e) {
      print('❌ Erro ao criar habit_completions: $e');
      return null;
    }
  }

  /// Verifica se um hábito foi concluído em uma data específica
  Future<bool> isHabitCompletedOnDate({
    required String userId,
    required String habitId,
    required DateTime date,
  }) async {
    try {
      final dateStr = date.toIso8601String().split('T').first;

      final response = await _client
          .from('habit_completions')
          .select()
          .eq('user_id', userId)
          .eq('habit_id', habitId)
          .eq('date', dateStr);

      final list = response as List<dynamic>;
      return list.isNotEmpty;
    } catch (e) {
      // Registra esperado se nenhuma conclusão for encontrada
      return false;
    }
  }

  /// Obtém estatísticas de um usuário
  Future<Map<String, dynamic>?> getUserStats(String userId) async {
    try {
      final response = await _client
          .from('user_stats')
          .select()
          .eq('user_id', userId)
          .single();

      return response as Map<String, dynamic>?;
    } catch (e) {
      print('❌ Erro ao buscar estatísticas: $e');
      return null;
    }
  }

  /// Busca as últimas conclusões de hábito para um usuário (opcionalmente por hábito)
  Future<List<HabitCompletionDto>> fetchHabitCompletionsForUser({
    required String userId,
    String? habitId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _client.from('habit_completions').select();

      query = query.eq('user_id', userId);
      if (habitId != null && habitId.isNotEmpty) {
        query = query.eq('habit_id', habitId);
      }

      final response = await query.range(offset, offset + limit - 1);

      final list = (response as List)
          .map((item) =>
              HabitCompletionDto.fromMap(item as Map<String, dynamic>))
          .toList();

      return list;
    } catch (e) {
      print('❌ Erro ao buscar habit_completions: $e');
      return [];
    }
  }

  /// Retorna entidades de domínio (HabitCompletion) para facilitar uso na UI
  Future<List<HabitCompletion>> fetchHabitCompletionsEntitiesForUser({
    required String userId,
    String? habitId,
    int limit = 50,
    int offset = 0,
  }) async {
    final dtos = await fetchHabitCompletionsForUser(
      userId: userId,
      habitId: habitId,
      limit: limit,
      offset: offset,
    );
    return dtos.map((d) => HabitCompletionMapper.toEntity(d)).toList();
  }

  /// Subscribe a mudanças em tempo real em uma tabela
  ///
  /// Exemplo:
  /// ```dart
  /// final sub = service.subscribeToTable('providers', (event) {
  ///   print('Mudança: ${event.eventType}');
  /// });
  /// // Depois, cancele quando não precisar mais:
  /// await sub.cancel();
  /// ```
  RealtimeChannel subscribeToTable(
    String tableName,
    Function(PostgresChangePayload event) onEvent,
  ) {
    return _client
        .channel('public:$tableName')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: tableName,
          callback: onEvent,
        )
        .subscribe();
  }

  /// Autentica usuário com email e senha
  Future<AuthResponse?> signInWithEmail(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      print('❌ Erro ao fazer login: $e');
      return null;
    }
  }

  /// Registra novo usuário
  Future<AuthResponse?> signUpWithEmail(String email, String password) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      print('❌ Erro ao registrar: $e');
      return null;
    }
  }

  /// Faz logout do usuário atual
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      print('❌ Erro ao fazer logout: $e');
    }
  }

  /// Obtém o usuário atualmente autenticado
  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  /// Verifica se há uma sessão ativa
  bool isUserAuthenticated() {
    return _client.auth.currentSession != null;
  }

  // ==================== GOALS ====================

  /// Cria uma nova meta no Supabase
  /// Retorna o GoalDto criado ou null em caso de erro
  /// [id] - ID opcional para sincronizar com armazenamento local
  Future<GoalDto?> createGoal({
    String? id,
    required String title,
    required int target,
    String? reminder,
  }) async {
    try {
      // Permite criar metas mesmo sem autenticação (local-first)
      final userId = getCurrentUser()?.id;

      final dto = GoalDto(
        id: id, // Usa o ID local se fornecido, senão Supabase gera um novo
        userId: userId, // Pode ser null se não autenticado
        title: title,
        target: target,
        currentProgress: 0,
        reminder: reminder,
        completed: false,
      );

      print('💾 [createGoal] Criando meta: ${dto.toJson()}');
      final response =
          await _client.from('goals').insert(dto.toJson()).select();

      if ((response as List).isEmpty) return null;
      final created = GoalDto.fromJson(response.first);
      print('✅ [createGoal] Meta criada com ID: ${created.id}');
      return created;
    } catch (e) {
      print('❌ [createGoal] Erro ao criar meta: $e');
      return null;
    }
  }

  /// Busca todas as metas do usuário atual (ou metas sem usuário se não autenticado)
  Future<List<GoalDto>> fetchGoals() async {
    try {
      final userId = getCurrentUser()?.id;

      var query = _client.from('goals').select();

      if (userId != null) {
        // Usuário autenticado: busca suas metas
        query = query.eq('user_id', userId);
      } else {
        // Usuário não autenticado: busca metas sem user_id
        query = query.isFilter('user_id', null);
      }

      final response = await query.order('created_at', ascending: false);

      final list = (response as List)
          .map((item) => GoalDto.fromJson(item as Map<String, dynamic>))
          .toList();

      print('✅ [fetchGoals] ${list.length} metas encontradas');
      return list;
    } catch (e) {
      print('❌ [fetchGoals] Erro ao buscar metas: $e');
      return [];
    }
  }

  /// Retorna as metas como entidades de domínio
  Future<List<Goal>> fetchGoalsAsEntities() async {
    final dtos = await fetchGoals();
    return GoalMapper.toEntityList(dtos);
  }

  /// Busca uma meta específica pelo ID
  Future<GoalDto?> fetchGoalById(String goalId) async {
    try {
      final response =
          await _client.from('goals').select().eq('id', goalId).single();

      return GoalDto.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('❌ [fetchGoalById] Erro ao buscar meta: $e');
      return null;
    }
  }

  /// Atualiza o progresso de uma meta
  Future<GoalDto?> updateGoalProgress(String goalId, int newProgress) async {
    try {
      final response = await _client
          .from('goals')
          .update({'current_progress': newProgress})
          .eq('id', goalId)
          .select();

      if ((response as List).isEmpty) return null;
      print('✅ [updateGoalProgress] Progresso atualizado para: $newProgress');
      return GoalDto.fromJson(response.first);
    } catch (e) {
      print('❌ [updateGoalProgress] Erro ao atualizar progresso: $e');
      return null;
    }
  }

  /// Marca uma meta como concluída
  Future<GoalDto?> completeGoal(String goalId) async {
    try {
      final response = await _client
          .from('goals')
          .update({
            'completed': true,
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', goalId)
          .select();

      if ((response as List).isEmpty) return null;
      print('✅ [completeGoal] Meta marcada como concluída');
      return GoalDto.fromJson(response.first);
    } catch (e) {
      print('❌ [completeGoal] Erro ao completar meta: $e');
      return null;
    }
  }

  /// Reabre uma meta (remove status de concluída)
  Future<GoalDto?> reopenGoal(String goalId) async {
    try {
      final response = await _client
          .from('goals')
          .update({
            'completed': false,
            'completed_at': null,
          })
          .eq('id', goalId)
          .select();

      if ((response as List).isEmpty) return null;
      print('✅ [reopenGoal] Meta reaberta');
      return GoalDto.fromJson(response.first);
    } catch (e) {
      print('❌ [reopenGoal] Erro ao reabrir meta: $e');
      return null;
    }
  }

  /// Atualiza uma meta existente
  Future<GoalDto?> updateGoal({
    required String goalId,
    String? title,
    int? target,
    String? reminder,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (target != null) updates['target'] = target;
      if (reminder != null) updates['reminder'] = reminder;

      if (updates.isEmpty) return null;

      final response =
          await _client.from('goals').update(updates).eq('id', goalId).select();

      if ((response as List).isEmpty) return null;
      print('✅ [updateGoal] Meta atualizada');
      return GoalDto.fromJson(response.first);
    } catch (e) {
      print('❌ [updateGoal] Erro ao atualizar meta: $e');
      return null;
    }
  }

  /// Deleta uma meta
  Future<bool> deleteGoal(String goalId) async {
    try {
      print('🗑️ [deleteGoal] Deletando meta ID: $goalId');
      await _client.from('goals').delete().eq('id', goalId);
      print('✅ [deleteGoal] Meta deletada com sucesso');
      return true;
    } catch (e) {
      print('❌ [deleteGoal] Erro ao deletar meta: $e');
      return false;
    }
  }

  /// Busca metas filtradas por status de conclusão
  Future<List<GoalDto>> fetchGoalsByStatus({required bool completed}) async {
    try {
      final userId = getCurrentUser()?.id;
      if (userId == null) return [];

      final response = await _client
          .from('goals')
          .select()
          .eq('user_id', userId)
          .eq('completed', completed)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => GoalDto.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ [fetchGoalsByStatus] Erro: $e');
      return [];
    }
  }

  /// Retorna estatísticas das metas do usuário
  Future<Map<String, int>> getGoalStats() async {
    try {
      final userId = getCurrentUser()?.id;
      if (userId == null) return {'total': 0, 'completed': 0, 'pending': 0};

      final response =
          await _client.from('goals').select('completed').eq('user_id', userId);

      final list = response as List;
      final total = list.length;
      final completed = list.where((g) => g['completed'] == true).length;

      return {
        'total': total,
        'completed': completed,
        'pending': total - completed,
      };
    } catch (e) {
      print('❌ [getGoalStats] Erro: $e');
      return {'total': 0, 'completed': 0, 'pending': 0};
    }
  }
}
