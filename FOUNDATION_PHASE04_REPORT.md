# Foundation Remediation — Phase 04

تاريخ التحقق: 2026-10-20
بيئة التحقق: Flutter 3.44.4، Dart 3.12.2، Linux test host
النطاق: FND-009 إلى FND-013، مع مراجعة متابعة محدودة لضمانات Phase 03. لم تُنفّذ أي أعمال من مرحلة لاحقة.

## 1. الأسباب الجذرية المثبتة

### FND-009 — GoRouter Error Handling

- لم يكن `GoRouter` يملك `errorBuilder` خاصًا بالتطبيق، لذلك كانت المسارات غير المعروفة تعتمد على واجهة الخطأ الافتراضية ولا تقدم مسار استرداد مترجمًا.
- اختبار deep link الدافئ كان يتحقق من واجهة خطأ قديمة، لكنه لم يركّب delegates الترجمة التي تحتاجها واجهة التطبيق الفعلية.

### FND-010 — Android Back Navigation

- الغلاف الجذري لم يكن يميز بين: الرجوع داخل stack فرعي، الرجوع من تبويب ثانوي إلى الرئيسي، ومحاولة الخروج من جذر التطبيق.
- لم يكن Android manifest يصرّح بتفعيل `OnBackInvokedCallback`، لذلك لم يكن تكامل predictive back صريحًا.

### FND-011 — Design Token Violations

- `BookmarkDetailColors` كان نظام ألوان محليًا داخل feature، وفيه قيم `Color(...)` وظلال خارج tokens المشتركة.
- بعض واجهات Document Center استخدمت `Colors.green` و`Colors.blue` مباشرة.
- حجم أيقونة واحد كان رقمًا ثابتًا بدل `AppIconSize`.

### FND-012 — Hardcoded Localization

- احتوت Document Center على تسمية demo ورسائل تقدم ونجاح وفشل ظاهرة للمستخدم داخل Dart.
- كانت بعض الأخطاء تعرض `Exception.toString()` للمستخدم.
- لم تكن placeholders العددية الجديدة والقديمة تصرّح بتنسيق `decimalPattern`.
- تاريخ تفاصيل Bookmark لم يكن يستخدم locale النشط صراحة.

### FND-013 — Document Parsing Performance

- فك CSV/XLSX، واستخراج headers، وبناء خطة الاستيراد القياسية كانت تتم على UI isolate مهما كان حجم الملف.
- كان حد الإدخال 10 MiB موجودًا، لكن لم يوجد سقف افتراضي لعدد الصفوف بعد فك ملف مضغوط مثل XLSX.
- التقاط الأخطاء على الحدود لم يكن يميز بما يكفي بين فشل مستند متوقع وخطأ برمجي يصدر من validator مخصص.

### متابعة Phase 03

- المعاملات المتداخلة كانت تحتاج عقدًا صريحًا للانضمام إلى المعاملة المحيطة بدل فتح معاملة مستقلة قد تتعطل.
- pending sync كان يحتاج إثبات بقاء حالته بعد إغلاق ObjectBox وفتحه مجددًا.
- العلاقات القديمة التي تحتوي Bookmark IDs غير موجودة لم يكن لها إصلاح غير مدمر ومكرر بأمان عند القراءة.

## 2. الملفات التي تغيرت ضمن Phase 04

### التنقل ودورة الرجوع

- `android/app/src/main/AndroidManifest.xml`
- `lib/app/router.dart`
- `lib/app/widgets/app_shell.dart`
- `test/app/router_redirect_test.dart`
- `test/app/deep_link_navigation_test.dart`
- `test/app/app_shell_navigation_test.dart`

### Design System وLocalization

- `packages/features/bookmarks/lib/src/presentation/widgets/bookmark_detail_widgets.dart`
- `packages/features/bookmarks/lib/src/presentation/widgets/detail/bookmark_detail_sections.dart`
- حُذف `packages/features/bookmarks/lib/src/presentation/widgets/detail/bookmark_detail_colors.dart`
- `packages/features/bookmarks/test/presentation/widgets/bookmark_detail_design_test.dart`
- ملفات `packages/features/document_center/lib/src/presentation/bloc/`
- ملفات views المتأثرة داخل `packages/features/document_center/lib/src/presentation/views/`
- اختبارات Document Center المتأثرة
- `packages/localization/lib/l10n/app_en.arb`
- `packages/localization/lib/l10n/app_ar.arb`
- ملفات localization المولدة
- `packages/localization/test/arabic_localization_test.dart`
- `test/architecture/foundation_phase04_ui_guardrails_test.dart`

