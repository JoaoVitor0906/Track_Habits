import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/habit_dto.dart';
import '../../../data/mappers/habit_mapper.dart';
import '../../../domain/entities/habit_entities.dart';
import '../domain/repositories/habit_repository.dart';
import 'supabase_habits_remote_datasource.dart';

/// Implementação do repositório de hábitos.
///
/// Papel:
/// - Orquestrar chamadas ao datasource remoto (`HabitsRemoteApi`) e ao DAO
///   local (injetado como `localDao`).
/// - Manter marca de `lastSync` para sincronizações incrementais.
///
/// Observações e dicas:
/// - `localDao` deve expor ao menos: `Future<List<Map<String, dynamic>>> listAll()`
///   e `Future<void> upsertAll(List<Map<String, dynamic>> items)`.
/// - Adicione logs via `kDebugMode` nos pontos principais: início/fim do sync,
///   número de itens aplicados e erros de parsing.
/// - Sempre faça parsing defensivo de datas e tipos (conversões envoltas em try/catch).
class HabitsRepositoryImpl implements HabitsRepository {
  final HabitsRemoteApi remoteApi;
  final dynamic localDao; // contrato mínimo descrito acima

  // Chave de last sync. Versão v1 — incremente se mudar formato.
  static const String _lastSyncKey = 'habits_last_sync_v1';

