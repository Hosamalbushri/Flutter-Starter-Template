# Flutter Starter Template — Final Foundation Certification

**تاريخ التنفيذ:** 2026-10-21 (Asia/Aden)  
**النطاق:** الفرع المحلي `feat/document-engine` عند
`caa7e2928ac19b9295d93f5e3c7c2261e6694a81`  
**الحالة النهائية:** **FAIL**

## الملخص التنفيذي

لا يمكن اعتماد الأساس الحالي. التحليل الساكن واختبارات التطبيق الجذرية نجحت
محليًا، كما نجحت اختبارات Drift وتدفقات الاستيراد والجلسة والشبكة المحددة،
لكن توجد إخفاقات ومتطلبات إلزامية غير متحققة:

1. مؤشر submodule الخاص بـ`published/cli` هو commit غير منشور على GitHub؛
   الاسترجاع المباشر أعاد `not our ref`. لذلك لا يمكن بناء HEAD من clean
   checkout مستقل.
2. `fst create` لا يقدّم اختيارًا لـDocument Engine أوDocument Center. جميع
   المشاريع الستة المولدة، بما فيها Minimal، احتوت الحزمتين دائمًا، ولذلك
   مصفوفة Gate 02 الإلزامية غير مدعومة.
3. اختبارات ObjectBox الإلزامية فشلت 8/8 لعدم توفر `libobjectbox.so` عند تشغيل
   اختبار package بالطريقة نفسها التي يستخدمها CI للحزم.
4. بقيت خمسة اختبارات Golden في `app_ui` فاشلة محليًا. لم تُحدّث الصور
   المرجعية لإخفاء الفشل.
5. آخر GitHub Actions run منشور للفرع فاشل، والـHEAD المحلي متقدم عنه باثنين من
   الـcommits؛ لا يوجد CI ناجح للـHEAD محل الاعتماد.
6. لم يمكن إثبات توقيع Android Release فعليًا لغياب `key.properties` والـkeystore؛
   تم فقط إثبات الفشل الآمن وعدم الرجوع إلى debug signing.

وفق تعريف الحالة المطلوب، وجود اختبارات إلزامية فاشلة يفرض **FAIL** حتى مع
وجود بنود أخرى حالتها BLOCKED.

## بيئة التنفيذ وحالة Git

- Flutter المحلي: `3.44.4` / Dart `3.12.2`.
- نسخة FVM المستهدفة والمثبتة: Flutter `3.44.0` كما في `.fvmrc`.
- الجهاز الفعلي المتصل: Samsung SM G986U، Android 13 / API 33.
- الفرع: `feat/document-engine`.
- HEAD المحلي: `caa7e2928ac19b9295d93f5e3c7c2261e6694a81`.
- remote branch: `fd9f7430e663def60be8be6aeb789784877823e6`.
- الفرع المحلي متقدم باثنين من الـcommits.
- كان الـworking tree نظيفًا في بداية الاعتماد، بلا ملفات غير متتبعة، وبلغ عدد
  المسارات المتتبعة 1048. التغييرات الحالية هي إصلاح الاعتماد وهذا التقرير.
- لم يُستخدم `git reset` أو`git clean`، ولم يُنشأ commit أوpush.

## Gate 01 — Git and Clean Checkout

**النتيجة: BLOCKED**

### الأدلة

```text
git submodule status
 fee6cf2cbd8c88b8dcd364dec6d5267448984909 published/cli
 7d6c48dbf8b467a5ef57ffcdb57a76a3f49ccba7 published/rev_sync
 6f6c8970f348122ef83b59406a088f36bccadc68 simple_backend_server
```

تم تنفيذ:

```sh
git ls-remote https://github.com/kido-luci/flutter-starter-template-cli.git
git init /tmp/foundation-cert-git.*
git -C /tmp/foundation-cert-git.* fetch --no-tags origin \
  fee6cf2cbd8c88b8dcd364dec6d5267448984909
```

النتيجة المباشرة:

```text
fatal: remote error: upload-pack: not our ref
fee6cf2cbd8c88b8dcd364dec6d5267448984909
```

كما أن صفحة commit العامة تعيد 404. لم يُغيّر مؤشر submodule إلى إصدار أقدم.
محاولتا recursive clone المستقلتان بدأتا، لكنهما عُلّقتا أثناء استرجاع
submodules وأوقفتا بعد إثبات عدم قابلية fetch للـSHA المحدد؛ لم تُحسبا نجاحًا.

جميع ملفات المصدر التي كانت موجودة في الشجرة المحلية كانت متتبعة عند البداية،
ومنها `packages/document_engine/pubspec.yaml`. إلا أن clean checkout للـHEAD لا
يمكن ماديًا إكماله حتى نشر commit الـCLI المشار إليه، ولذلك لم يُنفذ بناء clean
checkout ولم يُعتبر ناجحًا.

