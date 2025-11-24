import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/dtos/provider_dto.dart';

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
    required int habitId,
  }) async {
    try {
      final today = DateTime.now().toIso8601String().split('T').first;

      await _client.from('habit_completions').insert({
        'user_id': userId,
        'habit_id': habitId,
        'date': today,
        'completed_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('❌ Erro ao registrar conclusão de hábito: $e');
      return false;
    }
  }

  /// Verifica se um hábito foi concluído em uma data específica
  Future<bool> isHabitCompletedOnDate({
    required String userId,
    required int habitId,
    required DateTime date,
  }) async {
    try {
      final dateStr = date.toIso8601String().split('T').first;

      await _client
          .from('habit_completions')
          .select()
          .eq('user_id', userId)
          .eq('habit_id', habitId)
          .eq('date', dateStr)
          .single();

      return true;
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
