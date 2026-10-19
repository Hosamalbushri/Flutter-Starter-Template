import 'package:meta/meta.dart';

/// Standard document metadata (author, title, keywords, dates, custom attributes).
@immutable
class DocumentMetadata {
  const DocumentMetadata({
    this.title,
    this.author,
    this.creator = 'document_engine',
    this.subject,
    this.keywords = const [],
    this.createdAt,
    this.modifiedAt,
    this.customAttributes = const {},
  });

  final String? title;
  final String? author;
  final String? creator;
  final String? subject;
  final List<String> keywords;
  final DateTime? createdAt;
  final DateTime? modifiedAt;
  final Map<String, String> customAttributes;

  DocumentMetadata copyWith({
    String? title,
    String? author,
    String? creator,
    String? subject,
    List<String>? keywords,
    DateTime? createdAt,
    DateTime? modifiedAt,
    Map<String, String>? customAttributes,
  }) => DocumentMetadata(
    title: title ?? this.title,
    author: author ?? this.author,
    creator: creator ?? this.creator,
    subject: subject ?? this.subject,
    keywords: keywords ?? this.keywords,
    createdAt: createdAt ?? this.createdAt,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    customAttributes: customAttributes ?? this.customAttributes,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentMetadata &&
          other.title == title &&
          other.author == author &&
          other.creator == creator &&
          other.subject == subject &&
          other.createdAt == createdAt &&
          other.modifiedAt == modifiedAt);

  @override
  int get hashCode =>
      Object.hash(title, author, creator, subject, createdAt, modifiedAt);

  @override
  String toString() => 'DocumentMetadata(title: $title, author: $author)';
}
