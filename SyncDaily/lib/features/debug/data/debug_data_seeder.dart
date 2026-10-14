import 'package:sync_daily/core/database/app_database.dart';
import 'package:sync_daily/features/notifications/domain/entities/app_notification.dart';
import 'package:sync_daily/features/notifications/domain/repositories/notification_repository.dart';
import 'package:sync_daily/features/projects/domain/entities/project.dart';
import 'package:sync_daily/features/projects/domain/repositories/project_repository.dart';
import 'package:sync_daily/features/tasks/domain/entities/task.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';
import 'package:sync_daily/features/tasks/domain/repositories/task_repository.dart';
import 'package:uuid/uuid.dart';

/// Utilitas HANYA untuk debug: mengisi data contoh ke database lokal atau
/// menghapus semuanya. Dipakai lewat galeri komponen (mode debug).
class DebugDataSeeder {
  final AppDatabase _database;
  final TaskRepository _taskRepository;
  final ProjectRepository _projectRepository;
  final NotificationRepository _notificationRepository;
  final Uuid _uuid;

  DebugDataSeeder({
    required AppDatabase database,
    required TaskRepository taskRepository,
    required ProjectRepository projectRepository,
    required NotificationRepository notificationRepository,
    Uuid? uuid,
  })  : _database = database,
        _taskRepository = taskRepository,
        _projectRepository = projectRepository,
        _notificationRepository = notificationRepository,
        _uuid = uuid ?? const Uuid();

  /// Menghapus seluruh baris pada semua tabel (anak lebih dulu agar tidak
  /// melanggar foreign key).
  Future<void> clearAll() async {
    const tablesInOrder = [
      'task_reminders',
      'task_recurrences',
      'tasks',
      'projects',
      'notes',
      'app_notifications',
    ];
    for (final table in tablesInOrder) {
      await _database.customStatement('DELETE FROM $table');
    }
  }

  /// Mengisi beberapa proyek dan tugas berbagai tipe.
  Future<void> seed() async {
    await clearAll();

    final now = DateTime.now();
    final ts = now.toUtc();
    final week = DateTime.now();
    final weekStart = week.subtract(Duration(days: week.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    final projectA = _uuid.v4();
    final projectB = _uuid.v4();

    await _projectRepository.upsertProject(
      Project(
        id: projectA,
        title: 'Redesain Aplikasi',
        description: 'Perombakan tampilan dan alur utama.',
        role: ProjectRole.owned,
        startDate: weekStart,
        dueDate: weekEnd,
        createdAt: ts,
        updatedAt: ts,
      ),
    );
    await _projectRepository.upsertProject(
      Project(
        id: projectB,
        title: 'Skripsi Bab 3',
        description: 'Metodologi penelitian.',
        role: ProjectRole.owned,
        startDate: weekStart,
        dueDate: weekEnd.add(const Duration(days: 14)),
        createdAt: ts,
        updatedAt: ts,
      ),
    );

    // Tugas level atas: satu punya sub-task.
    final mainTaskId = _uuid.v4();
    await _taskRepository.upsertTask(
      Task(
        id: mainTaskId,
        projectId: projectA,
        title: 'Buat wireframe beranda',
        type: TaskType.task,
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
        dueAt: now,
        createdAt: ts,
        updatedAt: ts,
      ),
    );
    await _taskRepository.upsertTask(
      Task(
        id: _uuid.v4(),
        projectId: projectA,
        parentTaskId: mainTaskId,
        title: 'Rancang header',
        type: TaskType.task,
        dueAt: now,
        createdAt: ts,
        updatedAt: ts,
      ),
    );
    await _taskRepository.upsertTask(
      Task(
        id: _uuid.v4(),
        projectId: projectA,
        parentTaskId: mainTaskId,
        title: 'Rancang kartu statistik',
        type: TaskType.task,
        dueAt: now,
        createdAt: ts,
        updatedAt: ts,
      ),
    );
    await _taskRepository.upsertTask(
      Task(
        id: _uuid.v4(),
        projectId: projectB,
        title: 'Susun daftar pustaka',
        type: TaskType.task,
        dueAt: now,
        createdAt: ts,
        updatedAt: ts,
      ),
    );

    // Acara dan pengingat minggu ini (jadwal).
    await _taskRepository.upsertTask(
      Task(
        id: _uuid.v4(),
        title: 'Meeting mingguan tim',
        type: TaskType.event,
        startAt: weekStart.add(const Duration(hours: 9)),
        endAt: weekStart.add(const Duration(hours: 10)),
        createdAt: ts,
        updatedAt: ts,
      ),
    );
    await _taskRepository.upsertTask(
      Task(
        id: _uuid.v4(),
        title: 'Ambil obat',
        type: TaskType.reminder,
        startAt: weekStart.add(const Duration(hours: 7)),
        createdAt: ts,
        updatedAt: ts,
      ),
    );

    // Milestone.
    await _taskRepository.upsertTask(
      Task(
        id: _uuid.v4(),
        projectId: projectA,
        title: 'Rilis versi 1.0',
        type: TaskType.milestone,
        dueAt: weekEnd,
        createdAt: ts,
        updatedAt: ts,
      ),
    );

    // Notifikasi belum dibaca (badge lonceng).
    await _notificationRepository.upsertNotification(
      AppNotification(
        id: _uuid.v4(),
        type: NotificationType.reminder,
        title: 'Pengingat: Ambil obat',
        body: 'Hari ini 07.00',
        createdAt: ts,
        updatedAt: ts,
      ),
    );
    await _notificationRepository.upsertNotification(
      AppNotification(
        id: _uuid.v4(),
        type: NotificationType.taskAssigned,
        title: 'Tugas baru untukmu',
        body: 'Redesain Aplikasi',
        createdAt: ts,
        updatedAt: ts,
      ),
    );
  }
}
