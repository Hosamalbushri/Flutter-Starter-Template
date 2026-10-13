import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_contracts/shared_contracts.dart';

/// Shared visual vocabulary for collections so both the collections feature and
/// the home dashboard render identical icon/color cards without one feature
/// importing the other's presentation layer.

/// A selectable icon + color preset for a collection.
class CollectionVisualOption {
  const CollectionVisualOption({required this.icon, required this.color});

  final FaIconData icon;
  final Color color;

  /// Stable token persisted on the collection, derived from the icon's code
  /// point so it survives JSON/ObjectBox round-trips without depending on
  /// icon-font internals.
  String get token => icon.codePoint.toRadixString(16);
}

/// The fixed set of icon/color presets offered when creating a collection.
const List<CollectionVisualOption> collectionPalette = [
  CollectionVisualOption(
    icon: FontAwesomeIcons.layerGroup,
    color: Color(0xFF6366F1),
  ),
  CollectionVisualOption(
    icon: FontAwesomeIcons.palette,
    color: Color(0xFFEC4899),
  ),
  CollectionVisualOption(
    icon: FontAwesomeIcons.bookOpen,
    color: Color(0xFF0EA5E9),
  ),
  CollectionVisualOption(
    icon: FontAwesomeIcons.screwdriverWrench,
    color: Color(0xFF10B981),
  ),
  CollectionVisualOption(
    icon: FontAwesomeIcons.lightbulb,
    color: Color(0xFFF59E0B),
  ),
  CollectionVisualOption(
    icon: FontAwesomeIcons.heart,
    color: Color(0xFFEF4444),
  ),
  CollectionVisualOption(
    icon: FontAwesomeIcons.briefcase,
    color: Color(0xFF8B5CF6),
  ),
  CollectionVisualOption(
    icon: FontAwesomeIcons.graduationCap,
    color: Color(0xFF14B8A6),
  ),
];

final Map<String, FaIconData> _iconsByToken = {
  for (final option in collectionPalette) option.token: option.icon,
};

/// Resolves a persisted icon `token` back to a `FaIconData`, falling back to a
/// generic collection icon for unknown tokens.
FaIconData collectionIconFor(String token) =>
    _iconsByToken[token] ?? FontAwesomeIcons.layerGroup;

/// Builds the two-stop gradient for a collection card from its seed [color].
List<Color> collectionGradientFor(int color) {
  final seed = Color(color);
  final darker = Color.lerp(seed, Colors.black, 0.28) ?? seed;
  return [seed, darker];
}

/// A gradient card representing a single collection, shared across the
/// collections feature and the home dashboard.
class CollectionCard extends StatelessWidget {
  const CollectionCard({
    super.key,
    required this.collection,
    required this.onTap,
    this.width = 160,
    this.height = 104,
  });

  final CollectionSummary collection;
  final VoidCallback onTap;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    final effectiveHeight = height * (1 + (textScale - 1) * 0.45);

    return Material(
      clipBehavior: Clip.antiAlias,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Ink(
        width: width,
        height: effectiveHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: collectionGradientFor(collection.color),
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FaIcon(
                      collectionIconFor(collection.icon),
                      color: Colors.white,
                      size: AppIconSize.md,
                    ),
                    Text(
                      '${collection.itemCount}',
                      style: context.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Flexible(
                  child: Text(
                    collection.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
