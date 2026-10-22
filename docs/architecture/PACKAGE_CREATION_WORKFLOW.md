# Package Creation Workflow

> **Step-by-Step Authoritative Guide for Creating & Wiring Packages**
> Supports both CLI-driven automation and manual architecture-compliant procedures.

---

## 1. Choosing the Package Path & CLI Command

| Package Archetype | CLI Generation Command | Target Directory |
|-------------------|------------------------|------------------|
| **Feature Package** | `fst add-feature <name> --source <presentation\|local\|api\|sync> [--route <path>]` | `packages/features/<name>/` |
| **Contracts Package** | `fst create-package <name> --type contracts [--dependency <pkg>]` | `packages/<name>/` |
| **Infrastructure Package** | `fst create-package <name> --type infrastructure [--dependency <pkg>]` | `packages/<name>/` |
| **Platform Integration** | `fst create-package <name> --type platform [--dependency <pkg>]` | `packages/<name>/` |
| **UI Design System** | `fst create-package <name> --type ui [--dependency <pkg>]` | `packages/<name>/` |
| **Dev Test Utilities** | `fst create-package <name> --type dev [--dependency <pkg>]` | `packages/<name>/` |

> [!TIP]
> The `fst` CLI binary resides in the `published/cli` submodule. If running from local source:
> `fvm dart run published/cli/bin/fst.dart create-package <name> --type <type>`

---

## 2. Step-by-Step Workflow

### Step 01: Directory Creation & Registration

1. Scaffold the package using the CLI or create the folder structure corresponding to the archetype defined in [`NEW_PACKAGE_TEMPLATE.md`](NEW_PACKAGE_TEMPLATE.md).
2. Register the package in the root `pubspec.yaml` under `workspace:`:
```yaml
workspace:
  - packages/app_ui
  ...
  # fst:feature:orders:start (wrap in sentinel if optional)
  - packages/features/orders
  # fst:feature:orders:end
```

---

### Step 02: Dependency Declaration & DAG Compliance

In `packages/<name>/pubspec.yaml`, declare only dependencies permitted by the **Layer Rank DAG**:

| Current Package Rank | Permitted Dependency Target Rank | Forbidden Targets |
|----------------------|-----------------------------------|-------------------|
| **0 (Foundation)** | *None* (Pure foundation) | Any workspace package |
| **1 (Platform)** | Rank 0 (`architecture`, `rev_sync`) | Rank 1, 2, 3, 4, App Shell |
| **2 (Infrastructure)** | Rank 0, 1 | Rank 2, 3, 4, App Shell |
| **3 (Contracts & UI)** | Rank 0, 1, 2 | Rank 3, 4, App Shell |
| **4 (Features)** | Rank 0, 1, 2, 3 (and allowlisted features) | Other features outside allowlist, App Shell |

> [!CAUTION]
> `packages/test_utils` must **NEVER** be placed in `dependencies:`. It is only permitted in `dev_dependencies:`.

---

### Step 03: Public Barrel Creation (`lib/<name>.dart`)

Every package must have exactly one public entry point: `lib/<name>.dart`.

#### Feature Barrel Rules:
```dart
library;

// 1. DI micro-package module
export 'src/di.module.dart' show FeatureOrdersPackageModule;

// 2. Domain entities
export 'src/domain/entities/order.dart';

// 3. Presentation routes, screens, and cubits
export 'src/presentation/bloc/orders_cubit.dart';
export 'src/presentation/orders_routes.dart';
export 'src/presentation/screens/orders_screen.dart';

// STRICTLY FORBIDDEN:
// export 'src/di.dart';
// export 'src/locator.dart';
// export 'src/data/**';
// export 'src/domain/repositories/**';
// export 'src/domain/usecases/**';
```

---

### Step 04: Micro-Package DI Self-Registration

For Feature and Infrastructure packages:

1. Create `lib/src/di.dart`:
```dart
import 'package:injectable/injectable.dart';

@InjectableInit.microPackage()
void initMicroPackage() {}
```

2. Annotate all local/remote data sources and repository implementations directly with `@LazySingleton(as: Interface)`:
```dart
@LazySingleton(as: OrdersLocalDataSource)
class InMemoryOrdersDataSource implements OrdersLocalDataSource { ... }
```
> [!IMPORTANT]
> The app-root `DriftModule` or `ObjectBoxModule` must never import feature data sources. Features self-register.

---

### Step 05: Application Shell Wiring (with Symmetrical Markers)

For optional feature packages, wrap all host wiring in balanced sentinels:

#### A. In `lib/app/di/injection.dart`:
```dart
// fst:feature:orders:start
import 'package:feature_orders/feature_orders.dart';
// fst:feature:orders:end

@InjectableInit(
  externalPackageModulesBefore: [
    ...
    // Must be placed AFTER infrastructure modules
    // fst:feature:orders:start
    ExternalModule(FeatureOrdersPackageModule),
    // fst:feature:orders:end
  ],
)
```

#### B. In `lib/app/features.dart`:
```dart
// fst:feature:orders:start
import 'package:feature_orders/feature_orders.dart';
// fst:feature:orders:end

const List<FeatureModule> enabledFeatures = [
  ...
  // fst:feature:orders:start
  _OrdersModule(),
  // fst:feature:orders:end
];

// fst:feature:orders:start
final class _OrdersModule extends FeatureModule {
  const _OrdersModule();

  @override
  String get id => 'orders';

  @override
  FeatureNavigationRegistration get navigation =>
      const FeatureNavigationRegistration(routePath: '/orders');

  @override
  Iterable<RouteBase> get routes => ordersRoutes;
}
// fst:feature:orders:end
```

#### C. In `lib/app/router.dart` (if mounting a stateful shell branch):
```dart
// fst:feature:orders:start
TypedStatefulShellBranch<OrdersBranchData>(
  routes: <TypedRoute<RouteData>>[
    TypedGoRoute<OrdersRoute>(path: '/orders', name: 'orders'),
  ],
),
// fst:feature:orders:end
```

---

### Step 06: Architecture Guardrails Registration

Update the test suites in `test/architecture/`:

1. **`test/architecture/package_layering_test.dart`:**
   - If non-feature: add package to `_nonFeatureCategories`.
   - Add package name and integer rank (0 to 4) to `_layers`.
   - Wrap entry in `// fst:feature:<name>:start ... end` if optional.
2. **`test/architecture/feature_boundaries_test.dart`:**
   - If feature has a justified single-consumer dependency, document it in `_allowedCrossFeatureImports`.
3. **`test/architecture/di_module_ordering_test.dart`:**
   - If module has a load-bearing construction order constraint, add it to `_mustPrecede`.

---

### Step 07: Code Generation & Formatting

Execute the code generation pipeline using the FVM SDK:

```bash
# 1. Resolve workspace dependencies
fvm flutter pub get

# 2. Run codegen for the package
./tool/codegen.sh --package packages/features/orders

# 3. Regenerate app root DI graph
fvm dart run build_runner build -d

# 4. Format all modified and generated files
fvm dart format .
```

---

### Step 08: Pre-Commit Verification Gate

Before submitting a PR, run the mandatory verification gate:

```bash
# 1. Format check (must return exit code 0)
fvm dart format --set-exit-if-changed .

# 2. Static analysis (must be 0 errors, 0 warnings)
fvm flutter analyze

# 3. Architecture guardrails (all 18 suites must pass)
fvm flutter test test/architecture/

# 4. Verify codegen coverage
fvm flutter test test/architecture/di_module_codegen_coverage_test.dart

# 5. Run package unit tests
fvm flutter test packages/features/orders/
```
