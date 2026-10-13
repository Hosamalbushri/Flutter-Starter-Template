import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../app_ui.dart';

/// Development-only interactive showcase for the shared `app_ui` design system.
///
/// Renders tokens, typography, buttons, text fields, cards, feedback states,
/// skeletons, dialogs, and responsive layout primitives with live controls for:
/// - Light / Dark theme mode
/// - English (`en`, LTR) / Arabic (`ar`, RTL) directionality & copy
/// - Representative viewport widths (`320`, `360`, `390`, `600`, `800`, `1200`)
/// - Text scale factors (`1.0x`, `1.5x`, `2.0x`)
class AppUiShowcaseScreen extends StatefulWidget {
  const AppUiShowcaseScreen({
    super.key,
    this.initialBrightness = Brightness.light,
    this.initialLocale = const Locale('en'),
    this.initialWidth,
    this.initialTextScale = 1,
  });

  final Brightness initialBrightness;
  final Locale initialLocale;
  final double? initialWidth;
  final double initialTextScale;

  static const List<double> representativeWidths = [
    320,
    360,
    390,
    600,
    800,
    1200,
  ];

  static const List<double> textScales = [1, 1.5, 2];

  @override
  State<AppUiShowcaseScreen> createState() => _AppUiShowcaseScreenState();
}

class _AppUiShowcaseScreenState extends State<AppUiShowcaseScreen> {
  late Brightness _brightness = widget.initialBrightness;
  late Locale _locale = widget.initialLocale;
  late double? _selectedWidth = widget.initialWidth;
  late double _textScale = widget.initialTextScale;

  bool get _isArabic => _locale.languageCode == 'ar';