## Gate 02 — Optional Package Architecture

**النتيجة: FAIL**

### ما ثبت في المصدر

- `feature_document_center` يعتمد على `document_engine` في pubspec ويستورده.
- لم يُعثر على اعتماد عكسي من `document_engine` إلى`feature_document_center`.
- كلاهما مسجل دائمًا في workspace واعتماديات التطبيق وDI/routes/imports.
- واجهة `fst create --help` و`CreateCommand` لا تحتوي اختيار include/exclude
  لأي منهما.

### مصفوفة التوليد الفعلية

تم توليد ستة مشاريع مستقلة تحت `/tmp/foundation-cli-matrix.*` باستخدام
`--template-path` و`--no-setup`:

| الحالة | نتيجة التوليد | Document Engine | Document Center |
|---|---:|---:|---:|
| default ObjectBox | 0 | موجود | موجود |
| default Drift | 0 | موجود | موجود |
| minimal ObjectBox | 0 | موجود | موجود |
| minimal Drift | 0 | موجود | موجود |
| no Firebase + no backend + JWT + Drift | 0 | موجود | موجود |
| exclusions + no auth + ObjectBox | 0 | موجود | موجود |

بالتالي لا يمكن توليد الحالات الإلزامية التالية عبر CLI الحالي:

- دون الحزمتين.
- Document Engine فقط.
- الحزمتان معًا كاختيار صريح (المتاح حاليًا هو وجودهما الإجباري فقط).
- رفض/تصحيح Document Center بلا Document Engine، لأن هذا الاختيار غير موجود.

هذا ليس حدًا بيئيًا؛ إنه نقص معماري مثبت في واجهة التوليد، ولذلك صُنّف FAIL.

## Gate 03 — CLI Scaffolding

**النتيجة: FAIL**

### نتائج CLI نفسه

```sh
cd published/cli
dart pub get
dart analyze --fatal-infos
dart test
```

- `pub get`: PASS.
- التحليل: PASS، بلا diagnostics.
- الاختبارات: PASS، عددها 266.
- `published/rev_sync`: التحليل PASS والاختبارات 19/19 PASS.

### أوضاع التوليد

الأوضاع الستة المذكورة أعلاه غطت default/minimal، ObjectBox/Drift، تعطيل
Firebase/backend، الاحتفاظ بـJWT auth، تعطيل auth، واستبعاد features. كل عمليات
التوليد نجحت بنيويًا.

`flutter pub get` العادي نجح في المشاريع الستة. لكن:

```sh
flutter pub get --enforce-lockfile
```

نجح فقط في default ObjectBox وفشل في الحالات الخمس المتحوّلة لأن lockfile
الموروث ما زال يحتوي اعتماديات أزيلت أو استبدلت. `pub get` العادي أعاد كتابة
الـlockfile ونجح؛ لذا scaffold المتحوّل ليس reproducible بالـlockfile فور
التوليد.

بدأ `tool/setup.sh --no-hooks --no-backend` للمشروع الافتراضي ونفذ `pub get`
ودخل full workspace codegen، لكنه لم يكتمل ضمن نافذة الاعتماد وأوقف يدويًا بعد
عدة دقائق. لم تُعتبر عمليات analyze/test للمشاريع الستة ناجحة، ولم تُنفذ بعد
عدم اكتمال codegen. هذا قيد موثق، إضافة إلى FAIL مستقل في Gate 02 والـlockfile.

## Gate 04 — Data Integrity

**النتيجة: FAIL**

### Drift

تم التشغيل من داخل `packages/database_drift` باستخدام Flutter 3.44.0:

```sh
flutter test test/app_database_test.dart
```

النتيجة: **8/8 PASS**، وتشمل:

- schema drift وforeign-key enforcement.
- rollback للدفعة الذرية.
- retry بعد فشل commit وانتظار sync لما بعد commit.
- interruption قبل commit.
- nested transaction بلا deadlock.
- الحفاظ على الخطأ الأصلي عند فشل completion/rollback.

### ObjectBox

```sh
cd packages/database
flutter test test/atomic_write_coordinator_test.dart
```

النتيجة: **0/8، FAIL**. فشلت الاختبارات قبل تنفيذ منطقها بسبب:

```text
Failed to load dynamic library 'libobjectbox.so'
```

وهذا يمنع إثبات atomicity، nested transactions، serialization، وpending-sync
durability عبر restart على ObjectBox. لم تُضف package أومكتبة نظام لتجاوز
المشكلة.

### اختبارات التكامل المنطقي المحددة

