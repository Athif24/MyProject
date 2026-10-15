import 'package:equatable/equatable.dart';
import 'package:sync_daily/features/notes/domain/entities/note.dart';
import 'package:sync_daily/features/notes/domain/entities/note_category.dart';

enum NotesStatus { loading, loaded, error }

/// Mode tampilan daftar catatan: grid dua kolom (bawaan) atau daftar.
enum NotesViewMode { grid, list }

/// Keadaan layar Catatan.
class NotesState extends Equatable {
  final NotesStatus status;

  /// Semua catatan dari repository (belum disaring).
  final List<Note> allNotes;

  /// Catatan yang lolos filter kategori dan pencarian, sudah diurutkan
  /// (disematkan lebih dulu, lalu yang terbaru).
  final List<Note> visibleNotes;

  final String query;

  /// Kategori terpilih; `null` berarti "Semua".
  final NoteCategory? category;

  final NotesViewMode viewMode;

  /// Tanggal hari ini (tanpa jam) dari jam yang diinjeksi, dipakai untuk label
  /// tanggal kartu ("Hari ini" / "Kemarin").
  final DateTime today;

  final String? errorMessage;

  const NotesState({
    this.status = NotesStatus.loading,
    this.allNotes = const [],
    this.visibleNotes = const [],
    this.query = '',
    this.category,
    this.viewMode = NotesViewMode.grid,
    required this.today,
    this.errorMessage,
  });

  bool get isEmpty => visibleNotes.isEmpty;

  /// True bila ada kata kunci atau kategori aktif sehingga keadaan kosong
  /// berarti "tidak cocok", bukan "belum ada catatan".
  bool get hasFilter => query.trim().isNotEmpty || category != null;

  NotesState copyWith({
    NotesStatus? status,
    List<Note>? allNotes,
    List<Note>? visibleNotes,
    String? query,
    NoteCategory? category,
    bool clearCategory = false,
    NotesViewMode? viewMode,
    DateTime? today,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotesState(
      status: status ?? this.status,
      allNotes: allNotes ?? this.allNotes,
      visibleNotes: visibleNotes ?? this.visibleNotes,
      query: query ?? this.query,
      category: clearCategory ? null : (category ?? this.category),
      viewMode: viewMode ?? this.viewMode,
      today: today ?? this.today,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        allNotes,
        visibleNotes,
        query,
        category,
        viewMode,
        today,
        errorMessage,
      ];
}
