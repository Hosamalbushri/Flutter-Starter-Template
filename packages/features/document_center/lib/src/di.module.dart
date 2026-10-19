// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i687;

import 'package:feature_document_center/src/presentation/bloc/document_center_cubit.dart'
    as _i370;
import 'package:injectable/injectable.dart' as _i526;

class FeatureDocumentCenterPackageModule extends _i526.MicroPackageModule {
  // initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
    gh.factory<_i370.DocumentCenterCubit>(() => _i370.DocumentCenterCubit());
  }
}