### Document Engine

- `packages/document_engine/lib/src/csv/csv_import_adapter.dart`
- `packages/document_engine/lib/src/xlsx/xlsx_import_adapter.dart`
- `packages/document_engine/lib/src/import/import_definition.dart`
- `packages/document_engine/test/csv_test.dart`
- `packages/document_engine/test/import_performance_test.dart`

### متابعة سلامة Phase 03

- منسقا الكتابة الذرية واختباراتهما في `packages/database` و`packages/database_drift`
- `packages/features/collections/lib/src/domain/services/collections_membership_service.dart`
- `packages/features/bookmarks/lib/src/data/repositories/bookmarks_repository_impl.dart`
- اختبارات repository وmembership المتأثرة

توجد تعديلات محلية أخرى سابقة مرتبطة بالمراحل 01–03. حُفظت ولم تُستبدل أو تُحذف، ولم يُنشأ commit أو push.

## 3. الإصلاحات المنفذة والعقود المتأثرة

### التنقل

- أضيفت شاشة خطأ مترجمة عبر `GoRouter.errorBuilder` تعرض URI غير المعروف وتوفر عودة صريحة إلى Home.
- لم يتغير عقد deep links أو auth redirects؛ اختبارات cold/warm redirect الحالية بقيت فعالة.
- يستخدم `AppShell` الآن `PopScope<Object?>`:
  - إذا كان navigator الحالي يستطيع الرجوع، يترك النظام ينفذ pop الطبيعي ويحافظ على stack.
  - عند جذر تبويب ثانوي، ينتقل إلى branch الرئيسي دون تكرار صفحة.
  - عند جذر branch الرئيسي، يعرض تأكيد خروج مترجمًا ويمنع تكرار الحوار.
- فُعّل `android:enableOnBackInvokedCallback="true"`. هذا، مع `PopScope` في Flutter 3.44.4، هو التكامل المدعوم حاليًا لمسار Android predictive back.
- عولج انحدار runtime لاحق في زر إضافة Bookmark: أُلغي تسجيل `Hero` ذي الوسم الثابت لأن شاشة الإنشاء لا تحتوي shared-element مقابلًا له. يمنع ذلك تصادم الوسم عندما تحتفظ شجرة shell بأكثر من نسخة انتقالية من الفرع.

### Design System

- أزيل token المحلي `BookmarkDetailColors` كليًا.
- استُخدمت `ColorScheme` و`SemanticColors` و`AppElevation` و`AppIconSize` المشتركة.
- لم تتغير النية البصرية؛ الألوان الدلالية تأتي من theme وتدعم Light/Dark.
- أضيف guard معماري يمنع `Color(0x...)` و`Colors.*` في نطاقي Bookmark Detail وDocument Center، ويمنع إعادة ملف token المحلي.

### Localization

- نُقلت كل النصوص المتأثرة إلى ARB بالإنجليزية والعربية ثم أعيد توليد ملفات l10n.
- تحولت إشعارات وفشل Document Center إلى enums داخل الحالة، وتُترجم فقط في طبقة العرض.
- لم يعد raw engine progress أو `Exception.toString()` يظهر نصًا للمستخدم في المسارات المعدلة.
- تُنسق الأعداد بـ `decimalPattern`، وتواريخ Bookmark بـ locale النشط.
- أضيف guard يمنع `Text('...')` المباشر في presentation الخاصة بـ Document Center.

### Document Engine

- الملفات ذات الحجم `>= 64 KiB` تُفك وتُحلل في `Isolate.run` لكل من CSV وXLSX، ويشمل ذلك header inspection.
- بناء خطة الاستيراد القياسية ينتقل أيضًا إلى isolate عندما لا توجد validators مخصصة.
- validators المخصصة تبقى في caller isolate لأن closures غير قابلة للنقل بأمان، وللحفاظ على عقدها العام دون كسره.
- يبقى حد bytes عند 10 MiB، وأضيف سقف افتراضي مقداره 100,000 صف، ويجري التحقق منه قبل توسيع rows إلى خرائط التطبيق.
- فشل الملف التالف يبقى `DocumentParseFailure` منظمًا، بينما أخطاء البرمجة الصادرة من validator مخصص (مثل `StateError`) لا تُبتلع ولا تتحول تلقائيًا إلى خطأ مستخدم.
- لم تتغير نتائج وسياسات الاستيراد والتصدير الحالية.

