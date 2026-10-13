/// Bookmarks feature: data, domain, and presentation layers.
///
/// The host app wires `FeatureBookmarksPackageModule` via
/// `externalPackageModulesBefore`, mounts the exported screens in its router,
/// and drives background sync through `BookmarksSyncController`. Only the
/// `Bookmark` entity is exported from the domain layer; repositories and use
/// cases are internal, resolved through dependency injection. Data and
/// presentation internals stay private.
library;

export 'src/di.module.dart' show FeatureBookmarksPackageModule;
export 'src/domain/entities/bookmark.dart';
export 'src/domain/services/bookmarks_sync_controller.dart';
export 'src/presentation/bloc/bookmark_form/bookmark_form_bloc.dart';
export 'src/presentation/bloc/bookmark_form/bookmark_form_state.dart';
export 'src/presentation/bloc/bookmarks_list/bookmarks_list_bloc.dart';
export 'src/presentation/bloc/bookmarks_list/bookmarks_list_state.dart';
export 'src/presentation/bookmarks_routes.dart';
export 'src/presentation/screens/bookmark_detail_screen.dart';
export 'src/presentation/screens/bookmark_form_screen.dart';
export 'src/presentation/screens/bookmarks_list_screen.dart';
