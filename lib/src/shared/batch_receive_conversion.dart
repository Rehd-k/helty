enum BatchReceiveUnit { unit, pack, carton }

class BatchReceiveConversion {
  BatchReceiveConversion({
    required this.quantityInUnits,
    required this.costPricePerUnit,
  });

  final int quantityInUnits;
  final double costPricePerUnit;

  double get lineTotal => quantityInUnits * costPricePerUnit;

  static double roundPrice(double value) =>
      (value * 10000).roundToDouble() / 10000;

  static BatchReceiveConversion? compute({
    required BatchReceiveUnit receiveUnit,
    required int enteredQuantity,
    required double enteredCostPrice,
    int? unitsPerPack,
    int? packsPerCarton,
    void Function(String message)? onError,
  }) {
    void fail(String message) => onError?.call(message);

    if (enteredQuantity < 1) {
      fail('Enter a valid quantity.');
      return null;
    }
    if (enteredCostPrice <= 0) {
      fail('Enter a valid cost price.');
      return null;
    }

    switch (receiveUnit) {
      case BatchReceiveUnit.unit:
        return BatchReceiveConversion(
          quantityInUnits: enteredQuantity,
          costPricePerUnit: roundPrice(enteredCostPrice),
        );
      case BatchReceiveUnit.pack:
        if (unitsPerPack == null || unitsPerPack < 1) {
          fail('Enter units in one pack (must be at least 1).');
          return null;
        }
        return BatchReceiveConversion(
          quantityInUnits: enteredQuantity * unitsPerPack,
          costPricePerUnit: roundPrice(enteredCostPrice / unitsPerPack),
        );
      case BatchReceiveUnit.carton:
        if (unitsPerPack == null || unitsPerPack < 1) {
          fail('Enter units in one pack (must be at least 1).');
          return null;
        }
        if (packsPerCarton == null || packsPerCarton < 1) {
          fail('Enter packs in one carton (must be at least 1).');
          return null;
        }
        final unitsPerCarton = unitsPerPack * packsPerCarton;
        return BatchReceiveConversion(
          quantityInUnits: enteredQuantity * unitsPerCarton,
          costPricePerUnit: roundPrice(enteredCostPrice / unitsPerCarton),
        );
    }
  }

  /// Converts an entered container price to per-unit price (e.g. pack/carton selling price).
  static double? convertEnteredPriceToUnitPrice({
    required BatchReceiveUnit receiveUnit,
    required double enteredPrice,
    int? unitsPerPack,
    int? packsPerCarton,
  }) {
    if (enteredPrice < 0) return null;

    switch (receiveUnit) {
      case BatchReceiveUnit.unit:
        return roundPrice(enteredPrice);
      case BatchReceiveUnit.pack:
        if (unitsPerPack == null || unitsPerPack < 1) return null;
        return roundPrice(enteredPrice / unitsPerPack);
      case BatchReceiveUnit.carton:
        if (unitsPerPack == null ||
            unitsPerPack < 1 ||
            packsPerCarton == null ||
            packsPerCarton < 1) {
          return null;
        }
        return roundPrice(enteredPrice / (unitsPerPack * packsPerCarton));
    }
  }
}
