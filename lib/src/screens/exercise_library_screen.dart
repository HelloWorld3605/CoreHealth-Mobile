import 'dart:convert';

import 'package:flutter/material.dart';
import '../services/catalog_service.dart';
import '../theme.dart';
import '../widgets/visuals.dart';

class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  String _selectedCategory = 'Tất cả';
  String _searchQuery = '';

  final List<String> _categories = [
    'Tất cả',
    'Ngực',
    'Lưng',
    'Chân',
    'Vai/Tay',
    'Core',
    'Cardio'
  ];

  final CatalogService _catalog = CatalogService();

  List<Map<String, dynamic>> _exercises = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await _catalog.exercises();
      if (!mounted) return;
      setState(() {
        _exercises = rows.map((e) {
          List<String> instructions = const [];
          final raw = e['instructionsJson'];
          if (raw is String && raw.trim().isNotEmpty) {
            try {
              final parsed = jsonDecode(raw);
              if (parsed is List) {
                instructions = parsed.map((x) => x.toString()).toList();
              }
            } catch (_) {}
          }
          return <String, dynamic>{
            'name': e['name'] ?? '',
            'category': e['category'] ?? e['muscleGroup'] ?? '',
            'difficulty': e['difficulty'] ?? '',
            'calories': e['calories'] ?? 0,
            'duration': e['sets'] ?? '',
            'image': e['thumbnailUrl'] ?? e['videoUrl'] ?? '',
            'instructions': instructions,
            'safety': e['tips'] ?? '',
          };
        }).toList();
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _exercises = const [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _exercises.where((ex) {
      final matchesCat =
          _selectedCategory == 'Tất cả' || ex['category'] == _selectedCategory;
      final matchesSearch = ex['name']
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CoreHealthSubPageAppBar(title: 'Thư viện bài tập'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm bài tập...',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppPalette.mutedText),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppPalette.border),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final cat = _categories[idx];
                final active = _selectedCategory == cat;
                return ChoiceChip(
                  selected: active,
                  label: Text(cat),
                  selectedColor: AppPalette.blue,
                  backgroundColor: AppPalette.surfaceElevated,
                  labelStyle: TextStyle(
                    color: active ? Colors.white : AppPalette.text,
                    fontWeight: FontWeight.w800,
                  ),
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: AppEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'Không tìm thấy bài tập',
                      message: 'Thử tìm kiếm từ khóa khác xem sao.',
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, idx) {
                      final ex = filtered[idx];
                      return GestureDetector(
                        onTap: () => _showExerciseDetail(context, ex),
                        child: AppCard(
                          child: Row(
                            children: [
                              RemoteImage(
                                url: ex['image'],
                                height: 72,
                                width: 72,
                                radius: 16,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ex['name'],
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppPalette.blueSoft,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            ex['category'],
                                            style: const TextStyle(
                                              color: AppPalette.blue,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          ex['difficulty'],
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded,
                                  color: AppPalette.mutedText),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showExerciseDetail(BuildContext context, Map<String, dynamic> ex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppRadius.sheet)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDE2EA),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.network(
                                ex['image'],
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              Container(
                                height: 200,
                                decoration: const BoxDecoration(
                                  color: Colors.black26,
                                ),
                              ),
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.play_arrow_rounded,
                                    color: AppPalette.text, size: 36),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                ex['name'],
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppPalette.blueSoft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${ex['calories']} cal/set',
                                style: const TextStyle(
                                    color: AppPalette.blue,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Nhóm cơ chính: ${ex['category']} • Thời lượng: ${ex['duration']}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 18),
                        const SectionHeading(
                          title: 'Hướng dẫn thực hiện',
                          icon: Icon(Icons.format_list_numbered_rounded,
                              color: AppPalette.blue),
                        ),
                        const SizedBox(height: 10),
                        ...List.generate(
                          (ex['instructions'] as List).length,
                          (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: AppPalette.blueSoft,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text('${i + 1}',
                                      style: const TextStyle(
                                          color: AppPalette.blue,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Text(ex['instructions'][i],
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4F4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFFE3E3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: Colors.redAccent, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Lưu ý an toàn',
                                        style: TextStyle(
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(ex['safety'],
                                        style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 12,
                                            height: 1.4)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        GradientActionButton(
                          label: 'Thêm vào buổi tập',
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Đã thêm bài tập ${ex['name']} vào danh sách.')),
                            );
                          },
                          colors: const [AppPalette.blue, Color(0xFF67A1FF)],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
