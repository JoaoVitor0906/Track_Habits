import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/dtos/provider_dto.dart';
import '../data/dtos/habit_completion_dto.dart';
import '../data/mappers/habit_completion_mapper.dart';
import '../domain/entities/habit_completion_entities.dart';

/// Serviço para integração com Supabase
/// Fornece métodos para operações CRUD com tabelas do backend
class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Obtém a lista de providers (fornecedores)
  ///
  /// Parâmetros:
  /// - [limit]: número máximo de registros (padrão 20)
  /// - [offset]: deslocamento para paginação (padrão 0)
  /// - [searchTerm]: filtro opcional por nome ou descrição
  ///
  /// Retorna: Lista de [ProviderDto] ou lista vazia em caso de erro
  Future<List<ProviderDto>> fetchProviders({
    int limit = 20,
    int offset = 0,
    String? searchTerm,
  }) async {
    try {
      var query = _client.from('providers').select();

      // Aplicar filtro de busca se fornecido
      if (searchTerm != null && searchTerm.isNotEmpty) {
        query = query.ilike('name', '%$searchTerm%');
      }

      final response = await query.range(offset, offset + limit - 1);

      final list = (response as List)
          .map((item) => ProviderDto.fromMap(item as Map<String, dynamic>))
          .toList();

      return list;
    } catch (e) {
      print('❌ Erro ao buscar providers: $e');
      return [];
    }
  }

  /// Cria um novo provider
  Future<ProviderDto?> createProvider({
    required String name,
    required double rating,
    String? imageUrl,
    String? brandColorHex,
    double? distanceKm,
  }) async {
    try {
      final response = await _client.from('providers').insert({
        'name': name,
        'rating': rating,
        'image_url': imageUrl,
        'brand_color_hex': brandColorHex,
        'distance_km': distanceKm,
        'updated_at': DateTime.now().toIso8601String(),
      }).select();

      if ((response as List).isEmpty) return null;

      return ProviderDto.fromMap(response.first);
    } catch (e) {
      print('❌ Erro ao criar provider: $e');
      return null;
    }
  }

  /// Cria um hábito no Supabase (opcionalmente sincroniza dados locais com o servidor)
  /// Retorna o mapa criado ou null
  Future<Map<String, dynamic>?> createHabit(Map<String, dynamic> habit) async {
    try {
      final row = <String, dynamic>{
        'title': habit['title'],
        'goal': habit['goal'],
        'reminder': habit['reminder'],
        'enabled': habit['enabled'] == true,
        'target': habit['target'] ?? 1,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _client.from('habits').insert(row).select();
      if ((response as List).isEmpty) return null;
      return Map<String, dynamic>.from(response.first);
    } catch (e) {
      print('❌ Erro ao criar habit no Supabase: $e');
      return null;
    }
  }

  /// Atualiza um provider existente
  Future<bool> updateProvider({
    required int id,
    required String name,
    required double rating,
    String? imageUrl,
    String? brandColorHex,
    double? distanceKm,
  }) async {
    try {
      await _client.from('providers').update({
        'name': name,
        'rating': rating,
        'image_url': imageUrl,
        'brand_color_hex': brandColorHex,
        'distance_km': distanceKm,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);

      return true;
    } catch (e) {
      print('❌ Erro ao atualizar provider: $e');
      return false;
    }
  }

  /// Deleta um provider
  Future<bool> deleteProvider(int id) async {
    try {
      await _client.from('providers').delete().eq('id', id);
      return true;
    } catch (e) {
      print('❌ Erro ao deletar provider: $e');
      return false;
    }
  }

  /// Registra a conclusão de um hábito no dia atual
  Future<bool> recordHabitCompletion({
    required String userId,
    required String habitId,
  }) async {
    try {
      final dto = await createHabitCompletion(
        userId: userId,
        habitId: habitId,
        date: DateTime.now(),
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
          .map((item) => HabitCompletionDto.fromMap(item as Map<String, dynamic>))
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
}
