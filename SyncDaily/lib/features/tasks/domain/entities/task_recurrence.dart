import 'package:equatable/equatable.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';

/// Aturan pengulangan (1:1 dengan tugas). Hanya menyimpan aturan; perluasan
/// kemunculan dihitung oleh `RecurrenceCalculator`.
///
/// TODO(F4): penyelesaian per kemunculan (menandai kemunculan tertentu selesai)
/// belum dikerjakan.
class TaskRecurrence extends Equatable {
  final String taskId;
  final RecurrenceFrequency frequency;
  final int intervalValue;

  /// Daftar hari untuk frekuensi mingguan, disimpan sebagai bitmask.
  /// Null berarti memakai hari dari titik acuan.
  final Set<Weekday>? byWeekdays;
  final int? byMonthDay;
  final DateTime? untilAt;
  final int? count;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskRecurrence({
    required this.taskId,
    required this.frequency,
    this.intervalValue = 1,
    this.byWeekdays,
    this.byMonthDay,
    this.untilAt,
    this.count,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        taskId,
        frequency,
        intervalValue,
        byWeekdays,
        byMonthDay,
        untilAt,
        count,
        createdAt,
        updatedAt,
      ];
}
