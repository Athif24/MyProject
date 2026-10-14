import 'package:equatable/equatable.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/features/projects/domain/entities/project.dart';
import 'package:sync_daily/features/projects/domain/entities/project_with_counts.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_summary.dart';

enum HomeStatus { loading, loaded, error }

/// Filter periode pada seksi Overview. Hanya memengaruhi kartu Jadwal.
enum PeriodFilter {
  thisWeek(AppStrings.periodThisWeek),
  thisMonth(AppStrings.periodThisMonth),
  all(AppStrings.periodAll);

  const PeriodFilter(this.label);

  final String label;
}

/// Tab pada seksi Projects.
enum ProjectTab {
  mine(AppStrings.projectTabMine),
  received(AppStrings.projectTabReceived);

  const ProjectTab(this.label);

  final String label;
}

class HomeState extends Equatable {
  final HomeStatus status;
  final TaskSummary? summary;
  final List<ProjectWithCounts> projects;
  final int unreadCount;
  final String userName;
  final String greeting;
  final PeriodFilter period;
  final ProjectTab projectTab;
  final String? errorMessage;

  const HomeState({
    this.status = HomeStatus.loading,
    this.summary,
    this.projects = const [],
    this.unreadCount = 0,
    this.userName = AppStrings.defaultUserName,
    this.greeting = AppStrings.greetingMorning,
    this.period = PeriodFilter.thisWeek,
    this.projectTab = ProjectTab.mine,
    this.errorMessage,
  });

  List<ProjectWithCounts> get ownedProjects => projects
      .where((item) => item.project.role != ProjectRole.received)
      .toList();

  List<ProjectWithCounts> get receivedProjects => projects
      .where((item) => item.project.role == ProjectRole.received)
      .toList();

  HomeState copyWith({
    HomeStatus? status,
    TaskSummary? summary,
    List<ProjectWithCounts>? projects,
    int? unreadCount,
    String? userName,
    String? greeting,
    PeriodFilter? period,
    ProjectTab? projectTab,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      projects: projects ?? this.projects,
      unreadCount: unreadCount ?? this.unreadCount,
      userName: userName ?? this.userName,
      greeting: greeting ?? this.greeting,
      period: period ?? this.period,
      projectTab: projectTab ?? this.projectTab,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        summary,
        projects,
        unreadCount,
        userName,
        greeting,
        period,
        projectTab,
        errorMessage,
      ];
}