  @override
  Widget build(BuildContext context) {
    final themeData = _brightness == Brightness.dark
        ? AppTheme.dark()
        : AppTheme.light();
    final direction = _isArabic ? TextDirection.rtl : TextDirection.ltr;
    final parentMedia = MediaQuery.of(context);
    final effectiveWidth = _selectedWidth ?? parentMedia.size.width;

    return Theme(
      data: themeData,
      child: Directionality(
        textDirection: direction,
        child: MediaQuery(
          data: parentMedia.copyWith(
            textScaler: TextScaler.linear(_textScale),
            size: Size(effectiveWidth, parentMedia.size.height),
          ),
          child: Builder(
            builder: (innerContext) {
              return AppScaffold(
                title: _isArabic
                    ? 'معرض نظام التصميم (App UI)'
                    : 'App UI Design System Showcase',
                padding: EdgeInsets.zero,
                body: Column(
                  children: [
                    _ShowcaseControlPanel(
                      brightness: _brightness,
                      locale: _locale,
                      selectedWidth: _selectedWidth,
                      textScale: _textScale,
                      onBrightnessChanged: (value) =>
                          setState(() => _brightness = value),
                      onLocaleChanged: (value) =>
                          setState(() => _locale = value),
                      onWidthChanged: (value) =>
                          setState(() => _selectedWidth = value),
                      onTextScaleChanged: (value) =>
                          setState(() => _textScale = value),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: effectiveWidth,
                          ),
                          child: _ShowcaseBody(isArabic: _isArabic),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ShowcaseControlPanel extends StatelessWidget {
  const _ShowcaseControlPanel({
    required this.brightness,
    required this.locale,
    required this.selectedWidth,
    required this.textScale,
    required this.onBrightnessChanged,
    required this.onLocaleChanged,
    required this.onWidthChanged,
    required this.onTextScaleChanged,
  });

  final Brightness brightness;
  final Locale locale;
  final double? selectedWidth;
  final double textScale;
  final ValueChanged<Brightness> onBrightnessChanged;
  final ValueChanged<Locale> onLocaleChanged;
  final ValueChanged<double?> onWidthChanged;
  final ValueChanged<double> onTextScaleChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Material(
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                key: const ValueKey('showcase_theme_light'),
                label: const Text('Light'),
                selected: brightness == Brightness.light,
                onSelected: (_) => onBrightnessChanged(Brightness.light),
              ),
              const SizedBox(width: AppSpacing.xs),
              ChoiceChip(
                key: const ValueKey('showcase_theme_dark'),
                label: const Text('Dark'),
                selected: brightness == Brightness.dark,
                onSelected: (_) => onBrightnessChanged(Brightness.dark),
              ),
              const SizedBox(width: AppSpacing.md),
              ChoiceChip(
                key: const ValueKey('showcase_locale_en'),
                label: const Text('EN (LTR)'),
                selected: locale.languageCode == 'en',
                onSelected: (_) => onLocaleChanged(const Locale('en')),
              ),
              const SizedBox(width: AppSpacing.xs),
              ChoiceChip(
                key: const ValueKey('showcase_locale_ar'),
                label: const Text('AR (RTL)'),
                selected: locale.languageCode == 'ar',
                onSelected: (_) => onLocaleChanged(const Locale('ar')),
              ),
              const SizedBox(width: AppSpacing.md),
              for (final scale in AppUiShowcaseScreen.textScales) ...[
                ChoiceChip(
                  key: ValueKey('showcase_scale_$scale'),
                  label: Text('${scale}x'),
                  selected: textScale == scale,
                  onSelected: (_) => onTextScaleChanged(scale),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              const SizedBox(width: AppSpacing.sm),
              ChoiceChip(
                key: const ValueKey('showcase_width_full'),
                label: const Text('Full'),
                selected: selectedWidth == null,
                onSelected: (_) => onWidthChanged(null),
              ),
              const SizedBox(width: AppSpacing.xs),
              for (final width
                  in AppUiShowcaseScreen.representativeWidths) ...[
                ChoiceChip(
                  key: ValueKey('showcase_width_${width.toInt()}'),
                  label: Text('${width.toInt()}px'),
                  selected: selectedWidth == width,
                  onSelected: (_) => onWidthChanged(width),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ShowcaseBody extends StatelessWidget {
  const _ShowcaseBody({required this.isArabic});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final colorScheme = context.colorScheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _SectionTitle(
          title: isArabic ? 'الألوان الدلالية والرموز' : 'Semantic Tokens',
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _SemanticBadge(
              label: isArabic ? 'نجاح' : 'Success',
              background: semantic.success,
              foreground: semantic.onSuccess,
            ),
            _SemanticBadge(
              label: isArabic ? 'تحذير' : 'Warning',
              background: semantic.warning,
              foreground: semantic.onWarning,
            ),
            _SemanticBadge(
              label: isArabic ? 'معلومات' : 'Info',
              background: semantic.info,
              foreground: semantic.onInfo,
            ),
            _SemanticBadge(
              label: isArabic ? 'خطر' : 'Danger',
              background: colorScheme.error,
              foreground: colorScheme.onError,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _SectionTitle(title: isArabic ? 'الأزرار (AppButton)' : 'Buttons'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppButton(
              label: isArabic ? 'أساسي' : 'Primary',
              icon: FontAwesomeIcons.check,
              onPressed: () {},
            ),
            AppButton(
              label: isArabic ? 'نغمي' : 'Tonal',
              variant: AppButtonVariant.tonal,
              onPressed: () {},
            ),
            AppButton(
              label: isArabic ? 'محدد' : 'Outlined',
              variant: AppButtonVariant.outlined,
              onPressed: () {},
            ),
            AppButton(
              label: isArabic ? 'نصي' : 'Text',
              variant: AppButtonVariant.text,
              onPressed: () {},
            ),
            AppButton(
              label: isArabic ? 'كبير' : 'Large',
              size: AppButtonSize.large,
              icon: FontAwesomeIcons.bolt,
              onPressed: () {},
            ),
            AppButton(
              label: isArabic ? 'معطل' : 'Disabled',
              onPressed: null,
            ),
            AppButton(
              label: isArabic ? 'جاري التحميل' : 'Loading',
              isLoading: true,
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _SectionTitle(
          title: isArabic ? 'حقول الإدخال (AppTextField)' : 'Text Fields',
        ),
        AppTextField(
          label: isArabic ? 'البريد الإلكتروني' : 'Email Address',
          hint: 'user@example.com',
          prefixIcon: FontAwesomeIcons.envelope,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: isArabic ? 'حقل مع خطأ' : 'Field with Error',
          hint: isArabic ? 'أدخل قيمة صالحة' : 'Enter a valid value',
          errorText: isArabic ? 'هذا الحقل مطلوب' : 'This field is required',
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: isArabic ? 'حقل معطل' : 'Disabled Field',
          hint: isArabic ? 'غير قابل للتعديل' : 'Read-only value',
          enabled: false,
        ),
        const SizedBox(height: AppSpacing.xl),
        _SectionTitle(
          title: isArabic ? 'البطاقات والقوائم' : 'Cards & Slidable Lists',
        ),
        AppCard(
          semanticLabel: isArabic ? 'بطاقة تفاعلية' : 'Interactive Card',
          onTap: () {},
          child: Row(
            children: [
              FaIcon(
                FontAwesomeIcons.bookmark,
                size: AppIconSize.md,
                color: context.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic
                          ? 'بطاقة تفاعلية قابلة للنقر'
                          : 'Interactive Tappable Card',
                      style: context.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      isArabic
                          ? 'تتكيف مع عرض الشاشة وتكبير النصوص والاتجاه من اليمين لليسار.'
                          : 'Adapts cleanly across widths, text scales, and RTL/LTR.',
                      style: context.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppSlidable(
          endActions: [
            AppSlidableAction(
              label: isArabic ? 'تعديل' : 'Edit',
              icon: FontAwesomeIcons.pen,
              onPressed: (_) {},
            ),
            AppSlidableAction.delete(
              label: isArabic ? 'حذف' : 'Delete',
              onPressed: (_) {},
            ),
          ],
          child: AppCard(
            child: Text(
              isArabic
                  ? 'عنصر قابل للسحب مع إجراءات'
                  : 'Slidable List Tile with Actions',
              style: context.textTheme.bodyMedium,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _SectionTitle(
          title: isArabic
              ? 'حالات التحميل والفراغ والخطأ'
              : 'Loading, Empty & Error States',
        ),
        AppCard(
          child: Column(
            children: [
              AppLoading(
                label: isArabic ? 'جاري تحميل البيانات...' : 'Loading data...',
              ),
              const Divider(height: AppSpacing.xxl),
              AppEmptyView(
                title: isArabic ? 'لا توجد عناصر بعد' : 'No items yet',
                message: isArabic
                    ? 'أضف عنصراً جديداً للبدء.'
                    : 'Add your first item to get started.',
                action: AppButton(
                  label: isArabic ? 'إضافة عنصر' : 'Add Item',
                  size: AppButtonSize.small,
                  onPressed: () {},
                ),
              ),
              const Divider(height: AppSpacing.xxl),
              AppErrorView(
                title: isArabic ? 'تعذر التحميل' : 'Failed to load',
                message: isArabic
                    ? 'تحقق من اتصالك بالشبكة وحاول مرة أخرى.'
                    : 'Check your network connection and try again.',
                retryLabel: isArabic ? 'إعادة المحاولة' : 'Retry',
                onRetry: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _SectionTitle(
          title: isArabic ? 'الحوارات والهياكل العظمية' : 'Dialogs & Skeletons',
        ),
        AppButton(
          key: const ValueKey('showcase_open_dialog'),
          label: isArabic ? 'فتح حوار التأكيد' : 'Open Confirm Dialog',
          variant: AppButtonVariant.tonal,
          onPressed: () {
            AppConfirmDialog.show(
              context,
              title: isArabic ? 'تأكيد الحذف؟' : 'Confirm deletion?',
              message: isArabic
                  ? 'لا يمكن التراجع عن هذا الإجراء بعد تنفيذه.'
                  : 'This action cannot be undone once confirmed.',
              confirmLabel: isArabic ? 'حذف' : 'Delete',
              cancelLabel: isArabic ? 'إلغاء' : 'Cancel',
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        const SizedBox(
          height: 170,
          child: AppSkeletonList(itemCount: 2),
        ),
        const SizedBox(height: AppSpacing.xl),
        _SectionTitle(
          title: isArabic
              ? 'التخطيط المتجاوب (AppListDetailPane)'
              : 'Responsive Master-Detail (AppListDetailPane)',
        ),
        SizedBox(
          height: 160,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: context.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: AppListDetailPane(
                master: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      isArabic ? 'القائمة الرئيسية' : 'Master Pane',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                detail: context.isMedium
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Text(
                            isArabic ? 'لوحة التفاصيل' : 'Detail Pane',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : null,
                placeholder: Center(
                  child: Text(isArabic ? 'اختر عنصراً' : 'Select an item'),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: context.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SemanticBadge extends StatelessWidget {
  const _SemanticBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDurations.fast,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: context.textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
