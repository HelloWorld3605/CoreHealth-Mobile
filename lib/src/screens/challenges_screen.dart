import 'package:flutter/material.dart';
import '../services/catalog_service.dart';
import '../theme.dart';
import '../widgets/visuals.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  final CatalogService _catalog = CatalogService();

  List<Map<String, dynamic>> _challenges = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await _catalog.challenges();
      if (!mounted) return;
      const palette = [
        AppPalette.orange,
        AppPalette.blue,
        AppPalette.emeraldDeep
      ];
      setState(() {
        _challenges = rows.asMap().entries.map((entry) {
          final e = entry.value;
          final totalDays = (e['totalDays'] as num?)?.toInt() ?? 0;
          return <String, dynamic>{
            'id': e['id'] ?? '',
            'title': e['title'] ?? '',
            'description': e['description'] ?? '',
            'reward': (e['rewardTokens'] as num?)?.toInt() ?? 0,
            'duration': totalDays > 0 ? '$totalDays ngày' : '',
            'participants': (e['participants'] as num?)?.toInt() ?? 0,
            'joined': e['joined'] == true,
            'progress': (e['progress'] as num?)?.toInt() ?? 0,
            'color': palette[entry.key % palette.length],
            'image': e['image'] ?? '',
          };
        }).toList();
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _challenges = const [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CoreHealthSubPageAppBar(title: 'Thử thách cộng đồng'),
      ),
      body: _challenges.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: AppEmptyState(
                  icon: Icons.emoji_events_outlined,
                  title: 'Chưa có thử thách',
                  message: 'Backend chưa trả thử thách cộng đồng nào.',
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: _challenges.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, idx) {
                final ch = _challenges[idx];
                return AppCard(
                  padding: EdgeInsets.zero,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => ChallengeDetailScreen(
                            challenge: ch,
                            onJoin: () {
                              setState(() {
                                ch['joined'] = true;
                                ch['progress'] = 1;
                              });
                            },
                          ),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppRadius.card)),
                          child: Image.network(
                            ch['image'],
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    ch['title'],
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppPalette.surfaceElevated,
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: AppPalette.border),
                                    ),
                                    child: Text(
                                      '+${ch['reward']} Token',
                                      style: TextStyle(
                                          color: ch['color'],
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11),
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                ch['description'],
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded,
                                      size: 14, color: ch['color']),
                                  const SizedBox(width: 4),
                                  Text(ch['duration'],
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 14),
                                  Icon(Icons.people_outline_rounded,
                                      size: 16, color: AppPalette.mutedText),
                                  const SizedBox(width: 4),
                                  Text('${ch['participants']} người tham gia',
                                      style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                              if (ch['joined']) ...[
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: (ch['progress'] as int) /
                                              int.parse(ch['duration']
                                                  .toString()
                                                  .split(' ')
                                                  .first),
                                          backgroundColor: ch['color']
                                              .withValues(alpha: 0.1),
                                          color: ch['color'],
                                          minHeight: 6,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '${ch['progress']} ngày hoàn thành',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: ch['color'],
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                )
                              ]
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class ChallengeDetailScreen extends StatelessWidget {
  const ChallengeDetailScreen(
      {super.key, required this.challenge, required this.onJoin});
  final Map<String, dynamic> challenge;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final joined = challenge['joined'] as bool;
    final progress = challenge['progress'] as int;
    final durationDays =
        int.parse(challenge['duration'].toString().split(' ').first);

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CoreHealthSubPageAppBar(title: 'Chi tiết thử thách'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                challenge['image'],
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    challenge['title'],
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: challenge['color'].withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+${challenge['reward']} Token',
                    style: TextStyle(
                        color: challenge['color'],
                        fontWeight: FontWeight.w800,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              challenge['description'],
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 18),
            const SectionHeading(title: 'Tổng quan nhiệm vụ'),
            const SizedBox(height: 10),
            _TaskOverviewRow(
              icon: Icons.check_circle_outline_rounded,
              title: 'Lịch tập hằng ngày',
              subtitle:
                  'Nhận bài tập chuyên biệt thiết kế riêng cho thử thách.',
              color: challenge['color'],
            ),
            const SizedBox(height: 12),
            _TaskOverviewRow(
              icon: Icons.toll_rounded,
              title: 'Tích lũy phần thưởng',
              subtitle: 'Nhận token ngay sau khi hoàn thành 100% thử thách.',
              color: challenge['color'],
            ),
            const SizedBox(height: 24),
            if (joined) ...[
              Text(
                'Tiến độ của bạn: $progress / $durationDays ngày',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: durationDays,
                itemBuilder: (context, idx) {
                  final dayNum = idx + 1;
                  final isDone = dayNum <= progress;
                  final isCurrent = dayNum == progress + 1;

                  return Container(
                    decoration: BoxDecoration(
                      color: isDone
                          ? challenge['color']
                          : isCurrent
                              ? challenge['color'].withValues(alpha: 0.12)
                              : AppPalette.surfaceElevated,
                      border: Border.all(
                        color:
                            isCurrent ? challenge['color'] : AppPalette.border,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$dayNum',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: isDone
                            ? Colors.white
                            : isCurrent
                                ? challenge['color']
                                : AppPalette.mutedText,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              GradientActionButton(
                label: 'Hoàn thành nhiệm vụ hôm nay',
                onPressed: () {
                  onJoin(); // triggers state update (adds 1 to progress)
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Chúc mừng! Bạn đã hoàn thành nhiệm vụ ngày hôm nay.')),
                  );
                },
                colors: [challenge['color'], const Color(0xFFC58FFF)],
              ),
            ] else ...[
              GradientActionButton(
                label: 'Tham gia thử thách',
                onPressed: () {
                  onJoin();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Đã tham gia thử thách ${challenge['title']}')),
                  );
                },
                colors: [challenge['color'], const Color(0xFFC58FFF)],
              )
            ]
          ],
        ),
      ),
    );
  }
}

class _TaskOverviewRow extends StatelessWidget {
  const _TaskOverviewRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        )
      ],
    );
  }
}
