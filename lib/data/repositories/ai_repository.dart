import '../../core/networking/api_client.dart';
import '../models/ai_models.dart';
import '../models/github_models.dart';

/// AI endpoints: review / optimize / explain / insights.
class AiRepository {
  AiRepository(this._api);
  final ApiClient _api;

  Future<CodeReviewResult> review(
      {required String code, String language = 'javascript'}) async {
    final json = await _api.post<Map<String, dynamic>>(
      '/ai/review',
      body: {'code': code, 'language': language},
      decode: (d) => (d as Map).cast<String, dynamic>(),
    );
    final data = json['review'] is Map
        ? (json['review'] as Map).cast<String, dynamic>()
        : json;
    return CodeReviewResult.fromJson(data);
  }

  Future<String> optimize(
      {required String code, String language = 'javascript'}) async {
    final json = await _api.post<Map<String, dynamic>>(
      '/ai/optimize',
      body: {'code': code, 'language': language},
      decode: (d) => (d as Map).cast<String, dynamic>(),
    );
    return parseString(json['optimized_code'] ??
        json['optimizedCode'] ??
        json['result'] ??
        json['response']);
  }

  Future<String> explain(
      {required String code, String language = 'javascript'}) async {
    final json = await _api.post<Map<String, dynamic>>(
      '/ai/explain',
      body: {'code': code, 'language': language},
      decode: (d) => (d as Map).cast<String, dynamic>(),
    );
    return parseString(
        json['explanation'] ?? json['result'] ?? json['response']);
  }

  Future<String> insights(
      {required String prompt, List<ChatMessage> history = const []}) async {
    final json = await _api.post<Map<String, dynamic>>(
      '/ai/insights',
      body: {
        'prompt': prompt,
        'conversation_history': history.map((m) => m.toJson()).toList(),
      },
      decode: (d) => (d as Map).cast<String, dynamic>(),
    );
    return parseString(json['response'] ?? json['result'] ?? json['insight']);
  }
}
