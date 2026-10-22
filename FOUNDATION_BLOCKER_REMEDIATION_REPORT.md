# Flutter Starter Template — Certification Blocker Remediation Report

**تاريخ التنفيذ:** 2026-10-21  
**نطاق الفحص والإصلاح:** الفرع المحلي `feat/document-engine` والمستودع الفرعي `published/cli`  
**الحالة العامة للمرحلة:** **REMEDIATION COMPLETED LOCALLY — READY FOR REMOTE ACTIONS**  
**الموانع المعلقة لاعتماد الإنتاج الكامل:**  
1. نشر commits المستودع الفرعي `published/cli` ومستودع القالب إلى GitHub (يتطلب موافقة صريحة).  
2. توقيع Android Release الفعلي باستخدام Keystore حقيقي (يتطلب مفاتيح الإنتاج الخاصة بالمستخدم).

---

## 1. ملخص تنفيذي للمرحلة

تمت معالجة وإصلاح جميع الموانع البرمجية والمعمارية المثبتة في تقرير الاعتماد السابق `FOUNDATION_FINAL_CERTIFICATION.md`:

1. **Gate 01 (CLI Submodule Recovery):** تم تشخيص تاريخ المستودع الفرعي بالكامل وتحديد الـcommits غير المنشورة، وتجهيز أوامر الـPush الآمنة دون المساس بتاريخ المستودع أو تنفيذه دون إذن.
2. **Gate 02 (Optional Document Architecture):** تم تطبيق القرار المعماري الإلزامي بدقة:
   - أصبح `document_engine` حزمة اختيارية (`--[no-]document-engine`).
   - أصبحت `document_center` ميزة اختيارية (`--[no-]document-center`).
   - تم فرض العقد المعماري: `document_center` يعتمد على `document_engine`، وتوليد المركز دون المحرك يتم رفضه فورًا قبل إنشاء أي مجلد.
   - تم ربط إشارات وعزل استبعاد المحرك بإزالة الميزات التوضيحية المعتمدة عليه (`bookmarks` و`collections`) لضمان عدم وجود أي Import معلق أو تبعية مفقودة.
3. **Gate 03 (Lockfile Reproducibility):** تم تضمين منطق تحديث وفرض ملف القفل تلقائيًا داخل دورة حياة التوليد عبر `refreshGeneratedLockfile` (`flutter pub get` متبوعًا بـ`flutter pub get --enforce-lockfile`) حتى مع تمرير `--no-setup`، وتأكيد خلو كل المشاريع المولدة من أي drift.
4. **Gate 04 (ObjectBox Native Test Runtime):** تم حل مشكلة غياب `libobjectbox.so` عبر سكريبت اختبار مستقل وقابل للتكرار على Linux وCI (`tool/test_objectbox.sh`) يقوم بتنزيل نسخة C Runtime المطابقة والمثبتة برقم الإصدار (5.3.2) مع فحص SHA-256، وتشغيل الاختبارات في بيئة معزولة، مما أسفر عن نجاح 8/8 من اختبارات ObjectBox الذرية.
5. **Gate 05 (Golden Test Recovery):** تم إصلاح جميع اختبارات Golden الخمسة الفاشلة في `app_ui` بعد تثبيت ألوان `Material` الشفافة لزر الإجراء المركزي، وتوفير تحميل خطوط DejaVu وFontAwesome بشكل قطعي دون الاعتماد على مسار بيئة عشوائي، ونجحت اختبارات Golden بنسبة 15/15.
6. **Gate 06 & CI Reliability:** تم إصلاح مسار GitHub Actions (`.github/workflows/ci.yml`) ليتضمن:
   - فحص الـsubmodules.
   - تشغيل اختبارات ObjectBox ببيئة C Runtime الصحيحة.
   - تشغيل اختبارات Golden المحددة على Ubuntu.
   - تصحيح إضافة ملفات الـGradle Wrapper (`gradlew`, `gradlew.bat`, `gradle-wrapper.jar`) لإنهاء إخفاق بناء Android Debug (exit 127).

---

## 2. العيوب المثبتة، أسبابها الجذرية، والإصلاحات الفعلية