### متابعة Phase 03

- العمليات المتداخلة تنضم إلى ambient transaction في ObjectBox وDrift؛ لا تُفتح معاملة مستقلة تدعي ذرية غير حقيقية.
- sync callback لا ينطلق قبل نجاح commit، وحالة pending sync تُكتب ضمن البيانات الملتزم بها.
- إصلاح العلاقات القديمة يزيل IDs غير الموجودة فقط، ويحافظ على IDs الصحيحة وترتيبها، وهو idempotent وغير مدمر.
- لم تُضف migration schema، لذلك لا توجد ترقية مدمرة أو حاجة لخطة استرجاع بيانات في هذه المرحلة.

## 4. نتائج اختبارات التنقل

| السيناريو | النتيجة |
|---|---|
| مسار غير معروف يعرض شاشة مترجمة ومسار استرداد | PASS |
| warm deep link معروف مع back stack صحيح ومنع التكرار | PASS |
| warm deep link غير معروف | PASS |
| الرجوع من صفحة فرعية إلى السابقة | PASS |
| الرجوع من branch ثانوي إلى الرئيسي | PASS |
| تأكيد الخروج من الجذر، cancel ثم confirm | PASS |
| بقاء stacks وحالة التبويبات بعد التبديل وتغير compact/rail | PASS |
| Android predictive-back manifest guard | PASS |

مجموعة اختبارات التنقل المستهدفة: 29/29 ناجحة. مجموعة التطبيق الجذرية الكاملة، التي تشمل اختبارات architecture وnavigation وgolden/widget: 154/154 ناجحة.

## 5. نتائج اختبارات التصميم والترجمة

- Bookmark Detail: 4/4 ناجحة عبر Light/Dark، EN/AR، RTL/LTR، عرض 320×640، وtext scale مقداره 2.0 دون overflow.
- Localization package: 3/3 ناجحة، ومنها تنسيق الأرقام العربية واتجاه RTL وتغطية plural rules.
- Document Center: 16/16 ناجحة، ومنها النص العربي واتجاه RTL والتسمية المترجمة.
- guardrails المعمارية الخاصة بالألوان والنصوص وملف token المحذوف وpredictive back نجحت ضمن مجموعة root.
- `flutter analyze --no-pub`: لا توجد issues.

## 6. قياسات الأداء قبل وبعد

القياسات wall-clock من test host وليست micro-benchmark معزولًا؛ لذلك تُستخدم لاكتشاف الانحدارات الكبيرة وتوثيق الكلفة، لا كـ SLA إنتاجي.

| المدخل | bytes | قبل isolate | تشغيل الاعتماد بعد الإصلاح |
|---|---:|---:|---:|
| CSV، 1,000 صف | 19,795 | 58 ms | 83 ms |
| CSV، 10,000 صف | 217,795 | 113 ms | 243 ms |
| CSV، 50,000 صف | 1,177,795 | 252 ms | 585 ms |
| XLSX، 1,000 صف | 23,632 | 130 ms | 140 ms |
| XLSX، 5,000 صف | 106,238 | 268 ms | 306 ms |

النتيجة الصحيحة: لم يتحسن throughput العام في هذه البيئة؛ ازدادت كلفة wall-clock، وبخاصة CSV، بسبب نسخ البيانات وتهيئة isolate. التحسن المثبت هو عدم حجب caller/UI isolate للملفات الكبيرة؛ اختبار event-loop yield ينجح أثناء التحليل. لذلك لا يدعي الإصلاح تسريع المعالجة، بل يعزل العمل الثقيل ويحمي الاستجابة مع حدود bytes/rows.

Document Engine الكامل: 82/82 ناجحة، وتشمل CSV/XLSX التالفين، حدود الحجم والصفوف، الحفاظ على النتائج، yield، وتمرير خطأ validator البرمجي.

## 7. حدود سلامة البيانات ونتائج متابعة Phase 03

