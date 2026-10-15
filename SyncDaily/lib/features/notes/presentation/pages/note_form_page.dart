import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_daily/core/di/injection.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/core/theme/app_colors.dart';
import 'package:sync_daily/core/theme/app_icons.dart';
import 'package:sync_daily/core/theme/app_radius.dart';
import 'package:sync_daily/core/theme/app_sizes.dart';
import 'package:sync_daily/core/theme/app_typography.dart';
import 'package:sync_daily/core/widgets/app_icon_button.dart';
import 'package:sync_daily/core/widgets/latar_layar.dart';
import 'package:sync_daily/features/notes/domain/repositories/note_repository.dart';
import 'package:sync_daily/features/notes/presentation/cubit/note_form_cubit.dart';
import 'package:sync_daily/features/notes/presentation/cubit/note_form_state.dart';
import 'package:sync_daily/features/notes/presentation/widgets/note_category_chips.dart';

/// Form buat/ubah catatan: Judul, Isi, Kategori, dan Sematkan.
///
/// Tanpa penyuntingan otomatis: kolom tidak menerima fokus saat layar dibuka
/// sehingga keyboard tidak langsung muncul. Warna catatan tidak dipilih
/// manual, melainkan mengikuti kategori (lihat `note_color_theme.dart`).
///
/// TODO(design): layar ini belum didesain (lihat docs/DESIGN.md bagian "Layar
/// yang BELUM didesain"). Sementara memakai komponen dan token yang ada.
class NoteFormPage extends StatelessWidget {
  final String? noteId;

  const NoteFormPage({super.key, this.noteId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NoteFormCubit(
        noteRepository: getIt<NoteRepository>(),
      )..init(noteId: noteId),
      child: _NoteFormView(noteId: noteId),
    );
  }
}

class _NoteFormView extends StatelessWidget {
  final String? noteId;

  const _NoteFormView({this.noteId});

  @override
  Widget build(BuildContext context) {
    return BlocListener<NoteFormCubit, NoteFormState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == NoteFormStatus.saved) {
          context.pop(true);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: LayarLatar(
          child: SafeArea(
            child: Column(
              children: [
                _FormHeader(noteId: noteId),
                Expanded(
                  child: BlocBuilder<NoteFormCubit, NoteFormState>(
                    builder: (context, state) => _FormBody(state: state),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FormHeader extends StatelessWidget {
  final String? noteId;

  const _FormHeader({this.noteId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NoteFormCubit, NoteFormState>(
      builder: (context, state) {
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
                onTap: () => context.canPop()
                    ? context.pop()
                    : context.go('/notes'),
              ),
              const SizedBox(width: AppSizes.cardGap),
              Expanded(
                child: Text(
                  state.isEditing ? AppStrings.noteEdit : AppStrings.noteNew,
                  style: AppTypography.textTheme.headlineMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () =>
                    context.read<NoteFormCubit>().save(editingNoteId: noteId),
                child: Text(
                  AppStrings.save,
                  style: AppTypography.textTheme.labelLarge?.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FormBody extends StatefulWidget {
  final NoteFormState state;

  const _FormBody({required this.state});

  @override
  State<_FormBody> createState() => _FormBodyState();
}

class _FormBodyState extends State<_FormBody> {
  late final TextEditingController _title;
  late final TextEditingController _content;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.state.title);
    _content = TextEditingController(text: widget.state.content);
  }

  @override
  void didUpdateWidget(covariant _FormBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sinkronkan saat data dimuat dari repository (mode ubah).
    if (widget.state.title != _title.text &&
        oldWidget.state.title != widget.state.title) {
      _title.text = widget.state.title;
    }
    if (widget.state.content != _content.text &&
        oldWidget.state.content != widget.state.content) {
      _content.text = widget.state.content;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  NoteFormCubit get _cubit => context.read<NoteFormCubit>();

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
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
          _TextField(
            controller: _title,
            label: AppStrings.title,
            onChanged: _cubit.setTitle,
          ),
          const SizedBox(height: AppSizes.cardGap),
          _TextField(
            controller: _content,
            label: AppStrings.noteContentLabel,
            onChanged: _cubit.setContent,
            maxLines: 6,
          ),
          const SizedBox(height: AppSizes.sectionGap),
          const _FieldLabel(AppStrings.noteCategoryLabel),
          const SizedBox(height: AppSizes.itemSpacing),
          NoteCategoryChips(
            value: state.category,
            nullLabel: AppStrings.noteCategoryNone,
            onChanged: _cubit.setCategory,
          ),
          const SizedBox(height: AppSizes.sectionGap),
          Semantics(
            label: AppStrings.notePin,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.notePin,
                    style: AppTypography.textTheme.titleSmall,
                  ),
                ),
                Switch(
                  value: state.isPinned,
                  onChanged: _cubit.setIsPinned,
                ),
              ],
            ),
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: AppSizes.cardGap),
            Text(
              state.errorMessage!,
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: AppColors.deadlineIcon,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Judul seksi form (kapital di awal tiap kata, sesuai EYD).
class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTypography.textTheme.labelSmall,
      );
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;
  final int maxLines;

  const _TextField({
    required this.controller,
    required this.label,
    required this.onChanged,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.searchField),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        maxLines: maxLines,
        style: AppTypography.textTheme.bodyLarge,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTypography.textTheme.bodyMedium,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