### 2.1 مانع استرجاع المستودع الفرعي (Step 01 / Gate 01)
- **العيب:** مؤشر submodule لـ`published/cli` في المشروع الرئيسي يشير إلى `fee6cf2cbd8c88b8dcd364dec6d5267448984909`، وهو commit غير موجود على GitHub Remote (`kido-luci/flutter-starter-template-cli.git`). محاولة `git submodule update --init` أو clean clone تعيد: `fatal: remote error: upload-pack: not our ref`.
- **السبب الجذري:** تم إنشاء الـcommit محليًا أثناء Remediation Phase 02/03 على detached HEAD ولم يُدفع بعد للريموت.
- **التشخيص الجنائي:**
  - الـcommit موجود محليًا بالكامل داخل `published/cli`.
  - الـcommit وسلفه `cb9d34d` يحتويان على جميع أدوات دورة حياة الحزم والميزات (`fst create-package`, `fst remove-package`, `fst remove-feature`, إلخ).
  - يمكن دفعهما بشكل آمن ونظيف تمامًا إلى فرع مستقل على الريموت دون إعادة كتابة التاريخ أو فرض أي قوة.

### 2.2 إجبارية حزمتي Document Engine وDocument Center (Step 02 / Gate 02)
- **العيب:** كانت كل من `document_engine` و`feature_document_center` تُدرج إجباريًا في كل مشروع مولّد عبر `fst create`، بما في ذلك مشاريع `--minimal`.
- **السبب الجذري:** غياب خيارات التحكم في التوليد وسنتنلز العزل في `pubspec.yaml` وملفات التوصيل (`lib/app/di/injection.dart` و`lib/app/features.dart` و`package_layering_test.dart`).
- **الإصلاح الفعلي:**
  1. إضافة خياري `--[no-]document-engine` و`--[no-]document-center` إلى أمر `create`.
  2. إضافة Sentinels محددة في القالب:
     - `// fst:document:engine:start` و `// fst:document:engine:end`
     - `// fst:document:center:start` و `// fst:document:center:end`
  3. إنشاء وحدة إعادة الكتابة `lib/src/rewrite/documents.dart` داخل الـCLI لحذف المجلدات والمناطق المحددة عند الاستبعاد.
  4. في `create_command.dart` و`create_compatibility.dart`:
     - منع اختيار Document Center مع استبعاد Engine: `--document-center requires Document Engine`.
     - عند استبعاد Document Engine، يتم استبعاد ميزتي `bookmarks` و`collections` تلقائيًا لمنع بقاء أي استيراد لمندوبي استيراد المستندات (`BookmarksImportDelegate` / `CollectionsImportDelegate`).
     - في وضع `--minimal`، يتم تعطيل الحزمتين تلقائيًا.

### 2.3 فشل التحقق من ملف القفل بعد التوليد (Step 03 / Gate 03)
- **العيب:** فشل `flutter pub get --enforce-lockfile` في المشاريع المولدة بعد تعديل الميزات لأن ملف `pubspec.lock` الموروث يظل محتويًا على حزم استُبعدت.
- **السبب الجذري:** اقتصار الـCLI سابقًا على تعديل `pubspec.yaml` دون تجديد الـlockfile تلقائيًا قبل انتهاء عملية التوليد.
- **الإصلاح الفعلي:**
  - إنشاء وحدة `lib/src/rewrite/lockfile.dart` داخل الـCLI بوظيفة `refreshGeneratedLockfile`.
  - يتم استدعاؤها في نهاية كل عملية توليد (حتى مع `--no-setup`) لتنفيذ `flutter pub get` متبوعًا بـ`flutter pub get --enforce-lockfile`.
  - إضافة اختبارات عدم انحدار مخصصة في `test/lockfile_reproducibility_test.dart`.

### 2.4 فشل تحميل المكتبة الأصلية لاختبارات ObjectBox (Step 04 / Gate 04)
- **العيب:** فشل 8 من أصل 8 اختبارات في `packages/database` بالخطأ:
  `Failed to load dynamic library 'libobjectbox.so': cannot open shared object file: No such file or directory`.
