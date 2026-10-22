/// DocumentCenter feature.
///
/// The host app wires `FeatureDocumentCenterPackageModule` via `externalPackageModulesBefore`
/// and mounts `documentCenterRoutes` through its `FeatureModule`. Internals stay
/// private.
library;

export 'src/di.module.dart' show FeatureDocumentCenterPackageModule;
export 'src/presentation/bloc/document_center_cubit.dart';
export 'src/presentation/bloc/document_center_state.dart';
export 'src/presentation/document_center_routes.dart';
export 'src/presentation/screens/document_center_screen.dart';
