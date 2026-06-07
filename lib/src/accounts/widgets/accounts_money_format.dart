import 'package:intl/intl.dart';

NumberFormat accountsNairaFormat() => NumberFormat.currency(
      locale: 'en_NG',
      symbol: '₦',
      decimalDigits: 0,
    );

NumberFormat accountsNairaCompactFormat() => NumberFormat.compactCurrency(
      locale: 'en_NG',
      symbol: '₦',
      decimalDigits: 0,
    );
