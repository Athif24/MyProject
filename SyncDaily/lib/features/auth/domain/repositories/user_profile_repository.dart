import 'package:sync_daily/features/auth/domain/entities/user_profile.dart';

/// Sumber data profil pengguna.
///
/// TODO(F9/Fase 2): ganti dengan implementasi berbasis API + penyimpanan lokal
/// setelah fitur akun (login/daftar) tersedia.
abstract class UserProfileRepository {
  UserProfile get profile;

  Stream<UserProfile> watchProfile();

  Future<void> updateName(String name);
}
