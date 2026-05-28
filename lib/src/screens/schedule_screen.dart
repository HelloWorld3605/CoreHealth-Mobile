import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/visuals.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _selectedDayIndex = 0;
  String _activePlanTab = 'Ăn'; // 'Ăn' or 'Tập'

  final List<String> _weekdays = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ Nhật'];
  final List<int> _dates = [25, 26, 27, 28, 29, 30, 31];

  final List<Map<String, dynamic>> _meals = [
    {'slot': 'Bữa sáng', 'name': 'Cháo yến mạch chuối hạt chia', 'calories': 310, 'icon': Icons.light_mode_outlined, 'color': AppPalette.orange},
    {'slot': 'Bữa trưa', 'name': 'Ức gà áp chảo sốt chanh dây', 'calories': 380, 'icon': Icons.wb_sunny_outlined, 'color': AppPalette.blue},
    {'slot': 'Bữa xế', 'name': 'Sữa chua Hy Lạp hạt granola', 'calories': 180, 'icon': Icons.cookie_outlined, 'color': AppPalette.violet},
    {'slot': 'Bữa tối', 'name': 'Salad cá hồi quả bơ bắp cải', 'calories': 420, 'icon': Icons.nightlight_round_outlined, 'color': AppPalette.emeraldDeep}
  ];

  final List<Map<String, dynamic>> _workouts = [
    {'name': 'Hít đất (Push-up)', 'sets': 3, 'reps': '12 lần', 'calories': 120, 'duration': '12 phút'},
    {'name': 'Dumbbell Shoulder Press', 'sets': 3, 'reps': '10 lần', 'calories': 130, 'duration': '15 phút'},
    {'name': 'Plank (Giữ cơ bụng)', 'sets': 3, 'reps': '60 giây', 'calories': 80, 'duration': '8 phút'}
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CoreHealthSubPageAppBar(title: 'Lịch trình tuần'),
      ),
      body: Column(
        children: [
          // 7 days calendar strip
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppPalette.border)),
            ),
            child: SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 7,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, idx) {
                  final active = _selectedDayIndex == idx;
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => setState(() => _selectedDayIndex = idx),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 54,
                      decoration: BoxDecoration(
                        color: active ? AppPalette.emerald : AppPalette.surfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: active ? Colors.transparent : AppPalette.border,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _weekdays[idx],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: active ? Colors.white : AppPalette.mutedText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_dates[idx]}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: active ? Colors.white : AppPalette.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Custom tab switch
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _TabButton(
                  label: 'Dinh dưỡng',
                  active: _activePlanTab == 'Ăn',
                  activeColor: AppPalette.orange,
                  onTap: () => setState(() => _activePlanTab = 'Ăn'),
                ),
                const SizedBox(width: 10),
                _TabButton(
                  label: 'Tập luyện',
                  active: _activePlanTab == 'Tập',
                  activeColor: AppPalette.blue,
                  onTap: () => setState(() => _activePlanTab = 'Tập'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Plan content
          Expanded(
            child: _activePlanTab == 'Ăn' ? _buildMealPlanList() : _buildWorkoutPlanList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMealPlanList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: _meals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final meal = _meals[idx];
        return AppCard(
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: meal['color'].withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(meal['icon'], color: meal['color']),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meal['slot'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppPalette.mutedText)),
                    const SizedBox(height: 2),
                    Text(meal['name'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  ],
                ),
              ),
              Text('${meal['calories']} kcal', style: const TextStyle(fontWeight: FontWeight.w800, color: AppPalette.text)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWorkoutPlanList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: _workouts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final ex = _workouts[idx];
        return AppCard(
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppPalette.blueSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text('${idx + 1}', style: const TextStyle(color: AppPalette.blue, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ex['name'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('${ex['sets']} sets x ${ex['reps']} • ${ex['duration']}', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Text('${ex['calories']} cal', style: const TextStyle(fontWeight: FontWeight.w800, color: AppPalette.blue)),
            ],
          ),
        );
      },
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.label, required this.active, required this.activeColor, required this.onTap});
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? activeColor : AppPalette.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: active ? Colors.transparent : AppPalette.border),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: active ? Colors.white : AppPalette.mutedText,
            ),
          ),
        ),
      ),
    );
  }
}
