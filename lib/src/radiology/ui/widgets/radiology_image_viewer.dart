import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/radiology/models/radiology_models.dart';
import 'package:helty/src/radiology/services/radiology_service.dart';
import 'package:helty/src/radiology/ui/radiology_ui_helpers.dart';
import 'package:printing/printing.dart';

String radiologyImageUploadedLabel(RadiologyImage image) {
  final at = image.uploadedAt;
  final when = at == null || at.isEmpty
      ? '-'
      : DateFormatter.formatFromBackend(at, DateFormatter.dateTime);
  final by = image.uploadedBy?.displayName.isNotEmpty == true
      ? image.uploadedBy!.displayName
      : 'staff';
  return '${image.mimeType ?? 'file'} · $when · $by';
}

Future<Uint8List> loadRadiologyImageBytes(
  RadiologyService service,
  String imageId,
) async {
  final raw = await service.getImageFileBytes(imageId);
  return Uint8List.fromList(raw);
}

void showRadiologyImageExpanded(
  BuildContext context, {
  required RadiologyImage image,
  required Uint8List bytes,
}) {
  final isPdf = radiologyImageIsLikelyPdf(image);
  showDialog<void>(
    context: context,
    builder: (ctx) {
      final size = MediaQuery.sizeOf(ctx);
      return Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          width: size.width * 0.92,
          height: size.height * 0.88,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        image.fileName,
                        style: Theme.of(ctx).textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: isPdf
                    ? PdfPreview(
                        build: (_) async => bytes,
                        canChangePageFormat: false,
                        canChangeOrientation: false,
                        pdfFileName: image.fileName,
                      )
                    : InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4,
                        child: Center(
                          child: Image.memory(bytes, fit: BoxFit.contain),
                        ),
                      ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Loads and previews a single radiology attachment (list or carousel slide).
class RadiologyImageSlide extends StatefulWidget {
  const RadiologyImageSlide({
    super.key,
    required this.service,
    required this.image,
    this.itemLabel,
    this.showHeader = true,
    this.maxPreviewHeight = 240,
    this.compact = false,
    this.onTapWithBytes,
  });

  final RadiologyService service;
  final RadiologyImage image;
  final String? itemLabel;
  final bool showHeader;
  final double maxPreviewHeight;
  final bool compact;

  /// When set, used instead of [showRadiologyImageExpanded] on tap.
  final void Function(BuildContext context, Uint8List bytes)? onTapWithBytes;

  @override
  State<RadiologyImageSlide> createState() => _RadiologyImageSlideState();
}

class _RadiologyImageSlideState extends State<RadiologyImageSlide> {
  Future<Uint8List>? _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = loadRadiologyImageBytes(widget.service, widget.image.id);
  }

  @override
  void didUpdateWidget(covariant RadiologyImageSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image.id != widget.image.id) {
      _bytesFuture = loadRadiologyImageBytes(widget.service, widget.image.id);
    }
  }

  void _onTap(BuildContext context, Uint8List bytes) {
    if (widget.onTapWithBytes != null) {
      widget.onTapWithBytes!(context, bytes);
      return;
    }
    showRadiologyImageExpanded(context, image: widget.image, bytes: bytes);
  }

  String? get _subtitle {
    final parts = <String>[];
    if (widget.itemLabel != null && widget.itemLabel!.isNotEmpty) {
      parts.add(widget.itemLabel!);
    }
    if (widget.showHeader) {
      parts.add(radiologyImageUploadedLabel(widget.image));
    }
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPdf = radiologyImageIsLikelyPdf(widget.image);
    final isRaster = radiologyImageIsLikelyRaster(widget.image);

    if (!isPdf && !isRaster) {
      final child = ListTile(
        leading: Icon(
          Icons.insert_drive_file_outlined,
          color: theme.colorScheme.primary,
        ),
        title: Text(widget.image.fileName),
        subtitle: _subtitle != null ? Text(_subtitle!) : null,
      );
      return widget.compact
          ? child
          : Card(child: child);
    }

    final content = FutureBuilder<Uint8List>(
      future: _bytesFuture,
      builder: (context, snap) {
        if (snap.hasError) {
          return _slideError(theme, 'Could not load file.\n${snap.error}');
        }
        if (!snap.hasData) {
          return _slideLoading(theme);
        }
        final bytes = snap.data!;

        if (isPdf) {
          return _buildPdfPreview(theme, bytes);
        }
        return _buildRasterPreview(theme, bytes);
      },
    );

    if (widget.compact) {
      return content;
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }

  Widget _slideLoading(ThemeData theme) {
    if (widget.compact) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListTile(
      leading: const SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      title: Text(widget.image.fileName),
      subtitle: _subtitle != null ? Text(_subtitle!) : null,
    );
  }

  Widget _slideError(ThemeData theme, String message) {
    if (widget.compact) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListTile(
      leading: Icon(Icons.error_outline, color: theme.colorScheme.error),
      title: Text(widget.image.fileName),
      subtitle: Text(message),
    );
  }

  Widget _buildPdfPreview(ThemeData theme, Uint8List bytes) {
    final pdfHeight = widget.compact ? widget.maxPreviewHeight : 320.0;
    final preview = SizedBox(
      height: pdfHeight,
      child: PdfPreview(
        build: (_) async => bytes,
        canChangePageFormat: false,
        canChangeOrientation: false,
        pdfFileName: widget.image.fileName,
      ),
    );

    if (widget.compact) {
      return Material(
        color: theme.colorScheme.surfaceContainerHighest,
        child: InkWell(
          onTap: () => _onTap(context, bytes),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_compactCaption(theme) != null) _compactCaption(theme)!,
              Expanded(child: preview),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHeader) _listHeader(theme, Icons.picture_as_pdf),
        Material(
          color: theme.colorScheme.surfaceContainerHighest,
          child: InkWell(
            onTap: () => _onTap(context, bytes),
            child: preview,
          ),
        ),
      ],
    );
  }

  Widget _buildRasterPreview(ThemeData theme, Uint8List bytes) {
    final preview = Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: () => _onTap(context, bytes),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: widget.maxPreviewHeight),
          child: Center(
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Preview not available for this file.',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_compactCaption(theme) != null) _compactCaption(theme)!,
          Expanded(child: preview),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHeader) _listHeader(theme, Icons.image_outlined),
        preview,
      ],
    );
  }

  Widget? _compactCaption(ThemeData theme) {
    if (_subtitle == null && widget.image.fileName.isEmpty) return null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.image.fileName,
            style: theme.textTheme.labelLarge,
            overflow: TextOverflow.ellipsis,
          ),
          if (_subtitle != null)
            Text(
              _subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
        ],
      ),
    );
  }

  Widget _listHeader(ThemeData theme, IconData icon) {
    return ListTile(
      dense: true,
      leading: Icon(
        icon,
        color: icon == Icons.picture_as_pdf
            ? theme.colorScheme.error
            : null,
      ),
      title: Text(widget.image.fileName),
      subtitle: _subtitle != null ? Text(_subtitle!) : null,
    );
  }
}

