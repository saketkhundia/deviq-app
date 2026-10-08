import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure storage for credentials/tokens ONLY. Never store analytics here.
class SecureStore {
  SecureStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kToken = 'deviq.auth.token';
  static const _kEmail = 'deviq.auth.email';

  Future<void> saveSession(
      {required String token, required String email}) async {
    try {
      await _storage.write(key: _kToken, value: token);
      await _storage.write(key: _kEmail, value: email);
    } catch (_) {
      // Non-fatal: session simply won't survive a restart.
    }
  }

  Future<({String token, String email})?> readSession() async {
    try {
      final token = await _storage.read(key: _kToken);
      final email = await _storage.read(key: _kEmail);
      if (token == null || token.isEmpty || email == null || email.isEmpty) {
        return null;
      }
      return (token: token, email: email);
    } catch (_) {
      // Secure storage unavailable (e.g. missing platform plugin):
      // fail closed to signed-out instead of red-screening.
      return null;
    }
  }

  Future<void> clearSession() async {
    try {
      await _storage.delete(key: _kToken);
      await _storage.delete(key: _kEmail);
    } catch (_) {
      // Best-effort; session is already dropped in memory.
    }
  }
}

/// Non-sensitive local persistence: theme, recent usernames, playground
/// drafts, interview progress, cached profile fields.
class PrefsStore {
  // ignore: prefer_initializing_formals (public param feeds private field)
  PrefsStore({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  // In-memory fallback when the platform plugin is unavailable
  // (widget tests, rare device failure). Never used for secrets.
  final Map<String, Object> _mem = {};
  bool _memOnly = false;
  static const _kTheme = 'deviq.theme.mode'; // system|dark|light
  static const _kLastGh = 'deviq.analyze.github';
  static const _kLastLc = 'deviq.analyze.leetcode';
  static const _kLastCf = 'deviq.analyze.codeforces';
  static const _kPlayCode = 'deviq.playground.code';
  static const _kPlayLang = 'deviq.playground.language';
  static const _kPlayStdin = 'deviq.playground.stdin';
  static const _kSolved = 'deviq.interview.solved'; // string list
  static const _kHistory = 'deviq.history.records'; // string list (JSON)
  static const _kProfileCache = 'deviq.profile.cache';

  Future<SharedPreferences?> _db() async {
    if (_memOnly) return null;
    try {
      return _prefs ??= await SharedPreferences.getInstance();
    } catch (_) {
      _memOnly = true;
      return null;
    }
  }

  Future<String?> _getS(String k) async =>
      (await _db())?.getString(k) ?? _mem[k] as String?;
  Future<void> _setS(String k, String v) async {
    if (!await _put((p) => p.setString(k, v))) _mem[k] = v;
  }

  Future<List<String>> _getL(String k) async =>
      (await _db())?.getStringList(k) ??
      ((_mem[k] as List?)?.cast<String>() ?? const []);
  Future<void> _setL(String k, List<String> v) async {
    if (!await _put((p) => p.setStringList(k, v))) _mem[k] = v;
  }

  /// Runs [fn] against shared prefs; false when falling back to memory.
  Future<bool> _put(Future<bool> Function(SharedPreferences p) fn) async {
    final db = await _db();
    if (db == null) return false;
    try {
      await fn(db);
      return true;
    } catch (_) {
      return false;
    }
  }

  // Theme
  Future<String?> themeMode() async => _getS(_kTheme);
  Future<void> setThemeMode(String v) async => _setS(_kTheme, v);

  // Last analyzed usernames (prefill)
  Future<Map<String, String>> lastUsernames() async => {
        'github': await _getS(_kLastGh) ?? '',
        'leetcode': await _getS(_kLastLc) ?? '',
        'codeforces': await _getS(_kLastCf) ?? '',
      };

  Future<void> saveUsernames(
      {String? github, String? leetcode, String? codeforces}) async {
    if (github != null) await _setS(_kLastGh, github);
    if (leetcode != null) await _setS(_kLastLc, leetcode);
    if (codeforces != null) await _setS(_kLastCf, codeforces);
  }

  // Playground drafts
  Future<String?> playgroundCode(String language) async =>
      _getS('$_kPlayCode.$language');
  Future<void> savePlaygroundCode(String language, String code) async =>
      _setS('$_kPlayCode.$language', code);
  Future<String?> playgroundLang() async => _getS(_kPlayLang);
  Future<void> savePlaygroundLang(String v) async => _setS(_kPlayLang, v);
  Future<String?> playgroundStdin() async => _getS(_kPlayStdin);
  Future<void> savePlaygroundStdin(String v) async => _setS(_kPlayStdin, v);

  // Interview progress
  Future<List<String>> solvedProblems() async => _getL(_kSolved);
  Future<void> setSolved(String slug, bool solved) async {
    final cur = Set<String>.of(await _getL(_kSolved));
    if (solved) {
      cur.add(slug);
    } else {
      cur.remove(slug);
    }
    await _setL(_kSolved, cur.toList());
  }

  Future<List<String>> historyJson() async => _getL(_kHistory);
  Future<void> saveHistoryJson(List<String> items) async =>
      _setL(_kHistory, items);

  Future<String?> profileCache() async => _getS(_kProfileCache);
  Future<void> saveProfileCache(String json) async =>
      _setS(_kProfileCache, json);
}
