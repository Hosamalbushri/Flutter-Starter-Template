import 'package:injectable/injectable.dart';

/// Code-generation anchor for the feature_document_center micro-package.
///
/// Running `build_runner` here generates `di.module.dart` containing
/// `FeatureDocumentCenterPackageModule`, which the host app wires via
/// `externalPackageModulesBefore`.
@InjectableInit.microPackage()
void initDocumentCenterFeature() {}
