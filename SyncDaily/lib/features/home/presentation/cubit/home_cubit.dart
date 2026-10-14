import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_daily/core/utils/greeting.dart';
import 'package:sync_daily/features/auth/domain/entities/user_profile.dart';
import 'package:sync_daily/features/auth/domain/repositories/user_profile_repository.dart';
import 'package:sync_daily/features/home/presentation/cubit/home_state.dart';
import 'package:sync_daily/features/notifications/domain/repositories/notification_repository.dart';
import 'package:sync_daily/features/projects/domain/entities/project_with_counts.dart';
import 'package:sync_daily/features/projects/domain/repositories/project_repository.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_summary.dart';
import 'package:sync_daily/features/tasks/domain/repositories/task_repository.dart';
import 'package:sync_daily/features/tasks/domain/task_date_utils.dart';

/// Cubit Beranda: berlangganan ringkasan tugas, daftar proyek, jumlah
/// notifikasi belum dibaca, dan nama pengguna.
class HomeCubit extends Cubit<HomeState> {
  final TaskRepository _taskRepository;
  final ProjectRepository _projectRepository;
  final NotificationRepository _notificationRepository;
  final UserProfileRepository _userProfileRepository;

  /// Sumber waktu; bisa diganti pada pengujian.
  final DateTime Function() _now;

  StreamSubscription<TaskSummary>? _summarySub;
  StreamSubscription<List<ProjectWithCounts>>? _projectsSub;
  StreamSubscription<int>? _unreadSub;
  StreamSubscription<UserProfile>? _profileSub;

  bool _gotSummary = false;
  bool _gotProjects = false;
  bool _hasError = false;

  HomeCubit({
    required TaskRepository taskRepository,
    required ProjectRepository projectRepository,
    required NotificationRepository notificationRepository,
    required UserProfileRepository userProfileRepository,
    DateTime Function() now = DateTime.now,
  })  : _taskRepository = taskRepository,
        _projectRepository = projectRepository,
        _notificationRepository = notificationRepository,
        _userProfileRepository = userProfileRepository,
        _now = now,
        super(const HomeState());

  void start() {
    // Batalkan langganan lama lebih dulu supaya pemanggilan ulang (mis. dari
    // [retry]) tidak meninggalkan listener ganda.
    unawaited(_cancelAll());
    emit(state.copyWith(greeting: Greeting.forTime(_now())));
    _profileSub = _userProfileRepository.watchProfile().listen(
          (profile) => emit(state.copyWith(userName: profile.name)),
          onError: _onError,
        );
    _unreadSub = _notificationRepository.watchUnreadCount().listen(
          (count) => emit(state.copyWith(unreadCount: count)),
          onError: _onError,
        );
    _projectsSub = _projectRepository.watchProjectsWithCounts().listen(
          (projects) {
            _gotProjects = true;
            emit(state.copyWith(projects: projects, status: _readyStatus()));
          },
          onError: _onError,
        );
    _listenSummary();
  }

  void setPeriod(PeriodFilter period) {
    if (period == state.period) {
      return;
    }
    emit(state.copyWith(period: period));
    _listenSummary();
  }

  void setProjectTab(ProjectTab tab) {
    if (tab == state.projectTab) {
      return;
    }
    emit(state.copyWith(projectTab: tab));
  }

  Future<void> deleteProject(String id) => _projectRepository.softDeleteProject(id);

  /// Memulai ulang langganan setelah keadaan error.
  void retry() {
    _hasError = false;
    _gotSummary = false;
    _gotProjects = false;
    emit(state.copyWith(status: HomeStatus.loading, errorMessage: null));
    start();
  }

  void _listenSummary() {
    final now = _now();
    final range = _range(state.period, now);
    unawaited(_summarySub?.cancel());
    _summarySub = _taskRepository
        .watchSummary(
          periodStart: range?.start,
          periodEnd: range?.end,
          today: now,
        )
        .listen(
          (summary) {
            _gotSummary = true;
            emit(state.copyWith(summary: summary, status: _readyStatus()));
          },
          onError: _onError,
        );
  }

  ({DateTime start, DateTime end})? _range(PeriodFilter period, DateTime now) {
    switch (period) {
      case PeriodFilter.thisWeek:
        return TaskDateUtils.weekRange(now);
      case PeriodFilter.thisMonth:
        return TaskDateUtils.monthRange(now);
      case PeriodFilter.all:
        return null;
    }
  }

  HomeStatus _readyStatus() {
    if (_hasError) {
      return HomeStatus.error;
    }
    return (_gotSummary && _gotProjects)
        ? HomeStatus.loaded
        : HomeStatus.loading;
  }

  void _onError(Object error, StackTrace stackTrace) {
    _hasError = true;
    emit(
      state.copyWith(
        status: HomeStatus.error,
        errorMessage: error.toString(),
      ),
    );
  }

  /// Membatalkan seluruh langganan yang sedang berjalan lalu mengosongkan
  /// rujukannya, supaya [start] ulang tidak membuat listener ganda.
  Future<void> _cancelAll() async {
    final subscriptions = [
      _profileSub,
      _unreadSub,
      _projectsSub,
      _summarySub,
    ].whereType<StreamSubscription<dynamic>>().toList();
    _profileSub = null;
    _unreadSub = null;
    _projectsSub = null;
    _summarySub = null;
    await Future.wait(subscriptions.map((sub) => sub.cancel()));
  }

  @override
  Future<void> close() async {
    await _cancelAll();
    return super.close();
  }
}
