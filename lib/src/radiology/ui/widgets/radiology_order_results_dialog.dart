import 'package:flutter/material.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/radiology/models/radiology_models.dart';
import 'package:helty/src/radiology/services/radiology_service.dart';
import 'package:helty/src/radiology/ui/radiology_ui_helpers.dart';
import 'package:helty/src/radiology/ui/widgets/radiology_image_viewer.dart';

void showRadiologyOrderResultsDialog(
  BuildContext context, {
  required RadiologyService service,
  RadiologyOrder? order,
  String? orderId,
  Map<String, String> studyNamesByServiceId = const {},
  bool showEncounterId = false,
}) {
  assert(order != null || (orderId != null && orderId.isNotEmpty));
  showDialog<void>(
    context: context,
    builder: (ctx) => RadiologyOrderResultsDialog(
      service: service,
      order: order,
      orderId: orderId,
      studyNamesByServiceId: studyNamesByServiceId,
      showEncounterId: showEncounterId,
    ),
  );
}

class RadiologyOrderResultsDialog extends StatefulWidget {
  const RadiologyOrderResultsDialog({
    super.key,
    required this.service,
    this.order,
    this.orderId,
    this.studyNamesByServiceId = const {},
    this.showEncounterId = false,
  });

  final RadiologyService service;
  final RadiologyOrder? order;
  final String? orderId;
  final Map<String, String> studyNamesByServiceId;
  final bool showEncounterId;

  @override
  State<RadiologyOrderResultsDialog> createState() =>
      _RadiologyOrderResultsDialogState();
}

class _RadiologyOrderResultsDialogState
    extends State<RadiologyOrderResultsDialog> {
  bool _loading = true;
  String? _error;
  RadiologyOrder? _order;
  List<RadiologyImage> _images = [];
  Map<String, String> _itemLabels = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final order = widget.order ??
          await widget.service.getOrder(widget.orderId!);
      final itemLabels = radiologyOrderItemLabels(
        order,
        studyNamesByServiceId: widget.studyNamesByServiceId,
      );
      final images = await fetchRadiologyOrderImages(widget.service, order);
      if (!mounted) return;
      setState(() {
        _order = order;
        _itemLabels = itemLabels;
        _images = images;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order ?? widget.order;
    final theme = Theme.of(context);
    final firstItem = order?.items.isNotEmpty == true ? order!.items.first : null;
    final titleId = order?.id ?? widget.orderId ?? '';
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final maxContentHeight = (viewportHeight * 0.62).clamp(360.0, 560.0);
    final carouselHeight =
        (maxContentHeight * 0.42).clamp(150.0, 200.0);
    final detailsMaxHeight = maxContentHeight - carouselHeight - 88;

    return AlertDialog(
      title: Text(
        'Order ${titleId.length > 8 ? titleId.substring(0, 8) : titleId}',
      ),
      content: SizedBox(
        width: 520,
        child: _loading
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            : _error != null
                ? Text(
                    _error!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  )
                : ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxContentHeight),
                    child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: detailsMaxHeight),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (order != null) ...[
                                _ResultRow(
                                  label: 'Ordered',
                                  value: DateFormatter.formatFromBackend(
                                    order.createdAt,
                                    DateFormatter.dateTime,
                                  ),
                                ),
                                if (widget.showEncounterId &&
                                    order.encounterId != null &&
                                    order.encounterId!.trim().isNotEmpty)
                                  _ResultRow(
                                    label: 'Encounter',
                                    value: order.encounterId!,
                                  ),
                                _ResultRow(
                                  label: 'Status',
                                  value: orderStatusLabel(order.status),
                                ),
                                _ResultRow(
                                  label: 'Items',
                                  value: '${order.items.length}',
                                ),
                                if (firstItem != null) ...[
                                  _ResultRow(
                                    label: 'Study',
                                    value: firstItem.studyLabel(
                                      namesByServiceId:
                                          widget.studyNamesByServiceId,
                                    ),
                                  ),
                                  if (firstItem.bodyPart != null &&
                                      firstItem.bodyPart!.trim().isNotEmpty)
                                    _ResultRow(
                                      label: 'Area',
                                      value: firstItem.bodyPart!,
                                    ),
                                ],
                                const SizedBox(height: 16),
                                Text(
                                  'Report',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...order.items.map((item) {
                                  final report = item.report;
                                  if (report == null) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: Text(
                                        '${item.scanType.displayLabel}: No signed report yet.',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.7),
                                        ),
                                      ),
                                    );
                                  }
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          item.scanType.displayLabel,
                                          style: theme.textTheme.labelLarge
                                              ?.copyWith(
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          reportPreviewText(report),
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Files',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RadiologyImageCarousel(
                        service: widget.service,
                        images: _images,
                        itemLabels: _itemLabels,
                        height: carouselHeight,
                      ),
                    ],
                  ),
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