- Bookmarks import/repository: 33/33 PASS؛ تشمل rollback للعلاقات والإلغاء
  والدفعات والمزامنة بعد commit.
- Collections import/membership/repository: 24/24 PASS؛ تشمل referential
  integrity وإصلاح dangling legacy IDs والrollback والمزامنة.
- Network token refresh/retry/session notifier: 19/19 PASS؛ تشمل single-flight
  refresh، إنهاء الجلسة مرة واحدة، network/5xx handling، وإعادة المحاولة
  الآمنة.
- Auth repository/session: 19/19 PASS؛ تشمل sign-out/expiry/session restoration.
- `rev_sync`: 19/19 PASS؛ تشمل retry/backoff وstop أثناء retry وoffline sync.

نجاح هذه الاختبارات لا يعوض فشل حزمة ObjectBox الفعلية.

## Gate 05 — Navigation and UI

**النتيجة: BLOCKED مع اختبارات محلية ناجحة جزئيًا**

### نجح محليًا

- `flutter test` من الجذر: 154/154 PASS، ويشمل root Golden tests.
- اختبارات back stack، warm/cold deep links، auth redirects، unknown routes،
  والخروج بعد تأكيد متعدد الخطوات ضمن مجموعة الجذر: PASS.
- `app_ui` دون Golden: 149/149 PASS بعد الإصلاح أدناه.
- المصفوفة تغطي 320/360/390/600/840/1200، RTL/LTR، text scale حتى 2.0،
  Light/Dark، design tokens، localization، وreduced motion.
- manifest يحتوي `android:enableOnBackInvokedCallback="true"`.

### لم يمكن إثباته

- الجهاز الفعلي هو API 33، لكن `adb settings get global enable_back_animation`
  أعاد `0`. لم يُغيّر إعداد جهاز المستخدم، ولذلك لم ينفذ Predictive Back gesture
  فعليًا ولم يُعتبر ناجحًا.
- E2E الحقيقي لم يُنفذ: harness الحالي يتطلب iOS Simulator مع Firebase config
  وbackend على localhost، ولا يوجد iOS target في البيئة. وجود Android فعلي لا
  يحقق متطلبات harness الحالية.

### إصلاح مثبت نُفذ

اختبار `light and dark mode theme token and contrast integration` فشل لأن
`Material.color` لزر الإجراء المركزي كان لون surface بقيمة alpha صفر، لا
`Colors.transparent` حرفيًا. عُدّل موضع Material المثبت في
`packages/app_ui/lib/src/widgets/app_adaptive_scaffold.dart`. بعد ذلك:

- الاختبار المستهدف: PASS.
- جميع اختبارات `app_ui` غير Golden: 149/149 PASS.
- التحليل الساكن: PASS.

لم تُعدّل الاختبارات أوتوقعاتها.

## Gate 06 — Performance and Security

**النتيجة: BLOCKED**

### CSV/XLSX

```sh
cd packages/document_engine
flutter test test/import_performance_test.dart
```

على Flutter 3.44.0:

- CSV 1,000 صف: 62 ms.
- CSV 10,000 صف: 219 ms.
- CSV 50,000 صف: 476 ms.
- XLSX 1,000 صف: 140 ms.
- XLSX 5,000 صف: 303 ms.
- الاختبارات الأربعة: PASS.

تشغيل sampling مستقل أعطى peak مباشرًا تقريبيًا قدره 875,492 KiB، لكنه يشمل
Flutter tool وflutter_tester وليس parser وحده؛ لذلك هو upper bound خشن وليس
قياس استهلاك ذاكرة صالحًا لاعتماد parser. لا يوجد baseline أوbudget لذا لم
يُعتبر شرط الذاكرة ناجحًا.

الحدود الافتراضية مثبتة ومختبرة:

- أقصى ملف: 10 MiB قبل فك الترميز.
- أقصى صفوف: 100,000.
- اختبارات تجاوز file/row limits: PASS.
- الملفات الكبيرة تنتقل إلى isolate عند 64 KiB، واختبار yield: PASS.

### Android Release

```sh
flutter build apk --release --flavor prod \
  --dart-define-from-file=env/prod.json
```

فشل كما ينبغي قبل البناء:

```text
Production release signing is not configured.
```

لا يوجد `android/key.properties` أوkeystore، ولا يوجد fallback إلى debug
signing. هذا يثبت fail-closed فقط؛ التوقيع الحقيقي والتحقق من شهادة APK لم
يمكن تنفيذهما، لذلك البند BLOCKED.

### الأسرار والبيئة

- لا توجد keystore أوFirebase credential متتبعة.
- `.gitignore` يغطي `key.properties` وkeystore وGoogle service files وFastlane
  `.env` مع السماح بملفات example فقط.