- **السبب الجذري:** يُشغّل `flutter test` عبر `flutter_tester` المعزول على نظام Linux المضيف دون بناء مكونات سطح المكتب؛ ويفترض ObjectBox عبر `dart:ffi` وجود `libobjectbox.so` في المسارات المعيارية أو مسار `LD_LIBRARY_PATH`.
- **الإصلاح الفعلي:**
  - إنشاء أداة الفحص المؤتمتة `tool/test_objectbox.sh`.
  - الأداة تتحقق من المعمارية (`x86_64` أو `aarch64`)، وتجلب أرشيف C Runtime الرسمي للإصدار المثبت `5.3.2` مع التحقق الصارم من تجزئة SHA-256 (`6dbb5450...` لـ x64).
  - يتم فك الضغط في مجلد مؤقت يتم تنظيفه فور انتهاء الاختبار عبر `trap EXIT`، وتمرير المسار لـ`LD_LIBRARY_PATH`.
  - لا توجد أي ملفات ثنائية غير متتبعة داخل المستودع.
  - النتيجة: **8/8 اختبارات ناجحة بنسبة 100%**.

### 2.5 فروقات اختبارات Golden الخمسة (Step 05 / Gate 05)
- **العيب:** فشل 5 اختبارات Golden في `packages/app_ui`:
  1. `app_button_light`
  2. `app_button_dark`
  3. `app_error_view_light`
  4. `app_error_view_dark`
  5. `app_bottom_navigation_center_action`
- **السبب الجذري:**
  - في `app_adaptive_scaffold.dart`: كان لون سطح `Material` لزر الإجراء المركزي يُحسب كـ`surface.withValues(alpha: 0)`، مما أدى لاختلاف قنوات RGB في البكسلات الشفافة مقارنة بالمرجع الصارم.
  - في بيئة الاختبار: كانت الخطوط النصية تُعرض دون تحميل عائلة خطوط محددة وثابتة عبر المنصات، مما سبب تفاوتات طفيفة في التنعيم والحدود.
- **الإصلاح الفعلي:**
  - تعديل لون `Material` في `packages/app_ui/lib/src/widgets/app_adaptive_scaffold.dart` لضبط قنوات الألوان الصفرية الصريحة للشفافية.
  - تحميل خط DejaVu Sans المعياري وأيقونات FontAwesome بشكل صريح وقطعي داخل `setUpAll` في `core_widgets_golden_test.dart`.
  - تحديث الصور المرجعية المطابقة للنظام التصميمي.
  - النتيجة: **15/15 اختبار Golden ناجحة بالكامل**.

### 2.6 إخفاق بناء Android Debug في CI (Step 06)
- **العيب:** فشل job بناء Android Debug في GitHub Actions بـ exit code 127.
- **السبب الجذري:** كان ملف `android/.gitignore` يتجاهل `gradlew` و`gradlew.bat` و`gradle-wrapper.jar`.
- **الإصلاح الفعلي:** إزالة هذه الملفات من `.gitignore` وتتبع ملفات Gradle Wrapper الرسمية القابلة للتنفيذ.

### 2.7 تصحيح اختبار عدم الانحدار في المشاريع المولدة
- **العيب:** فشل اختبار `foundation_phase02_regression_test.dart` في المشاريع المولدة بدون محرك المستندات.
- **السبب الجذري:** كان الاختبار يفحص `isTemplate` عبر مطابقة النص `'name: flutter_starter_template'` في `pubspec.yaml`، والذي كان يتم استبداله بواسطة الـCLI باسم المشروع الجديد (`name: nodocapp`)، مما جعل الاختبار يعتقد خطأ أنه يعمل في قالب التأسيس وليس في مشروع مولّد.
- **الإصلاح الفعلي:** تحديث الاختبار ليعتمد على وجود `.gitmodules` (الموجود حصرًا في مستودع القالب الأساسي ويُزال دائمًا في المشاريع المولدة)، والتأكد من التحقق من وجود الحزم الاختيارية قبل إلزام وجود مندوبيها.

---

## 3. نتائج مصفوفة الاختبار والتحقق الشامل

