import '../../core/networking/api_client.dart';
import '../models/ai_models.dart';
import '../models/github_models.dart';

/// Code execution: single-shot POST /execute with polling fallback
/// (/exec/start → /exec/poll → /exec/input → /exec/kill).
class ExecutionRepository {
  ExecutionRepository(this._api);
  final ApiClient _api;

  /// Raw reachability probe for the Live badge. Throws on failure
  /// (unlike [languages], which degrades to a static fallback).
  Future<void> reachable() async {
    await _api.get<dynamic>('/exec/languages');
  }

  Future<List<String>> languages() async {
    try {
      final json = await _api.get<Map<String, dynamic>>(
        '/exec/languages',
        decode: (d) => (d as Map).cast<String, dynamic>(),
      );
      final sup = asMap(json['supported']);
      return sup.entries
          .where((e) => e.value == true)
          .map((e) => e.key)
          .toList();
    } catch (_) {
      return const [
        'python',
        'javascript',
        'typescript',
        'java',
        'c',
        'cpp',
        'go',
      ];
    }
  }

  Future<ExecutionResult> execute({
    required String language,
    required String code,
    String stdin = '',
    int timeout = 10,
    String? filename,
  }) async {
    try {
      final json = await _api.post<Map<String, dynamic>>(
        '/execute',
        body: {
          'language': language,
          'code': code,
          'stdin': stdin,
          'timeout': timeout,
          ...?filename == null ? null : {'filename': filename},
        },
        decode: (d) => (d as Map).cast<String, dynamic>(),
      );
      return ExecutionResult.fromJson(json);
    } catch (_) {
      return _interactive(
        language: language,
        code: code,
        filename: filename,
        stdin: stdin,
      );
    }
  }

  /// Interactive session path for stdin-driven programs.
  Future<ExecutionResult> _interactive({
    required String language,
    required String code,
    String? filename,
    String stdin = '',
  }) async {
    final sw = Stopwatch()..start();
    final start = await _api.post<Map<String, dynamic>>(
      '/exec/start',
      body: {
        'language': language,
        'code': code,
        ...?filename == null ? null : {'filename': filename},
      },
      decode: (d) => (d as Map).cast<String, dynamic>(),
    );
    final sid = parseString(start['session_id'] ?? start['sid']);
    if (sid.isEmpty) throw const FormatException('no session');
    if (stdin.isNotEmpty) {
      for (final line in stdin.split('\n')) {
        await _api.post<dynamic>(
          '/exec/input',
          body: {'session_id': sid, 'line': line},
        );
      }
    }
    var so = 0, se = 0;
    var out = StringBuffer();
    var err = StringBuffer();
    var exit = 0;
    var done = false;
    for (var i = 0; i < 40 && !done; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 750));
      final poll = await _api.get<Map<String, dynamic>>(
        '/exec/poll/$sid',
        query: {'so': so, 'se': se},
        decode: (d) => (d as Map).cast<String, dynamic>(),
      );
      out.write(parseString(poll['stdout'] ?? poll['output']));
      err.write(parseString(poll['stderr'] ?? poll['error']));
      so = parseInt(poll['so'] ?? so);
      se = parseInt(poll['se'] ?? se);
      done = poll['done'] == true || poll['status'] == 'done';
      exit = parseInt(poll['exit_code'] ?? poll['exitCode']);
    }
    sw.stop();
    return ExecutionResult(
      output: out.toString(),
      error: err.toString(),
      exitCode: exit,
      elapsedMs: sw.elapsedMilliseconds,
      timedOut: !done,
    );
  }

  Future<void> sendInput(String sessionId, String line) => _api.post<dynamic>(
    '/exec/input',
    body: {'session_id': sessionId, 'line': line},
  );

  Future<void> kill(String sessionId) =>
      _api.post<dynamic>('/exec/kill', body: {'session_id': sessionId});
}
