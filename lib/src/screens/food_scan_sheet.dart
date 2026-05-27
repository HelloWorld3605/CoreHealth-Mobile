import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app_controller.dart';
import '../services/food_scan_service.dart';
import '../theme.dart';

enum _ScanState { idle, naming, loading, result, error }

const _slots = ['🌅 Sáng', '☀️ Trưa', '🍎 Xế', '🌙 Tối'];

class FoodScanSheet extends StatefulWidget {
  const FoodScanSheet({super.key});

  @override
  State<FoodScanSheet> createState() => _FoodScanSheetState();
}

class _FoodScanSheetState extends State<FoodScanSheet> {
  final _service = FoodScanService();
  final _picker = ImagePicker();
  final _nameCtrl = TextEditingController();

  _ScanState _state = _ScanState.idle;
  FoodScanResult? _result;
  Uint8List? _imageBytes;
  String _errorMsg = '';
  String _selectedSlot = _slots[0];
  bool _logging = false;
  // null = chưa hỏi, true = muốn ghi vào plan, false = chỉ xem
  bool? _wantsToLog;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (mounted) {
      setState(() {
        _imageBytes = bytes;
        _state = _ScanState.naming;
        _nameCtrl.clear();
      });
    }
  }

  Future<void> _analyze() async {
    final name = _nameCtrl.text.trim();
    final bytes = _imageBytes;

    setState(() => _state = _ScanState.loading);
    try {
      final result = bytes != null && name.isEmpty
          ? await _service.analyzeByImage(bytes)
          : await _service.analyzeByName(name.isEmpty ? 'món ăn' : name);
      if (mounted) setState(() { _result = result; _state = _ScanState.result; });
    } catch (e) {
      if (mounted) setState(() { _errorMsg = e.toString(); _state = _ScanState.error; });
    }
  }

  Future<void> _logToMealPlan() async {
    final result = _result;
    if (result == null) return;
    setState(() => _logging = true);
    try {
      final controller = CoreHealthScope.of(context);
      await controller.logMealFromScan(result, _selectedSlot);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã ghi "${result.name}" vào $_selectedSlot'),
            backgroundColor: AppPalette.emerald,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _logging = false);
    }
  }

  void _reset() => setState(() {
        _state = _ScanState.idle;
        _imageBytes = null;
        _result = null;
        _nameCtrl.clear();
        _wantsToLog = null;
      });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom
        + MediaQuery.of(context).padding.bottom + 20;

    return Container(
      decoration: const BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppPalette.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppPalette.emerald, AppPalette.emeraldDeep]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Scan đồ ăn',
                          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      Text('Chụp ảnh & tính dinh dưỡng bằng AI',
                          style: tt.bodySmall?.copyWith(color: AppPalette.mutedText)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppPalette.mutedText),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppPalette.border),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset),
            child: _buildBody(tt),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(TextTheme tt) {
    return switch (_state) {
      _ScanState.idle    => _buildIdle(tt),
      _ScanState.naming  => _buildNaming(tt),
      _ScanState.loading => _buildLoading(tt),
      _ScanState.result  => _buildResult(tt),
      _ScanState.error   => _buildError(tt),
    };
  }

  Widget _buildIdle(TextTheme tt) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28),
          decoration: BoxDecoration(
            color: AppPalette.emeraldSoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Container(
                width: 68, height: 68,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppPalette.emerald, AppPalette.emeraldDeep],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 34),
              ),
              const SizedBox(height: 14),
              Text('Chụp ảnh hoặc chọn từ thư viện',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Sau đó xác nhận tên món để AI tính dinh dưỡng',
                  style: tt.bodySmall?.copyWith(color: AppPalette.mutedText),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _PickButton(
                icon: Icons.camera_alt_rounded,
                label: 'Chụp ảnh',
                gradient: const [AppPalette.emerald, AppPalette.emeraldDeep],
                onTap: () => _pickImage(ImageSource.camera),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PickButton(
                icon: Icons.photo_library_rounded,
                label: 'Thư viện',
                gradient: const [Color(0xFF6C63FF), Color(0xFF9C8BFF)],
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _state = _ScanState.naming),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppPalette.mutedText,
              side: const BorderSide(color: AppPalette.border),
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: const Text('Nhập tên món trực tiếp'),
          ),
        ),
      ],
    );
  }

  Widget _buildNaming(TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_imageBytes != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(_imageBytes!,
                height: 160, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 16),
        ],
        Text('Tên món ăn',
            style: tt.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700, color: AppPalette.mutedText)),
        const SizedBox(height: 8),
        TextField(
          controller: _nameCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'VD: Phở bò, Cơm tấm sườn...',
            hintStyle: tt.bodyLarge?.copyWith(color: AppPalette.mutedText),
            filled: true,
            fillColor: AppPalette.surfaceElevated,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppPalette.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppPalette.emerald, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppPalette.border),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: const Icon(Icons.restaurant_menu_rounded,
                color: AppPalette.emerald, size: 20),
          ),
          onSubmitted: (_) => _analyze(),
        ),
        const SizedBox(height: 14),
        if (_imageBytes != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _nameCtrl.clear();
                  _analyze();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppPalette.emerald,
                  side: const BorderSide(color: AppPalette.emerald),
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: const Text('Nhận diện tự động từ ảnh'),
              ),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _reset,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppPalette.mutedText,
                  side: const BorderSide(color: AppPalette.border),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Quay lại'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _analyze,
                style: FilledButton.styleFrom(
                  backgroundColor: AppPalette.emerald,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('Phân tích dinh dưỡng',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoading(TextTheme tt) {
    return Column(
      children: [
        if (_imageBytes != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(_imageBytes!,
                height: 140, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 20),
        ] else
          const SizedBox(height: 20),
        const CircularProgressIndicator(color: AppPalette.emerald, strokeWidth: 3),
        const SizedBox(height: 16),
        Text('Đang phân tích...', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('AI đang tính calo và dinh dưỡng',
            style: tt.bodySmall?.copyWith(color: AppPalette.mutedText)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildResult(TextTheme tt) {
    final r = _result!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_imageBytes != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(_imageBytes!,
                height: 150, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 14),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppPalette.emerald, AppPalette.emeraldDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.restaurant_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(r.name,
                        style: tt.titleMedium?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              if (r.serving.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(r.serving,
                    style: tt.bodySmall
                        ?.copyWith(color: Colors.white.withValues(alpha: 0.8))),
              ],
              const SizedBox(height: 14),
              Row(children: [
                _NutrientChip(label: 'Calo', value: '${r.calories}', unit: 'kcal',
                    icon: Icons.local_fire_department_rounded),
                const SizedBox(width: 8),
                _NutrientChip(label: 'Protein', value: r.protein.toStringAsFixed(1),
                    unit: 'g', icon: Icons.egg_alt_rounded),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                _NutrientChip(label: 'Carbs', value: r.carbs.toStringAsFixed(1),
                    unit: 'g', icon: Icons.grain_rounded),
                const SizedBox(width: 8),
                _NutrientChip(label: 'Fat', value: r.fat.toStringAsFixed(1),
                    unit: 'g', icon: Icons.water_drop_rounded),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Hỏi ý định: đã ăn hay chỉ muốn đo?
        if (_wantsToLog == null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppPalette.surfaceElevated,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppPalette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bạn vừa ăn món này chưa?',
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Chọn để ghi vào nhật ký hoặc chỉ xem thông tin dinh dưỡng.',
                    style: tt.bodySmall?.copyWith(color: AppPalette.mutedText)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _wantsToLog = false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppPalette.mutedText,
                          side: const BorderSide(color: AppPalette.border),
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.search_rounded, size: 18),
                        label: const Text('Chỉ xem'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () => setState(() => _wantsToLog = true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppPalette.emerald,
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: const Text('Đã ăn, ghi vào plan',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _reset,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppPalette.mutedText,
                side: const BorderSide(color: AppPalette.border),
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.camera_alt_rounded, size: 16),
              label: const Text('Scan món khác'),
            ),
          ),
        ] else if (_wantsToLog == true) ...[
          // Slot selector + log button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppPalette.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppPalette.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSlot,
                isExpanded: true,
                dropdownColor: AppPalette.surfaceElevated,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                items: _slots
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) { if (v != null) setState(() => _selectedSlot = v); },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _wantsToLog = null),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppPalette.mutedText,
                    side: const BorderSide(color: AppPalette.border),
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Quay lại'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _logging ? null : _logToMealPlan,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppPalette.emerald,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _logging
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.add_task_rounded, size: 18),
                  label: const Text('Xác nhận ghi',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ] else ...[
          // Chỉ xem — nút scan khác
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _reset,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppPalette.emerald,
                side: const BorderSide(color: AppPalette.emerald),
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.camera_alt_rounded, size: 18),
              label: const Text('Scan món khác'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildError(TextTheme tt) {
    return Column(
      children: [
        const SizedBox(height: 8),
        const Icon(Icons.error_outline_rounded, color: AppPalette.orange, size: 48),
        const SizedBox(height: 12),
        Text('Không thể phân tích',
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(_errorMsg,
            style: tt.bodySmall?.copyWith(color: AppPalette.mutedText),
            textAlign: TextAlign.center),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _reset,
          style: FilledButton.styleFrom(
            backgroundColor: AppPalette.emerald,
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Thử lại'),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _PickButton extends StatelessWidget {
  const _PickButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _NutrientChip extends StatelessWidget {
  const _NutrientChip({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 15),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 10)),
                  Text('$value $unit',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
