import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/auth_models.dart';
import '../../app/providers/app_providers.dart';

/// Profile state: fetch / edit / sync + connected accounts.
class ProfileState {
  const ProfileState(
      {this.profile,
      this.loading = false,
      this.saving = false,
      this.error,
      this.connected = const {}});

  final UserProfile? profile;
  final bool loading;
  final bool saving;
  final String? error;
  final Map<String, bool> connected;

  ProfileState copyWith({
    UserProfile? profile,
    bool? loading,
    bool? saving,
    String? error,
    Map<String, bool>? connected,
  }) =>
      ProfileState(
        profile: profile ?? this.profile,
        loading: loading ?? this.loading,
        saving: saving ?? this.saving,
        error: error,
        connected: connected ?? this.connected,
      );
}

final profileProvider =
    StateNotifierProvider<ProfileController, ProfileState>(
        (ref) => ProfileController(ref));

class ProfileController extends StateNotifier<ProfileState> {
  ProfileController(this._ref) : super(const ProfileState());

  final Ref _ref;

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final p = await _ref.read(profileRepoProvider).fetch();
      final c = await _ref.read(profileRepoProvider).connectedAccounts();
      state = state.copyWith(loading: false, profile: p, connected: c);
    } catch (e) {
      state = state.copyWith(loading: false, error: '$e');
    }
  }

  Future<bool> save(UserProfile p) async {
    state = state.copyWith(saving: true, error: null);
    try {
      await _ref.read(profileRepoProvider).save(p);
      state = state.copyWith(saving: false, profile: p);
      return true;
    } catch (e) {
      state = state.copyWith(saving: false, error: '$e');
      return false;
    }
  }

  Future<void> sync() async {
    final p = state.profile;
    if (p == null) return;
    state = state.copyWith(saving: true);
    try {
      await _ref.read(profileRepoProvider).sync(p);
    } catch (e) {
      state = state.copyWith(error: '$e');
    } finally {
      state = state.copyWith(saving: false);
    }
  }
}
