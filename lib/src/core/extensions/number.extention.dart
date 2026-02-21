import 'package:intl/intl.dart';

extension FinancialFormatting on num {
  String toFinancial({bool isMoney = false}) {
    final formatter = NumberFormat("#,##0.00", "en_NG");

    final formatted = formatter.format(this);

    if (isMoney) {
      return "₦$formatted";
    }

    return formatted;
  }
}