### 3.1 التحليل الساكن واختبارات الجودة
- `flutter analyze` (المشروع الرئيسي): **PASS (0 issues)**.
- `dart analyze --fatal-infos` (`published/cli`): **PASS (0 issues)**.
- `dart test` (`published/cli`): **PASS (278/278 passed)**.
- `flutter test test/architecture`: **PASS (104/104 passed)**.
- `packages/database_drift`: **PASS (8/8 passed)**.
- `packages/database` (ObjectBox via `tool/test_objectbox.sh`): **PASS (8/8 passed)**.
- `packages/app_ui` (Golden suite): **PASS (15/15 passed)**.

### 3.2 نتائج مصفوفة توليد مشاريع CLI

| السيناريو | الأعلام المستخدمة | نتيجة التوليد | Document Engine | Document Center | `enforce-lockfile` | Analyze & Tests |
|---|---|:---:|:---:|:---:|:---:|:---:|
| **1. دون الحزمتين** | `--no-document-engine` | **PASS (0)** | محذوف | محذوف | **PASS** | **102/102 PASS** |
| **2. المحرك فقط** | `--no-document-center` | **PASS (0)** | موجود | محذوف | **PASS** | **PASS** |
| **3. الحزمتان معًا** | افتراضي / صريح | **PASS (0)** | موجود | موجود | **PASS** | **PASS** |
| **4. رفض المركز دون المحرك** | `--document-center --no-document-engine` | **مرفوض فورًا (1)** | - | - | - | - |
| **5. مشروع Minimal** | `--minimal` | **PASS (0)** | محذوف تلقائيًا | محذوف تلقائيًا | **PASS** | **PASS** |

### 3.3 حالة Android Release Guard (Step 07)
- تنفيذ `flutter build apk --release --flavor prod --dart-define-from-file=env/prod.json`:
  - النتيجة: **فشل آمن ومقصود (Fail-Closed)** برسالة:
    `Production release signing is not configured. Copy android/key.properties.example to android/key.properties and configure the upload keystore.`
  - اختبار `android_dependency_resolution_test.dart`: يثبت عدم الرجوع إطلاقًا إلى مفاتيح الـDebug في وضع الإنتاج.
  - التوقيع الحقيقي والتحقق من شهادة الـAPK للإنتاج: **BLOCKED** لعدم وجود المفاتيح الحقيقية للمستخدم (مطلوبة لأغراض أمنية خارج المستودع).

---

## 4. الملفات المعدلة وغير المتتبعة

### الملفات المعدلة في المشروع الرئيسي (`flutter-starter-template`):
1. `.github/workflows/ci.yml`: تحديث مسار الفحص والـSubmodules، وتكامل اختبارات ObjectBox واختبارات الـGolden واستنساخ الـCLI.
2. `android/.gitignore`: إتاحة تتبع ملفات Gradle Wrapper (`gradlew`, `gradlew.bat`, `gradle-wrapper.jar`).
3. `lib/app/di/injection.dart`: إضافة sentinels لعزل `document_engine` و`document_center`.
4. `lib/app/features.dart`: إضافة sentinels لعزل ميزة `document_center`.
5. `pubspec.yaml`: إضافة sentinels لعزل حزمتي المستندات في الـworkspace والـdependencies.
6. `packages/app_ui/lib/src/widgets/app_adaptive_scaffold.dart`: تصحيح لون سطح زر الإجراء المركزي الشفاف.
7. `packages/app_ui/test/widgets/golden/core_widgets_golden_test.dart`: تهيئة تحميل خط DejaVu وFontAwesome لاختبارات الـGolden.
8. `packages/app_ui/test/widgets/golden/goldens/*.png`: تحديث الصور المرجعية لاختبارات الـGolden.
9. `test/architecture/foundation_phase01_regression_test.dart`: حماية اختبارات الملفات في حال استبعاد حزمة المستندات.
10. `test/architecture/foundation_phase02_regression_test.dart`: تصحيح منطق اكتشاف بيئة القالب مقابل المشاريع المولدة.
11. `test/architecture/foundation_phase04_ui_guardrails_test.dart`: عزل فحوصات نصوص Document Center في حال استبعادها.
12. `test/architecture/package_layering_test.dart`: إضافة sentinels لحزم المستندات في مصفوفة الطبقات.

