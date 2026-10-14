import 'dart:async';

import 'package:sync_daily/features/auth/domain/entities/user_profile.dart';
import 'package:sync_daily/features/auth/domain/repositories/user_profile_repository.dart';

/// Stub profil pengguna yang disimpan di memori saja.
///
/// TODO(F9/Fase 2): ganti dengan repository berbasis API + penyimpanan lokal
/// saat fitur akun tersedia. Nama bawaan "Pengguna" (bukan nama pribadi siapa
/// pun).
class UserProfileRepositoryImpl implements UserProfileRepository {
  static const String defaultName = 'Pengguna';

  final _controller = StreamController<UserProfile>.broadcast();
  UserProfile _profile = const UserProfile(name: defaultName);

  @override
  UserProfile get profile => _profile;

  @override
  Stream<UserProfile> watchProfile() async* {
    yield _profile;
    yield* _controller.stream;
  }

  @override
  Future<void> updateName(String name) async {
    _profile = UserProfile(name: name);
    _controller.add(_profile);
  }
}
