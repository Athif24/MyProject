import 'package:equatable/equatable.dart';

/// Profil pengguna yang sedang aktif. Untuk sementara hanya berisi nama
/// tampilan. Akan diperluas saat fitur akun tersedia.
class UserProfile extends Equatable {
  final String name;

  const UserProfile({required this.name});

  @override
  List<Object?> get props => [name];
}
