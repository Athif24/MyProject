import 'package:equatable/equatable.dart';
import 'package:sync_daily/features/notes/domain/entities/note_category.dart';

enum NoteFormStatus { idle, saving, saved, error }

/// Keadaan form buat/ubah catatan.
class NoteFormState extends Equatable {
  final NoteFormStatus status;
  final bool isEditing;
  final String title;
  final String content;

  /// Kategori terpilih; warnanya mengikuti kategori ini.
  final NoteCategory? category;

  final bool isPinned;
  final String? errorMessage;

  const NoteFormState({
    this.status = NoteFormStatus.idle,
    this.isEditing = false,
    this.title = '',
    this.content = '',
    this.category,
    this.isPinned = false,
    this.errorMessage,
  });

  bool get canSave => title.trim().isNotEmpty;

  NoteFormState copyWith({
    NoteFormStatus? status,
    bool? isEditing,
    String? title,
    String? content,
    NoteCategory? category,
    bool clearCategory = false,
    bool? isPinned,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NoteFormState(
      status: status ?? this.status,
      isEditing: isEditing ?? this.isEditing,
      title: title ?? this.title,
      content: content ?? this.content,
      category: clearCategory ? null : (category ?? this.category),
      isPinned: isPinned ?? this.isPinned,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        isEditing,
        title,
        content,
        category,
        isPinned,
        errorMessage,
      ];
}
