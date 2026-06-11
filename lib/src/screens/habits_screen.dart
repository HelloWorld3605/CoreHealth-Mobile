import 'package:flutter/material.dart';
import '../services/catalog_service.dart';
import '../theme.dart';
import '../widgets/visuals.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  int _waterDrankMl = 1250;
  final int _waterTargetMl = 2500;

  double _sleepHours = 6.5;
  final double _sleepTargetHours = 8.0;

  int _stepsWalked = 6200;
  final int _stepsTarget = 10000;

  final CatalogService _catalog = CatalogService();

  // Loaded from BE (/api/me/habits) on open; list below is offline fallback.
  List<Map<String, dynamic>> _customHabits = [
    {'name': 'Đọc sách 15 phút', 'done': false, 'category': 'Trí tuệ'},
    {'name': 'Thiền định buổi sáng', 'done': true, 'category': 'Tinh thần'},
    {'name': 'Không ăn vặt sau 8h tối', 'done': false, 'category': 'Dinh dưỡng'},
    {'name': 'Giãn cơ trước khi ngủ', 'done': false, 'category': 'Thể lực'}
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await _catalog.habits();
      if (rows.isEmpty || !mounted) return;
      setState(() {
        _customHabits = rows.map((e) {
          final week = e['weekProgress'];
          final doneToday =
              week is List && week.isNotEmpty && week.last == true;
          final streak = (e['streak'] as num?)?.toInt() ?? 0;
          return <String, dynamic>{
            'name': e['name'] ?? '',
            'done': doneToday,
            'category': streak > 0 ? '🔥 $streak ngày' : 'Thói quen',
          };
        }).toList();
      });
    } catch (_) {
      // Backend unreachable — keep the offline fallback list.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CoreHealthSubPageAppBar(title: 'Thói quen hằng ngày'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Water Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeading(
                    title: 'Uống nước sạch',
                    icon: Icon(Icons.local_drink_rounded, color: AppPalette.blue),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_waterDrankMl / $_waterTargetMl ml',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: AppPalette.blue,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Đã hoàn thành ${((_waterDrankMl / _waterTargetMl) * 100).toStringAsFixed(0)}% mục tiêu',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          _QuickAddButton(
                            label: '+250ml',
                            onTap: () {
                              setState(() {
                                _waterDrankMl = (_waterDrankMl + 250).clamp(0, 5000);
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _QuickAddButton(
                            label: '+500ml',
                            onTap: () {
                              setState(() {
                                _waterDrankMl = (_waterDrankMl + 500).clamp(0, 5000);
                              });
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (_waterDrankMl / _waterTargetMl).clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: AppPalette.blueSoft,
                      color: AppPalette.blue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Sleep Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeading(
                    title: 'Giấc ngủ ngon',
                    icon: Icon(Icons.nightlight_round, color: AppPalette.violet),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_sleepHours.toStringAsFixed(1)} / ${_sleepTargetHours.toStringAsFixed(0)} giờ',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: AppPalette.violet,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Mục tiêu duy trì giấc ngủ chất lượng',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _sleepHours = (_sleepHours - 0.5).clamp(0.0, 24.0);
                              });
                            },
                            icon: const Icon(Icons.remove_circle_outline_rounded, color: AppPalette.violet),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _sleepHours = (_sleepHours + 0.5).clamp(0.0, 24.0);
                              });
                            },
                            icon: const Icon(Icons.add_circle_outline_rounded, color: AppPalette.violet),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (_sleepHours / _sleepTargetHours).clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: AppPalette.violetSoft,
                      color: AppPalette.violet,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Steps Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeading(
                    title: 'Vận động đi bộ',
                    icon: Icon(Icons.directions_walk_rounded, color: AppPalette.emeraldDeep),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_stepsWalked / $_stepsTarget bước',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: AppPalette.emeraldDeep,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Góp phần cải thiện hệ tim mạch',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          _QuickAddButton(
                            label: '+1000',
                            onTap: () {
                              setState(() {
                                _stepsWalked = (_stepsWalked + 1000).clamp(0, 50000);
                              });
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (_stepsWalked / _stepsTarget).clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: AppPalette.emeraldSoft,
                      color: AppPalette.emeraldDeep,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Checklist section
            const SectionHeading(
              title: 'Checklist thói quen tự chọn',
              icon: Icon(Icons.assignment_turned_in_outlined, color: AppPalette.text),
            ),
            const SizedBox(height: 10),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _customHabits.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final habit = _customHabits[idx];
                final done = habit['done'] as bool;
                return AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Checkbox(
                        value: done,
                        activeColor: AppPalette.emeraldDeep,
                        onChanged: (val) {
                          setState(() {
                            habit['done'] = val ?? false;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              habit['name'],
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    decoration: done ? TextDecoration.lineThrough : null,
                                    color: done ? AppPalette.subtleText : AppPalette.text,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              habit['category'],
                              style: const TextStyle(fontSize: 10, color: AppPalette.mutedText),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                        onPressed: () {
                          setState(() {
                            _customHabits.removeAt(idx);
                          });
                        },
                      )
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _showAddHabitDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Thêm thói quen mới'),
            )
          ],
        ),
      ),
    );
  }

  void _showAddHabitDialog() {
    final textController = TextEditingController();
    String selectedCat = 'Lối sống';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Thêm thói quen mới', style: TextStyle(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  labelText: 'Tên thói quen',
                  hintText: 'Ví dụ: Đọc sách, uống sữa...',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCat,
                items: ['Dinh dưỡng', 'Thể lực', 'Trí tuệ', 'Tinh thần', 'Lối sống']
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) selectedCat = val;
                },
                decoration: const InputDecoration(labelText: 'Phân loại'),
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: AppPalette.mutedText)),
            ),
            ElevatedButton(
              onPressed: () {
                final name = textController.text.trim();
                if (name.isNotEmpty) {
                  setState(() {
                    _customHabits.add({'name': name, 'done': false, 'category': selectedCat});
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Thêm'),
            )
          ],
        );
      },
    );
  }
}

class _QuickAddButton extends StatelessWidget {
  const _QuickAddButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppPalette.surfaceElevated,
          border: Border.all(color: AppPalette.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppPalette.text),
        ),
      ),
    );
  }
}
