import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:peakform_ai/models/barcode_food_result.dart';

class OpenFoodFactsService {
  OpenFoodFactsService._();

  static final OpenFoodFactsService instance = OpenFoodFactsService._();

  static const _baseUrl = 'https://world.openfoodfacts.org/api/v2/product';
  static const _userAgent = 'PeakFormAI/1.0 (Flutter; barcode scanner)';

  Future<BarcodeFoodResult?> lookup(String barcode) async {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty) return null;

    final uri = Uri.parse('$_baseUrl/$trimmed.json');
    final response = await http.get(
      uri,
      headers: {
        'User-Agent': _userAgent,
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw OpenFoodFactsException(
        'Could not reach Open Food Facts (HTTP ${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (decoded['status'] != 1) return null;

    final product = decoded['product'] as Map<String, dynamic>? ?? {};
    final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};

    final basis = _detectBasis(nutriments);
    final productName = _readProductName(product);
    if (productName.isEmpty) return null;

    return BarcodeFoodResult(
      barcode: trimmed,
      productName: productName,
      brand: _readString(product['brands']),
      servingSize: _readString(product['serving_size']),
      imageUrl: _readString(
        product['image_front_small_url'] ?? product['image_small_url'],
      ),
      calories: _readCalories(nutriments, basis),
      proteinG: _readNutrient(nutriments, 'proteins', basis),
      fatG: _readNutrient(nutriments, 'fat', basis),
      carbsG: _readNutrient(nutriments, 'carbohydrates', basis),
      basis: basis,
    );
  }

  String _detectBasis(Map<String, dynamic> nutriments) {
    if (_hasServingData(nutriments)) return 'serving';
    return '100g';
  }

  bool _hasServingData(Map<String, dynamic> nutriments) {
    return nutriments.containsKey('energy-kcal_serving') ||
        nutriments.containsKey('proteins_serving') ||
        nutriments.containsKey('fat_serving') ||
        nutriments.containsKey('carbohydrates_serving');
  }

  String _readProductName(Map<String, dynamic> product) {
    final name = _readString(product['product_name']) ??
        _readString(product['product_name_en']) ??
        _readString(product['generic_name']);
    return name ?? 'Unknown product';
  }

  double? _readNutrient(
    Map<String, dynamic> nutriments,
    String key,
    String basis,
  ) {
    if (basis == 'serving') {
      final serving = nutriments['${key}_serving'];
      if (serving is num) return serving.toDouble();
    }

    final per100 = nutriments['${key}_100g'];
    if (per100 is num) return per100.toDouble();
    return null;
  }

  double? _readCalories(Map<String, dynamic> nutriments, String basis) {
    if (basis == 'serving') {
      final kcalServing = nutriments['energy-kcal_serving'];
      if (kcalServing is num) return kcalServing.toDouble();
    }

    final kcal100 = nutriments['energy-kcal_100g'];
    if (kcal100 is num) return kcal100.toDouble();

    final energy100 = nutriments['energy_100g'];
    if (energy100 is num) {
      return energy100.toDouble() / 4.184;
    }

    return null;
  }

  String? _readString(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}

class OpenFoodFactsException implements Exception {
  OpenFoodFactsException(this.message);

  final String message;

  @override
  String toString() => message;
}
