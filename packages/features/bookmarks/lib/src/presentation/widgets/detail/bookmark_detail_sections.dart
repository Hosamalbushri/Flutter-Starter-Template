import 'dart:io';

import 'package:app_platform/app_platform.dart';
import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:localization/localization.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/entities/bookmark.dart';
import '../../bloc/bookmark_detail/bookmark_detail_bloc.dart';
import '../app_video_player.dart';

/// "Source" card: shows the bookmark URL and a button to open it.
class SourceSection extends StatelessWidget {
  const SourceSection({super.key, required this.bookmark});

  final Bookmark bookmark;

  @override
  Widget build(BuildContext context) {
    return DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            icon: FontAwesomeIcons.link,
            label: context.l10n.bookmarkSourceLabel,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            bookmark.url,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.semanticColors.mutedForeground,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SubtleButton(
            label: context.l10n.bookmarkVisitWebsite,
            icon: FontAwesomeIcons.arrowUpRightFromSquare,
            onPressed: () => openBookmarkUrl(context, bookmark),
          ),
        ],
      ),
    );
  }
}

/// "Tags" card: pill chips for each tag.
class TagsSection extends StatelessWidget {
  const TagsSection({super.key, required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            icon: FontAwesomeIcons.tag,
            label: context.l10n.bookmarkTagsLabel,
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final tag in tags)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(
                      color: context.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs + 2,
                    ),
                    child: Text(
                      tag,
                      style: context.textTheme.labelMedium?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Details" card: created / last-modified dates and sync status.
class DetailsSection extends StatelessWidget {
  const DetailsSection({super.key, required this.bookmark});

  final Bookmark bookmark;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat.yMMMd(locale);
    final rows = <DetailRow>[
      DetailRow(
        label: context.l10n.bookmarkDateCreatedLabel,
        value: dateFormat.format(bookmark.createdAt),
      ),
      DetailRow(
        label: context.l10n.bookmarkLastModifiedLabel,
        value: dateFormat.format(bookmark.updatedAt),
      ),
      if (bookmark.isPendingSync)
        DetailRow(
          label: context.l10n.bookmarksNotYetSynced,
          value: '',
          valueIcon: FontAwesomeIcons.solidClock,
        ),
    ];

    return DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            icon: FontAwesomeIcons.circleInfo,
            label: context.l10n.bookmarkDetailsLabel,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < rows.length; i++)
            Container(
              decoration: BoxDecoration(
                border: i == rows.length - 1
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: context.colorScheme.outlineVariant,
                        ),
                      ),
              ),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      rows[i].label,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.semanticColors.mutedForeground,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  if (rows[i].valueIcon != null)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: AppSpacing.xs,
                      ),
                      child: FaIcon(
                        rows[i].valueIcon,
                        size: AppIconSize.xs,
                        color: context.semanticColors.mutedForeground,
                      ),
                    ),
                  if (rows[i].value.isNotEmpty)
                    Flexible(
                      child: Text(
                        rows[i].value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelMedium?.copyWith(
                          color: context.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class DetailRow {
  const DetailRow({required this.label, required this.value, this.valueIcon});

  final String label;
  final String value;
  final FaIconData? valueIcon;
}

/// "Media" card: a grid of attached image thumbnails.
class MediaSection extends StatelessWidget {
  const MediaSection({super.key, required this.bookmark});

  final Bookmark bookmark;

  @override
  Widget build(BuildContext context) {
    return DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            icon: FontAwesomeIcons.images,
            label: context.l10n.bookmarkMediaLabel,
          ),
          const SizedBox(height: AppSpacing.lg),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bookmark.imageUrls.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
            ),
            itemBuilder: (context, index) {
              final path = bookmark.imageUrls[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: path.startsWith('http')
                    ? AppNetworkImage(
                        imageUrl: path,
                        fit: BoxFit.cover,
                        semanticLabel: context.l10n.bookmarkImageLabel(
                          bookmark.title,
                        ),
                      )
                    : Image.file(File(path), fit: BoxFit.cover),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Sticky bottom action bar with the primary "Open in Browser" button.
class OpenInBrowserBar extends StatelessWidget {
  const OpenInBrowserBar({super.key, required this.bookmark});

  final Bookmark bookmark;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surface.withValues(alpha: 0.94),
        boxShadow: AppElevation.cardShadow,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: AppButton(
            label: context.l10n.bookmarkOpenInBrowser,
            icon: FontAwesomeIcons.arrowUpRightFromSquare,
            size: AppButtonSize.large,
            expand: true,
            onPressed: () => openBookmarkUrl(context, bookmark),
          ),
        ),
      ),
    );
  }
}

/// Surface card with the soft ambient shadow used across the detail view.
class DetailCard extends StatelessWidget {
  const DetailCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppElevation.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: child,
      ),
    );
  }
}

/// Icon + title header shared by the detail cards.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.icon, required this.label});

  final FaIconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FaIcon(
          icon,
          size: AppIconSize.sm,
          color: context.colorScheme.primary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelLarge?.copyWith(
              color: context.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

/// Ghost-style button used inside cards (subtle fill, primary text).
class SubtleButton extends StatelessWidget {
  const SubtleButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final FaIconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final primary = context.colorScheme.primary;
    return Material(
      color: context.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelLarge?.copyWith(
                    color: primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FaIcon(icon, size: AppIconSize.xs, color: primary),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> openBookmarkUrl(BuildContext context, Bookmark bookmark) async {
  final uri = Uri.tryParse(bookmark.url);
  if (uri == null || !uri.hasScheme) {
    toast(context, context.l10n.bookmarkInvalidUrl);
    return;
  }
  final bloc = context.read<BookmarkDetailBloc>();
  bool launched;
  try {
    launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Object catch (_) {
    launched = false;
  }
  if (launched) {
    bloc.add(BookmarkDetailUrlOpened(bookmark));
  } else if (context.mounted) {
    toast(context, context.l10n.bookmarkCouldNotOpenUrl);
  }
}

void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class VideoSection extends StatefulWidget {
  const VideoSection({super.key, required this.videoUrl});

  final String videoUrl;

  @override
  State<VideoSection> createState() => _VideoSectionState();
}

class _VideoSectionState extends State<VideoSection> {
  AppVideoPlayerController? _videoPlayerController;

  @override
  void initState() {
    super.initState();
    final service = context.read<VideoPlayerService>();
    final uri = Uri.tryParse(widget.videoUrl);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      _videoPlayerController = service.network(uri);
    } else {
      _videoPlayerController = service.file(File(widget.videoUrl));
    }
    _videoPlayerController?.initialize().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _videoPlayerController;
    if (controller == null) return const SizedBox.shrink();

    return DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            icon: FontAwesomeIcons.film,
            label: context.l10n.bookmarkAttachedVideo,
          ),
          const SizedBox(height: AppSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: AppVideoPlayer(controller: controller),
          ),
        ],
      ),
    );
  }
}
