import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Stub DAO: ProvidersLocalDaoSharedPrefs
/// Methods: listAll, upsertAll, clear
/// This is a minimal implementation using SharedPreferences for local storage.
class ProvidersLocalDaoSharedPrefs {
  static const _key = 'providers_list_v1';
  final SharedPreferences _prefs;

  ProvidersLocalDaoSharedPrefs(this._prefs);

  Future<List<Map<String, dynamic>>> listAll() async {
    final list = _prefs.getStringList(_key) ?? [];
    return list.map((s) => Map<String, dynamic>.from(jsonDecode(s))).toList();
  }

  Future<void> upsertAll(List<Map<String, dynamic>> items) async {
    final encoded = items.map((e) => jsonEncode(e)).toList();
    await _prefs.setStringList(_key, encoded);
  }

  /// Upsert a single item by id (replace or add).
  Future<void> upsert(Map<String, dynamic> item) async {
    final list = await listAll();
    final id = item['id'] as String?;
    if (id == null) {
      // If no id provided, generate a simple unique id based on timestamp
      final genId = DateTime.now().toIso8601String();
      final withId = Map<String, dynamic>.from(item);
      withId['id'] = genId;
      list.add(withId);
      await upsertAll(list);
      return;
    }

    final idx = list.indexWhere((e) => (e['id'] as String?) == id);
    if (idx >= 0) {
      list[idx] = item;
    } else {
      list.add(item);
    }
    await upsertAll(list);
  }

  Future<void> clear() async {
    await _prefs.remove(_key);
  }

  /// Remove an item by id. Returns true if removed.
  Future<bool> remove(String id) async {
    final list = await listAll();
    final idx = list.indexWhere((e) => (e['id'] as String?) == id);
    if (idx < 0) return false;
    list.removeAt(idx);
    await upsertAll(list);
    return true;
  }
}
