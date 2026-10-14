import 'package:equatable/equatable.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';

class Task extends Equatable {
  final String id;
  final String? projectId;
  final String? parentTaskId;
  final String title;
  final String? description;
  final TaskType type;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? startAt;
  final DateTime? endAt;
  final DateTime? dueAt;
  final bool isAllDay;

  /// Diisi otomatis saat [status] menjadi [TaskStatus.done].
  final DateTime? completedAt;

  /// ID dari server (diisi saat sinkronisasi Fase 2). Null untuk data lokal.
  final String? remoteId;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Task({
    required this.id,
    this.projectId,
    this.parentTaskId,
    required this.title,
    this.description,
    required this.type,
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.medium,
    this.startAt,
    this.endAt,
    this.dueAt,
    this.isAllDay = false,
    this.completedAt,
    this.remoteId,
    this.version = 1,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Task copyWith({
    String? id,
    String? projectId,
    String? parentTaskId,
    String? title,
    String? description,
    TaskType? type,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? startAt,
    DateTime? endAt,
    DateTime? dueAt,
    bool? isAllDay,
    DateTime? completedAt,
    String? remoteId,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Task(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      dueAt: dueAt ?? this.dueAt,
      isAllDay: isAllDay ?? this.isAllDay,
      completedAt: completedAt ?? this.completedAt,
      remoteId: remoteId ?? this.remoteId,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        parentTaskId,
        title,
        description,
        type,
        status,
        priority,
        startAt,
        endAt,
        dueAt,
        isAllDay,
        completedAt,
        remoteId,
        version,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}