- ملفات `env/*.json` تحتوي المفاتيح:
  `FLAVOR`, `FIREBASE_ENABLED`, `API_BASE_URL`, `API_TIMEOUT_SECONDS`.
- لم يكشف الفحص المحدود للأنماط المعروفة private keys/API tokens داخل المصدر
  الإنتاجي. التطابق الوحيد كان نص guard/pattern داخل CI، وليس secret.

## Gate 07 — CI Certification

**النتيجة: FAIL**

### محلي

- `flutter pub get`: PASS.
- `flutter analyze --fatal-infos`: PASS قبل الإصلاح وبعده.
- root tests: 154/154 PASS.
- CLI: 266/266 PASS.
- rev_sync: 19/19 PASS.
- Drift: 8/8 PASS.
- حزم البيانات/الشبكة/auth المحددة: PASS كما سبق.
- ObjectBox: 8 failures بسبب native library.
- `app_ui` Golden: بقيت خمسة failures:
  `app_button_light`, `app_button_dark`, `app_error_view_light`,
  `app_error_view_dark`, و`app_bottom_navigation_center_action`.
  الفروقات المسجلة تراوحت من 0.06% إلى1.81% في المخرجات الظاهرة.
- لم تُستخدم `--update-goldens`.

### GitHub Actions

آخر run عام ظاهر للفرع هو
[CI #2 عند fd9f743](https://github.com/Hosamalbushri/Flutter-Starter-Template/actions/runs/39186695490)،
وحالته **Failure** بتاريخ 2026-10-19. من أدلته المنشورة:

- 26 errors.
- جميع jobs الخاصة بـCLI scaffold/CLI quality فشلت exit 128، متسقة مع submodule
  غير القابل للاسترجاع.
- Analyze & Test فشل بسبب generated DI modules غير محدثة عند ذلك commit.
- Golden tests على macOS: 0 passed و9 failed.
- Android debug job فشل exit 127.

الـcommits المحليان `0c755c3` و`caa7e29` غير منشورين على branch remote، لذلك
لا يوجد workflow run للـHEAD الحالي. لم يُنفذ push أوworkflow dispatch لعدم
وجود إذن، كما أن `gh` غير مثبت. نجاح محلي لا يعوض هذا الفشل.

## المشاكل المكتشفة والإصلاحات

| المشكلة | التصنيف | الإجراء |
|---|---|---|
| CLI submodule SHA غير منشور | مانع | موثق فقط؛ لم يُرجع المؤشر |
| Document Engine/Center إجباريان في كل scaffold | عيب معماري | موثق؛ يحتاج remediation في CLI/template |
| lockfile stale في 5 أوضاع متحوّلة | عيب reproducibility | موثق؛ `pub get` العادي يصلحه، enforce يفشل |
| ObjectBox package tests لا تجد native library | اختبار إلزامي فاشل | موثق؛ لم تُضف dependency |
| Material alpha-zero ليس transparent contract | عيب مثبت | أُصلح موضع زر الإجراء المركزي واختُبر |
| خمسة Golden mismatches | اختبارات فاشلة | لم تُقبل baselines الجديدة |
| لا release keystore | مانع تحقق | fail-closed مثبت؛ التوقيع الفعلي غير منفذ |
| لا Predictive Back فعلي ولاE2E مناسب | مانع تحقق | موثق، غير محسوب PASS |

## المخاطر المتبقية

- لا يمكن لأي مستهلك إعادة تكوين HEAD من GitHub حتى نشر CLI SHA.
- خيارات document packages لا تطابق القرار المعماري الإلزامي.
- CI للـHEAD غير موجود، وآخر CI المتاح فاشل.
- مسار test لكل package قد يفشل في CI عند ObjectBox native loading.
- Golden baselines غير متوافقة مع التشغيل الحالي/بيئة macOS المستهدفة حسب آخر
  run منشور.
- لا يوجد إثبات release artifact موقع أوcertificate verification.
- لا يوجد قياس ذاكرة parser معزول مقابل budget معتمد.
- لا يوجد device-level evidence لـPredictive Back أوE2E الكامل.

## قرار الاعتماد

**FAIL — المشروع غير معتمد تأسيسيًا وغير مثبت الجاهزية للإنتاج.**

أقصر مسار لإعادة الاعتماد هو: نشر commit الـCLI المحدد، إضافة مصفوفة اختيار
Document Engine/Center مع dependency correction، معالجة lockfile عند rewrite،
تشغيل ObjectBox tests مع native runtime صحيح من دون خرق سياسة الاعتماديات،
حسم Golden baselines على macOS CI، توفير release signing credentials في بيئة
آمنة، ثم تشغيل workflow كاملة وdevice E2E/Predictive Back وإرفاق الأدلة.
