import 'package:intl/intl.dart';

class NutritionLog {
  const NutritionLog({
    required this.id,
    required this.productName,
    required this.loggedAt,
    this.barcode,
    this.calories,
    this.proteinG,
    this.fatG,
    this.carbsG,
    this.servingSize,
    this.servings = 1,
    this.source = 'barcode',
    this.imageUrl,
  });

  final String id;
  final String productName;
  final DateTime loggedAt;
  final String? barcode;
  final double? calories;
  final double? proteinG;
  final double? fatG;
  final double? carbsG;
  final String? servingSize;
  final double servings;
  final String source;
  final String? imageUrl;

  double get totalCalories => (calories ?? 0) * servings;
  double get totalProteinG => (proteinG ?? 0) * servings;
  double get totalFatG => (fatG ?? 0) * servings;
  double get totalCarbsG => (carbsG ?? 0) * servings;

  String get timeLabel => DateFormat('h:mm a').format(loggedAt);

  String get metaLabel {
    final sourceLabel = source == 'manual' ? 'Manual entry' : 'Barcode scan';
    final parts = <String>[sourceLabel, timeLabel];
    if (servingSize != null && servingSize!.isNotEmpty) {
      parts.insert(1, servingSize!);
    }
    return parts.join(' · ');
  }

  bool isSameDay(DateTime day) {
    return loggedAt.year == day.year &&
        loggedAt.month == day.month &&
        loggedAt.day == day.day;
  }

  factory NutritionLog.fromMap(Map<String, dynamic> map) {
    return NutritionLog(
      id: map['id'] as String,
      productName: map['product_name'] as String,
      loggedAt: DateTime.parse(map['logged_at'] as String).toLocal(),
      barcode: map['barcode'] as String?,
      calories: _readDouble(map['calories']),
      proteinG: _readDouble(map['protein_g']),
      fatG: _readDouble(map['fat_g']),
      carbsG: _readDouble(map['carbs_g']),
      servingSize: map['serving_size'] as String?,
      servings: _readDouble(map['servings']) ?? 1,
      source: map['source'] as String? ?? 'barcode',
      imageUrl: map['image_url'] as String?,
    );
  }

  Map<String, dynamic> toLocalMap() {
    return {
      'id': id,
      'product_name': productName,
      'logged_at': loggedAt.toIso8601String(),
      'barcode': barcode,
      'calories': calories,
      'protein_g': proteinG,
      'fat_g': fatG,
      'carbs_g': carbsG,
      'serving_size': servingSize,
      'servings': servings,
      'source': source,
      'image_url': imageUrl,
    };
  }

  factory NutritionLog.fromLocalMap(Map<String, dynamic> map) {
    return NutritionLog(
      id: map['id'] as String,
      productName: map['product_name'] as String,
      loggedAt: DateTime.parse(map['logged_at'] as String),
      barcode: map['barcode'] as String?,
      calories: _readDouble(map['calories']),
      proteinG: _readDouble(map['protein_g']),
      fatG: _readDouble(map['fat_g']),
      carbsG: _readDouble(map['carbs_g']),
      servingSize: map['serving_size'] as String?,
      servings: _readDouble(map['servings']) ?? 1,
      source: map['source'] as String? ?? 'barcode',
      imageUrl: map['image_url'] as String?,
    );
  }

  static double? _readDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class NutritionDayTotals {
  const NutritionDayTotals({
    this.calories = 0,
    this.proteinG = 0,
    this.fatG = 0,
    this.carbsG = 0,
  });

  final double calories;
  final double proteinG;
  final double fatG;
  final double carbsG;
}
