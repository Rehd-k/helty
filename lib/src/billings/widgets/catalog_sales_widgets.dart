import 'package:flutter/material.dart';
import 'package:helty/src/core/extensions/number.extention.dart';

/// Tap-to-edit quantity field used in catalog sales carts (pharmacy + purchases).
class QuantityEditor extends StatefulWidget {
  const QuantityEditor({
    super.key,
    required this.quantity,
    required this.maxQuantity,
    required this.onChanged,
  });

  final int quantity;
  final int maxQuantity;
  final ValueChanged<int> onChanged;

  @override
  State<QuantityEditor> createState() => _QuantityEditorState();
}

class _QuantityEditorState extends State<QuantityEditor> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.quantity.toString());
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _commitValue();
      }
    });
  }

  @override
  void didUpdateWidget(covariant QuantityEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quantity != widget.quantity) {
      if (_controller.text != widget.quantity.toString()) {
        _controller.text = widget.quantity.toString();
      }
    }
  }

  void _commitValue() {
    final parsed = int.tryParse(_controller.text);
    if (parsed != null && parsed >= 0) {
      final clamped = parsed.clamp(0, widget.maxQuantity);
      widget.onChanged(clamped);
      _controller.text = clamped.toString();
    } else {
      _controller.text = widget.quantity.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 4),
          border: InputBorder.none,
        ),
        onSubmitted: (_) => _commitValue(),
      ),
    );
  }
}

class CatalogSalesQtyButton extends StatelessWidget {
  const CatalogSalesQtyButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.colorScheme,
  });

  final IconData icon;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: colorScheme.onSurface),
      ),
    );
  }
}

/// Single cart line: title, optional subtitle, qty controls, line total.
class CatalogSalesCartRow extends StatelessWidget {
  const CatalogSalesCartRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.quantity,
    required this.maxQuantity,
    required this.unitPrice,
    required this.onDecrement,
    required this.onIncrement,
    required this.onQuantityChanged,
    required this.colorScheme,
  });

  final String title;
  final String? subtitle;
  final int quantity;
  final int maxQuantity;
  final double unitPrice;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final ValueChanged<int> onQuantityChanged;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final lineTotal = unitPrice * quantity;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              CatalogSalesQtyButton(
                icon: Icons.remove,
                onTap: onDecrement,
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 8),
              QuantityEditor(
                quantity: quantity,
                maxQuantity: maxQuantity,
                onChanged: onQuantityChanged,
              ),
              const SizedBox(width: 8),
              CatalogSalesQtyButton(
                icon: Icons.add,
                onTap: onIncrement,
                colorScheme: colorScheme,
              ),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              lineTotal.toFinancial(isMoney: true),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}

/// Cart panel shell with header, column labels, and scrollable lines.
class CatalogSalesCartPanel extends StatelessWidget {
  const CatalogSalesCartPanel({
    super.key,
    required this.colorScheme,
    required this.itemColumnLabel,
    required this.isEmpty,
    required this.onClear,
    required this.itemCount,
    required this.itemBuilder,
  });

  final ColorScheme colorScheme;
  final String itemColumnLabel;
  final bool isEmpty;
  final VoidCallback onClear;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Current Order',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: isEmpty ? null : onClear,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Clear All'),
                style: TextButton.styleFrom(foregroundColor: colorScheme.error),
              ),
            ],
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    itemColumnLabel,
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      'QUANTITY',
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'PRICE',
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isEmpty
                ? Center(
                    child: Text(
                      'Cart is empty',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  )
                : ListView.separated(
                    itemCount: itemCount,
                    separatorBuilder: (_, __) => const Divider(height: 24),
                    itemBuilder: itemBuilder,
                  ),
          ),
        ],
      ),
    );
  }
}

/// Patient card + order summary + primary checkout button.
class CatalogSalesSummaryPanel extends StatelessWidget {
  const CatalogSalesSummaryPanel({
    super.key,
    required this.colorScheme,
    required this.patientIdLabel,
    required this.patientName,
    required this.patientSubtitle,
    required this.subtotal,
    required this.totalAmount,
    required this.checkoutBusy,
    required this.checkoutEnabled,
    required this.onCheckout,
    this.checkoutLabel = 'Send To Bill',
    this.checkoutIcon = Icons.send_and_archive_outlined,
  });

  final ColorScheme colorScheme;
  final String patientIdLabel;
  final String patientName;
  final String patientSubtitle;
  final double subtotal;
  final double totalAmount;
  final bool checkoutBusy;
  final bool checkoutEnabled;
  final VoidCallback onCheckout;
  final String checkoutLabel;
  final IconData checkoutIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                child: Icon(Icons.person, color: colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientIdLabel,
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      patientName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      patientSubtitle,
                      style: TextStyle(fontSize: 12, color: colorScheme.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Order Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        subtotal.toFinancial(isMoney: true),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'TOTAL AMOUNT',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          totalAmount.toFinancial(isMoney: true),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: checkoutEnabled && !checkoutBusy
                        ? onCheckout
                        : null,
                    icon: checkoutBusy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(checkoutIcon),
                    label: Text(
                      checkoutLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Responsive 3-column layout used by pharmacy dispense and purchase sales.
class CatalogSalesLayout extends StatelessWidget {
  const CatalogSalesLayout({
    super.key,
    required this.leftPanel,
    required this.middlePanel,
    required this.rightPanel,
  });

  final Widget leftPanel;
  final Widget middlePanel;
  final Widget rightPanel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        final maxH = constraints.maxHeight;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 5, child: leftPanel),
              const SizedBox(width: 16),
              Expanded(flex: 4, child: middlePanel),
              const SizedBox(width: 16),
              Expanded(flex: 3, child: rightPanel),
            ],
          );
        }

        final leftH = (maxH * 0.45).clamp(320.0, 500.0);
        final midH = (maxH * 0.35).clamp(280.0, 400.0);
        final rightH = (maxH * 0.35).clamp(280.0, 400.0);
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: leftH, child: leftPanel),
              const SizedBox(height: 16),
              SizedBox(height: midH, child: middlePanel),
              const SizedBox(height: 16),
              SizedBox(height: rightH, child: rightPanel),
            ],
          ),
        );
      },
    );
  }
}
