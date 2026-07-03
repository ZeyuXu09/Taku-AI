import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:peakform_ai/models/barcode_food_result.dart';
import 'package:peakform_ai/models/nutrition_log.dart';
import 'package:peakform_ai/services/nutrition_log_service.dart';
import 'package:peakform_ai/services/open_food_facts_service.dart';
import 'package:peakform_ai/theme/app_colors.dart';
import 'package:peakform_ai/widgets/add_food_sheet.dart';

class NutritionScannerScreen extends StatefulWidget {
  const NutritionScannerScreen({super.key, required this.logDate});

  final DateTime logDate;

  @override
  State<NutritionScannerScreen> createState() => _NutritionScannerScreenState();
}

class _NutritionScannerScreenState extends State<NutritionScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  BarcodeFoodResult? _result;
  String? _lastBarcode;
  DateTime? _lastScanAt;
  bool _loading = false;
  bool _saving = false;
  String? _error;
  double _servings = 1;

  late final TextEditingController _nameController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _fatController;
  late final TextEditingController _carbsController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _caloriesController = TextEditingController();
    _proteinController = TextEditingController();
    _fatController = TextEditingController();
    _carbsController = TextEditingController();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    super.dispose();
  }

  bool get _isToday {
    final now = DateTime.now();
    return widget.logDate.year == now.year &&
        widget.logDate.month == now.month &&
        widget.logDate.day == now.day;
  }

  String get _addButtonLabel {
    if (_isToday) return "Add to Today's Log";
    return 'Add to ${DateFormat('MMM d').format(widget.logDate)}';
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_loading || _saving || _result != null) return;

    final barcode = capture.barcodes
        .map((item) => item.rawValue?.trim())
        .firstWhere((value) => value != null && value.isNotEmpty, orElse: () => null);
    if (barcode == null) return;

    final now = DateTime.now();
    if (_lastBarcode == barcode &&
        _lastScanAt != null &&
        now.difference(_lastScanAt!) < const Duration(seconds: 2)) {
      return;
    }

    _lastBarcode = barcode;
    _lastScanAt = now;

    await _scannerController.stop();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final product = await OpenFoodFactsService.instance.lookup(barcode);
      if (!mounted) return;

      if (product == null) {
        HapticFeedback.mediumImpact();
        setState(() {
          _result = null;
          _error =
              'Product not found in Open Food Facts. Try another barcode or enter manually later.';
        });
        await _resumeScanning();
        return;
      }

      HapticFeedback.lightImpact();
      await _applyResult(product);
    } on OpenFoodFactsException catch (error) {
      if (!mounted) return;
      setState(() {
        _result = null;
        _error = error.message;
      });
      await _resumeScanning();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _result = null;
        _error = 'Could not look up barcode. Check your connection and retry.';
      });
      await _resumeScanning();
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _resumeScanning() async {
    if (!mounted || _result != null) return;
    await _scannerController.start();
  }

  Future<void> _applyResult(BarcodeFoodResult product) async {
    await _scannerController.stop();
    setState(() {
      _result = product;
      _servings = 1;
      _nameController.text = product.productName;
      _caloriesController.text = _formatNumber(product.calories);
      _proteinController.text = _formatNumber(product.proteinG);
      _fatController.text = _formatNumber(product.fatG);
      _carbsController.text = _formatNumber(product.carbsG);
    });
  }

  String _formatNumber(double? value) {
    if (value == null) return '';
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  double? _parseNumber(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  Future<void> _saveLog() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Product name is required.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await NutritionLogService.instance.addLog(
        productName: name,
        logDate: widget.logDate,
        barcode: _result?.barcode,
        calories: _parseNumber(_caloriesController.text),
        proteinG: _parseNumber(_proteinController.text),
        fatG: _parseNumber(_fatController.text),
        carbsG: _parseNumber(_carbsController.text),
        servingSize: _result?.basisLabel,
        servings: _servings,
        imageUrl: _result?.imageUrl,
      );

      if (!mounted) return;
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added $name to your log')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = NutritionLogService.friendlyError(error);
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _scanAgain() async {
    setState(() {
      _result = null;
      _error = null;
      _lastBarcode = null;
      _lastScanAt = null;
      _servings = 1;
    });
    await _resumeScanning();
  }

  Future<void> _openManualAdd() async {
    await _scannerController.stop();
    if (!mounted) return;

    final saved = await showAddFoodSheet(context, logDate: widget.logDate);
    if (!mounted) return;

    if (saved == true) {
      Navigator.of(context).pop(true);
      return;
    }

    if (_result == null) {
      await _resumeScanning();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onBarcodeDetected,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background.withValues(alpha: 0.55),
                  Colors.transparent,
                  AppColors.background.withValues(alpha: 0.92),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(child: _buildViewfinder()),
                _buildBottomPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ScannerIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            iconSize: 16,
            onTap: () => Navigator.of(context).pop(),
          ),
          const Text(
            'Scan Barcode',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Row(
            children: [
              _ScannerIconButton(
                icon: Icons.edit_rounded,
                onTap: _openManualAdd,
              ),
              const SizedBox(width: 8),
              _ScannerIconButton(
                icon: Icons.bolt_rounded,
                onTap: () => _scannerController.toggleTorch(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewfinder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: AspectRatio(
          aspectRatio: 4 / 5,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  ..._cornerPositions.map(
                    (corner) => _ViewfinderCorner(
                      alignment: corner.alignment,
                      borders: corner.borders,
                    ),
                  ),
                  if (_loading)
                    const Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: -36,
                    child: Text(
                      _result != null
                          ? 'Review below or tap refresh to scan again'
                          : _loading
                              ? 'Looking up product...'
                              : 'Point camera at product barcode',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                _error!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFFCA5A5),
                ),
              ),
            ),
          ],
          if (_result != null) _buildResultCard(),
          if (_result == null && !_loading)
            _buildScanPromptCard(),
          const SizedBox(height: 20),
          _buildRecentScans(),
        ],
      ),
    );
  }

  Widget _buildScanPromptCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.qr_code_scanner_rounded, color: AppColors.textSecondary),
          const SizedBox(height: 10),
          const Text(
            'Scan a packaged food barcode',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Nutrition data comes from Open Food Facts.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _openManualAdd,
            child: const Text('Enter food manually'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final result = _result!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: result.imageUrl != null
                    ? Image.network(
                        result.imageUrl!,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _productPlaceholder(),
                      )
                    : _productPlaceholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Product name',
                      ),
                    ),
                    Text(
                      '${result.basisLabel} · ${result.barcode}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _scanAgain,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                color: AppColors.textSecondary,
                tooltip: 'Scan again',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _editableStat('cal', _caloriesController),
              const SizedBox(width: 8),
              _editableStat('protein', _proteinController, suffix: 'g'),
              const SizedBox(width: 8),
              _editableStat('fat', _fatController, suffix: 'g'),
              const SizedBox(width: 8),
              _editableStat('carbs', _carbsController, suffix: 'g'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Servings',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              _ServingButton(
                icon: Icons.remove_rounded,
                onTap: _servings <= 1
                    ? null
                    : () => setState(() => _servings -= 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  _formatNumber(_servings),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _ServingButton(
                icon: Icons.add_rounded,
                onTap: () => setState(() => _servings += 1),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.accent, Color(0xFF764BA2)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _saving ? null : _saveLog,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_saving)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else
                        const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _addButtonLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productPlaceholder() {
    return Container(
      width: 44,
      height: 44,
      color: AppColors.barTrack,
      child: const Icon(Icons.restaurant_rounded, color: AppColors.textSecondary),
    );
  }

  Widget _editableStat(
    String label,
    TextEditingController controller, {
    String suffix = '',
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.barTrack,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: '—',
                suffixText: suffix.isEmpty ? null : suffix,
                suffixStyle: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentScans() {
    return ValueListenableBuilder<List<NutritionLog>>(
      valueListenable: NutritionLogService.instance.logs,
      builder: (context, _, __) {
        final recent = NutritionLogService.instance.recentScans();
        if (recent.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Scans',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recent.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final scan = recent[index];
                  return GestureDetector(
                    onTap: () {
                      if (scan.barcode == null) return;
                      unawaited(_applyResult(
                        BarcodeFoodResult(
                          barcode: scan.barcode!,
                          productName: scan.productName,
                          servingSize: scan.servingSize,
                          imageUrl: scan.imageUrl,
                          calories: scan.calories,
                          proteinG: scan.proteinG,
                          fatG: scan.fatG,
                          carbsG: scan.carbsG,
                        ),
                      ));
                    },
                    child: SizedBox(
                      width: 80,
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: scan.imageUrl != null
                                ? Image.network(
                                    scan.imageUrl!,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _recentPlaceholder(),
                                  )
                                : _recentPlaceholder(),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            scan.productName,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _recentPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: AppColors.barTrack,
      child: const Icon(Icons.restaurant_rounded, color: AppColors.textSecondary),
    );
  }

  static const _cornerPositions = [
    _CornerSpec(Alignment.topLeft, [true, false, false, true]),
    _CornerSpec(Alignment.topRight, [true, true, false, false]),
    _CornerSpec(Alignment.bottomLeft, [false, false, true, true]),
    _CornerSpec(Alignment.bottomRight, [false, true, true, false]),
  ];
}

class _ServingButton extends StatelessWidget {
  const _ServingButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.barTrack,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 18, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _CornerSpec {
  const _CornerSpec(this.alignment, this.borders);

  final Alignment alignment;
  final List<bool> borders;
}

class _ViewfinderCorner extends StatelessWidget {
  const _ViewfinderCorner({
    required this.alignment,
    required this.borders,
  });

  final Alignment alignment;
  final List<bool> borders;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border(
            top: borders[0]
                ? BorderSide(color: AppColors.accent, width: 3)
                : BorderSide.none,
            right: borders[1]
                ? BorderSide(color: AppColors.accent, width: 3)
                : BorderSide.none,
            bottom: borders[2]
                ? BorderSide(color: AppColors.accent, width: 3)
                : BorderSide.none,
            left: borders[3]
                ? BorderSide(color: AppColors.accent, width: 3)
                : BorderSide.none,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.5),
              blurRadius: 12,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerIconButton extends StatelessWidget {
  const _ScannerIconButton({
    required this.icon,
    this.onTap,
    this.iconSize = 18,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card.withValues(alpha: 0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: iconSize, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
