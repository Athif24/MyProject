import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_daily/core/di/injection.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/core/theme/app_sizes.dart';
import 'package:sync_daily/core/theme/app_typography.dart';
import 'package:sync_daily/core/widgets/app_icon_button.dart';
import 'package:sync_daily/core/widgets/app_search_field.dart';
import 'package:sync_daily/core/widgets/empty_state.dart';
import 'package:sync_daily/core/widgets/latar_layar.dart';
import 'package:sync_daily/features/notes/domain/entities/note.dart';
import 'package:sync_daily/features/notes/domain/entities/note_category.dart';
import 'package:sync_daily/features/notes/domain/repositories/note_repository.dart';
import 'package:sync_daily/features/notes/presentation/cubit/notes_cubit.dart';
import 'package:sync_daily/features/notes/presentation/cubit/notes_state.dart';
import 'package:sync_daily/features/notes/presentation/widgets/note_card.dart';
import 'package:sync_daily/features/notes/presentation/widgets/note_category_chips.dart';
import 'package:sync_daily/features/notes/presentation/widgets/note_detail_flow.dart';
import 'package:sync_daily/features/notes/presentation/widgets/note_labels.dart';
import 'package:sync_daily/features/notes/presentation/widgets/note_tile.dart';

/// Layar Catatan: judul dan tombol ganti tampilan, kolom cari, chip kategori,
/// lalu grid dua kolom (atau daftar) kartu catatan pastel.
///
/// Penambahan catatan lewat panel "Buat Baru" (tombol + di navigasi bawah),
/// bukan tombol tambah di layar ini.
///
/// TODO(design): rincian layar Catatan (ukuran kartu, jarak, dan gaya label)
/// belum ada; memakai komponen dan token theme sampai desain tersedia.
class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotesCubit(
        noteRepository: getIt<NoteRepository>(),
      )..start(),
      child: const _NotesView(),
    );
  }
}

/// Jarak bawah agar kartu terakhir tidak tertutup bottom nav.
const double _bottomInset = AppSizes.navHeight + AppSizes.sectionGap * 2;

/// Sisa ruang minimal untuk daftar catatan yang bergulir sendiri. Bila ruang di
/// layar lebih kecil dari ini (layar pendek), seluruh halaman bergulir seperti
/// pola Kalender supaya tidak ada isi yang terpotong.
const double _minListHeight = 160;

class _NotesView extends StatelessWidget {
  const _NotesView();

  /// Membuka detail catatan; bila catatan dihapus di sana, kembali ke sini dan
  /// tampilkan snackbar "Urungkan" seperti pola daftar tugas.
  Future<void> _openDetail(BuildContext context, Note note) {
    return openNoteDetailWithUndo(
      context: context,
      noteId: note.id,
      onUndo: context.read<NotesCubit>().restore,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayarLatar(
        child: SafeArea(
          child: BlocBuilder<NotesCubit, NotesState>(
            builder: (context, state) {
              switch (state.status) {
                case NotesStatus.loading:
                  return const Center(child: CircularProgressIndicator());
                case NotesStatus.error:
                  return _ErrorState(
                    onRetry: () => context.read<NotesCubit>().retry(),
                  );
                case NotesStatus.loaded:
                  return _LoadedView(
                    state: state,
                    onQueryChanged: context.read<NotesCubit>().setQuery,
                    onCategoryChanged: context.read<NotesCubit>().setCategory,
                    onToggleView: context.read<NotesCubit>().toggleViewMode,
                    onOpenDetail: (note) => _openDetail(context, note),
                  );
              }
            },
          ),
        ),
      ),
    );
  }
}

/// Isi Catatan yang sudah termuat.
///
/// Judul, tombol ganti tampilan, kolom cari, dan chip kategori tetap di atas;
/// hanya grid/daftar catatan yang bergulir. Bila sisa ruang untuk daftar
/// terlalu kecil (< [_minListHeight]), seluruh halaman bergulir seperti pola
/// Kalender supaya tidak ada isi yang terpotong; peralihan itu hanya dilakukan
/// setelah bagian tetap terukur, jadi frame pertama sudah memakai tata letak
/// yang mengisi penuh.
class _LoadedView extends StatefulWidget {
  final NotesState state;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<NoteCategory?> onCategoryChanged;
  final VoidCallback onToggleView;
  final ValueChanged<Note> onOpenDetail;

  const _LoadedView({
    required this.state,
    required this.onQueryChanged,
    required this.onCategoryChanged,
    required this.onToggleView,
    required this.onOpenDetail,
  });

  @override
  State<_LoadedView> createState() => _LoadedViewState();
}

class _LoadedViewState extends State<_LoadedView> {
  /// Kunci bagian tetap untuk mengukur tingginya.
  final GlobalKey _fixedKey = GlobalKey();

