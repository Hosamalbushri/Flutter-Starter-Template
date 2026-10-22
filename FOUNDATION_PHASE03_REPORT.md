# Flutter Starter Template — Foundation Remediation Phase 03

**التاريخ:** 2026-10-20
**النطاق:** FND-005، FND-006، FND-007 فقط
**الحالة النهائية:** **PASS — مع حدود اختبار موثقة**

## 1. الأسباب الجذرية المثبتة

### FND-006 — سلامة الاستيراد

- كان `beginImportBatch/endImportBatch` يؤجل إطلاق المزامنة فقط؛ لم يكن معاملة قاعدة بيانات.
- كانت كل عملية repository تُكتب وتُعتمد منفردة، ثم يحاول الـ import delegate تعويض العمليات السابقة يدويًا عند الفشل.
- التعويض اليدوي لم يكن ذريًا، وكان يمكن أن يفشل بعد ترك بيانات جزئية أو أن يحجب الخطأ الأصلي.
- لم يكن هناك حد معاملة واحد يشمل إنشاء Bookmark، وإنشاء/تعديل Collection، وربطهما.

### FND-007 — التكامل المرجعي بين Bookmarks وCollections

- تخزن Collection العلاقات كقائمة `bookmarkIds`، ولا يفرض ObjectBox أو Drift قيد foreign key على عناصر هذه القائمة.
- حذف Bookmark، منطقيًا أو نهائيًا أثناء sync، لم يكن يزيل معرّفه من Collections.
- عمليات القراءة-التعديل-الكتابة المتزامنة لم تكن متسلسلة، مما أتاح فقد تحديث أو إعادة علاقة محذوفة.

### FND-005 — دورة حياة الجلسة

- كان `TokenRefresher` يمسح الرموز عند رفض refresh، لكن لم يوجد مسار يوصل انتهاء الجلسة إلى `AuthBloc` و`Session` وGoRouter.
- لذلك أمكن أن تبقى الواجهة في حالة Authenticated بعد زوال الرموز الآمنة.
- لم يكن الفصل صريحًا بين رفض refresh الدال على جلسة منتهية وبين فشل شبكة/5xx المؤقت.
- لم يكن هناك deduplication على مستوى إشعار انتهاء الجلسة، مع أن single-flight كان يمنع بعض طلبات refresh المتكررة فقط.

## 2. الإصلاحات والعقود المعمارية

### Atomic write contract

أضيف `AtomicWriteCoordinator` بتنفيذ مستقل لكل محرك:

- ObjectBox يجمع عمليات الكتابة ثم ينفذها داخل `Store.runInTransaction(TxMode.write, ...)`.
- Drift يجمع العمليات ثم ينفذها داخل `AppDatabase.transaction(...)`.
- الاستدعاءات المتداخلة تنضم إلى نفس وحدة العمل، بينما تُسلسل الوحدات المستقلة لمنع سباقات read-modify-write.
- توفر data sources overlay داخل المعاملة حتى ترى عمليات الاستيراد الكتابات المرحلية قبل commit.
- تُنفذ callbacks الخاصة بالمزامنة بعد نجاح commit فقط.
- عند إخفاق الكتابة ثم إخفاق طبقة المعاملة/rollback، يُعاد طرح خطأ الكتابة الأصلي مع stack trace الأصلي.

أصبح كامل مسار كل import — بما فيه فحص التكرار والكتابة والربط — داخل وحدة عمل واحدة. بقيت سياسة `skip/update/create` دون تغيير، وأزيل التعويض اليدوي من delegates.

### Referential integrity contract

- أضيف `CollectionsMembershipService.removeBookmarkEverywhere`.
- حذف Bookmark المنطقي والنهائي ينظف كل Collections المرئية في نفس المعاملة.
- مسار hard-delete القادم من sync يطبق القاعدة نفسها.
- تحديث Collection وحذف Bookmark متسلسلان عبر المنسق نفسه، لذلك لا يمكن لعملية مستقلة أن تتجاوز read-modify-write الجارية.
- فشل تنظيف العلاقات يلغي حذف Bookmark وبقية الوحدة بدل ترك حالة نصف مكتملة.