/// Horizontal carousel of radiology attachments for a single order.
class RadiologyImageCarousel extends StatefulWidget {
  const RadiologyImageCarousel({
    super.key,
    required this.service,
    required this.images,
    this.itemLabels = const {},
    this.height = 280,
  });

  final RadiologyService service;
  final List<RadiologyImage> images;
  final Map<String, String> itemLabels;
  final double height;

  @override
  State<RadiologyImageCarousel> createState() => _RadiologyImageCarouselState();
}

class _RadiologyImageCarouselState extends State<RadiologyImageCarousel> {
  late final PageController _pageController;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant RadiologyImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.images.length != widget.images.length) {
      final maxIndex = widget.images.isEmpty ? 0 : widget.images.length - 1;
      if (_index > maxIndex) {
        setState(() => _index = maxIndex);
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_index);
        }
      }
    }
  }

  String? _labelFor(RadiologyImage image) {
    return widget.itemLabels[image.orderItemId];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.images.isEmpty) {
      return Text(
        'No images uploaded for this order yet.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_index + 1} / ${widget.images.length}',
              style: theme.textTheme.labelLarge,
            ),
            Text(
              'Tap image to expand',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: widget.height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.images.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final image = widget.images[i];
                  return RadiologyImageSlide(
                    service: widget.service,
                    image: image,
                    itemLabel: _labelFor(image),
                    showHeader: true,
                    maxPreviewHeight: widget.height - 56,
                    compact: true,
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.images.length, (i) {
            final selected = i == _index;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: selected ? 10 : 6,
                height: selected ? 10 : 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.25),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// Fetches all images for a radiology order (embedded or via listImages).
Future<List<RadiologyImage>> fetchRadiologyOrderImages(
  RadiologyService service,
  RadiologyOrder order,
) async {
  final all = <RadiologyImage>[];
  for (final item in order.items) {
    final embedded = item.images;
    if (embedded != null && embedded.isNotEmpty) {
      all.addAll(embedded);
    } else {
      all.addAll(await service.listImages(item.id));
    }
  }
  return all;
}

Map<String, String> radiologyOrderItemLabels(
  RadiologyOrder order, {
  Map<String, String>? studyNamesByServiceId,
}) {
  return {
    for (final item in order.items)
      item.id: [
        item.studyLabel(namesByServiceId: studyNamesByServiceId),
        if (item.bodyPart != null && item.bodyPart!.trim().isNotEmpty)
          item.bodyPart!.trim(),
      ].join(' · '),
  };
}
