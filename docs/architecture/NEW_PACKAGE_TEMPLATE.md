# Multi-Archetype Package Templates

> **Modular Package Scaffolding Templates**
> Covers all four architectural package types supported in the workspace.
> Avoids imposing unnecessary presentation or data layers on non-feature packages.

---

## Overview of Package Archetypes

| Archetype | Typical Path | Package Name | Uses Flutter? | Has Presentation/UI? | Has Data/DB? | Has Micro-Package DI? | CLI Generation Command |
|-----------|--------------|--------------|---------------|----------------------|--------------|-----------------------|------------------------|
| **A: Feature Package** | `packages/features/<name>/` | `feature_<name>` | Yes | Yes (Screens, Routes, BLoC) | Yes (Local/Remote DS) | Yes (`@InjectableInit.microPackage`) | `fst add-feature <name> --source <type>` |
| **B: Infrastructure Service** | `packages/<name>/` | `<name>` | Optional | No | Optional | Yes (`@InjectableInit.microPackage`) | `fst create-package <name> --type infrastructure` |
| **C: UI / Design System** | `packages/<name>/` | `<name>` | Yes | Yes (Widgets, Tokens) | No | No (Stateless/Scopes) | `fst create-package <name> --type ui` |
| **D: Pure Dart Domain / Contract** | `packages/<name>/` | `<name>` | **No** (Pure Dart) | No | No | No | `fst create-package <name> --type contracts` |

---

# Archetype A: Feature Package

Used for user-facing vertical feature slices (`packages/features/<name>/`).

### 1. Directory Structure
```
packages/features/<name>/
├── pubspec.yaml
├── lib/
│   ├── feature_<name>.dart
│   └── src/
│       ├── di.dart
│       ├── di.module.dart (generated)
│       ├── locator.dart
│       ├── domain/
│       │   ├── entities/<name>.dart
│       │   └── repositories/<name>_repository.dart
│       ├── data/
│       │   ├── local/<name>_local_data_source.dart
│       │   └── repositories/<name>_repository_impl.dart
│       └── presentation/
│           ├── <name>_routes.dart
│           ├── bloc/
│           │   ├── <name>_cubit.dart
│           │   └── <name>_state.dart
│           └── screens/
│               └── <name>_screen.dart
└── test/
    └── presentation/<name>_routes_test.dart
```

### 2. `pubspec.yaml`
```yaml
name: feature_<name>
description: <PascalCase> feature vertical slice.
publish_to: 'none'
version: 1.0.0

environment:
  sdk: ^3.12.0

dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.6
  go_router: ^14.8.1
  get_it: ^8.0.3
  injectable: ^2.5.0
  architecture:
    path: ../../architecture
  app_ui:
    path: ../../app_ui
  localization:
    path: ../../localization

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.15
  injectable_generator: ^2.7.0
  test_utils:
    path: ../../test_utils
```

### 3. Public Barrel (`lib/feature_<name>.dart`)
```dart
/// <PascalCase> feature: presentation, domain, and data layers.
library;

export 'src/di.module.dart' show Feature<PascalCase>PackageModule;
export 'src/domain/entities/<name>.dart';
export 'src/presentation/<name>_routes.dart';
export 'src/presentation/bloc/<name>_cubit.dart';
export 'src/presentation/bloc/<name>_state.dart';
export 'src/presentation/screens/<name>_screen.dart';
```

### 4. DI Anchor (`lib/src/di.dart`)
```dart
import 'package:injectable/injectable.dart';

@InjectableInit.microPackage()
void initMicroPackage() {}
```

### 5. Domain Entity (`lib/src/domain/entities/<name>.dart`)
```dart
import 'package:flutter/foundation.dart';

@immutable
class <PascalCase> {
  const <PascalCase>({
    required this.id,
    required this.title,
    required this.createdAt,
  });

  final String id;
  final String title;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is <PascalCase> &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, title, createdAt);
}
```