| الضمان | ObjectBox | Drift |
|---|---|---|
| rollback عند فشل بعد كتابة سابقة | PASS | PASS |
| إعادة المحاولة بعد abort | PASS | PASS |
| interruption قبل commit لا يترك صفوفًا | PASS | PASS |
| nested transaction بلا deadlock | PASS | PASS |
| خطأ completion/rollback لا يخفي الخطأ الأصلي | PASS | PASS |
| pending sync يبقى بعد إغلاق/فتح التخزين | PASS، اختبار store فعلي | حالة pending واختبارات commit/queue ناجحة؛ لم يُضف اختبار process-reopen مستقل في هذه المرحلة |

- ObjectBox: 8/8 ناجحة باستخدام المكتبة الأصلية المحلية.
- Drift: 8/8 ناجحة على قاعدة اختبار فعلية مع foreign keys مفعلة.
- Bookmarks: 116/116 ناجحة، ومنها guard يمنع إعادة وسم Hero الثابت لزر الإضافة.
- Collections: 66/66 ناجحة، ومنها إصلاح legacy dangling IDs وحفظ العلاقات الصحيحة.
- Network: 36/36 ناجحة، وتشمل refresh single-flight، عدم إنهاء الجلسة عند network/5xx، وإنهاءها مرة واحدة عند invalid refresh.
- Auth: 63/63 ناجحة، وتشمل تنظيف session والعودة إلى unauthenticated وإمكانية تسجيل الدخول لاحقًا.

لا يدعي اختبار interruption محاكاة kill حقيقي للعملية بين تعليمات native storage؛ ما يثبته هو أن الإلغاء قبل commit لا يترك بيانات staged. ضمان crash atomicity نفسه مفوض لمحرك المعاملة الأصلي لكل backend.

## 8. المخاطر والحدود المتبقية

1. validators المخصصة تعمل على caller isolate حفاظًا على عقد closures؛ validator ثقيل من طرف التطبيق قد يحجب UI. تغيير هذا العقد يحتاج API قابلًا للتسلسل، وهو خارج Phase 04.
2. `Isolate.run` ينسخ bytes والنتائج، لذا قد ترتفع الذاكرة مؤقتًا. حد 10 MiB و100,000 صف يحدان الخطر، لكن لا يوجد قياس RSS على جهاز منخفض الذاكرة ضمن CI الحالي.
3. predictive back تحقق منه على مستوى Widget/Router وmanifest، وليس باختبار instrumentation على جهاز Android فعلي يعرض animation النظام.
4. لم يُحاكَ kill حقيقي للعملية أثناء native commit؛ اختبارات الإلغاء، rollback، restart في ObjectBox، والعقود الأصلية هي حدود الدليل الحالي.
5. إصلاح العلاقات القديمة lazy عند قراءة bookmarks وليس migration شاملة عند startup. هو غير مدمر ومتكرر بأمان، لكن البيانات غير المقروءة بعد الترقية لن تُنظف حتى يمر مسار القراءة.
6. أرقام الأداء تتأثر بحمل test host وJIT؛ المطلوب مستقبلًا benchmark profile-mode على أجهزة ممثلة إذا تقرر وضع SLA زمني أو ذاكرة.

## 9. نتائج الاعتماد والحالة النهائية

الأوامر/المجموعات المعتمدة:

- `flutter analyze --no-pub`: PASS، صفر issues.
- Root Flutter tests: PASS، 154/154.
- Document Engine: PASS، 82/82.
- Document Center: PASS، 16/16.
- Localization: PASS، 3/3.
- Bookmarks: PASS، 116/116.
- Collections: PASS، 66/66.
- ObjectBox database: PASS، 8/8.
- Drift database: PASS، 8/8.
- Network: PASS، 36/36.
- Auth: PASS، 63/63.
- CLI database rewrite: analyze PASS، tests 2/2 PASS.

**حالة اعتماد Phase 04: PASS ضمن الحدود المعلنة أعلاه.**

أسباب اعتماد PASS: عيوب FND-009 إلى FND-013 أُصلحت فعليًا، جميع مجموعات الانحدار المتأثرة نجحت، ولا توجد مخالفة تحليل ساكن. لا يشمل الاعتماد ادعاء تحسن throughput، أو اختبار جهاز Android فعلي، أو ضمانًا يتجاوز معاملات backends الأصلية. لم تُضف dependencies أو features، ولم يُنشأ commit أو push.
