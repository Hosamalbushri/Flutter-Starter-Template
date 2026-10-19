import 'package:document_engine/document_engine.dart';

/// Target schema definition for importing Collections from CSV, XLSX, or JSON.
DocumentDefinition createCollectionsDocumentDefinition() {
  return DocumentDefinition(
    id: 'collections_schema',
    title: 'Collections Import Schema',
    columns: [
      DocumentColumn.text(
        id: 'name',
        label: 'Name',
        isRequired: true,
      ),
      DocumentColumn.text(
        id: 'icon',
        label: 'Icon',
      ),
      DocumentColumn.integer(
        id: 'color',
        label: 'Color',
      ),
      DocumentColumn.text(
        id: 'bookmarkIds',
        label: 'Bookmark IDs',
      ),
    ],
  );
}

/// Pre-configured [ImportDefinition] for Collections.
ImportDefinition createCollectionsImportDefinition({
  bool allowPartial = true,
  int? maxRows,
}) {
  return ImportDefinition(
    targetDefinition: createCollectionsDocumentDefinition(),
    columnMappings: const {
      'collection_name': 'name',
      'title': 'name',
      'اسم المجموعة': 'name',
      'الاسم': 'name',
      'icon_token': 'icon',
      'الأيقونة': 'icon',
      'color_argb': 'color',
      'اللون': 'color',
      'bookmarks': 'bookmarkIds',
      'bookmark_ids': 'bookmarkIds',
      'الإشارات': 'bookmarkIds',
    },
    allowPartial: allowPartial,
    maxRows: maxRows,
  );
}