### 6. Local Data Source with Self-Registration (`lib/src/data/local/<name>_local_data_source.dart`)
```dart
import 'package:injectable/injectable.dart';

import '../../domain/entities/<name>.dart';

abstract interface class <PascalCase>LocalDataSource {
  Future<List<<PascalCase>>> getAll();
}

@LazySingleton(as: <PascalCase>LocalDataSource)
class InMemory<PascalCase>DataSource implements <PascalCase>LocalDataSource {
  final List<<PascalCase>> _items = [];

  @override
  Future<List<<PascalCase>>> getAll() async => List.unmodifiable(_items);
}
```

### 7. Repository Implementation (`lib/src/data/repositories/<name>_repository_impl.dart`)
```dart
import 'package:architecture/architecture.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/<name>.dart';
import '../../domain/repositories/<name>_repository.dart';
import '../local/<name>_local_data_source.dart';

@LazySingleton(as: <PascalCase>Repository)
class <PascalCase>RepositoryImpl implements <PascalCase>Repository {
  const <PascalCase>RepositoryImpl(this._localDataSource);

  final <PascalCase>LocalDataSource _localDataSource;

  @override
  Future<Result<List<<PascalCase>>>> listItems() async {
    try {
      final items = await _localDataSource.getAll();
      return Ok(items);
    } on Object catch (error) {
      return Err(UnknownFailure(error.toString()));
    }
  }
}
```

---

# Archetype B: Infrastructure / Service Package

Used for adapters, persistence engines, networking, telemetry, and platform integrations (`packages/<name>/`).

### 1. Directory Structure
```
packages/<name>/
├── pubspec.yaml
├── lib/
│   ├── <name>.dart
│   └── src/
│       ├── di.dart
│       ├── di.module.dart (generated)
│       ├── <name>_service.dart
│       └── <name>_service_impl.dart
└── test/
    └── <name>_service_test.dart
```

### 2. `pubspec.yaml`
```yaml
name: <name>
description: <PascalCase> infrastructure service module.
publish_to: 'none'
version: 1.0.0

environment:
  sdk: ^3.12.0

dependencies:
  get_it: ^8.0.3
  injectable: ^2.5.0
  architecture:
    path: ../architecture

dev_dependencies:
  test: ^1.25.0
  build_runner: ^2.4.15
  injectable_generator: ^2.7.0
```

### 3. Public Barrel (`lib/<name>.dart`)
```dart
/// Public contract and DI module for <name>.
library;

export 'src/di.module.dart' show <PascalCase>PackageModule;
export 'src/<name>_service.dart';
```

### 4. Service Contract (`lib/src/<name>_service.dart`)
```dart
abstract interface class <PascalCase>Service {
  Future<void> initialize();
  Future<void> dispose();
}
```

### 5. Service Implementation with Self-Registration (`lib/src/<name>_service_impl.dart`)
```dart
import 'package:injectable/injectable.dart';

import '<name>_service.dart';

@LazySingleton(as: <PascalCase>Service)
class <PascalCase>ServiceImpl implements <PascalCase>Service {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}
}
```

---

# Archetype C: UI / Design System Package

Used for design tokens, reusable components, and presentation scopes (`packages/<name>/`).

### 1. Directory Structure
```
packages/<name>/
├── pubspec.yaml
├── lib/
│   ├── <name>.dart
│   └── src/
│       ├── tokens/
│       │   ├── <name>_spacing.dart
│       │   └── <name>_radius.dart
│       └── widgets/
│           └── <name>_host.dart
└── test/
    └── widgets/<name>_host_test.dart
```

### 2. `pubspec.yaml`
```yaml
name: <name>
description: <PascalCase> UI and design tokens module.
publish_to: 'none'
version: 1.0.0

environment:
  sdk: ^3.12.0

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
```

### 3. Public Barrel (`lib/<name>.dart`)
```dart
/// UI components and styling tokens for <name>.
library;

export 'src/tokens/<name>_radius.dart';
export 'src/tokens/<name>_spacing.dart';
export 'src/widgets/<name>_host.dart';
```

