import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/visuals.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  String _selectedFilter = 'Tất cả';
  String _searchQuery = '';

  final List<String> _filters = ['Tất cả', 'Cao Đạm', 'Ít Calo', 'Chay', 'Nấu Nhanh'];

  final List<Map<String, dynamic>> _recipes = [
    {
      'name': 'Ức gà áp chảo sốt chanh dây',
      'calories': 380,
      'protein': 38,
      'carbs': 12,
      'fat': 8,
      'time': '20 phút',
      'filters': ['Cao Đạm', 'Nấu Nhanh'],
      'image': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400&h=300&fit=crop',
      'ingredients': [
        '200g Ức gà phi lê sạch',
        '1 quả chanh dây lấy nước cốt',
        '1 muỗng cà phê mật ong',
        '1 tép tỏi băm nhuyễn',
        'Muối, tiêu, dầu ô liu'
      ],
      'steps': [
        'Rửa sạch ức gà, khía nhẹ trên bề mặt, ướp chút muối, tiêu trong 10 phút.',
        'Cho dầu ô liu vào chảo nóng, áp chảo gà vàng đều hai mặt (mỗi mặt khoảng 5-6 phút).',
        'Hòa nước cốt chanh dây với tỏi băm, mật ong và đun nhẹ cho sệt lại.',
        'Rưới sốt chanh dây lên gà và thưởng thức kèm bông cải xanh luộc.'
      ]
    },
    {
      'name': 'Salad cá hồi quả bơ sốt mè rang',
      'calories': 420,
      'protein': 26,
      'carbs': 15,
      'fat': 18,
      'time': '10 phút',
      'filters': ['Cao Đạm', 'Nấu Nhanh', 'Ít Calo'],
      'image': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400&h=300&fit=crop',
      'ingredients': [
        '100g Cá hồi xông khói hoặc áp chảo',
        '1/2 quả Bơ chín thái lát',
        'Xà lách caron, cà chua bi, dưa leo',
        '2 muỗng sốt mè rang kiêng calo'
      ],
      'steps': [
        'Rửa sạch rau xà lách, cà chua bi cắt đôi, dưa leo cắt lát mỏng.',
        'Xếp rau xanh xuống đĩa, đặt bơ thái lát và cá hồi lên trên.',
        'Rưới nước sốt mè rang kiêng calo đều lên bề mặt và trộn nhẹ trước khi ăn.'
      ]
    },
    {
      'name': 'Đậu hũ sốt cà chua nấm đông cô',
      'calories': 280,
      'protein': 16,
      'carbs': 24,
      'fat': 6,
      'time': '15 phút',
      'filters': ['Chay', 'Ít Calo'],
      'image': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400&h=300&fit=crop',
      'ingredients': [
        '2 miếng đậu hũ trắng',
        '2 quả cà chua chín mềm',
        '50g nấm đông cô tươi',
        'Hành lá, hạt nêm chay, nước tương'
      ],
      'steps': [
        'Đậu hũ cắt miếng vuông nhỏ, áp chảo vàng giòn các mặt hoặc hấp nóng.',
        'Cà chua băm nhuyễn, phi thơm đầu hành rồi xào chín mềm tạo nước sốt đỏ.',
        'Cho nấm đông cô vào xào cùng sốt cà chua, nêm gia vị vừa ăn.',
        'Cho đậu hũ vào om liu riu trong 5 phút để ngấm sốt, rắc hành lá cắt nhỏ.'
      ]
    },
    {
      'name': 'Cháo yến mạch ức gà xé phay',
      'calories': 310,
      'protein': 28,
      'carbs': 35,
      'fat': 4,
      'time': '20 phút',
      'filters': ['Cao Đạm', 'Ít Calo'],
      'image': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400&h=300&fit=crop',
      'ingredients': [
        '40g Yến mạch cán vỡ',
        '100g Ức gà luộc xé phay',
        'Nước dùng gà luộc',
        'Gừng tươi thái sợi, hành ngò'
      ],
      'steps': [
        'Nấu yến mạch với nước dùng gà luộc trong 10-12 phút cho chín nhừ dạng cháo.',
        'Nêm chút muối và hạt nêm cho cháo có vị thanh ngọt nhẹ.',
        'Múc cháo ra tô, xếp ức gà xé phay lên trên, rắc thêm gừng sợi và hành ngò cắt nhỏ.'
      ]
    }
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _recipes.where((rec) {
      final matchesFilter = _selectedFilter == 'Tất cả' || rec['filters'].contains(_selectedFilter);
      final matchesSearch = rec['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CoreHealthSubPageAppBar(title: 'Công thức món ăn'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm công thức...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppPalette.mutedText),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final filter = _filters[idx];
                final active = _selectedFilter == filter;
                return ChoiceChip(
                  selected: active,
                  label: Text(filter),
                  selectedColor: AppPalette.orange,
                  backgroundColor: AppPalette.surfaceElevated,
                  labelStyle: TextStyle(
                    color: active ? Colors.white : AppPalette.text,
                    fontWeight: FontWeight.w800,
                  ),
                  onSelected: (_) => setState(() => _selectedFilter = filter),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: AppEmptyState(
                      icon: Icons.restaurant_rounded,
                      title: 'Không tìm thấy công thức',
                      message: 'Thử tìm kiếm với từ khóa khác xem sao.',
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, idx) {
                      final rec = filtered[idx];
                      return GestureDetector(
                        onTap: () => _showRecipeDetail(context, rec),
                        child: AppCard(
                          child: Row(
                            children: [
                              RemoteImage(
                                url: rec['image'],
                                height: 80,
                                width: 80,
                                radius: 16,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      rec['name'],
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(
                                          '${rec['calories']} kcal',
                                          style: const TextStyle(
                                            color: AppPalette.orange,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '⏱️ ${rec['time']}',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        _MacroBadge(label: 'P', value: '${rec['protein']}g', color: AppPalette.orange),
                                        const SizedBox(width: 6),
                                        _MacroBadge(label: 'C', value: '${rec['carbs']}g', color: AppPalette.blue),
                                        const SizedBox(width: 6),
                                        _MacroBadge(label: 'F', value: '${rec['fat']}g', color: Colors.purpleAccent),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: AppPalette.mutedText),
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

  void _showRecipeDetail(BuildContext context, Map<String, dynamic> rec) {
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
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
                          child: Image.network(
                            rec['image'],
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                rec['name'],
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppPalette.orangeSoft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${rec['calories']} kcal',
                                style: const TextStyle(color: AppPalette.orange, fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _MacroCol(label: 'Protein', value: '${rec['protein']}g', color: AppPalette.orange),
                            _MacroCol(label: 'Carbs', value: '${rec['carbs']}g', color: AppPalette.blue),
                            _MacroCol(label: 'Fat', value: '${rec['fat']}g', color: Colors.purpleAccent),
                            _MacroCol(label: 'Thời gian', value: rec['time'], color: AppPalette.mutedText),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const SectionHeading(
                          title: 'Nguyên liệu cần chuẩn bị',
                          icon: Icon(Icons.shopping_basket_outlined, color: AppPalette.orange),
                        ),
                        const SizedBox(height: 10),
                        ...List.generate(
                          (rec['ingredients'] as List).length,
                          (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline_rounded, color: AppPalette.orange, size: 18),
                                const SizedBox(width: 10),
                                Expanded(child: Text(rec['ingredients'][i], style: Theme.of(context).textTheme.bodyLarge)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const SectionHeading(
                          title: 'Các bước thực hiện',
                          icon: Icon(Icons.restaurant_rounded, color: AppPalette.orange),
                        ),
                        const SizedBox(height: 10),
                        ...List.generate(
                          (rec['steps'] as List).length,
                          (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 11,
                                  backgroundColor: AppPalette.orangeSoft,
                                  child: Text('${i + 1}', style: const TextStyle(color: AppPalette.orange, fontWeight: FontWeight.w800, fontSize: 11)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(rec['steps'][i], style: Theme.of(context).textTheme.bodyLarge)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        GradientActionButton(
                          label: 'Thêm vào thực đơn (Tiêu 5 token)',
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Đã thêm ${rec['name']} vào thực đơn hôm nay.')),
                            );
                          },
                          colors: const [AppPalette.orange, Color(0xFFFFA955)],
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

class _MacroBadge extends StatelessWidget {
  const _MacroBadge({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _MacroCol extends StatelessWidget {
  const _MacroCol({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppPalette.mutedText, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
      ],
    );
  }
}
