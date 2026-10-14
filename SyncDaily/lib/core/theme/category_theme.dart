import 'package:flutter/material.dart';
import 'package:sync_daily/core/theme/app_colors.dart';

enum TaskCategory { task, reminder, event, milestone, note, project, deadline }

@immutable
class AppCategoryColors extends ThemeExtension<AppCategoryColors> {
  final Color taskBg;
  final Color taskIcon;
  final Color reminderBg;
  final Color reminderIcon;
  final Color eventBg;
  final Color eventIcon;
  final Color milestoneBg;
  final Color milestoneIcon;
  final Color noteBg;
  final Color noteIcon;
  final Color projectBg;
  final Color projectIcon;
  final Color deadlineBg;
  final Color deadlineIcon;

  const AppCategoryColors({
    required this.taskBg,
    required this.taskIcon,
    required this.reminderBg,
    required this.reminderIcon,
    required this.eventBg,
    required this.eventIcon,
    required this.milestoneBg,
    required this.milestoneIcon,
    required this.noteBg,
    required this.noteIcon,
    required this.projectBg,
    required this.projectIcon,
    required this.deadlineBg,
    required this.deadlineIcon,
  });

  @override
  AppCategoryColors copyWith({
    Color? taskBg,
    Color? taskIcon,
    Color? reminderBg,
    Color? reminderIcon,
    Color? eventBg,
    Color? eventIcon,
    Color? milestoneBg,
    Color? milestoneIcon,
    Color? noteBg,
    Color? noteIcon,
    Color? projectBg,
    Color? projectIcon,
    Color? deadlineBg,
    Color? deadlineIcon,
  }) {
    return AppCategoryColors(
      taskBg: taskBg ?? this.taskBg,
      taskIcon: taskIcon ?? this.taskIcon,
      reminderBg: reminderBg ?? this.reminderBg,
      reminderIcon: reminderIcon ?? this.reminderIcon,
      eventBg: eventBg ?? this.eventBg,
      eventIcon: eventIcon ?? this.eventIcon,
      milestoneBg: milestoneBg ?? this.milestoneBg,
      milestoneIcon: milestoneIcon ?? this.milestoneIcon,
      noteBg: noteBg ?? this.noteBg,
      noteIcon: noteIcon ?? this.noteIcon,
      projectBg: projectBg ?? this.projectBg,
      projectIcon: projectIcon ?? this.projectIcon,
      deadlineBg: deadlineBg ?? this.deadlineBg,
      deadlineIcon: deadlineIcon ?? this.deadlineIcon,
    );
  }

  @override
  AppCategoryColors lerp(ThemeExtension<AppCategoryColors>? other, double t) {
    if (other is! AppCategoryColors) {
      return this;
    }
    return AppCategoryColors(
      taskBg: Color.lerp(taskBg, other.taskBg, t) ?? taskBg,
      taskIcon: Color.lerp(taskIcon, other.taskIcon, t) ?? taskIcon,
      reminderBg: Color.lerp(reminderBg, other.reminderBg, t) ?? reminderBg,
      reminderIcon: Color.lerp(reminderIcon, other.reminderIcon, t) ?? reminderIcon,
      eventBg: Color.lerp(eventBg, other.eventBg, t) ?? eventBg,
      eventIcon: Color.lerp(eventIcon, other.eventIcon, t) ?? eventIcon,
      milestoneBg: Color.lerp(milestoneBg, other.milestoneBg, t) ?? milestoneBg,
      milestoneIcon: Color.lerp(milestoneIcon, other.milestoneIcon, t) ?? milestoneIcon,
      noteBg: Color.lerp(noteBg, other.noteBg, t) ?? noteBg,
      noteIcon: Color.lerp(noteIcon, other.noteIcon, t) ?? noteIcon,
      projectBg: Color.lerp(projectBg, other.projectBg, t) ?? projectBg,
      projectIcon: Color.lerp(projectIcon, other.projectIcon, t) ?? projectIcon,
      deadlineBg: Color.lerp(deadlineBg, other.deadlineBg, t) ?? deadlineBg,
      deadlineIcon: Color.lerp(deadlineIcon, other.deadlineIcon, t) ?? deadlineIcon,
    );
  }

  Color backgroundFor(TaskCategory category) {
    switch (category) {
      case TaskCategory.task:
        return taskBg;
      case TaskCategory.reminder:
        return reminderBg;
      case TaskCategory.event:
        return eventBg;
      case TaskCategory.milestone:
        return milestoneBg;
      case TaskCategory.note:
        return noteBg;
      case TaskCategory.project:
        return projectBg;
      case TaskCategory.deadline:
        return deadlineBg;
    }
  }

  Color iconFor(TaskCategory category) {
    switch (category) {
      case TaskCategory.task:
        return taskIcon;
      case TaskCategory.reminder:
        return reminderIcon;
      case TaskCategory.event:
        return eventIcon;
      case TaskCategory.milestone:
        return milestoneIcon;
      case TaskCategory.note:
        return noteIcon;
      case TaskCategory.project:
        return projectIcon;
      case TaskCategory.deadline:
        return deadlineIcon;
    }
  }

  static const defaultValue = AppCategoryColors(
    taskBg: AppColors.taskBg,
    taskIcon: AppColors.taskIcon,
    reminderBg: AppColors.reminderBg,
    reminderIcon: AppColors.reminderIcon,
    eventBg: AppColors.eventBg,
    eventIcon: AppColors.eventIcon,
    milestoneBg: AppColors.milestoneBg,
    milestoneIcon: AppColors.milestoneIcon,
    noteBg: AppColors.noteBg,
    noteIcon: AppColors.noteIcon,
    projectBg: AppColors.projectBg,
    projectIcon: AppColors.projectIcon,
    deadlineBg: AppColors.deadlineBg,
    deadlineIcon: AppColors.deadlineIcon,
  );
}
