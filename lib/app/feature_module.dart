import 'package:go_router/go_router.dart';

/// Lifecycle interface for an optional feature's background sync.
abstract interface class FeatureSyncController {
  Future<void> start();
  Future<void> stop();
}

/// Optional navigation metadata declared by a [FeatureModule].
final class FeatureNavigationRegistration {
  const FeatureNavigationRegistration({
    required this.routePath,
    this.routeName,
    this.isShellBranch = false,
  });

  /// Primary entry route path (must be an absolute path starting with `/`).
  final String routePath;

  /// Optional GoRouter route name for the primary entry point.
  final String? routeName;

  /// Whether this feature is exposed as a persistent shell branch in `AppShell`.
  final bool isShellBranch;
}

/// Formal contract between the application shell and an optional feature
/// package.
///
/// Architectural boundaries:
/// - **Identity**: [id] is a unique `snake_case` identifier matching
///   `packages/features/<id>` and `feature_<id>`.
/// - **Routes**: [routes] contributes non-shell `GoRoute` trees composed into
///   the application router (`enabledFeatures.expand((f) => f.routes)`).
/// - **DI Registrations**: Exported as `Feature<Name>PackageModule` via
///   `@InjectableInit.microPackage()` and registered in
///   `lib/app/di/injection.dart` (`externalPackageModulesBefore`).
/// - **Required Capabilities**: [requiredFeatures] declares other optional
///   feature IDs whose runtime capabilities this feature consumes.
/// - **Navigation Exposure**: [navigation] optionally declares the feature's
///   primary entry route and whether it participates in shell navigation.
/// - **Initialization**: [initialize] runs once during host startup when
///   post-DI setup is needed; [syncController] manages session-scoped sync.
/// - **Public API**: Only symbols exported from
///   `package:feature_<id>/feature_<id>.dart` may be imported by the host
///   shell or capability consumers.
abstract class FeatureModule {
  const FeatureModule();

  /// Stable, unique `snake_case` feature identifier (e.g. `'bookmarks'`).
  String get id;

  /// Optional feature IDs that must also be enabled when this feature is active.
  Set<String> get requiredFeatures => const {};

  /// Optional navigation descriptor for the feature's primary entry point.
  FeatureNavigationRegistration? get navigation => null;

  /// Optional initialization hook invoked after dependency injection completes.
  Future<void> initialize() async {}

  /// The feature's sync controller, or null if it has no background sync.
  FeatureSyncController? get syncController => null;

  /// The feature's non-shell routes, mounted by the app router.
  ///
  /// Empty for features that only contribute a shell tab (e.g. notifications).
  Iterable<RouteBase> get routes => const [];
}

final RegExp _featureIdPattern = RegExp(r'^[a-z][a-z0-9_]*$');

