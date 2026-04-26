import 'package:intl/intl.dart';

/// Nigerian Naira for CMD surfaces — matches financial command center rules.
NumberFormat cmdNairaFormat() => NumberFormat.currency(
      locale: 'en_NG',
      symbol: '₦',
      decimalDigits: 0,
    );

/// Compact Naira for chart axes (e.g. ₦1.2M).
NumberFormat cmdNairaCompactFormat() => NumberFormat.compactCurrency(
      locale: 'en_NG',
      symbol: '₦',
      decimalDigits: 0,
    );
