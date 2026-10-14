import 'package:equatable/equatable.dart';

/// Warna pastel catatan. Nilai disimpan sebagai teks dan dipetakan ke token
/// warna theme di lapisan UI.
enum NoteColor { violet, orange, blue, green, pink, yellow, red }

class Note extends Equatable {
  final String id;
  final String title;
  final String content;
  final String? category;
  final NoteColor? color;
  final bool isPinned;
  final String? remoteId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    this.category,
    this.color,
    this.isPinned = false,
    this.remoteId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        category,
        color,
        isPinned,
        remoteId,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}
