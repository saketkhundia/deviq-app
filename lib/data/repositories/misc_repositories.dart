import '../../core/networking/api_client.dart';
import '../models/ai_models.dart';
import '../models/auth_models.dart';
import '../models/github_models.dart';

/// Interview prep: company problems + profile persistence.
class InterviewRepository {
  InterviewRepository(this._api);
  final ApiClient _api;

  Future<List<CompanyProblem>> companyProblems(String slug) async {
    final json = await _api.get<Map<String, dynamic>>(
      '/leetcode/company-problems/$slug',
      decode: (d) => (d as Map).cast<String, dynamic>(),
    );
    return asList(json['problems'])
        .whereType<Map<String, dynamic>>()
        .map(CompanyProblem.fromJson)
        .toList();
  }
}

class ProfileRepository {
  ProfileRepository(this._api);
  final ApiClient _api;

  Future<UserProfile> fetch() async {
    final json = await _api.get<Map<String, dynamic>>(
      '/profile',
      decode: (d) => (d as Map).cast<String, dynamic>(),
    );
    final data = json['profile'] is Map
        ? (json['profile'] as Map).cast<String, dynamic>()
        : json;
    return UserProfile.fromJson(data);
  }

  Future<void> save(UserProfile p) async {
    await _api.put<dynamic>(
      '/profile',
      body: {
        ...p.toJson(),
        'bio': p.bio,
        'website': p.website,
        'location': p.location,
      },
    );
  }

  Future<void> sync(UserProfile p) async {
    await _api.post<dynamic>('/sync/profile', body: p.toJson());
  }

  Future<Map<String, bool>> connectedAccounts() async {
    try {
      final json = await _api.get<Map<String, dynamic>>(
        '/accounts/connected',
        decode: (d) => (d as Map).cast<String, dynamic>(),
      );
      final out = <String, bool>{};
      json.forEach((k, v) {
        if (v is bool) out[k] = v;
      });
      return out;
    } catch (_) {
      return const {};
    }
  }
}
