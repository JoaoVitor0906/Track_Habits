import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../../data/models/habit_dto.dart';

/// Datasource remoto para a tabela `habits` usando Supabase.
///
/// Papel:
/// - Executar queries contra a tabela `habits` no Supabase e converter o
///   resultado em DTOs do projeto (`HabitDto`).
/// - Normalizar formatos vindos do backend (ex: id como int, datas como
///   `DateTime`) para que o `HabitDto.fromJson` consiga consumir os dados.
///
/// Dicas para evitar erros comuns:
/// - Garanta que o DTO e o Mapper aceitam múltiplos formatos (ex: id como
///   int/string, datas como DateTime/String). Aqui fazemos normalizações
///   adicionais antes de chamar `HabitDto.fromJson`.
/// - Adicione logs `if (kDebugMode) { print(...); }` para inspecionar rows
///   e DTOs durante o desenvolvimento.
/// - Envolva parsing e chamadas externas em try/catch e retorne valores
///   seguros em caso de falha.
/// - Não exponha chaves/segredos em prints.
/// - Consulte `supabase_init_debug_prompt.md` e `supabase_rls_remediation.md`
///   no diretório `prompts/` para exemplos e remediações.

/// Interface esperada para um remote API de hábitos. Implementada abaixo
/// por `SupabaseHabitsRemoteDatasource`.
abstract class HabitsRemoteApi {
  Future<RemotePage<HabitDto>> fetchHabits({
    DateTime? since,
    int limit = 100,
    int offset = 0,
  });
}

/// Página simples retornada pelo datasource remoto.
class RemotePage<T> {
  final List<T> items;
  final int? next; // próximo offset (nullable)

  RemotePage({required this.items, this.next});
}

class SupabaseHabitsRemoteDatasource implements HabitsRemoteApi {
  final SupabaseClient _client;

  SupabaseHabitsRemoteDatasource({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Busca hábitos no Supabase.
  ///
  /// - [since]: filtra por data (tentamos usar `updated_at` quando disponível,
  ///   caso contrário `created_at`).
  /// - [limit]: tamanho da página.
  /// - [offset]: deslocamento para paginação (usado em `range`).
  @override
  Future<RemotePage<HabitDto>> fetchHabits({
    DateTime? since,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      // Seleciona colunas conhecidas pelo DTO. Incluímos `updated_at` por
      // precaução — pode existir na tabela mesmo que o DTO não o declare.
      const selectColumns =
          'id, title, description, frequency_type, target_count, created_at, updated_at';

      // Decide qual coluna usar para filtro/ordenacao
      final dateColumn = 'updated_at'; // preferimos updated_at quando existir

      // Construímos a query encadeando operações. Evitamos reatribuir a
      // variável `query` porque as sobrecargas de tipos no client Supabase
      // podem causar incompatibilidades de tipo com o analyzer.
      final response = await (since != null
          ? _client
              .from('habits')
              .select(selectColumns)
              .gte(dateColumn, since.toIso8601String())
              .order(dateColumn, ascending: false)
              .range(offset, offset + limit - 1)
          : _client
              .from('habits')
              .select(selectColumns)
              .order(dateColumn, ascending: false)
              .range(offset, offset + limit - 1));

      final rows = (response as List<dynamic>?) ?? <dynamic>[];

      if (kDebugMode) {
        print(
            'SupabaseHabitsRemoteDatasource.fetchHabits: recebidos ${rows.length} registros');
      }

      final List<HabitDto> dtos = [];

      for (final r in rows) {
        if (r is Map) {
          // Normaliza tipos para o DTO:
          final Map<String, dynamic> m =
              Map<String, dynamic>.from(r as Map<String, dynamic>);

          // id: pode vir como int -> converte para String
          final idVal = m['id'];
          if (idVal != null && idVal is! String) {
            try {
              m['id'] = idVal.toString();
            } catch (_) {}
          }

          // Datas: Supabase pode retornar DateTime/DateTimeTZ em Dart
          for (final k in ['created_at', 'updated_at']) {
            final v = m[k];
            if (v != null && v is DateTime) {
              m[k] = v.toIso8601String();
            }
            // Se já for String, mantemos
          }

          try {
            final dto = HabitDto.fromJson(m.cast<String, dynamic>());
            dtos.add(dto);
          } catch (e, st) {
            if (kDebugMode) {
              print(
                  'SupabaseHabitsRemoteDatasource: falha ao converter row -> HabitDto: $e');
              print(st);
              print('row: $m');
            }
            // Ignora linha corrupta e segue
          }
        }
      }

      final next = dtos.length == limit ? offset + limit : null;

      return RemotePage<HabitDto>(items: dtos, next: next);
    } catch (e, st) {
      if (kDebugMode) {
        print('SupabaseHabitsRemoteDatasource.fetchHabits: erro $e');
        print(st);
      }
      return RemotePage<HabitDto>(items: []);
    }
  }
}

/*
// Exemplo de uso:
// final remote = SupabaseHabitsRemoteDatasource();
// final page = await remote.fetchHabits(limit: 50);

// Checklist de erros comuns e como evitar:
// - Erro de conversão de tipos (ex: id como int): normalizamos id para String
//   antes de chamar `HabitDto.fromJson`.
// - Datas vindas como `DateTime` do supabase: convertidas para ISO strings.
// - Linhas com formato inesperado são ignoradas (logadas em `kDebugMode`).
// - Não imprima chaves/segredos nos logs.

// Exemplo de logs esperados:
// SupabaseHabitsRemoteDatasource.fetchHabits: recebidos 3 registros

// Referências úteis:
// - prompts/supabase_init_debug_prompt.md
// - prompts/supabase_rls_remediation.md
*/
