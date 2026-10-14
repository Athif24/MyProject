import 'package:equatable/equatable.dart';

/// Pengingat sebelum titik acuan tugas.
///
/// Titik acuan dihitung dari `startAt` bila ada, jika tidak dari `dueAt`
/// (lihat `TaskDateUtils.reminderTimeFor`). Untuk item bertipe `reminder`,
/// waktunya sendiri adalah titik acuan sehingga `offsetMinutes = 0` sah.
class TaskReminder extends Equatable {
  final String id;
  final String taskId;
  final int offsetMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskReminder({
    required this.id,
    required this.taskId,
    required this.offsetMinutes,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, taskId, offsetMinutes, createdAt, updatedAt];
}
