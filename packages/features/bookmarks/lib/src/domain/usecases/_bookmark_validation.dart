import 'package:architecture/architecture.dart';
import '../entities/bookmark.dart';
import '../services/bookmark_url_validator.dart';

/// Domain validation for [BookmarkInput]. Returns the first failure found, or
/// null when the input is acceptable.
Failure? validateBookmarkInput(BookmarkInput input) {
  if (input.title.trim().isEmpty) {
    return const ValidationFailure('Title is required.');
  }
  final urlError = validateBookmarkUrl(input.url);
  if (urlError != null) {
    return ValidationFailure(urlError);
  }
  return null;
}