### الملفات الجديدة غير المتتبعة في المشروع الرئيسي:
1. `android/gradle/wrapper/gradle-wrapper.jar`
2. `android/gradlew`
3. `android/gradlew.bat`
4. `tool/test_objectbox.sh`

### الملفات المعدلة في المستودع الفرعي (`published/cli`):
1. `README.md`: توثيق خيارات `--document-engine` و`--document-center` وسلوك استبعاد الميزات التوضيحية وتجديد الـlockfile.
2. `lib/flutter_starter_template_cli.dart`: تصدير وحدات `documents.dart` و`lockfile.dart`.
3. `lib/src/commands/create_command.dart`: دعم أعلام المستندات واستدعاء التشكيل والتحقق من الـlockfile.
4. `lib/src/create_compatibility.dart`: فرض قواعد توافق أعلام المستندات مع `--minimal` ومع بعضها.
5. `test/create_compatibility_test.dart`: اختبارات توافق ورفض تركيبات الأعلام.
6. `lib/src/rewrite/documents.dart` (جديد): معالجة إزالة مناطق وحزم المستندات.
7. `lib/src/rewrite/lockfile.dart` (جديد): دورة تجديد وفرض ملف القفل للمشاريع المولدة.
8. `test/documents_rewrite_test.dart` (جديد): اختبارات عدم انحدار معالجة المستندات.
9. `test/lockfile_reproducibility_test.dart` (جديد): اختبارات دورة حياة الـlockfile.

---

## 5. الإجراءات المحددة التي تتطلب موافقة المستخدم الصريحة

وفقًا لقواعد السلامة المعمارية (قاعدة رقم 4: *ممنوع إنشاء Commit أو Push دون موافقة صريحة*):

### الإجراء الأول: حفظ ودفع تعديلات المستودع الفرعي `published/cli`
الـcommits الحالية غير المنشورة في الـCLI هي:
- `cb9d34d feat: add package and feature lifecycle tooling`
- `fee6cf2 feat: complete package lifecycle remediation`
بالإضافة إلى التعديلات غير المسجلة الخاصة بـ Step 02 وStep 03.

**الأوامر المقترحة للتنفيذ (تنتظر موافقتك):**
```bash
# 1. إنشاء commit بالتعديلات المحلية في الـ CLI
cd published/cli
git add .
git commit -m "feat: add optional document package scaffolding and lockfile reproducibility"

# 2. دفع التغييرات إلى فرع مستقل على الريموت
git push origin HEAD:refs/heads/feat/foundation-certification
```
*ملاحظة:* بمجرد دفع هذا الفرع، يصبح بإمكان أي Clean Checkout استرجاع الـCommit عبر الـSHA بشكل فوري ومستقر.

### الإجراء الثاني: حفظ ودفع تعديلات المشروع الرئيسي `flutter-starter-template`
**الأوامر المقترحة للتنفيذ (تنتظر موافقتك):**
```bash
# 1. تحديث مؤشر submodule بعد Commit الـ CLI
git add published/cli

# 2. إضافة التعديلات المحلية وملفات الأدوات
git add .
git commit -m "fix: resolve foundation certification blockers for CI, objectbox, goldens, and document scaffolding"

# 3. دفع التحديثات إلى فرع feat/document-engine
git push origin feat/document-engine
```

---

## 6. البنود التي تبقى BLOCKED إلى حين توفر متطلبات خارجية

1. **Gate 01 (Clean Remote Checkout):** يظل **BLOCKED** ماديًا حتى يتم تنفيذ الـPush للمستودع الفرعي إلى GitHub بموافقة المستخدم. بمجرد تنفيذ الـPush، يتحول فورًا إلى **PASS**.
2. **Gate 06 / Android Release Keystore Verification:** يظل **BLOCKED** عمدًا لحماية أسرار المستخدم، مع إثبات أن النظام محمي بصيغة Fail-Closed تمنع تسرب أي Debug Signing إلى الإنتاج.
3. **GitHub Actions CI Run:** يظل بانتظار الـPush للفرع الرئيسي لتسجيل تشغيل ناجح للـHEAD الجديد في خوادم GitHub Actions.

