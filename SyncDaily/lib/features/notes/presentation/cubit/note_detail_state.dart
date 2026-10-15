import 'package:equatable/equatable.dart';
import 'package:sync_daily/features/notes/domain/entities/note.dart';

enum NoteDetailStatus {
  loading,
  loaded,

  /// Sedang menghapus catatan. Layar menampilkan keadaan netral sampai halaman
  /// ditutup, supaya baris yang hilang dari aliran data tidak sempat
  /// memunculkan "Catatan tidak ditemukan".
  deleting,

  notFound,
  error,
}

/// Keadaan layar detail catatan.
class NoteDetailState extends Equatable {
  final NoteDetailStatus status;
  final Note? note;
  final String? errorMessage;

  const NoteDetailState({
    this.status = NoteDetailStatus.loading,
    this.note,
    this.errorMessage,
  });

  NoteDetailState copyWith({
    NoteDetailStatus? status,
    Note? note,
    bool clearNote = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NoteDetailState(
      status: status ?? this.status,
      note: clearNote ? null : (note ?? this.note),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, note, errorMessage];
}
