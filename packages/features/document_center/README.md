# feature_document_center

A feature package providing a complete UI workflow for document importing, dataset exporting, dynamic report generation, PDF preview, and thermal receipt printing within `Flutter Starter Template`.

---

## Features

- **Tabbed Workspace:** Seamlessly switch between three primary workflows:
  - **Import:** Select files (`.csv`, `.xlsx`, `.json`), inspect schema, validate rows with line-by-line feedback, preview data, and perform transactional commits.
  - **Export:** Select datasets, choose destination format (CSV, XLSX, JSON, PDF), toggle formula injection sanitization, and export bytes.
  - **Reports & Printing:** Choose from reference reports (Sales, Inventory, Supplier Statement, Tax Invoice), preview high-resolution PDFs interactively with page navigation, trigger system printing, or dispatch binary ESC/POS receipts to thermal printers.
- **Micro-Package Architecture:**
  - Registered via `fst add-feature document_center`.
  - Configured with `injectable` for dependency injection.
  - Decoupled from concrete backend implementations using `document_engine` abstractions and persistence adapters.
- **Full Localization (English & Arabic):**
  - Complete string parity across `app_en.arb` and `app_ar.arb`.
  - Automatic RTL layout adaptation for Arabic locales.

---

## Architecture & File Structure

```
packages/features/document_center/
├── lib/
│   ├── feature_document_center.dart        # Public library contract
│   └── src/
│       ├── di.dart                         # Injectable micro-package configuration
│       ├── di.module.dart                  # Generated dependency injection wiring
│       └── presentation/
│           ├── bloc/
│           │   ├── document_center_cubit.dart
│           │   └── document_center_state.dart
│           ├── routes/
│           │   └── document_center_routes.dart
│           ├── screens/
│           │   └── document_center_screen.dart
│           └── views/
│               ├── export_center_view.dart
│               ├── import_center_view.dart
│               └── report_center_view.dart
├── test/
│   └── presentation/
│       ├── document_center_cubit_test.dart
│       ├── document_center_routes_test.dart
│       └── document_center_screen_test.dart
└── pubspec.yaml
```

---

## Routing

The feature provides declarative navigation via `go_router`:

```dart
import 'package:feature_document_center/feature_document_center.dart';

// Access the route definition
final route = documentCenterRoute; // path: '/document-center'
```

---

## Testing & Quality Gates

Run all unit and widget tests:

```bash
fvm flutter test packages/features/document_center
```

Verify formatting and static analysis:

```bash
fvm dart format --output=none --set-exit-if-changed packages/features/document_center
fvm flutter analyze packages/features/document_center
```

