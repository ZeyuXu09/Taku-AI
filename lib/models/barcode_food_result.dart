class BarcodeFoodResult {
  const BarcodeFoodResult({
    required this.barcode,
    required this.productName,
    this.brand,
    this.servingSize,
    this.imageUrl,
    this.calories,
    this.proteinG,
    this.fatG,
    this.carbsG,
    this.basis = 'serving',
  });

  final String barcode;
  final String productName;
  final String? brand;
  final String? servingSize;
  final String? imageUrl;
  final double? calories;
  final double? proteinG;
  final double? fatG;
  final double? carbsG;

  /// `serving` or `100g` — which Open Food Facts fields were used.
  final String basis;

  String get basisLabel =>
      basis == '100g' ? 'Per 100g' : (servingSize ?? 'Per serving');

  BarcodeFoodResult copyWith({
    String? productName,
    String? servingSize,
    double? calories,
    double? proteinG,
    double? fatG,
    double? carbsG,
  }) {
    return BarcodeFoodResult(
      barcode: barcode,
      productName: productName ?? this.productName,
      brand: brand,
      servingSize: servingSize ?? this.servingSize,
      imageUrl: imageUrl,
      calories: calories ?? this.calories,
      proteinG: proteinG ?? this.proteinG,
      fatG: fatG ?? this.fatG,
      carbsG: carbsG ?? this.carbsG,
      basis: basis,
    );
  }
}
