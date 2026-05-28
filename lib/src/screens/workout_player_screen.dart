import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/visuals.dart';

class WorkoutPlayerScreen extends StatefulWidget {
  const WorkoutPlayerScreen({super.key, required this.workoutFocus, required this.exercises});
  final String workoutFocus;
  final List<dynamic> exercises;

  @override
  State<WorkoutPlayerScreen> createState() => _WorkoutPlayerScreenState();
}

class _WorkoutPlayerScreenState extends State<WorkoutPlayerScreen> {
  int _currentExIdx = 0;
  int _currentSet = 1;
  late int _reps;
  late double _weight;

  bool _isResting = false;
  int _restTimeLeft = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initExercise(0);
  }

  void _initExercise(int idx) {
    if (idx >= widget.exercises.length) return;
    final ex = widget.exercises[idx];
    _reps = ex.reps != null ? int.tryParse(ex.reps.toString().split(' ').first) ?? 10 : 10;
    _weight = 0; // standard base weight
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRest(int seconds) {
    _timer?.cancel();
    setState(() {
      _isResting = true;
      _restTimeLeft = seconds;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_restTimeLeft <= 1) {
        t.cancel();
        setState(() {
          _isResting = false;
        });
      } else {
        setState(() {
          _restTimeLeft--;
        });
      }
    });
  }

  void _completeSet(int totalSets) {
    if (_currentSet < totalSets) {
      _startRest(60);
      setState(() {
        _currentSet++;
      });
    } else {
      // Move to next exercise
      if (_currentExIdx < widget.exercises.length - 1) {
        _startRest(60);
        setState(() {
          _currentExIdx++;
          _currentSet = 1;
        });
        _initExercise(_currentExIdx);
      } else {
        // Workout complete
        _timer?.cancel();
        _showSuccessDialog();
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Chúc mừng! 🎉', style: TextStyle(fontWeight: FontWeight.w800), textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: AppPalette.emeraldSoft, shape: BoxShape.circle),
                child: const Icon(Icons.emoji_events_rounded, color: AppPalette.emeraldDeep, size: 48),
              ),
              const SizedBox(height: 18),
              const Text('Bạn đã hoàn thành xuất sắc buổi tập hôm nay!', textAlign: TextAlign.center),
              const SizedBox(height: 6),
              const Text('Nhận ngay +15 Token và +1 ngày streak.', style: TextStyle(fontWeight: FontWeight.w800, color: AppPalette.emeraldDeep)),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // pop dialog
                Navigator.pop(context); // pop player screen
              },
              child: const Text('Tuyệt vời'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.exercises.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trình phát tập luyện')),
        body: const Center(child: Text('Không có bài tập nào được tìm thấy.')),
      );
    }

    final ex = widget.exercises[_currentExIdx];
    final totalSets = ex.sets ?? 3;
    final progress = (_currentExIdx + (_currentSet - 1) / totalSets) / widget.exercises.length;

    final nextEx = _currentExIdx < widget.exercises.length - 1 ? widget.exercises[_currentExIdx + 1] : null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.workoutFocus, style: const TextStyle(fontSize: 14, color: AppPalette.blue, fontWeight: FontWeight.w800)),
            Text('Bài ${_currentExIdx + 1}/${widget.exercises.length}', style: const TextStyle(fontSize: 12, color: Colors.white60)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white10,
            color: AppPalette.blue,
            minHeight: 4,
          ),
        ),
      ),
      body: _isResting
          ? _buildRestView()
          : Column(
              children: [
                // Exercise Video/Image Area
                Expanded(
                  flex: 4,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage('https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=500&h=350&fit=crop'),
                            fit: BoxFit.cover,
                            opacity: 0.45,
                          ),
                        ),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black54, Colors.black87],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      // Play Button Overlay
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(color: Colors.white12, shape: BoxShape.circle),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 44),
                      ),
                      // Instructions Overlay
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Set $_currentSet / $totalSets',
                              style: const TextStyle(color: AppPalette.blue, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1.1),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ex.nameVi,
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                // Controls area
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: Column(
                      children: [
                        // Target Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppPalette.blueSoft,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.offline_bolt_rounded, color: AppPalette.blue, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Mục tiêu: ${ex.reps ?? '10'} reps • ${ex.sets ?? '3'} sets',
                                style: const TextStyle(color: AppPalette.blue, fontWeight: FontWeight.w800, fontSize: 12),
                              )
                            ],
                          ),
                        ),
                        const Spacer(),

                        // Steppers
                        Row(
                          children: [
                            // Reps Stepper
                            Expanded(
                              child: _StepperCard(
                                label: 'Reps',
                                value: '$_reps',
                                onMinus: () => setState(() => _reps = (_reps - 1).clamp(1, 100)),
                                onPlus: () => setState(() => _reps++),
                                color: AppPalette.blue,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Weight Stepper
                            Expanded(
                              child: _StepperCard(
                                label: 'Cân nặng (kg)',
                                value: '${_weight.toStringAsFixed(1).replaceAll('.0', '')} kg',
                                onMinus: () => setState(() => _weight = (_weight - 2.5).clamp(0.0, 500.0)),
                                onPlus: () => setState(() => _weight += 2.5),
                                color: AppPalette.orange,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),

                        // Next Up Preview
                        if (nextEx != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppPalette.surfaceElevated,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppPalette.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.next_plan_outlined, color: AppPalette.blue, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('BÀI TIẾP THEO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppPalette.mutedText)),
                                      Text(nextEx.nameVi, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                        ],

                        // Action Button
                        GradientActionButton(
                          label: (_currentSet == totalSets && _currentExIdx == widget.exercises.length - 1)
                              ? 'Hoàn thành buổi tập'
                              : 'Hoàn thành Set $_currentSet',
                          onPressed: () => _completeSet(totalSets),
                          colors: const [AppPalette.blue, Color(0xFF67A1FF)],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildRestView() {
    final ex = widget.exercises[_currentExIdx];
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('THỜI GIAN NGHỈ', style: TextStyle(color: AppPalette.blue, fontWeight: FontWeight.w800, letterSpacing: 1.5, fontSize: 13)),
          const SizedBox(height: 24),

          // Big circular countdown
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: CircularProgressIndicator(
                  value: _restTimeLeft / 60,
                  strokeWidth: 6,
                  color: AppPalette.blue,
                  backgroundColor: Colors.white10,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$_restTimeLeft', style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w900)),
                  const Text('giây', style: TextStyle(color: Colors.white54, fontSize: 14)),
                ],
              )
            ],
          ),
          const SizedBox(height: 48),

          // Next up preview card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  const Icon(Icons.play_circle_outline_rounded, color: Colors.white60, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TIẾP THEO', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(ex.nameVi, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text('Set $_currentSet / ${ex.sets ?? 3}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          OutlinedButton.icon(
            onPressed: () {
              _timer?.cancel();
              setState(() {
                _isResting = false;
              });
            },
            icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
            label: const Text('Bỏ qua nghỉ', style: TextStyle(color: Colors.white)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white24),
            ),
          )
        ],
      ),
    );
  }
}

class _StepperCard extends StatelessWidget {
  const _StepperCard({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
    required this.color,
  });

  final String label;
  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppPalette.mutedText, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onMinus,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withValues(alpha: 0.1),
                  child: Icon(Icons.remove_rounded, color: color, size: 18),
                ),
              ),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              GestureDetector(
                onTap: onPlus,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withValues(alpha: 0.1),
                  child: Icon(Icons.add_rounded, color: color, size: 18),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
