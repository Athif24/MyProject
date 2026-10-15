import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_daily/core/di/injection.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/core/theme/app_icons.dart';
import 'package:sync_daily/core/theme/app_sizes.dart';
import 'package:sync_daily/core/theme/app_typography.dart';
import 'package:sync_daily/core/utils/id_date.dart';
import 'package:sync_daily/core/widgets/app_chip.dart';
import 'package:sync_daily/core/widgets/app_icon_button.dart';
import 'package:sync_daily/core/widgets/empty_state.dart';
import 'package:sync_daily/core/widgets/latar_layar.dart';
import 'package:sync_daily/features/notes/domain/entities/note.dart';
import 'package:sync_daily/features/notes/domain/entities/note_category.dart';
import 'package:sync_daily/features/notes/domain/repositories/note_repository.dart';
import 'package:sync_daily/features/notes/presentation/cubit/note_detail_cubit.dart';
import 'package:sync_daily/features/notes/presentation/cubit/note_detail_state.dart';
import 'package:sync_daily/features/notes/presentation/theme/note_color_theme.dart';
import 'package:sync_daily/features/notes/presentation/widgets/note_labels.dart';

/// Layar detail catatan: label kategori, judul, tanggal, dan isi penuh, dengan
/// aksi Ubah, Sematkan, dan Hapus.
///
/// TODO(design): layar ini belum didesain. Sementara memakai komponen dan token
/// yang ada sampai desain tersedia.
class NoteDetailPage extends StatelessWidget {
  final String noteId;

  const NoteDetailPage({super.key, required this.noteId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NoteDetailCubit(
        noteId: noteId,
        noteRepository: getIt<NoteRepository>(),
      )..start(),
      child: const _NoteDetailView(),
    );
  }
}

class _NoteDetailView extends StatelessWidget {
  const _NoteDetailView();

  Future<void> _openEdit(BuildContext context) async {
    final cubit = context.read<NoteDetailCubit>();
    final saved = await context.push<bool>('/notes/${cubit.noteId}/edit');
    if (saved == true && context.mounted) {
      await cubit.refresh();
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<NoteDetailCubit>();
    final title = cubit.state.note?.title ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.deleteNoteTitle),
        content: Text(AppStrings.deleteNoteBody(title)),
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
  Future<List<String>?> _delete(NoteDetailCubit cubit) async {
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
          child: BlocBuilder<NoteDetailCubit, NoteDetailState>(
            builder: (context, state) => Column(
              children: [
                _Header(
                  onBack: () =>
                      context.canPop() ? context.pop() : context.go('/notes'),
                  onEdit: state.note == null ? null : () => _openEdit(context),
                  onDelete: state.note == null
                      ? null
                      : () => _confirmDelete(context),
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
  final VoidCallback onBack;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _Header({
    required this.onBack,
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
              AppStrings.noteDetail,
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
  final NoteDetailState state;

  const _Body({required this.state});

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case NoteDetailStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case NoteDetailStatus.error:
        return const _CenteredEmpty(
          title: AppStrings.loadFailedTitle,
          description: AppStrings.loadFailedDescription,
        );
      case NoteDetailStatus.deleting:
        // Keadaan netral: isi yang sudah ada tetap tampil tanpa pesan galat
        // sampai halaman ditutup.
        final note = state.note;
        return note == null
            ? const SizedBox.shrink()
            : _LoadedBody(note: note);
      case NoteDetailStatus.notFound:
        return const _CenteredEmpty(
          title: AppStrings.noteNotFound,
          description: AppStrings.noteNotFoundDescription,
        );
      case NoteDetailStatus.loaded:
        final note = state.note;
        if (note == null) {
          return const SizedBox.shrink();
        }
        return _LoadedBody(note: note);
    }
  }
}

class _LoadedBody extends StatelessWidget {
  final Note note;

  const _LoadedBody({required this.note});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NoteDetailCubit>();
    final palette = context.notePaletteFor(
      noteCategoryFromStorage(note.category),
      note.color,
    );

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
          Row(
            children: [
              Text(
                noteCategoryLabelFromStorage(note.category),
                style: AppTypography.textTheme.labelLarge
                    ?.copyWith(color: palette.icon),
              ),
              const SizedBox(width: AppSizes.cardGap),
              AppChip(
                label: AppStrings.notePin,
                isActive: note.isPinned,
                onTap: cubit.togglePin,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.cardGap),
          Text(
            note.title,
            style: AppTypography.textTheme.headlineLarge,
          ),
          const SizedBox(height: AppSizes.itemSpacing),
          Text(
            IdDate.full(note.updatedAt),
            style: AppTypography.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSizes.sectionGap),
          Text(
            note.content.trim().isEmpty
                ? AppStrings.noNoteContent
                : note.content,
            style: AppTypography.textTheme.bodyLarge,
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
