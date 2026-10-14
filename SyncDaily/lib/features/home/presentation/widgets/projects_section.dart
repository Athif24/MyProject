import 'package:flutter/material.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/core/theme/app_sizes.dart';
import 'package:sync_daily/core/widgets/app_chip.dart';
import 'package:sync_daily/core/widgets/empty_state.dart';
import 'package:sync_daily/core/widgets/section_header.dart';
import 'package:sync_daily/features/home/presentation/cubit/home_state.dart';
import 'package:sync_daily/features/home/presentation/widgets/home_filter_dropdown.dart';
import 'package:sync_daily/features/home/presentation/widgets/project_card.dart';
import 'package:sync_daily/features/projects/domain/entities/project_with_counts.dart';
import 'package:sync_daily/features/tasks/domain/task_date_utils.dart';

/// Seksi "Projects" pada Beranda: judul + filter waktu, tab Proyek saya /
/// Diterima, dan daftar kartu proyek.
class ProjectsSection extends StatefulWidget {
  final List<ProjectWithCounts> owned;
  final List<ProjectWithCounts> received;
  final ProjectTab projectTab;
  final ValueChanged<ProjectTab> onTabChanged;
  final ValueChanged<ProjectWithCounts> onEdit;
  final ValueChanged<ProjectWithCounts> onDelete;

  const ProjectsSection({
    super.key,
    required this.owned,
    required this.received,
    required this.projectTab,
    required this.onTabChanged,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<ProjectsSection> createState() => _ProjectsSectionState();
}

class _ProjectsSectionState extends State<ProjectsSection> {
  PeriodFilter _period = PeriodFilter.all;

  List<ProjectWithCounts> get _base =>
      widget.projectTab == ProjectTab.mine ? widget.owned : widget.received;

  List<ProjectWithCounts> get _filtered {
    if (_period == PeriodFilter.all) {
      return _base;
    }
    final now = DateTime.now();
    final range = _period == PeriodFilter.thisWeek
        ? TaskDateUtils.weekRange(now)
        : TaskDateUtils.monthRange(now);
    return _base.where((item) {
      final date = item.project.dueDate ?? item.project.startDate;
      if (date == null) {
        return false;
      }
      final local = date.toLocal();
      return !local.isBefore(range.start) && !local.isAfter(range.end);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: AppStrings.projects,
          trailing: HomeFilterDropdown<PeriodFilter>(
            semanticLabel: AppStrings.filterProjectTime,
            options: PeriodFilter.values,
            value: _period,
            labelOf: (value) => value.label,
            onChanged: (value) => setState(() => _period = value),
          ),
        ),
        const SizedBox(height: AppSizes.cardGap),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              AppChip(
                label: AppStrings.tabWithCount(
                  ProjectTab.mine.label,
                  widget.owned.length,
                ),
                isActive: widget.projectTab == ProjectTab.mine,
                onTap: () => widget.onTabChanged(ProjectTab.mine),
              ),
              const SizedBox(width: AppSizes.itemSpacing),
              AppChip(
                label: AppStrings.tabWithCount(
                  ProjectTab.received.label,
                  widget.received.length,
                ),
                isActive: widget.projectTab == ProjectTab.received,
                onTap: () => widget.onTabChanged(ProjectTab.received),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.cardGap),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: EmptyState(
              title: widget.projectTab == ProjectTab.mine
                  ? AppStrings.noProjects
                  : AppStrings.noReceivedProjects,
              description: widget.projectTab == ProjectTab.mine
                  ? AppStrings.noProjectsDescription
                  : AppStrings.noReceivedProjectsDescription,
            ),
          )
        else
          for (var i = 0; i < filtered.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSizes.itemSpacing),
            ProjectCard(
              item: filtered[i],
              onEdit: () => widget.onEdit(filtered[i]),
              onDelete: () => widget.onDelete(filtered[i]),
            ),
          ],
      ],
    );
  }
}
