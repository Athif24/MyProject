import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_daily/core/router/app_shell.dart';
import 'package:sync_daily/features/calendar/presentation/pages/calendar_page.dart';
import 'package:sync_daily/features/chat/presentation/pages/chat_page.dart';
import 'package:sync_daily/features/debug/presentation/pages/component_gallery_page.dart';
import 'package:sync_daily/features/home/presentation/pages/home_page.dart';
import 'package:sync_daily/features/notes/presentation/pages/notes_page.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';
import 'package:sync_daily/features/tasks/domain/task_list_filter.dart';
import 'package:sync_daily/features/tasks/presentation/detail/pages/task_detail_page.dart';
import 'package:sync_daily/features/tasks/presentation/form/pages/task_form_page.dart';
import 'package:sync_daily/features/tasks/presentation/list/pages/task_list_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return AppShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomePage(),
            ),
          ),
          GoRoute(
            path: '/chat',
            name: 'chat',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ChatPage(),
            ),
          ),
          GoRoute(
            path: '/notes',
            name: 'notes',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NotesPage(),
            ),
          ),
          GoRoute(
            path: '/calendar',
            name: 'calendar',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CalendarPage(),
            ),
          ),
        ],
      ),
      if (kDebugMode)
        GoRoute(
          path: '/debug/components',
          name: 'debug-components',
          builder: (context, state) => const ComponentGalleryPage(),
        ),
      GoRoute(
        path: '/tasks',
        name: 'task-list',
        builder: (context, state) => TaskListPage(
          filter: _parseFilter(state.uri.queryParameters['filter']),
        ),
      ),
      // Harus sebelum `/tasks/:id` agar "new" tidak dibaca sebagai id.
      GoRoute(
        path: '/tasks/new',
        name: 'task-new',
        builder: (context, state) {
          final type = state.uri.queryParameters['type'];
          return TaskFormPage(
            initialType: _parseType(type),
            initialDate: _parseDate(state.uri.queryParameters['date']),
          );
        },
      ),
      GoRoute(
        path: '/tasks/:id',
        name: 'task-detail',
        builder: (context, state) => TaskDetailPage(
          taskId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/tasks/:id/edit',
        name: 'task-edit',
        builder: (context, state) => TaskFormPage(
          taskId: state.pathParameters['id'],
        ),
      ),
    ],
  );
}

TaskListFilter _parseFilter(String? value) {
  switch (value) {
    case 'all':
      return TaskListFilter.allTasks;
    default:
      return TaskListFilter.today;
  }
}

/// Membaca parameter `?date=` (format ISO `YYYY-MM-DD`, waktu lokal) untuk
/// mengisi tanggal awal form. Nilai yang tidak sah diabaikan.
DateTime? _parseDate(String? value) {
  if (value == null) {
    return null;
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return null;
  }
  return DateTime(parsed.year, parsed.month, parsed.day);
}

TaskType _parseType(String? value) {
  switch (value) {
    case 'event':
      return TaskType.event;
    case 'reminder':
      return TaskType.reminder;
    case 'milestone':
      return TaskType.milestone;
    default:
      return TaskType.task;
  }
}
