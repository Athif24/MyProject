import 'package:equatable/equatable.dart';

/// Tipe notifikasi lokal/tersimpan. Token API memakai snake_case.
enum NotificationType {
  reminder('reminder'),
  deadline('deadline'),
  event('event'),
  message('message'),
  taskAssigned('task_assigned'),
  scheduleChanged('schedule_changed'),
  taskStatusChanged('task_status_changed'),
  projectInvite('project_invite'),
  memberJoined('member_joined'),
  system('system');

  const NotificationType(this.apiValue);

  final String apiValue;

  static NotificationType fromApiValue(String value) =>
      values.firstWhere((type) => type.apiValue == value);
}

class AppNotification extends Equatable {
  final String id;
  final NotificationType type;
  final String title;
  final String? body;
  final String? entityType;
  final String? entityId;
  final DateTime? scheduledAt;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    this.entityType,
    this.entityId,
    this.scheduledAt,
    this.isRead = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        body,
        entityType,
        entityId,
        scheduledAt,
        isRead,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}
