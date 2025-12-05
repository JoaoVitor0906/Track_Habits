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

  // --- New API: per-habit numeric targets and daily instance counts ---

  String _habitCountKey(String id, DateTime date) {
    final day = date.toIso8601String().split('T').first;
    return 'habit_count_${id}_$day';
  }

  /// Returns how many times the habit [id] was completed on [date].
  int getHabitCount(String id, DateTime date) {
    final key = _habitCountKey(id, date);
    return _prefs.getInt(key) ?? 0;
  }

  /// Sets the exact count for a habit on a given date.
  Future<void> setHabitCount(String id, DateTime date, int count) async {
    final key = _habitCountKey(id, date);
    if (count <= 0) {
      await _prefs.remove(key);
    } else {
      await _prefs.setInt(key, count);
    }
  }

  /// Increment (or decrement, if delta < 0) the habit count for [id] on [date].
  Future<void> incrementHabitCount(String id, DateTime date, int delta) async {
    final current = getHabitCount(id, date);
    final next = (current + delta) < 0 ? 0 : (current + delta);
    await setHabitCount(id, date, next);
  }

  /// Returns the total number of completed instances today across all given
  /// habit ids, counting up to each habit's configured `target` (so if a habit
  /// has target 3 and a user completed 4 times, it counts as 3 toward the total).
  int countCompletedInstancesCapped(List<String> ids, DateTime date) {
    var sum = 0;
    for (final id in ids) {
      final h = getHabit(id);
      final target = (h != null) ? (h['target'] as int?) ?? 1 : 1;
      final got = getHabitCount(id, date);
      sum += (got <= target) ? got : target;
    }
    return sum;
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

  // Daily goals set by the user (number of goals to achieve daily)
  static const String _dailyGoalCountKey = 'daily_goal_count';

  /// Returns the user-configured daily goals count. If 0, app may fall back to
  /// using the number of configured habits as implicit goal count.
  int getDailyGoalCount() => _prefs.getInt(_dailyGoalCountKey) ?? 0;

  Future<void> setDailyGoalCount(int count) async {
    if (count <= 0) {
      await _prefs.remove(_dailyGoalCountKey);
    } else {
      await _prefs.setInt(_dailyGoalCountKey, count);
    }
  }

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

  // --- Completion history (list of completed habit events) ---
  static const String _habitCompletionHistoryKey = 'habit_completion_history';

  /// Adds a completion record for a habit with timestamp. Newest entries are
  /// stored first.
  Future<void> addCompletionRecord(
      String habitId, String? title, DateTime at) async {
    final list = _prefs.getStringList(_habitCompletionHistoryKey) ?? [];
    final entry = jsonEncode({
      'habit_id': habitId,
      'title': title ?? '',
      'completed_at': at.toIso8601String(),
    });
    list.insert(0, entry);
    await _prefs.setStringList(_habitCompletionHistoryKey, list);
  }

  /// Returns completion history as a list of maps sorted newest-first.
  List<Map<String, dynamic>> getCompletionHistory() {
    final list = _prefs.getStringList(_habitCompletionHistoryKey) ?? [];
    return list
        .map((e) => Map<String, dynamic>.from(jsonDecode(e) as Map))
        .toList();
  }

  /// Clears the stored completion history.
  Future<void> clearCompletionHistory() async =>
      await _prefs.remove(_habitCompletionHistoryKey);

  // --- Goals management (separate from habits) ---
  static const String _goalsListKey = 'goals_list';

  /// Saves a goal and returns its ID.
  Future<String> saveGoal(Map<String, dynamic> goal) async {
    final id = (goal['id'] as String?) ?? const Uuid().v4();
    final key = 'goal_$id';
    final withId = Map<String, dynamic>.from(goal);
    withId['id'] = id;
    withId['createdAt'] =
        withId['createdAt'] ?? DateTime.now().toIso8601String();
    await _prefs.setString(key, jsonEncode(withId));
    final ids = _prefs.getStringList(_goalsListKey) ?? [];
    if (!ids.contains(id)) {
      ids.add(id);
      await _prefs.setStringList(_goalsListKey, ids);
    }
    return id;
  }

  /// Gets a goal by ID.
  Map<String, dynamic>? getGoal(String id) {
    final raw = _prefs.getString('goal_$id');
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  /// Deletes a goal by ID.
  Future<void> deleteGoal(String id) async {
    await _prefs.remove('goal_$id');
    final ids = _prefs.getStringList(_goalsListKey) ?? [];
    ids.remove(id);
    await _prefs.setStringList(_goalsListKey, ids);
  }

  /// Returns all goals.
  List<Map<String, dynamic>> getAllGoals() {
    final ids = _prefs.getStringList(_goalsListKey) ?? [];
    final out = <Map<String, dynamic>>[];
    for (final id in ids) {
      final g = getGoal(id);
      if (g != null) out.add(g);
    }
    return out;
  }

  /// Updates a goal's progress.
  Future<void> updateGoalProgress(String id, int currentProgress) async {
    final goal = getGoal(id);
    if (goal != null) {
      goal['currentProgress'] = currentProgress;
      goal['updatedAt'] = DateTime.now().toIso8601String();
      await _prefs.setString('goal_$id', jsonEncode(goal));
    }
  }

  /// Marks a goal as completed.
  Future<void> completeGoal(String id) async {
    final goal = getGoal(id);
    if (goal != null) {
      goal['completed'] = true;
      goal['completedAt'] = DateTime.now().toIso8601String();
      await _prefs.setString('goal_$id', jsonEncode(goal));
    }
  }
}
