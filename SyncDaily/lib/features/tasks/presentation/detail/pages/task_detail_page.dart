import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_daily/core/di/injection.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/core/theme/app_icons.dart';
import 'package:sync_daily/core/theme/app_sizes.dart';
import 'package:sync_daily/core/theme/app_typography.dart';
import 'package:sync_daily/core/theme/app_theme.dart';
import 'package:sync_daily/core/widgets/app_icon_button.dart';
import 'package:sync_daily/core/widgets/empty_state.dart';
import 'package:sync_daily/core/widgets/latar_layar.dart';
import 'package:sync_daily/core/widgets/section_header.dart';
import 'package:sync_daily/features/projects/domain/repositories/project_repository.dart';
import 'package:sync_daily/features/tasks/domain/entities/task.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';
import 'package:sync_daily/features/tasks/domain/repositories/task_repository.dart';
import 'package:sync_daily/features/tasks/presentation/detail/cubit/task_detail_cubit.dart';
import 'package:sync_daily/features/tasks/presentation/detail/cubit/task_detail_state.dart';
import 'package:sync_daily/features/tasks/presentation/form/pages/task_form_page.dart';
import 'package:sync_daily/features/tasks/presentation/widgets/task_date_label.dart';
import 'package:sync_daily/features/tasks/presentation/widgets/task_labels.dart';

/// Layar detail tugas (F4b).
///
/// TODO(design): layar ini belum didesain. Memakai komponen dan token yang ada
/// sampai desain tersedia.
class TaskDetailPage extends StatelessWidget {
  final String taskId;

  const TaskDetailPage({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TaskDetailCubit(
        taskId: taskId,
        taskRepository: getIt<TaskRepository>(),
        projectRepository: getIt<ProjectRepository>(),
      )..start(),
      child: const _TaskDetailView(),
    );
  }
}

class _TaskDetailView extends StatelessWidget {
  const _TaskDetailView();