### Session termination contract

- أضيف `SessionTerminationNotifier` كقناة موحدة، مع إشعار واحد لكل جيل انتهاء حتى `reset`.
- refresh بلا رمز، أو refresh يرفض بـ 401/403، أو استجابة refresh ناجحة شكليًا لكنها بلا رموز صالحة: يمسح الرموز ويعلن انتهاء الجلسة.
- أخطاء الاتصال و5xx وفشل حفظ الرموز: تبقى أخطاء مؤقتة ولا تنفذ logout.
- `AuthInterceptor` يجرب refresh لطلب API ذي 401 فقط؛ 403 العادي يبقى خطأ صلاحية ولا ينهي الجلسة. أما 401/403 من endpoint الخاص بالـ refresh فهما رفض للجلسة.
- `AuthSession` يحول الإشعار إلى `AuthSessionCleared`، و`AuthBloc` ينفذ `ExpireSessionUseCase` لتنظيف الحالة المحلية الحساسة والانتقال إلى unauthenticated دون استدعاء logout شبكي.
- نجاح refresh أو sign-in/register يعيد فتح جيل الإشعار، بما يسمح بتسجيل الدخول من جديد.
- بقي single-flight في `TokenRefresher`، وثبت أن عدة طلبات تشترك في POST واحد.

## 3. الملفات المتغيرة ضمن Phase 03

### قاعدة البيانات وDI

- `packages/database/lib/src/atomic_write_coordinator.dart`
- `packages/database/lib/database.dart`
- `packages/database/test/atomic_write_coordinator_test.dart`
- `packages/database_drift/lib/src/atomic_write_coordinator.dart`
- `packages/database_drift/lib/database.dart`
- `packages/database_drift/test/app_database_test.dart`
- `lib/core/data/database/object_box_module.dart`
- ملفات DI المولدة في auth/network/bookmarks/collections.
- `published/cli/lib/src/rewrite/database.dart` لضمان أن تحويل المشروع إلى Drift يولد wiring وdata sources مكافئة.

### الاستيراد والعلاقات

- ObjectBox local data sources وrepository implementations في bookmarks وcollections.
- `bookmarks_import_delegate.dart` و`collections_import_delegate.dart`.
- `collections_membership_service.dart`.
- اختبارات repositories/import/widgets ذات الصلة.
- `packages/features/bookmarks/test/atomic.dart`
- `packages/features/collections/test/atomic.dart`
- `packages/features/collections/test/domain/services/collections_membership_service_test.dart`

### المصادقة والشبكة

- `packages/network/lib/src/session_termination_notifier.dart`
- `packages/network/lib/src/token_refresher.dart` وbarrel/DI والاختبارات التابعة.
- `packages/features/auth/lib/src/domain/usecases/expire_session.dart`
- عقد وتنفيذ `AuthRepository`.
- `AuthBloc` و`AuthSession` وDI والاختبارات التابعة.
- `packages/features/auth/test/presentation/auth_session_test.dart`
- `lib/app/app.dart`
- `test/widget_test.dart`

لم تُضف حزم أو dependencies جديدة، ولم يُنشأ commit أو push. بقيت التعديلات المحلية السابقة، بما فيها تغييرات `published/cli` غير المتعلقة بهذه المرحلة، محفوظة.

## 4. ضمانات سلامة البيانات قبل الإصلاح وبعده

| المجال | قبل الإصلاح | بعد الإصلاح |
| --- | --- | --- |
| استيراد عدة صفوف | commits مستقلة وتعويض يدوي best-effort | commit واحد أصلي لكل import داخل المحرك المختار |
| فشل بعد بعض الكتابات | احتمال بيانات جزئية | rollback أصلي يعيد الحالة لما قبل الوحدة |
| التكرارات | سياسة موجودة لكن ضمن كتابات منفصلة | السياسة نفسها داخل الوحدة الذرية |
| sync | batching منطقي دون اقتران مؤكد بالـ commit | لا callback للمزامنة قبل نجاح commit |
| حذف Bookmark | احتمال IDs معلقة داخل Collections | تنظيف كل العلاقات مع الحذف في المعاملة نفسها |
| التزامن | احتمال lost update | تسلسل وحدات read-modify-write المستقلة |
| خطأ rollback | قد يحجب الخطأ الأصلي | يحتفظ المنسق بخطأ الكتابة الأصلي |

