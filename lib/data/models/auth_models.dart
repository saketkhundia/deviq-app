import 'github_models.dart';

/// Auth user (safe fields only, mirrors GET /auth/me).
class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    required this.provider,
  });

  final String id;
  final String name;
  final String email;
  final String avatar;
  final String provider;

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
    id: parseString(j['id'] ?? j['_id'] ?? j['user_id']),
    name: parseString(j['name']),
    email: parseString(j['email']),
    avatar: parseString(
      j['avatar'] ?? j['profile_picture_url'] ?? j['picture'],
    ),
    provider: parseString(j['provider']),
  );
}

/// Portfolio profile (GET/PUT /profile).
class UserProfile {
  const UserProfile({
    required this.displayName,
    required this.bio,
    required this.website,
    required this.location,
    required this.avatar,
    required this.githubUsername,
    required this.leetcodeUsername,
    required this.codeforcesHandle,
    required this.analysesRun,
    required this.comparisonsRun,
    required this.aiInsightsRun,
    required this.recentAnalyses,
    required this.solvedProblems,
  });

  final String displayName;
  final String bio;
  final String website;
  final String location;
  final String avatar;
  final String githubUsername;
  final String leetcodeUsername;
  final String codeforcesHandle;
  final int analysesRun;
  final int comparisonsRun;
  final int aiInsightsRun;
  final List<String> recentAnalyses;
  final List<String> solvedProblems;

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    displayName: parseString(j['displayName'] ?? j['display_name']),
    bio: parseString(j['bio']),
    website: parseString(j['website']),
    location: parseString(j['location']),
    avatar: parseString(j['avatar'] ?? j['profile_picture_url']),
    githubUsername: parseString(j['github_username']),
    leetcodeUsername: parseString(j['leetcode_username']),
    codeforcesHandle: parseString(j['codeforces_handle']),
    analysesRun: parseInt(j['analysesRun']),
    comparisonsRun: parseInt(j['comparisonsRun']),
    aiInsightsRun: parseInt(j['aiInsightsRun']),
    recentAnalyses: asList(j['recentAnalyses'])
        .map((e) => e.toString())
        .toList(),
    solvedProblems: asList(j['solvedProblems'])
        .map((e) => e.toString())
        .toList(),
  );

  factory UserProfile.empty() => const UserProfile(
    displayName: '',
    bio: '',
    website: '',
    location: '',
    avatar: '',
    githubUsername: '',
    leetcodeUsername: '',
    codeforcesHandle: '',
    analysesRun: 0,
    comparisonsRun: 0,
    aiInsightsRun: 0,
    recentAnalyses: [],
    solvedProblems: [],
  );

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'bio': bio,
    'website': website,
    'location': location,
    'avatar': avatar,
    'github_username': githubUsername,
    'leetcode_username': leetcodeUsername,
    'codeforces_handle': codeforcesHandle,
  };

  UserProfile copyWith({
    String? displayName,
    String? bio,
    String? website,
    String? location,
    String? avatar,
    String? githubUsername,
    String? leetcodeUsername,
    String? codeforcesHandle,
  }) => UserProfile(
    displayName: displayName ?? this.displayName,
    bio: bio ?? this.bio,
    website: website ?? this.website,
    location: location ?? this.location,
    avatar: avatar ?? this.avatar,
    githubUsername: githubUsername ?? this.githubUsername,
    leetcodeUsername: leetcodeUsername ?? this.leetcodeUsername,
    codeforcesHandle: codeforcesHandle ?? this.codeforcesHandle,
    analysesRun: analysesRun,
    comparisonsRun: comparisonsRun,
    aiInsightsRun: aiInsightsRun,
    recentAnalyses: recentAnalyses,
    solvedProblems: solvedProblems,
  );
}
