import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:helty/src/app/org_config.dart';
import 'package:helty/src/core/platform/helty_platform.dart';
import 'package:helty/src/printing/escpos/receipt_escpos_service.dart';
import 'package:helty/src/printing/escpos/windows_default_raw_printer.dart';

/// Shows a bottom sheet listing active Windows printers; prints when one is chosen.
Future<void> showReceiptPrinterPickerSheet(
  BuildContext context, {
  required Map<String, dynamic> data,
  ReceiptHospitalHeader? header,
  bool isCopy = false,
  String? logoAssetPath,
  bool askCopyCount = false,
}) async {
  if (!HeltyPlatform.isWindows) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thermal receipt printing is only supported on Windows.'),
      ),
    );
    return;
  }

  final resolvedLogo = logoAssetPath ?? OrgConfig.instance.logoAsset;
  final resolvedHeader = header ?? ReceiptHospitalHeader.fromOrg();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _ReceiptPrinterPickerBody(
      data: data,
      header: resolvedHeader,
      isCopy: isCopy,
      logoAssetPath: resolvedLogo,
      askCopyCount: askCopyCount,
    ),
  );
}

class _ReceiptPrinterPickerBody extends StatefulWidget {
  const _ReceiptPrinterPickerBody({
    required this.data,
    required this.header,
    required this.isCopy,
    required this.logoAssetPath,
    required this.askCopyCount,
  });

  final Map<String, dynamic> data;
  final ReceiptHospitalHeader header;
  final bool isCopy;
  final String logoAssetPath;
  final bool askCopyCount;

  @override
  State<_ReceiptPrinterPickerBody> createState() =>
      _ReceiptPrinterPickerBodyState();
}

class _ReceiptPrinterPickerBodyState extends State<_ReceiptPrinterPickerBody> {
  List<WindowsPrinterInfo>? _printers;
  Object? _loadError;
  bool _printing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _printers = null;
      _loadError = null;
    });
    try {
      final list = await listActiveWindowsPrinters();
      if (!mounted) return;
      setState(() => _printers = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e);
    }
  }

  Future<void> _onSelect(String name) async {
    if (_printing) return;
    setState(() => _printing = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final nav = Navigator.of(context);
    try {
      var copies = 1;
      if (widget.askCopyCount) {
        final chosen = await showDialog<int>(
          context: context,
          builder: (context) => const _ReceiptCopyCountDialog(),
        );
        if (!mounted) return;
        if (chosen == null) return;
        copies = chosen;
      }
      for (var i = 0; i < copies; i++) {
        await ReceiptEscposService.printReceipt(
          data: widget.data,
          header: widget.header,
          sink: ReceiptPrintSink.windowsDefault,
          windowsPrinterName: name,
          isCopy: widget.isCopy,
          logoAssetPath: widget.logoAssetPath,
        );
      }
      if (!mounted) return;
      nav.pop();
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            copies == 1
                ? 'Receipt sent to $name'
                : '$copies copies sent to $name',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger?.showSnackBar(SnackBar(content: Text('Print failed: $e')));
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom + 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Choose printer',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: _printing ? null : _load,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (_loadError != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Could not load printers: $_loadError',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: _printing ? null : _load,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              )
            else if (_printers == null)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_printers!.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No active printers found. Add or connect a printer in Windows Settings.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.55,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _printers!.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final p = _printers![i];
                    return ListTile(
                      enabled: !_printing,
                      leading: Icon(
                        Icons.print_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(p.name),
                      subtitle: p.isDefault
                          ? const Text('Default printer')
                          : null,
                      trailing: _printing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: _printing ? null : () => _onSelect(p.name),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptCopyCountDialog extends StatefulWidget {
  const _ReceiptCopyCountDialog();

  @override
  State<_ReceiptCopyCountDialog> createState() => _ReceiptCopyCountDialogState();
}

class _ReceiptCopyCountDialogState extends State<_ReceiptCopyCountDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? get _copies {
    final count = int.tryParse(_controller.text.trim());
    if (count == null || count < 1) return null;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final copies = _copies;
    return AlertDialog(
      title: const Text('How many copies?'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          labelText: 'Copies',
        ),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: copies == null
              ? null
              : () => Navigator.pop(context, copies),
          child: const Text('Print'),
        ),
      ],
    );
  }
}