الضمان الذري يشمل كل كتابات قاعدة البيانات التي ينفذها import عبر repositories الحالية، سواء كان backend هو ObjectBox أو Drift. لا توجد معاملة موزعة مع خدمات خارجية؛ المزامنة ليست جزءًا من commit بل تبدأ بعده.

## 5. نتائج Failure Injection وإعادة المحاولة

- فشل عملية لاحقة بعد put سابق: أعاد ObjectBox وDrift الحالة إلى صفر صفوف.
- فشل action قبل commit بعد staging: لم تُكتب صفوف.
- retry بعد batch فاشل: نجح وكتب صفًا واحدًا فقط.
- duplicate UUID أثناء commit: فشل كامل الوحدة دون صف جزئي.
- callback المزامنة: صفر استدعاءات عند الفشل، واستدعاء واحد بعد commit الناجح.
- فشل cleanup: لم يحجب خطأ الكتابة الأصلي.
- فشل transaction/rollback مُحقن: لم يحجب خطأ الكتابة الأصلي في المحركين.
- duplicate import بسياسات skip/update/create: بقي السلوك السابق ونجحت اختبارات الاستيراد.

تمت محاكاة انقطاع العملية بصورة معزولة باستثناء يُرمى قبل commit بعد staging. لم يُنفذ اختبار قتل OS/SIGKILL أثناء native commit؛ التعافي في تلك النافذة يعتمد على ضمانات المعاملة الأصلية للمحرك، ولا يدعي هذا التقرير إثبات crash-consistency الفيزيائي خارجها.

## 6. نتائج ObjectBox وDrift

| مجموعة الاختبارات | النتيجة |
| --- | --- |
| ObjectBox atomic coordinator | **6/6 PASS** |
| Drift schema + FK + atomic coordinator | **7/7 PASS** |
| Drift CLI rewrite | **2/2 PASS** |
| تحليل مولد Drift | **No issues** |

احتاج اختبار ObjectBox على Linux إلى `libobjectbox.so` في مسار مؤقت خارج workspace؛ لم تُضف dependency أو artifact إلى المشروع.

## 7. نتائج العلاقات، المصادقة، والمزامنة

| Suite | النتيجة |
| --- | --- |
| bookmarks package | **110/110 PASS** |
| collections package | **65/65 PASS** |
| network package | **36/36 PASS** |
| auth package | **63/63 PASS** |
| root app/architecture/router/widgets | **149/149 PASS** |
| `flutter analyze --no-pub` | **No issues found** |

التغطية المثبتة تشمل Bookmark موجودًا في عدة Collections، الحفاظ على IDs الأخرى، التزامن، refresh منتهي، فشل شبكة و5xx، refresh متزامن single-flight، deduplication، الانتقال الفعلي إلى شاشة الدخول، وإعادة تسجيل الدخول.

## 8. المخاطر والحدود المتبقية

- لا توجد migration رجعية تمسح علاقات يتيمة كانت موجودة في قواعد بيانات قديمة قبل هذا الإصلاح؛ القاعدة الجديدة تمنع إنشاء orphan عبر مسارات الحذف الحالية وتنظف الهدف عند حذفه لاحقًا.
- لم يُحقن قتل عملية حقيقي أثناء استدعاء native commit؛ الاختبارات تثبت حدود التطبيق قبل commit، وأخطاء commit/rollback، ثم تعتمد نافذة crash الداخلية على ACID الخاص بالمحرك.
- لا تشمل الذرية أي side effect خارجي؛ تصميم sync بعد commit مقصود، وقد يحتاج sync إلى retry مستقل إذا تعذر تشغيله بعد نجاح الكتابة.

## 9. حالة الاعتماد

**Phase 03: APPROVED / PASS ضمن الضمانات والحدود أعلاه.**

تمت معالجة FND-005 وFND-006 وFND-007 واختبار ObjectBox وDrift ودورة الجلسة. لم يبدأ أي عمل من Phase 04.