/// Validates the architectural contracts of the registered [modules]:
/// - Every [FeatureModule.id] is non-empty `snake_case` and unique.
/// - Every entry in [FeatureModule.requiredFeatures] is valid, non-self,
///   present in [modules], and free of circular feature requirements.
/// - Every [FeatureModule.navigation] route path is a valid absolute path.
/// - Every top-level [GoRoute] in [FeatureModule.routes] uses an absolute path
///   starting with `/`, and no two modules register colliding top-level paths
///   or route names.
///
/// Throws [StateError] on any contract violation.
void validateFeatureModules(Iterable<FeatureModule> modules) {
  final moduleList = modules.toList(growable: false);
  final byId = <String, FeatureModule>{};

  for (final module in moduleList) {
    final id = module.id;
    if (!_featureIdPattern.hasMatch(id)) {
      throw StateError(
        'Invalid FeatureModule.id "$id": must be lowercase snake_case '
        r'(matching ^[a-z][a-z0-9_]*$).',
      );
    }
    if (byId.containsKey(id)) {
      throw StateError('Duplicate FeatureModule.id "$id" registered.');
    }
    byId[id] = module;

    final nav = module.navigation;
    if (nav != null && !_isValidAbsoluteRoutePath(nav.routePath)) {
      throw StateError(
        'FeatureModule "$id" declares invalid navigation.routePath '
        '"${nav.routePath}": must be a valid absolute path starting with "/".',
      );
    }
  }

  for (final module in moduleList) {
    for (final requiredId in module.requiredFeatures) {
      if (!_featureIdPattern.hasMatch(requiredId)) {
        throw StateError(
          'FeatureModule "${module.id}" declares invalid requiredFeature '
          '"$requiredId": must be lowercase snake_case.',
        );
      }
      if (requiredId == module.id) {
        throw StateError(
          'FeatureModule "${module.id}" cannot require itself in '
          'requiredFeatures.',
        );
      }
      if (!byId.containsKey(requiredId)) {
        throw StateError(
          'FeatureModule "${module.id}" requires feature "$requiredId", '
          'which is not enabled.',
        );
      }
    }
  }

  final visiting = <String>{};
  final visited = <String>{};
  void visit(String id) {
    if (visited.contains(id)) return;
    if (!visiting.add(id)) {
      throw StateError(
        'Circular requiredFeatures dependency detected involving "$id".',
      );
    }
    final module = byId[id];
    if (module != null) {
      module.requiredFeatures.forEach(visit);
    }
    visiting.remove(id);
    visited.add(id);
  }

  byId.keys.forEach(visit);

  final routeOwnersByPath = <String, String>{};
  final routeOwnersByName = <String, String>{};

  for (final module in moduleList) {
    for (final route in module.routes) {
      _validateRouteTree(
        route,
        featureId: module.id,
        isTopLevel: true,
        routeOwnersByPath: routeOwnersByPath,
        routeOwnersByName: routeOwnersByName,
      );
    }
  }
}

void _validateRouteTree(
  RouteBase route, {
  required String featureId,
  required bool isTopLevel,
  required Map<String, String> routeOwnersByPath,
  required Map<String, String> routeOwnersByName,
}) {
  if (route is GoRoute) {
    final path = route.path;
    if (isTopLevel) {
      if (!_isValidAbsoluteRoutePath(path)) {
        throw StateError(
          'FeatureModule "$featureId" registers top-level GoRoute with '
          'invalid path "$path": top-level feature routes must start with "/".',
        );
      }
      final existingPathOwner = routeOwnersByPath[path];
      if (existingPathOwner != null) {
        throw StateError(
          'Duplicate GoRoute path "$path" registered by FeatureModule '
          '"$featureId" (already registered by "$existingPathOwner").',
        );
      }
      routeOwnersByPath[path] = featureId;
    } else if (path.isEmpty || path.startsWith('/')) {
      throw StateError(
        'FeatureModule "$featureId" registers nested GoRoute with invalid '
        'relative path "$path": nested routes must be non-empty relative '
        'paths.',
      );
    }

    final name = route.name;
    if (name != null) {
      if (name.trim().isEmpty) {
        throw StateError(
          'FeatureModule "$featureId" registers GoRoute at "$path" with an '
          'empty route name.',
        );
      }
      final existingNameOwner = routeOwnersByName[name];
      if (existingNameOwner != null) {
        throw StateError(
          'Duplicate GoRoute name "$name" registered by FeatureModule '
          '"$featureId" (already registered by "$existingNameOwner").',
        );
      }
      routeOwnersByName[name] = featureId;
    }
  }

  for (final child in route.routes) {
    _validateRouteTree(
      child,
      featureId: featureId,
      isTopLevel: false,
      routeOwnersByPath: routeOwnersByPath,
      routeOwnersByName: routeOwnersByName,
    );
  }
}

bool _isValidAbsoluteRoutePath(String path) {
  if (!path.startsWith('/') || path.length < 2) return false;
  if (path.contains('//') || path.endsWith('/')) return false;
  return true;
}