### 4. Layout-Neutral Host Widget (`lib/src/widgets/<name>_host.dart`)
```dart
import 'package:flutter/widgets.dart';

/// Layout-neutral container for reusable <name> presentation.
class <PascalCase>Host extends StatelessWidget {
  const <PascalCase>Host({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
```

---

# Archetype D: Pure Dart Domain / Contract Package

Used for shared interfaces, entities, failures, and pure domain logic (`packages/<name>/`). **Zero Flutter dependency.**

### 1. Directory Structure
```
packages/<name>/
├── pubspec.yaml
├── lib/
│   ├── <name>.dart
│   └── src/
│       ├── <name>_contract.dart
│       └── <name>_model.dart
└── test/
    └── <name>_model_test.dart
```

### 2. `pubspec.yaml`
```yaml
name: <name>
description: Pure Dart domain contracts for <name>.
publish_to: 'none'
version: 1.0.0

environment:
  sdk: ^3.12.0

dependencies:
  # Pure Dart only. NEVER include 'flutter' or 'flutter_test'.
  architecture:
    path: ../architecture

dev_dependencies:
  test: ^1.25.0
```

### 3. Public Barrel (`lib/<name>.dart`)
```dart
/// Pure Dart domain contracts and primitives for <name>.
library;

export 'src/<name>_contract.dart';
export 'src/<name>_model.dart';
```

### 4. Pure Contract Interface (`lib/src/<name>_contract.dart`)
```dart
import 'package:architecture/architecture.dart';

import '<name>_model.dart';

abstract interface class <PascalCase>Contract {
  Future<Result<<PascalCase>Model>> execute();
}
```

### 5. Pure Immutable Model (`lib/src/<name>_model.dart`)
```dart
final class <PascalCase>Model {
  const <PascalCase>Model({
    required this.id,
    required this.value,
  });

  final String id;
  final String value;
}
```

---

## Workspace Wiring Reference

| Item | Feature (Archetype A) | Infra (Archetype B) | UI (Archetype C) | Contract (Archetype D) |
|------|------------------------|---------------------|------------------|-------------------------|
| `pubspec.yaml` `workspace:` | `- packages/features/<name>` | `- packages/<name>` | `- packages/<name>` | `- packages/<name>` |
| `package_layering_test.dart` category | `feature` (auto) | `infrastructureService` or `platformIntegration` | `uiDesignSystem` | `sharedDomainContracts` |
| `package_layering_test.dart` rank | `4` | `2` (or `1` for platform) | `3` | `0` or `3` |
| `injection.dart` `externalPackageModulesBefore` | Yes (after infra) | Yes (before features) | No (Stateless) | Optional (No DI or early) |
| Sentinel markers needed? | Yes (`// fst:feature:<name>`) | Only if optional pillar | No | No |
| `codegen.sh` coverage | Yes | Yes (if declares build_runner) | No | No |

## Workspace Wiring Reference

| Item | Feature (Archetype A) | Infra (Archetype B) | UI (Archetype C) | Contract (Archetype D) |
|------|------------------------|---------------------|------------------|-------------------------|
| `pubspec.yaml` `workspace:` | `- packages/features/<name>` | `- packages/<name>` | `- packages/<name>` | `- packages/<name>` |
| `package_layering_test.dart` category | `feature` (auto) | `infrastructureService` or `platformIntegration` | `uiDesignSystem` | `sharedDomainContracts` |
| `package_layering_test.dart` rank | `4` | `2` (or `1` for platform) | `3` | `0` or `3` |
| `injection.dart` `externalPackageModulesBefore` | Yes (after infra) | Yes (before features) | No (Stateless) | Optional (No DI or early) |
| Sentinel markers needed? | Yes (`// fst:feature:<name>`) | Only if optional pillar | No | No |
| `codegen.sh` coverage | Yes | Yes (if declares build_runner) | No | No |