  HabitsRepositoryImpl({required this.remoteApi, required this.localDao});

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  /// Lê todos os registros do cache local e converte para entidades de domínio.
  @override
  Future<List<Habit>> loadFromCache() async {
    try {
      final rows = await localDao.listAll();
      final dtos = rows
          .map<HabitDto>((m) => HabitDto.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      final entities = dtos.map((d) => HabitMapper.toEntity(d)).toList();
      return entities;
    } catch (e, st) {
      if (kDebugMode) {
        print('HabitsRepositoryImpl.loadFromCache: erro $e');
        print(st);
      }
      return [];
    }
  }

  /// Sincroniza delta do servidor para o cache local.
  /// Retorna o número de registros aplicados.
  @override
  Future<int> syncFromServer() async {
    try {
      final prefs = await _prefs;
      final lastSyncIso = prefs.getString(_lastSyncKey);

      DateTime? since;
      if (lastSyncIso != null && lastSyncIso.isNotEmpty) {
        try {
          since = DateTime.parse(lastSyncIso);
        } catch (_) {
          // ignorar parse, faremos sync full
        }
      }

      if (kDebugMode) {
        print(
            'HabitsRepositoryImpl.syncFromServer: iniciando sync desde $since');
      }

      final page = await remoteApi.fetchHabits(since: since, limit: 500);

      if (page.items.isEmpty) {
        if (kDebugMode) {
          print('HabitsRepositoryImpl.syncFromServer: nenhum item retornado');
        }
        return 0;
      }

      // Prepara mapas para upsert no DAO local. Garantir que `created_at`/`updated_at`
      // sejam persistidos para auditoria/sincronização futura.
      final itemsForDao = <Map<String, dynamic>>[];
      for (final dto in page.items) {
        final map = dto.toJson();
        // `toJson` do DTO pode não incluir createdAt — asseguramos o campo
        if (dto.createdAt != null) map['created_at'] = dto.createdAt;
        // Se houver updated_at no DTO (não em HabitDto padrão), inclua também
        // (defensivo: verifique antes de acessar)
        // map['updated_at'] = dto.updatedAt ?? map['updated_at'];

        // Normalizar id: se nulo, geramos um id simples (iso timestamp)
        if (map['id'] == null) {
          map['id'] = DateTime.now().toIso8601String();
        }

        itemsForDao.add(map);
      }

      await localDao.upsertAll(itemsForDao);

      // Atualiza last sync com maior created_at/updated_at
      final newest = _computeNewest(page.items);
      final newestIso = newest.toIso8601String();
      await prefs.setString(_lastSyncKey, newestIso);

      if (kDebugMode) {
        print(
            'HabitsRepositoryImpl.syncFromServer: aplicados ${page.items.length} registros ao cache');
        print(
            'HabitsRepositoryImpl.syncFromServer: novo lastSync = $newestIso');
      }

      return page.items.length;
    } catch (e, st) {
      if (kDebugMode) {
        print('HabitsRepositoryImpl.syncFromServer: erro $e');
        print(st);
      }
      return 0;
    }
  }

  /// Retorna lista completa (cache local convertido para entidade).
  @override
  Future<List<Habit>> listAll() async {
    return await loadFromCache();
  }

  /// Filtra itens `featured` no cache local.
  /// Observação: a entidade `Habit` atual não possui campo `featured`.
  /// Portanto, aqui filtramos por chave `featured` no mapa salvo pelo DAO
  /// (se existir). Caso contrário retornamos lista vazia.
  @override
  Future<List<Habit>> listFeatured() async {
    try {
      final rows = await localDao.listAll();
      final featured = rows.where((m) {
        try {
          return (m['featured'] == true);
        } catch (_) {
          return false;
        }
      }).toList();
      final dtos = featured
          .map<HabitDto>((m) => HabitDto.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      return dtos.map((d) => HabitMapper.toEntity(d)).toList();
    } catch (e, st) {
      if (kDebugMode) {
        print('HabitsRepositoryImpl.listFeatured: erro $e');
        print(st);
      }
      return [];
    }
  }

  /// Busca por id no cache local.
  /// A interface original declara `getById(int id)` — adaptamos convertendo
  /// para String para manter compatibilidade com DAOs que usam id string.
  @override
  Future<Habit?> getById(int id) async {
    try {
      final idStr = id.toString();
      final rows = await localDao.listAll();
      final found = rows.firstWhere((m) => (m['id']?.toString() == idStr),
          orElse: () => null);
      if (found == null) return null;
      final dto = HabitDto.fromJson(Map<String, dynamic>.from(found));
      return HabitMapper.toEntity(dto);
    } catch (e, st) {
      if (kDebugMode) {
        print('HabitsRepositoryImpl.getById: erro $e');
        print(st);
      }
      return null;
    }
  }

  /// Computa a data mais recente entre `created_at`/`updated_at` dos DTOs.
  DateTime _computeNewest(List<HabitDto> items) {
    DateTime newest = DateTime.now().toUtc();
    for (final d in items) {
      try {
        if (d.createdAt != null) {
          final parsed = DateTime.parse(d.createdAt!);
          if (parsed.isAfter(newest)) newest = parsed.toUtc();
        }
      } catch (_) {
        // ignorar parsing inválido
      }
    }
    return newest;
  }
}

/*
// Exemplo de uso:
// final remote = SupabaseHabitsRemoteDatasource();
// final dao = ProvidersLocalDaoSharedPrefs(sp); // ou seu HabitsLocalDao
// final repo = HabitsRepositoryImpl(remoteApi: remote, localDao: dao);
// final applied = await repo.syncFromServer();
// final all = await repo.listAll();

// Checklist de erros comuns e como evitar:
// - Erro de conversão de tipos (ex: id como string/int): o datasource
//   normaliza id para String antes do DTO. Caso persistência exija int,
//   ajuste o DAO e os mapeamentos.
// - Falha ao atualizar UI após sync: verifique se o widget está mounted
//   antes de chamar setState.
// - Dados não aparecem após sync: ative logs (kDebugMode) em `syncFromServer`
//   e em `SupabaseHabitsRemoteDatasource.fetchHabits` para inspecionar rows.

// Exemplos de logs esperados:
// HabitsRepositoryImpl.syncFromServer: iniciando sync desde 2025-12-01T...
// HabitsRepositoryImpl.syncFromServer: aplicados 3 registros ao cache

// Referências úteis:
// - prompts/providers_cache_debug_prompt.md
// - prompts/supabase_init_debug_prompt.md
// - prompts/supabase_rls_remediation.md
*/
