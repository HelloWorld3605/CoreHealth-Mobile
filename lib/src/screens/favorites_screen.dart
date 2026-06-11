import 'package:flutter/material.dart';
import '../services/catalog_service.dart';
import '../theme.dart';
import '../widgets/visuals.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CatalogService _catalog = CatalogService();

  // Loaded from BE (/api/me/favorites) on open; lists below are offline fallback.
  List<Map<String, dynamic>> _favoriteMeals = [
    {
      'name': 'Ức gà phi lê áp chảo chanh dây',
      'calories': 380,
      'protein': 38,
      'image': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400&h=300&fit=crop',
    },
    {
      'name': 'Bún gạo lứt trộn thịt bò',
      'calories': 410,
      'protein': 28,
      'image': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400&h=300&fit=crop',
    }
  ];

  List<Map<String, dynamic>> _favoriteExercises = [
    {
      'name': 'Hít đất (Push-up)',
      'category': 'Ngực',
      'difficulty': 'Cơ bản',
      'image': 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=400&h=300&fit=crop',
    },
    {
      'name': 'Plank (Giữ tạ bụng)',
      'category': 'Core',
      'difficulty': 'Trung bình',
      'image': 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=400&h=300&fit=crop',
    }
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    try {
      final groups = await _catalog.favorites();
      if (!mounted || groups.isEmpty) return;
      List<Map<String, dynamic>> mapItems(String key) =>
          (groups[key] ?? const []).map((e) {
            return <String, dynamic>{
              'name': e['title'] ?? '',
              'image': e['image'] ?? '',
              'meta': e['meta'] ?? '',
            };
          }).toList();
      setState(() {
        _favoriteMeals = mapItems('Meals');
        _favoriteExercises = mapItems('Exercises');
      });
    } catch (_) {
      // Backend unreachable — keep the offline fallback lists.
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mục yêu thích', style: TextStyle(fontWeight: FontWeight.w800)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppPalette.emerald,
          labelColor: AppPalette.text,
          unselectedLabelColor: AppPalette.mutedText,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800),
          tabs: const [
            Tab(text: 'Món ăn'),
            Tab(text: 'Bài tập'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Meals Tab
          _favoriteMeals.isEmpty
              ? const Center(
                  child: AppEmptyState(
                    icon: Icons.restaurant_rounded,
                    title: 'Chưa có món ăn yêu thích',
                    message: 'Bấm biểu tượng trái tim khi xem món ăn để lưu.',
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _favoriteMeals.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final meal = _favoriteMeals[idx];
                    return AppCard(
                      child: Row(
                        children: [
                          RemoteImage(url: meal['image'], height: 64, width: 64, radius: 12),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  meal['name'],
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  (meal['meta']?.toString().isNotEmpty ?? false)
                                      ? meal['meta'].toString()
                                      : '${meal['calories']} kcal • ${meal['protein']}g protein',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
                            onPressed: () {
                              setState(() {
                                _favoriteMeals.removeAt(idx);
                              });
                            },
                          )
                        ],
                      ),
                    );
                  },
                ),

          // Exercises Tab
          _favoriteExercises.isEmpty
              ? const Center(
                  child: AppEmptyState(
                    icon: Icons.fitness_center_rounded,
                    title: 'Chưa có bài tập yêu thích',
                    message: 'Bấm biểu tượng trái tim khi xem động tác để lưu.',
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _favoriteExercises.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final ex = _favoriteExercises[idx];
                    return AppCard(
                      child: Row(
                        children: [
                          RemoteImage(url: ex['image'], height: 64, width: 64, radius: 12),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ex['name'],
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  (ex['meta']?.toString().isNotEmpty ?? false)
                                      ? ex['meta'].toString()
                                      : 'Cơ chính: ${ex['category']} • ${ex['difficulty']}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
                            onPressed: () {
                              setState(() {
                                _favoriteExercises.removeAt(idx);
                              });
                            },
                          )
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
