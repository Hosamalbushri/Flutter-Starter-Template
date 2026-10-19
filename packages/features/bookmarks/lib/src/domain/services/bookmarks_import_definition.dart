import 'package:document_engine/document_engine.dart';

import 'bookmark_url_validator.dart';

/// Target schema definition for importing Bookmarks from CSV, XLSX, or JSON.
DocumentDefinition createBookmarksDocumentDefinition() {
  return DocumentDefinition(
    id: 'bookmarks_schema',
    title: 'Bookmarks Import Schema',
    columns: [
      DocumentColumn.text(
        id: 'title',
        label: 'Title',
        isRequired: true,
      ),
      DocumentColumn.text(
        id: 'url',
        label: 'URL',
        isRequired: true,
        validator: (value) => validateBookmarkUrl(value.displayValue),
      ),
      DocumentColumn.text(
        id: 'description',
        label: 'Description',
      ),
      DocumentColumn.text(
        id: 'tags',
        label: 'Tags',
      ),
      DocumentColumn.text(
        id: 'imageUrls',
        label: 'Image URLs',
        validator: _validateImportedImageUrls,
      ),
      DocumentColumn.text(
        id: 'videoUrl',
        label: 'Video URL',
        validator: _validateImportedVideoUrl,
      ),
      DocumentColumn.text(
        id: 'collection',
        label: 'Collection',
      ),
    ],
  );
}

String? _validateImportedImageUrls(DocumentValue value) {
  final raw = value.displayValue.trim();
  if (raw.isEmpty) return null;

  final urls = raw
      .split(RegExp('[,;]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty);
  for (final url in urls) {
    if (!_isSafeRemoteMediaUrl(url)) {
      return 'Imported image attachments must be valid HTTP or HTTPS URLs.';
    }
  }
  return null;
}

String? _validateImportedVideoUrl(DocumentValue value) {
  final raw = value.displayValue.trim();
  if (raw.isEmpty || _isSafeRemoteMediaUrl(raw)) return null;
  return 'Imported video attachments must be valid HTTP or HTTPS URLs.';
}

bool _isSafeRemoteMediaUrl(String raw) {
  final uri = Uri.tryParse(raw);
  if (uri == null || uri.userInfo.isNotEmpty || uri.host.isEmpty) return false;
  final scheme = uri.scheme.toLowerCase();
  return scheme == 'http' || scheme == 'https';
}

/// Pre-configured [ImportDefinition] for Bookmarks.
ImportDefinition createBookmarksImportDefinition({
  bool allowPartial = true,
  int? maxRows,
}) {
  return ImportDefinition(
    targetDefinition: createBookmarksDocumentDefinition(),
    columnMappings: const {
      'name': 'title',
      'عنوان': 'title',
      'الاسم': 'title',
      'bookmark_title': 'title',
      'link': 'url',
      'uri': 'url',
      'website': 'url',
      'الرابط': 'url',
      'bookmark_url': 'url',
      'desc': 'description',
      'details': 'description',
      'الوصف': 'description',
      'tag': 'tags',
      'الوسوم': 'tags',
      'keywords': 'tags',
      'images': 'imageUrls',
      'image': 'imageUrls',
      'الصور': 'imageUrls',
      'video': 'videoUrl',
      'الفيديو': 'videoUrl',
      'collection_name': 'collection',
      'collection_id': 'collection',
      'المجموعة': 'collection',
      'folder': 'collection',
    },
    allowPartial: allowPartial,
    maxRows: maxRows,
  );
}
