import 'package:flutter/material.dart';
import '../services/catalog_service.dart';
import '../theme.dart';
import '../widgets/visuals.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _selectedPeriod = 'Tuần';

  final CatalogService _catalog = CatalogService();

  // Loaded from BE (/api/leaderboard) on open; list below is offline fallback.
  List<Map<String, dynamic>> _rankings = [
    {'name': 'Nguyễn Văn Nam', 'streak': 24, 'score': 96, 'rank': 1, 'avatar': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=100&h=100&fit=crop'},
    {'name': 'Trần Thị Mai', 'streak': 21, 'score': 94, 'rank': 2, 'avatar': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=100&h=100&fit=crop'},
    {'name': 'Lê Hoàng Long', 'streak': 19, 'score': 91, 'rank': 3, 'avatar': 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=100&h=100&fit=crop'},
    {'name': 'Phạm Minh Đức', 'streak': 18, 'score': 89, 'rank': 4, 'avatar': 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=100&h=100&fit=crop'},
    {'name': 'Đặng Hồng Nhung', 'streak': 15, 'score': 87, 'rank': 5, 'avatar': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=100&h=100&fit=crop'},
    {'name': 'Lê Tuấn Kiệt', 'streak': 14, 'score': 85, 'rank': 6, 'avatar': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=100&h=100&fit=crop'},
    {'name': 'Bạn (You)', 'streak': 6, 'score': 82, 'rank': 12, 'avatar': ''}
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await _catalog.leaderboard();
      if (rows.isEmpty || !mounted) return;
      setState(() {
        _rankings = rows.map((e) {
          return <String, dynamic>{
            'name': e['name'] ?? '',
            'streak': (e['streak'] as num?)?.toInt() ?? 0,
            'score': (e['points'] as num?)?.toInt() ?? 0,
            'rank': (e['rank'] as num?)?.toInt() ?? 0,
            'avatar': e['avatar'] ?? '',
          };
        }).toList();
      });
    } catch (_) {
      // Backend unreachable — keep the offline fallback list.
    }
  }

  @override
  Widget build(BuildContext context) {
    // Separate Top 3 from others
    final podium = _rankings.take(3).toList();
    final others = _rankings.skip(3).toList();

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CoreHealthSubPageAppBar(title: 'Bảng xếp hạng'),
      ),
      body: Column(
        children: [
          // Segmented control
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppPalette.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppPalette.border),
              ),
              child: Row(
                children: [
                  _PeriodTab(
                    label: 'Tuần này',
                    active: _selectedPeriod == 'Tuần',
                    onTap: () => setState(() => _selectedPeriod = 'Tuần'),
                  ),
                  _PeriodTab(
                    label: 'Tháng này',
                    active: _selectedPeriod == 'Tháng',
                    onTap: () => setState(() => _selectedPeriod = 'Tháng'),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                // Top 3 Podium
                SizedBox(
                  height: 250,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 2nd Place
                      _PodiumCol(user: podium[1], rank: 2, height: 110, color: AppPalette.blue),
                      // 1st Place
                      _PodiumCol(user: podium[0], rank: 1, height: 140, color: AppPalette.gold),
                      // 3rd Place
                      _PodiumCol(user: podium[2], rank: 3, height: 95, color: AppPalette.orange),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Table Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const SizedBox(width: 32), // Rank spacer
                      const Expanded(child: Text('Thành viên', style: TextStyle(fontWeight: FontWeight.w700, color: AppPalette.mutedText))),
                      Text('Streak 🔥', style: TextStyle(fontWeight: FontWeight.w700, color: AppPalette.orange)),
                      const SizedBox(width: 24),
                      const Text('Health 💚', style: TextStyle(fontWeight: FontWeight.w700, color: AppPalette.emeraldDeep)),
                    ],
                  ),
                ),
                const Divider(),

                // Others list
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: others.length,
                  separatorBuilder: (_, __) => const Divider(color: AppPalette.borderLight),
                  itemBuilder: (context, idx) {
                    final user = others[idx];
                    final isUser = user['name'].toString().contains('Bạn');

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: isUser
                          ? BoxDecoration(
                              color: AppPalette.emeraldSoft.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppPalette.emeraldSoft),
                            )
                          : null,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 32,
                            child: Text(
                              '#${user['rank']}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: isUser ? AppPalette.emeraldDeep : AppPalette.mutedText,
                              ),
                            ),
                          ),
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: user['avatar'].toString().isNotEmpty
                                ? NetworkImage(user['avatar'])
                                : null,
                            child: user['avatar'].toString().isEmpty
                                ? const Icon(Icons.person, size: 18)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              user['name'],
                              style: TextStyle(
                                fontWeight: isUser ? FontWeight.w800 : FontWeight.w700,
                                color: isUser ? AppPalette.text : AppPalette.text.withValues(alpha: 0.86),
                              ),
                            ),
                          ),
                          Text('${user['streak']} ngày', style: const TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(width: 24),
                          Text('${user['score']}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppPalette.emeraldDeep)),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodTab extends StatelessWidget {
  const _PeriodTab({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: active
                ? [const BoxShadow(color: AppPalette.shadow, blurRadius: 8, offset: Offset(0, 2))]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: active ? AppPalette.text : AppPalette.mutedText,
            ),
          ),
        ),
      ),
    );
  }
}

class _PodiumCol extends StatelessWidget {
  const _PodiumCol({
    required this.user,
    required this.rank,
    required this.height,
    required this.color,
  });

  final Map<String, dynamic> user;
  final int rank;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            CircleAvatar(
              radius: rank == 1 ? 34 : 28,
              backgroundImage: NetworkImage(user['avatar']),
            ),
            Positioned(
              bottom: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Text(
                  '$rank',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          user['name'].toString().split(' ').last,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.7)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: const [
              BoxShadow(color: AppPalette.shadow, blurRadius: 12, offset: Offset(0, 4))
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${user['streak']} ngày', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
              const SizedBox(height: 4),
              Text('${user['score']} pts', style: const TextStyle(color: Colors.white70, fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }
}
