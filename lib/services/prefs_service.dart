import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class PrefsService {
  static const String _policiesVersion = 'v1';
  static const String _privacyReadKey = 'privacy_read_$_policiesVersion';
  static const String _termsReadKey = 'terms_read_$_policiesVersion';
  static const String _policiesVersionAcceptedKey = 'policies_version_accepted';
  static const String _acceptedAtKey = 'accepted_at';
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _habitsListKey = 'habits_list'; // Para hábitos (JSON)

  final SharedPreferences _prefs;

  PrefsService(this._prefs);

  // Checa se fully accepted
  bool get isFullyAccepted {
    return _prefs.getBool(_onboardingCompletedKey) == true &&
        _prefs.getString(_policiesVersionAcceptedKey) == _policiesVersion;
  }

  // Checa se onboarding completed
  bool get isOnboardingCompleted =>
      _prefs.getBool(_onboardingCompletedKey) == true;

  // Set read for policy
  Future<void> setPolicyRead(String policy, bool read) async {
    final key = policy == 'privacy' ? _privacyReadKey : _termsReadKey;
    await _prefs.setBool(key, read);
  }

  // Generic setter used by onboarding flow
  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  bool get isPrivacyRead => _prefs.getBool(_privacyReadKey) == true;
  bool get isTermsRead => _prefs.getBool(_termsReadKey) == true;

  // Accept policies
  Future<void> acceptPolicies() async {
    await _prefs.setString(_policiesVersionAcceptedKey, _policiesVersion);
    await _prefs.setString(_acceptedAtKey, DateTime.now().toIso8601String());
    await _prefs.setBool(_onboardingCompletedKey, true);
  }

  // Revoke
  Future<void> revokePolicies() async {
    await _prefs.remove(_privacyReadKey);
    await _prefs.remove(_termsReadKey);
    await _prefs.remove(_policiesVersionAcceptedKey);
    await _prefs.remove(_acceptedAtKey);
    await _prefs.setBool(_onboardingCompletedKey, false);
  }

  List<Map<String, dynamic>> get habits =>
      _prefs
          .getStringList(_habitsListKey)
          ?.map((e) => Map<String, dynamic>.from(jsonDecode(e)))
          .toList() ??
      [];

  // New habit APIs: save/get/delete by id and list of ids in _habitsListKey
  Future<String> saveHabit(Map<String, dynamic> habit) async {
    final id = (habit['id'] as String?) ?? const Uuid().v4();
    final key = 'habit_$id';
    final withId = Map<String, dynamic>.from(habit);
    withId['id'] = id;
    await _prefs.setString(key, jsonEncode(withId));
    final ids = _prefs.getStringList(_habitsListKey) ?? [];
    if (!ids.contains(id)) {
      ids.add(id);
      await _prefs.setStringList(_habitsListKey, ids);
    }
    return id;
  }

  Map<String, dynamic>? getHabit(String id) {
    final raw = _prefs.getString('habit_$id');
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  Future<void> deleteHabit(String id) async {
    await _prefs.remove('habit_$id');
    final ids = _prefs.getStringList(_habitsListKey) ?? [];
    ids.remove(id);
    await _prefs.setStringList(_habitsListKey, ids);
  }

  List<Map<String, dynamic>> getAllHabits() {
    final ids = _prefs.getStringList(_habitsListKey) ?? [];
    final out = <Map<String, dynamic>>[];
    for (final id in ids) {
      final h = getHabit(id);
      if (h != null) out.add(h);
    }
    return out;
  }

  Future<void> addHabit(Map<String, dynamic> habit) async {
    final list = habits;
    list.add(habit);
    await _prefs.setStringList(
        _habitsListKey, list.map((e) => jsonEncode(e)).toList());
  }

  Future<void> clearHabits() async => await _prefs.remove(_habitsListKey);

  // Habit completion tracking (per-day). Keys are: habit_done_<id>_<YYYY-MM-DD>
  String _habitDoneKey(String id, DateTime date) {
    final day = date.toIso8601String().split('T').first;
    return 'habit_done_${id}_$day';
  }

  /// Mark or unmark a habit as done for a specific date (usually today).
  Future<void> setHabitDone(String id, DateTime date, bool done) async {
    final key = _habitDoneKey(id, date);
    if (done) {
      await _prefs.setBool(key, true);
    } else {
      await _prefs.remove(key);
    }
  }

  /// Check if a habit is marked done for a specific date.
  bool isHabitDone(String id, DateTime date) {
    final key = _habitDoneKey(id, date);
    return _prefs.getBool(key) == true;
  }

  /// Count how many habit ids from [ids] are marked done for [date].
  int countHabitsDone(List<String> ids, DateTime date) {
    var count = 0;
    for (final id in ids) {
      if (isHabitDone(id, date)) count++;
    }
    return count;
  }

  // Generic getters/setters for tests and API completeness
  bool getBoolKey(String key) => _prefs.getBool(key) == true;
  Future<void> setBoolKey(String key, bool value) async =>
      await _prefs.setBool(key, value);
  String? getStringKey(String key) => _prefs.getString(key);
  Future<void> setStringKey(String key, String value) async =>
      await _prefs.setString(key, value);
  Future<void> setString(String key, String value) async =>
      await setStringKey(key, value);

  // Migrate policy version (simple invalidation)
  Future<void> migratePolicyVersion(String from, String to) async {
    final accepted = _prefs.getString(_policiesVersionAcceptedKey);
    if (accepted != to) {
      await _prefs.remove(_privacyReadKey);
      await _prefs.remove(_termsReadKey);
      await _prefs.remove(_policiesVersionAcceptedKey);
      await _prefs.remove(_acceptedAtKey);
    }
  }
}

class HabitService {
  final PrefsService prefs;
  HabitService(this.prefs);

  Future<void> createExampleHabit() async {
    if (prefs.getAllHabits().isEmpty) {
      final id = await prefs.saveHabit({
        'title': 'Beber água',
        'goal': '3 copos/dia',
        'reminder': '09:00',
        'enabled': true
      });
      await prefs.setBoolKey('first_habit_created', true);
      await prefs.setStringKey('first_habit_id', id);
    }
  }
}
