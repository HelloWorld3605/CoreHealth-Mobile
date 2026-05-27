import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/visuals.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _targetWeightController;
  late TextEditingController _scheduleController;
  late Gender _gender;
  late GoalType _goal;
  late ActivityLevel _activityLevel;
  late String _trainingFrequency;
  late List<String> _dietaryRestrictions;
  late List<String> _allergies;
  late List<String> _healthConditions;
  late List<String> _focusAreas;
  late List<String> _preferredActivities;
  late String _mealBudget;
  late String _cookingTime;
  late List<String> _nutritionPriorities;
  bool _saving = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final profile = CoreHealthScope.of(context).profile;
    _nameController = TextEditingController(text: profile.name);
    _ageController = TextEditingController(text: '${profile.age}');
    _heightController =
        TextEditingController(text: _formatDecimal(profile.heightCm));
    _targetWeightController =
        TextEditingController(text: _formatDecimal(profile.targetWeightKg));
    _scheduleController = TextEditingController(text: profile.schedule);
    _gender = profile.gender;
    _goal = profile.goal;
    _activityLevel = profile.activityLevel;
    _trainingFrequency = profile.trainingFrequency.isEmpty
        ? profile.schedule
        : profile.trainingFrequency;
    _dietaryRestrictions = List.of(profile.dietaryRestrictions);
    _allergies = List.of(profile.allergies);
    _healthConditions = List.of(profile.healthConditions);
    _focusAreas = List.of(profile.focusAreas);
    _preferredActivities = List.of(profile.preferredActivities);
    _mealBudget = profile.mealBudget.isEmpty ? 'Cân bằng' : profile.mealBudget;
    _cookingTime =
        profile.cookingTime.isEmpty ? '15-30 phút' : profile.cookingTime;
    _nutritionPriorities = List.of(profile.nutritionPriorities);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _targetWeightController.dispose();
    _scheduleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final controller = CoreHealthScope.of(context);
    final current = controller.profile;

    final updated = current.copyWith(
      name: _nameController.text.trim(),
      age: int.tryParse(_ageController.text) ?? current.age,
      gender: _gender,
      heightCm:
          _parseLocalizedDouble(_heightController.text) ?? current.heightCm,
      targetWeightKg: _parseLocalizedDouble(_targetWeightController.text) ??
          current.targetWeightKg,
      goal: _goal,
      activityLevel: _activityLevel,
      schedule: _scheduleController.text.trim(),
      trainingFrequency: _trainingFrequency,
      focusAreas: _focusAreas,
      preferredActivities: _preferredActivities,
      dietaryRestrictions: _dietaryRestrictions,
      allergies: _allergies,
      healthConditions: _healthConditions,
      mealBudget: _mealBudget,
      cookingTime: _cookingTime,
      nutritionPriorities: _nutritionPriorities,
    );

    final error = await controller.updateProfile(updated);
    if (!mounted) return;
    setState(() => _saving = false);

    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu thông tin')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: const CoreHealthSubPageAppBar(title: 'Chỉnh sửa hồ sơ'),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 100 + bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(title: 'Thông tin cơ bản'),
            const SizedBox(height: 12),
            _buildTextField(
                _nameController, 'Họ tên', Icons.person_outline_rounded),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                      _ageController, 'Tuổi', Icons.cake_outlined,
                      keyboardType: TextInputType.number),
                ),
                const SizedBox(width: 12),
                Expanded(child: _buildGenderDropdown()),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Chỉ số cơ thể'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                      _heightController, 'Chiều cao (cm)', Icons.height_rounded,
                      keyboardType: TextInputType.number),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(_targetWeightController,
                      'Mục tiêu (kg)', Icons.flag_outlined,
                      keyboardType: TextInputType.number),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Mục tiêu & lối sống'),
            const SizedBox(height: 12),
            _buildGoalSelector(),
            const SizedBox(height: 12),
            _buildActivitySelector(),
            const SizedBox(height: 12),
            _buildTextField(
                _scheduleController, 'Lịch trình', Icons.schedule_rounded),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Thể lực theo survey'),
            const SizedBox(height: 12),
            _buildSingleChoiceChips(
              label: 'Tần suất tập luyện',
              value: _trainingFrequency,
              options: const [
                '1 lần/tuần',
                '2 lần/tuần',
                '3 lần/tuần',
                '4 lần/tuần',
                '5 lần/tuần',
                '6 lần/tuần',
                '7 lần/tuần',
              ],
              onChanged: (value) => setState(() {
                _trainingFrequency = value;
                _scheduleController.text = value;
              }),
            ),
            const SizedBox(height: 12),
            _buildChipEditor(
              label: 'Vùng cơ thể muốn tập trung',
              items: _focusAreas,
              suggestions: const [
                'Cánh tay',
                'Vai',
                'Ngực',
                'Bụng',
                'Chân',
                'Toàn Thân',
              ],
              onChanged: (list) => setState(() => _focusAreas = list),
            ),
            const SizedBox(height: 12),
            _buildChipEditor(
              label: 'Hoạt động yêu thích',
              items: _preferredActivities,
              suggestions: const [
                'Tập thể dục tại nhà',
                'Kéo dãn',
                'Calisthenics',
                'Tập luyện nhanh',
                'Bài tập với ghế',
                'Chạy',
                'Bài tập với tạ đơn',
                'HIIT',
                'Bài tập cải thiện tư thế',
                'Tabata',
                'Phục hồi',
                'Bài tập gym',
                'Tập tại giường',
                'Kegel',
              ],
              onChanged: (list) => setState(() => _preferredActivities = list),
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Dinh dưỡng'),
            const SizedBox(height: 12),
            _buildChipEditor(
              label: 'Chế độ ăn',
              items: _dietaryRestrictions,
              suggestions: const [
                'Không yêu cầu đặc biệt',
                'Ăn nhiều protein',
                'Ít đường',
                'Low-carb',
                'Ít dầu mỡ',
                'Ăn chay',
                'Không sữa',
                'Không gluten',
                'Món Việt',
                'Dễ nấu',
                'Tiết kiệm',
                'Meal prep',
              ],
              onChanged: (list) => setState(() => _dietaryRestrictions = list),
            ),
            const SizedBox(height: 12),
            _buildChipEditor(
              label: 'Dị ứng',
              items: _allergies,
              suggestions: const [
                'Không có',
                'Hải sản',
                'Đậu phộng',
                'Sữa',
                'Trứng',
                'Gluten',
                'Đậu nành',
                'Hạt cây',
                'Cá',
              ],
              onChanged: (list) => setState(() => _allergies = list),
            ),
            const SizedBox(height: 12),
            _buildSingleChoiceChips(
              label: 'Ngân sách mỗi bữa',
              value: _mealBudget,
              options: const ['Tiết kiệm', 'Cân bằng', 'Premium'],
              onChanged: (value) => setState(() => _mealBudget = value),
            ),
            const SizedBox(height: 12),
            _buildSingleChoiceChips(
              label: 'Thời gian nấu',
              value: _cookingTime,
              options: const ['<15 phút', '15-30 phút', '30-45 phút'],
              onChanged: (value) => setState(() => _cookingTime = value),
            ),
            const SizedBox(height: 12),
            _buildChipEditor(
              label: 'Ưu tiên meal plan',
              items: _nutritionPriorities,
              suggestions: const [
                'Giàu protein',
                'Cân bằng macro',
                'Giảm calo',
                'Món Việt',
                'Meal prep',
                'Dễ mua nguyên liệu',
                'Ít tinh bột',
                'Nhiều rau',
              ],
              onChanged: (list) => setState(() => _nutritionPriorities = list),
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Sức khỏe'),
            const SizedBox(height: 12),
            _buildChipEditor(
              label: 'Bệnh lý',
              items: _healthConditions,
              suggestions: const [
                'Không có',
                'Vai',
                'Cổ tay',
                'Đầu gối',
                'Cổ chân',
                'Lưng dưới',
                'Tiểu đường',
                'Huyết áp cao',
                'Tim mạch',
                'Gout',
              ],
              onChanged: (list) => setState(() => _healthConditions = list),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomInset),
        decoration: const BoxDecoration(
          color: AppPalette.surface,
          border: Border(top: BorderSide(color: AppPalette.borderLight)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: AppPalette.emerald,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Lưu thay đổi',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppPalette.emerald),
        filled: true,
        fillColor: AppPalette.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppPalette.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppPalette.borderLight),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return CoreHealthSelector<Gender>(
      label: 'Giới tính',
      value: _gender,
      icon: Icons.wc_rounded,
      displayText: (v) => switch (v) {
        Gender.male => 'Nam',
        Gender.female => 'Nữ',
        Gender.other => 'Khác',
      },
      options: const [
        (value: Gender.male, label: 'Nam', icon: Icons.male_rounded),
        (value: Gender.female, label: 'Nữ', icon: Icons.female_rounded),
        (value: Gender.other, label: 'Khác', icon: Icons.transgender_rounded),
      ],
      onChanged: (v) => setState(() => _gender = v),
    );
  }

  Widget _buildGoalSelector() {
    const goals = [
      (GoalType.loseWeight, 'Giảm cân', Icons.trending_down_rounded),
      (GoalType.maintain, 'Duy trì', Icons.balance_rounded),
      (GoalType.gainMuscle, 'Tăng cơ', Icons.trending_up_rounded),
    ];
    return Row(
      children: goals.map((item) {
        final active = _goal == item.$1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: item != goals.last ? 10 : 0),
            child: ChoiceChip(
              selected: active,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.$3,
                      size: 16, color: active ? Colors.white : AppPalette.text),
                  const SizedBox(width: 4),
                  Flexible(
                      child: Text(item.$2, overflow: TextOverflow.ellipsis)),
                ],
              ),
              selectedColor: AppPalette.emerald,
              backgroundColor: AppPalette.surfaceElevated,
              labelStyle: TextStyle(
                color: active ? Colors.white : AppPalette.text,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              onSelected: (_) => setState(() => _goal = item.$1),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActivitySelector() {
    const levels = [
      (ActivityLevel.sedentary, 'Ít vận động'),
      (ActivityLevel.light, 'Nhẹ'),
      (ActivityLevel.moderate, 'Vừa'),
      (ActivityLevel.active, 'Nhiều'),
      (ActivityLevel.veryActive, 'Rất nhiều'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: levels.map((item) {
        final active = _activityLevel == item.$1;
        return ChoiceChip(
          selected: active,
          label: Text(item.$2),
          selectedColor: AppPalette.emerald,
          backgroundColor: AppPalette.surfaceElevated,
          labelStyle: TextStyle(
            color: active ? Colors.white : AppPalette.text,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          onSelected: (_) => setState(() => _activityLevel = item.$1),
        );
      }).toList(),
    );
  }

  Widget _buildSingleChoiceChips({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final active = value == option;
            return ChoiceChip(
              selected: active,
              label: Text(option),
              selectedColor: AppPalette.emerald,
              backgroundColor: AppPalette.surfaceElevated,
              labelStyle: TextStyle(
                color: active ? Colors.white : AppPalette.text,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              onSelected: (_) => onChanged(option),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildChipEditor({
    required String label,
    required List<String> items,
    required List<String> suggestions,
    required ValueChanged<List<String>> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...items.map((item) => Chip(
                  label: Text(item),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    final updated = List.of(items)..remove(item);
                    onChanged(updated);
                  },
                  backgroundColor: AppPalette.emeraldSoft,
                  labelStyle: const TextStyle(
                      color: AppPalette.emeraldDeep,
                      fontWeight: FontWeight.w600),
                )),
            ...suggestions
                .where((s) => !items.contains(s))
                .map((s) => ActionChip(
                      label: Text('+ $s'),
                      backgroundColor: AppPalette.surfaceElevated,
                      labelStyle: const TextStyle(
                          color: AppPalette.mutedText,
                          fontWeight: FontWeight.w600),
                      onPressed: () {
                        final updated = _chipListWithAdded(items, s);
                        onChanged(updated);
                      },
                    )),
          ],
        ),
      ],
    );
  }

  List<String> _chipListWithAdded(List<String> items, String value) {
    final updated = List<String>.of(items);
    if (value == 'Không có' || value == 'Không yêu cầu đặc biệt') {
      return [value];
    }
    updated.remove('Không có');
    updated.remove('Không yêu cầu đặc biệt');
    if (!updated.contains(value)) {
      updated.add(value);
    }
    return updated;
  }
}

double? _parseLocalizedDouble(String raw) {
  return double.tryParse(raw.trim().replaceAll(',', '.'));
}

String _formatDecimal(double value) {
  return value.toStringAsFixed(1).replaceAll('.', ',');
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
    );
  }
}
