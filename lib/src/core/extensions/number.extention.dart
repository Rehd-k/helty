import 'package:intl/intl.dart';

extension FinancialFormatting on num {
  String toFinancial({bool isMoney = false}) {
    if (isMoney) {
      return NumberFormat.currency(
        locale: 'en_NG',
        symbol: 'NGN ',
        decimalDigits: 2,
      ).format(this);
    }

    return NumberFormat('#,##0.00', 'en_NG').format(this);
  }
}