  Future<void> _openEdit(BuildContext context) async {
    final cubit = context.read<TaskDetailCubit>();
    final saved = await context.push<bool>('/tasks/${cubit.taskId}/edit');
    if (saved == true && context.mounted) {
      await cubit.refresh();
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<TaskDetailCubit>();
    final title = cubit.state.task?.title ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.deleteTaskTitle),
        content: Text(AppStrings.deleteTaskBody(title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final deletedIds = await _delete(cubit);
    if (deletedIds == null || !context.mounted) {
      return;
    }
    // Kembali segera setelah penghapusan selesai; tidak menunggu emisi aliran
    // data.
    context.pop(deletedIds);
  }

  /// Menghapus lewat cubit. Mengembalikan id yang terhapus, atau null bila
  /// penghapusan gagal (keadaan galat sudah ditampilkan cubit).
  Future<List<String>?> _delete(TaskDetailCubit cubit) async {
    try {
      return await cubit.delete();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayarLatar(
        child: SafeArea(
          child: BlocBuilder<TaskDetailCubit, TaskDetailState>(
            builder: (context, state) => Column(
              children: [
                _Header(
                  title: state.task == null
                      ? null
                      : taskDetailTitleFor(state.task!.type),
                  onBack: () =>
                      context.canPop() ? context.pop() : context.go('/home'),
                  onEdit: state.task == null ? null : () => _openEdit(context),
                  onDelete:
                      state.task == null ? null : () => _confirmDelete(context),
                ),
                Expanded(child: _Body(state: state)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String? title;
  final VoidCallback onBack;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _Header({
    required this.onBack,
    this.title,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pagePadding,
        AppSizes.cardGap,
        AppSizes.pagePadding,
        AppSizes.cardGap,
      ),
      child: Row(
        children: [
          AppIconButton(
            icon: AppIcons.back,
            semanticLabel: AppStrings.back,
            onTap: onBack,
          ),
          const SizedBox(width: AppSizes.cardGap),
          Expanded(
            child: Text(
              title ?? '',
              style: AppTypography.textTheme.headlineMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onEdit != null)
            AppIconButton(
              icon: AppIcons.edit,
              semanticLabel: AppStrings.edit,
              onTap: onEdit,
            ),
          if (onDelete != null) ...[
            const SizedBox(width: AppSizes.itemSpacing),
            AppIconButton(
              icon: AppIcons.delete,
              semanticLabel: AppStrings.delete,
              onTap: onDelete,
            ),
          ],
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final TaskDetailState state;

  const _Body({required this.state});

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case TaskDetailStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case TaskDetailStatus.error:
        return const _CenteredEmpty(
          title: AppStrings.loadFailedTitle,
          description: AppStrings.loadFailedDescription,
        );
      case TaskDetailStatus.deleting:
        // Keadaan netral: isi yang sudah ada tetap tampil tanpa pesan galat
        // sampai halaman ditutup.
        final task = state.task;
        return task == null
            ? const SizedBox.shrink()
            : _LoadedBody(state: state, task: task);
      case TaskDetailStatus.notFound:
        return const _CenteredEmpty(
          title: AppStrings.taskNotFound,
          description: AppStrings.taskNotFoundDescription,
        );
      case TaskDetailStatus.loaded:
        final task = state.task;
        if (task == null) {
          return const SizedBox.shrink();
        }
        return _LoadedBody(state: state, task: task);
    }
  }
}

class _LoadedBody extends StatelessWidget {
  final TaskDetailState state;
  final Task task;

  const _LoadedBody({required this.state, required this.task});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TaskDetailCubit>();
    final colors = context.categoryColors;
    final iconColor = colors.iconFor(taskCategoryFor(task.type));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pagePadding,
        0,
        AppSizes.pagePadding,
        AppSizes.sectionGap * 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul + kontrol status.
          Semantics(
            label: state.isDone ? AppStrings.markUndone : AppStrings.markDone,
            checked: state.isDone,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: state.isDone,
                  onChanged: (_) => cubit.toggleStatus(),
                ),
                const SizedBox(width: AppSizes.itemSpacing),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      task.title,
                      style: AppTypography.textTheme.headlineLarge?.copyWith(
                        decoration: state.isDone
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.cardGap),
          Row(
            children: [
              Icon(taskIconFor(task.type), size: AppSizes.iconSmall, color: iconColor),
              const SizedBox(width: AppSizes.itemSpacing),
              Text(typeLabel(task.type), style: AppTypography.textTheme.labelLarge),
              const SizedBox(width: AppSizes.itemSpacing),
              Text('·', style: AppTypography.textTheme.bodySmall),
              const SizedBox(width: AppSizes.itemSpacing),
              Text(statusLabel(task.status), style: AppTypography.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: AppSizes.sectionGap),
          _InfoRow(label: AppStrings.description, value: task.description ?? AppStrings.noDescription),
          _InfoRow(label: AppStrings.priority, value: priorityLabel(task.priority)),
          _InfoRow(label: AppStrings.project, value: state.projectTitle ?? AppStrings.noProject),
          if (task.isAllDay)
            const _InfoRow(label: AppStrings.allDay, value: AppStrings.yes),
          if (task.startAt != null)
            _InfoRow(
              label: AppStrings.startAt,
              value: taskFieldDateTime(task.startAt, isAllDay: task.isAllDay),
            ),
          if (task.endAt != null)
            _InfoRow(
              label: AppStrings.endAt,
              value: taskFieldDateTime(task.endAt, isAllDay: task.isAllDay),
            ),
          if (task.dueAt != null)
            _InfoRow(
              label: task.type == TaskType.milestone
                  ? AppStrings.dueTarget
                  : AppStrings.dueDate,
              value: taskFieldDateTime(task.dueAt, isAllDay: task.isAllDay),
            ),
          _InfoRow(
            label: AppStrings.recurrence,
            value: state.recurrence == null
                ? AppStrings.noRecurrence
                : recurrenceFrequencyLabel(state.recurrence!.frequency),
          ),
          _InfoRow(
            label: AppStrings.reminderLabel,
            value: state.reminders.isEmpty
                ? AppStrings.noReminder
                : state.reminders
                    .map((r) => reminderOffsetLabel(r.offsetMinutes))
                    .join(', '),
          ),
          if (task.type == TaskType.task) ...[
            const SizedBox(height: AppSizes.sectionGap),
            const SectionHeader(title: AppStrings.subtask),
            const SizedBox(height: AppSizes.cardGap),
            if (state.subtasks.isEmpty)
              Text(AppStrings.noSubtasks, style: AppTypography.textTheme.bodyMedium)
            else
              for (final subtask in state.subtasks)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: subtask.status == TaskStatus.done,
                  onChanged: (_) => cubit.toggleSubtask(subtask.id),
                  title: Text(
                    subtask.title,
                    style: AppTypography.textTheme.bodyLarge,
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.cardGap),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label.toUpperCase(),
              style: AppTypography.textTheme.labelSmall,
            ),
          ),
          const SizedBox(width: AppSizes.itemSpacing),
          Expanded(
            child: Text(value, style: AppTypography.textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

class _CenteredEmpty extends StatelessWidget {
  final String title;
  final String? description;

  const _CenteredEmpty({required this.title, this.description});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        child: EmptyState(title: title, description: description),
      ),
    );
  }
}
