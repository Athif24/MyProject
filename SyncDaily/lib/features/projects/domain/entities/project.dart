import 'package:equatable/equatable.dart';

/// Peran pengguna pada proyek. Nilai sama dengan query API `role`.
enum ProjectRole { owned, received }

class Project extends Equatable {
  final String id;
  final String title;
  final String? description;
  final DateTime? startDate;
  final DateTime? dueDate;
  final ProjectRole? role;
  final String? remoteId;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Project({
    required this.id,
    required this.title,
    this.description,
    this.startDate,
    this.dueDate,
    this.role,
    this.remoteId,
    this.version = 1,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        startDate,
        dueDate,
        role,
        remoteId,
        version,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}