  /// Tinggi bagian tetap hasil pengukuran, null sebelum frame pertama selesai.
  double? _fixedHeight;

  @override
  Widget build(BuildContext context) {
    _measureFixed();

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = _fixedHeight;
        // Sebelum bagian tetap terukur (frame pertama), pakai tata letak yang
        // mengisi penuh. Kalau tidak, frame pertama memakai tata letak yang
        // seluruh halamannya bergulir: latar menyusut (terlihat sebagai kilatan
        // gelap di bawah) dan teks keadaan kosong tampak "terangkat" sebelum
        // kembali ke tengah. Peralihan ke seluruh halaman bergulir hanya
        // dilakukan setelah tinggi terukur dan sisa ruang untuk daftar
        // benar-benar kurang dari [_minListHeight].
        if (height != null &&
            constraints.maxHeight - height - AppSizes.cardGap <
                _minListHeight) {
          return _scrollingLayout();
        }
        return _fixedLayout();
      },
    );
  }

  /// Mengukur tinggi bagian tetap setelah frame selesai.
  void _measureFixed() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final size = _fixedKey.currentContext?.size;
      if (size == null) {
        return;
      }
      final measured = size.height;
      final previous = _fixedHeight;
      if (previous != null && (previous - measured).abs() < 0.5) {
        return;
      }
      setState(() => _fixedHeight = measured);
    });
  }

  /// Bagian tetap: judul, tombol ganti tampilan, kolom cari, dan chip kategori.
  Widget _fixedPart() {
    final isGrid = widget.state.viewMode == NotesViewMode.grid;
    return KeyedSubtree(
      key: _fixedKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.screenNotes,
                  style: AppTypography.textTheme.displayMedium,
                ),
              ),
              AppIconButton(
                icon: noteViewModeIcon(isGrid),
                semanticLabel: noteViewModeLabel(isGrid),
                onTap: widget.onToggleView,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sectionGap),
          AppSearchField(
            hintText: AppStrings.noteSearchHint,
            onChanged: widget.onQueryChanged,
          ),
          const SizedBox(height: AppSizes.sectionGap),
          NoteCategoryChips(
            value: widget.state.category,
            nullLabel: AppStrings.noteCategoryAll,
            onChanged: widget.onCategoryChanged,
          ),
        ],
      ),
    );
  }

  /// Keadaan kosong: "belum ada catatan" atau "tidak ada yang cocok" bila ada
  /// filter/pencarian aktif.
  Widget _emptyState() {
    final filtered = widget.state.hasFilter;
    return EmptyState(
      title: filtered ? AppStrings.noNotesMatch : AppStrings.noNotes,
      description: filtered
          ? AppStrings.noNotesMatchDescription
          : AppStrings.noNotesDescription,
    );
  }

  /// Grid dua kolom atau daftar, tanpa gulir sendiri (pembungkusnya yang
  /// bergulir).
  Widget _list() {
    final notes = widget.state.visibleNotes;
    if (widget.state.viewMode == NotesViewMode.grid) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSizes.itemSpacing,
          mainAxisSpacing: AppSizes.itemSpacing,
          mainAxisExtent: AppSizes.noteCardHeight,
        ),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return NoteCard(
            note: note,
            today: widget.state.today,
            onTap: () => widget.onOpenDetail(note),
          );
        },
      );
    }
    return Column(
      children: [
        for (final note in notes) ...[
          NoteTile(
            note: note,
            today: widget.state.today,
            onTap: () => widget.onOpenDetail(note),
          ),
          if (note != notes.last) const SizedBox(height: AppSizes.itemSpacing),
        ],
      ],
    );
  }

  /// Bagian tetap di atas, grid/daftar bergulir sendiri di bawahnya.
  Widget _fixedLayout() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            AppSizes.cardGap,
            AppSizes.pagePadding,
            0,
          ),
          child: _fixedPart(),
        ),
        Expanded(
          child: widget.state.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppSizes.pagePadding),
                  child: Center(child: _emptyState()),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.pagePadding,
                    AppSizes.cardGap,
                    AppSizes.pagePadding,
                    _bottomInset,
                  ),
                  child: _list(),
                ),
        ),
      ],
    );
  }

  /// Layar pendek: seluruh halaman bergulir.
  Widget _scrollingLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pagePadding,
        AppSizes.cardGap,
        AppSizes.pagePadding,
        _bottomInset,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fixedPart(),
          const SizedBox(height: AppSizes.cardGap),
          if (widget.state.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.sectionGap),
              child: _emptyState(),
            )
          else
            _list(),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        child: EmptyState(
          title: AppStrings.loadFailedTitle,
          description: AppStrings.loadFailedDescription,
          action: FilledButton(
            onPressed: onRetry,
            child: Text(
              AppStrings.retry,
              style: AppTypography.textTheme.labelLarge,
            ),
          ),
        ),
      ),
    );
  }
}
