import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/features/notes/domain/entities/note.dart';
import 'package:sync_daily/features/notes/domain/entities/note_category.dart';
import 'package:sync_daily/features/notes/domain/repositories/note_repository.dart';
import 'package:sync_daily/features/notes/presentation/cubit/note_form_state.dart';
import 'package:uuid/uuid.dart';

/// Cubit form buat/ubah catatan. SEMUA input dan validasi ada di sini; widget
/// hanya menampilkan state dan mengirim event.
class NoteFormCubit extends Cubit<NoteFormState> {
  final NoteRepository _noteRepository;

  /// Sumber waktu; bisa diganti pada pengujian.
  final DateTime Function() _now;
  final String Function() _newId;

  /// Catatan yang sedang diubah (mode ubah), dipakai agar `createdAt`,
  /// `remoteId`, dan `deletedAt` tidak tertimpa.
  Note? _existing;

  NoteFormCubit({
    required NoteRepository noteRepository,
    DateTime Function()? now,
    String Function()? newId,
  })  : _noteRepository = noteRepository,
        _now = now ?? DateTime.now,
        _newId = newId ?? const Uuid().v4,
        super(const NoteFormState());

  /// [noteId] null berarti membuat catatan baru.
  Future<void> init({String? noteId}) async {
    if (noteId == null) {
      return;
    }
    final note = await _noteRepository.getNote(noteId);
    if (note == null) {
      emit(state.copyWith(
        status: NoteFormStatus.error,
        errorMessage: AppStrings.loadFailedTitle,
      ));
      return;
    }
    _existing = note;
    emit(state.copyWith(
      status: NoteFormStatus.idle,
      isEditing: true,
      title: note.title,
      content: note.content,
      category: noteCategoryFromStorage(note.category),
      clearCategory: noteCategoryFromStorage(note.category) == null,
      isPinned: note.isPinned,
      clearError: true,
    ));
  }

  void setTitle(String value) => emit(state.copyWith(title: value));

  void setContent(String value) => emit(state.copyWith(content: value));

  /// Mengubah kategori; `null` berarti tanpa kategori.
  void setCategory(NoteCategory? value) => emit(value == null
      ? state.copyWith(clearCategory: true)
      : state.copyWith(category: value));

  void setIsPinned(bool value) => emit(state.copyWith(isPinned: value));

  /// Menyimpan. [editingNoteId] null berarti membuat catatan baru.
  Future<void> save({String? editingNoteId}) async {
    if (state.title.trim().isEmpty) {
      emit(state.copyWith(errorMessage: AppStrings.noteTitleRequired));
      return;
    }

    emit(state.copyWith(status: NoteFormStatus.saving, clearError: true));

    final now = _now().toUtc();
    final existing = _existing;

    final note = Note(
      id: editingNoteId ?? _newId(),
      title: state.title.trim(),
      content: state.content.trim(),
      category: state.category?.name,
      // Warna hanya ditentukan kategori (lihat pemetaan di note_category.dart).
      color: noteColorForCategory(state.category),
      isPinned: state.isPinned,
      remoteId: existing?.remoteId,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      deletedAt: existing?.deletedAt,
    );

    try {
      await _noteRepository.upsertNote(note);
      emit(state.copyWith(status: NoteFormStatus.saved, clearError: true));
    } catch (error) {
      emit(state.copyWith(
        status: NoteFormStatus.error,
        errorMessage: '$error',
      ));
    }
  }
}
