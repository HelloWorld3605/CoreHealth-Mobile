// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_element, unused_field

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';



import '../app_controller.dart';
import '../demo_data.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/adaptive.dart';
import 'onboarding_preview_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum _LengthUnit { cm, ft }

enum _WeightUnit { kg, lb }

enum _BodyShape { toned, average, soft, slim, muscular }

enum _FitnessExperience { never, lost, usedTo, advanced }

enum _GoalCategory { fatLoss, maintain, muscleGain, weightGain, performance }

enum _GoalTimeline { one, three, six, twelve }

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _maleGenderImage = 'assets/images/onboarding/ptnam-p1.png';
  static const _femaleGenderImage = 'assets/images/onboarding/ptnu-p1.png';
  static const _maleBodyImage = 'assets/images/onboarding/ptnam-p2.png';
  static const _femaleBodyImage = 'assets/images/onboarding/ptnu-p2.png';

  final nameController = TextEditingController();
  final ageController = TextEditingController();

  int currentStep = 0;
  int? _scheduledSectionStep;
  Gender gender = Gender.male;
  _LengthUnit lengthUnit = _LengthUnit.cm;
  _WeightUnit weightUnit = _WeightUnit.kg;
  double heightCm = DemoData.initialProfile.heightCm;
  double weightKg = DemoData.initialProfile.weightKg;
  double? targetWeightKg;
  int birthYear = DateTime.now().year - DemoData.initialProfile.age;
  _GoalCategory selectedGoalCategory = _GoalCategory.muscleGain;
  _GoalTimeline selectedGoalTimeline = _GoalTimeline.three;
  int desiredBodyIndex = 1;
  _BodyShape desiredBodyShape = _BodyShape.toned;
  _BodyShape currentBodyShape = _BodyShape.average;
  int trainingDays = 3;
  bool measureInputOpen = false;
  SubscriptionPlan selectedPlan = SubscriptionPlan.max;
  _FitnessExperience? fitnessExperience;
  final Set<String> focusParts = {};
  final Set<String> injuries = {};
  final Set<String> dietaryPreferences = {};
  final Set<String> foodAllergies = {'Không có'};
  final Set<String> activityPreferences = {};
  final Set<String> nutritionPriorities = {'Giàu protein', 'Món Việt'};
  String mealBudget = 'Cân bằng';
  String cookingTime = '15-30 phút';
  // Web-aligned survey answers (stored as web value IDs, labelled in VN).
  String priority = 'balanced'; // balanced | nutrition | training | health
  String workoutLocation = 'gym'; // gym | home | outdoor
  final Set<String> equipment = {'full-gym'};
  int sessionMinutes = 60;
  String preferredWorkoutTime = 'evening'; // morning|afternoon|evening|flexible
  String dietType = 'high-protein';
  String mealFrequency = '3 meals + 1 snack';

@override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final progress = CoreHealthScope.of(context).onboardingProgress;
      if (progress.currentStep > 0 && progress.currentStep < steps.length) {
        setState(() {
          currentStep = progress.currentStep;
        });
      }
    });
  }

  // Single source of truth: each step carries its title, kind, renderer and
  // advance-validator. No separate index switch — title always matches content.
  // De-branched (every user answers nutrition AND fitness) to mirror the web
  // onboarding, so both platforms collect the same profile.
  bool get _basicValid {
    final age = int.tryParse(ageController.text) ?? 0;
    return nameController.text.trim().isNotEmpty && age >= 10 && age <= 120;
  }

  List<_SurveyStep> get steps => [
        _SurveyStep('Thông tin cơ bản', _StepKind.form,
            build: _basicInfoStep, canContinue: () => _basicValid),
        _SurveyStep('Mục tiêu', _StepKind.choice, build: _goalStep),
        _SurveyStep('Đánh giá bữa ăn', _StepKind.section,
            build: (_) => const _SectionIntroStep(
                  kicker: 'Phần 1',
                  title: 'Đánh giá bữa ăn',
                  subtitle:
                      'Khẩu vị, thói quen và dị ứng sẽ định hình meal plan.',
                  icon: Icons.restaurant_menu_rounded,
                )),
        _SurveyStep('Khẩu vị', _StepKind.choice,
            build: _dietaryPreferenceStep,
            canContinue: () => dietaryPreferences.isNotEmpty),
        _SurveyStep('Dị ứng', _StepKind.choice,
            build: _allergyStep, canContinue: () => foodAllergies.isNotEmpty),
        _SurveyStep('Ngân sách & thời gian', _StepKind.choice,
            build: _mealPracticalStep),
        _SurveyStep('Kiểu ăn', _StepKind.choice, build: _dietTypeStep),
        _SurveyStep('Nhịp bữa ăn', _StepKind.choice, build: _mealFrequencyStep),
        _SurveyStep('Ưu tiên dinh dưỡng', _StepKind.choice,
            build: _nutritionPriorityStep,
            canContinue: () => nutritionPriorities.isNotEmpty),
        _SurveyStep('Đánh giá thể lực', _StepKind.section,
            build: (_) => const _SectionIntroStep(
                  kicker: 'Phần 2',
                  title: 'Đánh giá thể lực',
                  subtitle:
                      'Mục tiêu, vóc dáng và lịch tập giúp cá nhân hóa workout.',
                  icon: Icons.fitness_center_rounded,
                )),
        _SurveyStep('Giới tính', _StepKind.choice, build: _genderStep),
        _SurveyStep('Vùng tập trung', _StepKind.choice,
            build: _bodyFocusStep, canContinue: () => focusParts.isNotEmpty),
        _SurveyStep('Chiều cao', _StepKind.measure, build: _heightStep),
        _SurveyStep('Năm sinh', _StepKind.measure, build: _birthYearStep),
        _SurveyStep('Vóc dáng mong muốn', _StepKind.choice,
            build: _desiredBodyStep),
        _SurveyStep('Vóc dáng hiện tại', _StepKind.choice,
            build: _currentBodyStep),
        _SurveyStep('Cân nặng', _StepKind.measure, build: _weightStep),
        _SurveyStep('Mục tiêu cụ thể', _StepKind.measure,
            build: _goalTargetStep),
        _SurveyStep('Ưu tiên', _StepKind.choice, build: _priorityStep),
        _SurveyStep('Tần suất', _StepKind.measure,
            build: _trainingFrequencyStep),
        _SurveyStep('Thời lượng buổi tập', _StepKind.choice,
            build: _sessionMinutesStep),
        _SurveyStep('Nơi tập', _StepKind.choice, build: _workoutLocationStep),
        _SurveyStep('Thiết bị', _StepKind.choice, build: _equipmentStep),
        _SurveyStep('Giờ tập ưa thích', _StepKind.choice,
            build: _workoutTimeStep),
        _SurveyStep('Chấn thương', _StepKind.choice, build: _injuryStep),
        _SurveyStep('Hoạt động', _StepKind.choice,
            build: _activityStep,
            canContinue: () => activityPreferences.isNotEmpty),
        _SurveyStep('Kinh nghiệm', _StepKind.choice,
            build: _experienceStep, canContinue: () => fitnessExperience != null),
      ];

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    super.dispose();
  }

  int get _ageFromBirthYear => DateTime.now().year - birthYear;

  double get _bmi {
    final heightM = heightCm / 100;
    if (heightM <= 0) return 0;
    return weightKg / (heightM * heightM);
  }

  ActivityLevel get _activityLevel => switch (trainingDays) {
        <= 1 => ActivityLevel.sedentary,
        2 => ActivityLevel.light,
        <= 4 => ActivityLevel.moderate,
        5 || 6 => ActivityLevel.active,
        _ => ActivityLevel.veryActive,
      };

  GoalType get _goal => switch (selectedGoalCategory) {
        _GoalCategory.fatLoss => GoalType.loseWeight,
        _GoalCategory.maintain => GoalType.maintain,
        _GoalCategory.muscleGain => GoalType.gainMuscle,
        _GoalCategory.weightGain => GoalType.gainMuscle,
        _GoalCategory.performance => GoalType.maintain,
      };

  // Maps the answers already collected here into the web-aligned survey schema
  // (same value IDs as CoreHealth-FE). Fields not yet collected on mobile keep
  // their web defaults and are filled in by the added survey steps.
  FitnessSurvey get _survey => FitnessSurvey(
        daysPerWeek: trainingDays,
        trainingExperience: switch (fitnessExperience) {
          _FitnessExperience.never || _FitnessExperience.lost => 'beginner',
          _FitnessExperience.usedTo => 'intermediate',
          _FitnessExperience.advanced => 'advanced',
          null => 'beginner',
        },
        budget: switch (mealBudget) {
          'Tiết kiệm' => 'low',
          'Premium' => 'premium',
          _ => 'moderate',
        },
        cookingTimeMinutes: switch (cookingTime) {
          '<15 phút' => 15,
          '30-45 phút' => 45,
          _ => 30,
        },
        timelineWeeks: switch (selectedGoalTimeline) {
          _GoalTimeline.one => 4,
          _GoalTimeline.three => 12,
          _GoalTimeline.six => 24,
          _GoalTimeline.twelve => 48,
        },
        priority: priority,
        workoutLocation: workoutLocation,
        equipment: equipment.toList(),
        sessionMinutes: sessionMinutes,
        preferredWorkoutTime: preferredWorkoutTime,
        dietType: dietType,
        mealFrequency: mealFrequency,
      );

  DemoProfile get previewProfile {
    final typedAge = int.tryParse(ageController.text);
    final resolvedAge =
        currentStep == 0 && typedAge != null ? typedAge : _ageFromBirthYear;
    return DemoProfile(
      name: nameController.text.trim().isEmpty
          ? DemoData.initialProfile.name
          : nameController.text.trim(),
      age: resolvedAge.clamp(10, 120).toInt(),
      gender: gender,
      heightCm: heightCm,
      weightKg: weightKg,
      targetWeightKg: _resolvedTargetWeightKg,
      goal: _goal,
      activityLevel: _activityLevel,
      schedule: '$trainingDays lần/tuần',
      dietaryRestrictions: dietaryPreferences
          .where((item) => item != 'Không yêu cầu đặc biệt')
          .toList(),
      allergies: foodAllergies.where((item) => item != 'Không có').toList(),
      healthConditions: injuries.where((item) => item != 'Không có').toList(),
      trainingFrequency: '$trainingDays lần/tuần',
      focusAreas: focusParts.toList(),
      preferredActivities: activityPreferences.toList(),
      mealBudget: mealBudget,
      cookingTime: cookingTime,
      nutritionPriorities: nutritionPriorities.toList(),
      plan: SubscriptionPlan.free,
      subscriptionMonths: 0,
      survey: _survey,
    );
  }

  double get _defaultTargetWeightKg {
    final delta = switch (selectedGoalCategory) {
      _GoalCategory.fatLoss => -5.0,
      _GoalCategory.maintain => 0.0,
      _GoalCategory.muscleGain => 4.0,
      _GoalCategory.weightGain => 5.0,
      _GoalCategory.performance => 0.0,
    };
    return (weightKg + delta).clamp(35.0, 180.0).toDouble();
  }

  double get _resolvedTargetWeightKg =>
      targetWeightKg ?? _defaultTargetWeightKg;

  bool get _canContinue => steps[currentStep].canContinue?.call() ?? true;

  Future<void> _nextStep() async {
    if (!_canContinue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn thông tin để tiếp tục.')),
      );
      return;
    }

    if (currentStep == 0) {
      final age =
          int.tryParse(ageController.text) ?? DemoData.initialProfile.age;
      birthYear = DateTime.now().year - age;
    }

    if (currentStep < steps.length - 1) {
      await CoreHealthScope.of(context).saveOnboardingStep(currentStep + 1, {'data': 'test'});
      if (mounted) {
        setState(() => currentStep += 1);
      }
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OnboardingPreviewScreen(
          onStart: () async {
            final error = await CoreHealthScope.of(context).finishOnboarding(previewProfile);
            if (!mounted) return;
            if (error == null) {
              Navigator.of(context).pop();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error)),
              );
            }
          },
        ),
      ),
    );
  }

  void _previousStep() {
    if (currentStep == 0) {
      CoreHealthScope.of(context).goToWelcome();
      return;
    }
    _scheduledSectionStep = null;
    var previousStep = currentStep - 1;
    if (steps[previousStep].kind == _StepKind.section) {
      previousStep -= 1;
    }
    setState(
        () => currentStep = previousStep.clamp(0, steps.length - 1).toInt());
  }

  void _scheduleSectionAdvance(int stepIndex) {
    if (_scheduledSectionStep == stepIndex) {
      return;
    }

    _scheduledSectionStep = stepIndex;
    Future<void>.delayed(const Duration(milliseconds: 1650), () {
      if (!mounted) {
        return;
      }
      if (currentStep != stepIndex) {
        if (_scheduledSectionStep == stepIndex) {
          _scheduledSectionStep = null;
        }
        return;
      }
      if (currentStep < steps.length - 1) {
        setState(() {
          _scheduledSectionStep = null;
          currentStep += 1;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = steps[currentStep];
    final isSection = step.kind == _StepKind.section;
    if (isSection) {
      _scheduleSectionAdvance(currentStep);
    }

    return Scaffold(
      backgroundColor:
          isSection ? AppPalette.emeraldDeep : AppPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            _SurveyTopBar(
              currentStep: currentStep,
              totalSteps: steps.length,
              onBack: _previousStep,
              inverted: isSection,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: KeyedSubtree(
                  key: ValueKey(currentStep),
                  child: isSection
                      ? steps[currentStep].build!(context)
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            PhoneLayout.of(context).horizontalPadding,
                            0,
                            PhoneLayout.of(context).horizontalPadding,
                            18,
                          ),
                          child: AdaptiveContent(
                            maxWidth: 520,
                            child: steps[currentStep].build!(context),
                          ),
                        ),
                ),
              ),
            ),
            if (step.kind != _StepKind.section)
              _BottomCta(
                label: 'Tiếp Theo',
                enabled: _canContinue,
                onPressed: _nextStep,
              ),
          ],
        ),
      ),
    );
  }

  Widget _basicInfoStep(BuildContext context) {
    return _StepFrame(
      title: 'Thông tin cơ bản',
      subtitle:
          'Hồ sơ ban đầu giúp CoreHealth cá nhân hóa kế hoạch ngay từ bước đầu.',
      child: Column(
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Tên của bạn'),
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: ageController,
            decoration: const InputDecoration(labelText: 'Tuổi'),
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 18),
          _CoachNote(
            text:
                'Các thông tin này chỉ dùng để tính BMI, nhịp tập và mức vận động phù hợp với bạn.',
          ),
        ],
      ),
    );
  }

  Widget _goalStep(BuildContext context) {
    final options = [
      (
        category: _GoalCategory.fatLoss,
        title: 'Giảm mỡ',
        subtitle: 'Đốt mỡ, giảm % body fat',
        icon: Icons.trending_down_rounded,
        accent: AppPalette.emeraldDeep,
      ),
      (
        category: _GoalCategory.maintain,
        title: 'Duy trì',
        subtitle: 'Giữ vóc dáng hiện tại',
        icon: Icons.balance_rounded,
        accent: AppPalette.emeraldDeep,
      ),
      (
        category: _GoalCategory.muscleGain,
        title: 'Tăng cơ',
        subtitle: 'Xây dựng muscle mass',
        icon: Icons.fitness_center_rounded,
        accent: AppPalette.emeraldDeep,
      ),
      (
        category: _GoalCategory.weightGain,
        title: 'Tăng cân',
        subtitle: 'Tăng weight tổng thể',
        icon: Icons.monitor_weight_rounded,
        accent: AppPalette.emeraldDeep,
      ),
      (
        category: _GoalCategory.performance,
        title: 'Fitness performance',
        subtitle: 'Tăng sức bền / sức mạnh',
        icon: Icons.bolt_rounded,
        accent: AppPalette.emeraldDeep,
      ),
    ];

    return _StepFrame(
      title: 'Mục tiêu chính của bạn là gì?',
      subtitle:
          'Ở bước này CoreHealth chỉ cần biết định hướng. Mục tiêu kg và timeline sẽ được tinh chỉnh sau trang cân nặng.',
      child: Column(
        children: [
          ...options.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _GoalChoiceCard(
                title: item.title,
                subtitle: item.subtitle,
                icon: item.icon,
                accent: item.accent,
                selected: selectedGoalCategory == item.category,
                onTap: () {
                  setState(() {
                    selectedGoalCategory = item.category;
                    targetWeightKg = null;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _genderStep(BuildContext context) {
    return _StepFrame(
      title: 'Giới tính của bạn là gì?',
      subtitle:
          'Điều này sẽ giúp chúng tôi điều chỉnh bài tập của bạn sao cho hoàn hảo với tỷ lệ trao đổi chất của bạn.',
      child: Column(
        children: [
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: _GenderImageCard(
                  title: 'Nam',
                  image: _maleGenderImage,
                  selected: gender == Gender.male,
                  onTap: () => setState(() => gender = Gender.male),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GenderImageCard(
                  title: 'Nữ',
                  image: _femaleGenderImage,
                  selected: gender == Gender.female,
                  onTap: () => setState(() => gender = Gender.female),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          _PillChoice(
            label: 'Khác / Tôi thà không nói',
            selected: gender == Gender.other,
            centered: true,
            onTap: () => setState(() => gender = Gender.other),
          ),
        ],
      ),
    );
  }

  Widget _bodyFocusStep(BuildContext context) {
    const parts = ['Cánh tay', 'Vai', 'Ngực', 'Bụng', 'Chân', 'Toàn Thân'];
    return _StepFrame(
      title: 'Bạn muốn tập trung vào phần nào của cơ thể?',
      child: SizedBox(
        height: 500,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -120,
              top: -130,
              bottom: -140,
              width: 440,
              child: _BodyFocusFigure(
                gender: gender,
                focusParts: focusParts,
                maleImage: _maleBodyImage,
                femaleImage: _femaleBodyImage,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _BodyFocusConnectorPainter(
                    gender: gender,
                    focusParts: focusParts,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 145,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: parts
                        .map(
                          (part) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _FocusOption(
                              label: part,
                              selected: focusParts.contains(part),
                              onTap: () {
                                setState(() {
                                  if (part == 'Toàn Thân') {
                                    if (focusParts.contains(part)) {
                                      focusParts.clear();
                                    } else {
                                      focusParts
                                        ..clear()
                                        ..addAll(parts);
                                    }
                                    return;
                                  }
                                  if (focusParts.contains(part)) {
                                    focusParts.remove(part);
                                    focusParts.remove('Toàn Thân');
                                  } else {
                                    focusParts.add(part);
                                  }
                                });
                              },
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heightStep(BuildContext context) {
    final display = lengthUnit == _LengthUnit.cm
        ? _formatDecimal(heightCm)
        : _feetDisplay(heightCm);
    return _StepFrame(
      title: 'Chiều cao của bạn là bao nhiêu?',
      subtitle:
          'Chúng tôi sẽ tính toán chỉ số BMI và điều chỉnh bài tập để phù hợp nhất với vóc dáng của bạn.',
      child: Column(
        children: [
          _CoachNote(
            text:
                'Chiều cao giúp CoreHealth điều chỉnh bài tập, khẩu phần và tốc độ tiến bộ hợp lý.',
          ),
          const SizedBox(height: 26),
          _SegmentedBadge<_LengthUnit>(
            value: lengthUnit,
            options: const [
              (value: _LengthUnit.cm, label: 'cm'),
              (value: _LengthUnit.ft, label: 'ft'),
            ],
            onChanged: (value) => setState(() => lengthUnit = value),
          ),
          const SizedBox(height: 22),
          _VerticalMeasurePicker(
            value: heightCm,
            unit: lengthUnit == _LengthUnit.cm ? 'cm' : 'ft',
            display: display,
            min: 100,
            max: 250,
            onChanged: (value) => setState(() => heightCm = value),
            onDisplayTap: _showHeightInputSheet,
          ),
        ],
      ),
    );
  }

  Widget _birthYearStep(BuildContext context) {
    return _StepFrame(
      title: 'Bạn sinh năm bao nhiêu?',
      subtitle:
          'Điều này giúp chúng tôi cá nhân hóa bài tập phù hợp với khả năng cơ thể của bạn và đảm bảo an toàn khi tập luyện.',
      child: Column(
        children: [
          _CoachNote(
            text:
                'Độ tuổi ảnh hưởng đến nhịp hồi phục, cường độ và cách tăng tải theo từng tuần.',
          ),
          const SizedBox(height: 34),
          _YearWheel(
            year: birthYear,
            onChanged: (value) => setState(() => birthYear = value),
          ),
        ],
      ),
    );
  }

  Widget _desiredBodyStep(BuildContext context) {
    final percent = _desiredBodyFatPercent(desiredBodyIndex);
    final insight = _desiredBodyInsight(desiredBodyIndex);
    final image = _desiredBodyImage(desiredBodyIndex);
    final previousImage = _desiredBodyImage(desiredBodyIndex - 1);
    final nextImage = _desiredBodyImage(desiredBodyIndex + 1);
    return _StepFrame(
      title: 'Hình dáng cơ thể mong muốn của bạn như thế nào?',
      greenWords: const {'mong muốn'},
      child: Column(
        children: [
          SizedBox(
            height: 328,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: -42,
                  bottom: 18,
                  child: _FadedBodyPreview(
                    image: previousImage,
                    opacity: desiredBodyIndex == 0 ? 0.08 : 0.16,
                  ),
                ),
                Positioned(
                  right: -42,
                  bottom: 18,
                  child: _FadedBodyPreview(
                    image: nextImage,
                    opacity: desiredBodyIndex == 4 ? 0.08 : 0.16,
                  ),
                ),
                Positioned.fill(
                  bottom: -8,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeOutCubic,
                      child: Image.asset(
                        image,
                        key: ValueKey(image),
                        height: 318,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -1,
                  child: Container(
                    height: 86,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppPalette.background.withValues(alpha: 0),
                          AppPalette.background.withValues(alpha: 0.94),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppPalette.emerald,
              inactiveTrackColor: AppPalette.blueSoft,
              thumbColor: AppPalette.emerald,
              overlayColor: AppPalette.emerald.withValues(alpha: 0.14),
              activeTickMarkColor: Colors.white.withValues(alpha: 0.7),
              inactiveTickMarkColor: AppPalette.blue.withValues(alpha: 0.34),
              trackHeight: 16,
              thumbShape: const _BorderedThumbShape(
                radius: 18,
                borderWidth: 4,
                borderColor: Colors.white,
              ),
            ),
            child: Slider(
              min: 0,
              max: 4,
              divisions: 4,
              value: desiredBodyIndex.toDouble(),
              onChanged: (value) {
                setState(() {
                  desiredBodyIndex = value.round();
                  desiredBodyShape = _desiredShapeFromIndex(desiredBodyIndex);
                });
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Săn chắc'),
                Text('Thừa mỡ'),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _InsightCard(
            title: insight.title,
            value: '$percent (${insight.badge})',
            message: insight.message,
            color: insight.color,
          ),
        ],
      ),
    );
  }

  Widget _currentBodyStep(BuildContext context) {
    final items = [
      (
        _BodyShape.average,
        'Trung bình',
        'assets/images/onboarding/size_body/male_body_medium.png',
      ),
      (
        _BodyShape.soft,
        'Thiếu săn chắc',
        'assets/images/onboarding/size_body/male_body_fat.png',
      ),
      (
        _BodyShape.slim,
        'Gầy',
        'assets/images/onboarding/size_body/male_body_thin.png',
      ),
      (
        _BodyShape.muscular,
        'Cơ bắp',
        'assets/images/onboarding/size_body/male_body_muscle.png',
      ),
      (
        _BodyShape.toned,
        'Săn chắc',
        'assets/images/onboarding/size_body/male_body_firm.png',
      ),
    ];
    return _StepFrame(
      title: 'Hình dáng cơ thể hiện tại của bạn như thế nào?',
      greenWords: const {'hiện tại'},
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _BodyShapeCard(
                  label: item.$2,
                  image: item.$3,
                  selected: currentBodyShape == item.$1,
                  onTap: () => setState(() => currentBodyShape = item.$1),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _weightStep(BuildContext context) {
    final displayWeight =
        weightUnit == _WeightUnit.kg ? weightKg : weightKg * 2.20462;
    final bmiColor = _bmi < 18.5
        ? AppPalette.blue
        : _bmi < 23
            ? AppPalette.emeraldDeep
            : _bmi < 25
                ? AppPalette.orange
                : Colors.redAccent;
    final bmiText = _bmi < 18.5
        ? 'Bạn hơi nhẹ cân. Kế hoạch sẽ ưu tiên tăng sức mạnh.'
        : _bmi < 23
            ? 'Bạn có một chỉ số tuyệt vời. Hãy duy trì nhé!'
            : 'Bạn chỉ cần thêm một chút bài tập đổ mồ hôi nữa để có cơ thể phù hợp hơn!';

    return _StepFrame(
      title: 'Cân nặng hiện tại của bạn là bao nhiêu?',
      greenWords: const {'hiện tại'},
      child: Column(
        children: [
          _SegmentedBadge<_WeightUnit>(
            value: weightUnit,
            options: const [
              (value: _WeightUnit.kg, label: 'kg'),
              (value: _WeightUnit.lb, label: 'lb'),
            ],
            onChanged: (value) => setState(() => weightUnit = value),
          ),
          const SizedBox(height: 42),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _showWeightInputSheet,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppPalette.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppPalette.borderLight),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.keyboard_rounded,
                        size: 13,
                        color: AppPalette.mutedText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Chạm để tự nhập',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppPalette.mutedText,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    text: _formatDecimal(displayWeight),
                    children: [
                      TextSpan(
                        text: ' ${weightUnit == _WeightUnit.kg ? 'kg' : 'lb'}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _HorizontalWeightRuler(
            valueKg: weightKg,
            onChanged: (value) => setState(() => weightKg = value),
          ),
          const SizedBox(height: 28),
          _BmiCard(
            bmi: _bmi,
            color: bmiColor,
            message: bmiText,
          ),
        ],
      ),
    );
  }

  Widget _goalTargetStep(BuildContext context) {
    final target = _resolvedTargetWeightKg;
    final range = _targetWeightRange;
    final isKg = weightUnit == _WeightUnit.kg;

    final currentDisplay = isKg ? weightKg : weightKg * 2.20462;
    final minDisplay = isKg ? range.$1 : range.$1 * 2.20462;
    final maxDisplay = isKg ? range.$2 : range.$2 * 2.20462;
    final unitStr = isKg ? 'kg' : 'lb';

    final title = switch (selectedGoalCategory) {
      _GoalCategory.fatLoss => 'Bạn muốn giảm bao nhiêu?',
      _GoalCategory.maintain => 'Bạn muốn giữ cân nặng quanh mức nào?',
      _GoalCategory.muscleGain => 'Bạn muốn tăng bao nhiêu cơ?',
      _GoalCategory.weightGain => 'Bạn muốn tăng bao nhiêu?',
      _GoalCategory.performance => 'Bạn muốn đặt mốc thể lực nào?',
    };
    final helper = switch (selectedGoalCategory) {
      _GoalCategory.fatLoss =>
        'CoreHealth sẽ ưu tiên giảm mỡ chậm, giữ cơ và không ép calo quá sâu.',
      _GoalCategory.maintain =>
        'Giữ mục tiêu sát cân nặng hiện tại để app tối ưu năng lượng duy trì.',
      _GoalCategory.muscleGain =>
        'Tăng cơ nên đi kèm lịch tập tiến bộ và tốc độ tăng cân vừa phải.',
      _GoalCategory.weightGain =>
        'Tăng cân tổng thể sẽ ưu tiên surplus calo, protein và phục hồi.',
      _GoalCategory.performance =>
        'Hiệu suất tập luyện không nhất thiết phải đổi cân nặng quá nhiều.',
    };

    return _StepFrame(
      title: title,
      subtitle: 'Cân nặng hiện tại: ${_formatDecimal(currentDisplay)} $unitStr',
      greenWords: const {'giảm', 'tăng', 'giữ'},
      child: Column(
        children: [
          _TargetWeightCard(
            currentWeightKg: weightKg,
            targetWeightKg: target,
            onDecrease: () => _setTargetWeight(target - 0.5),
            onIncrease: () => _setTargetWeight(target + 0.5),
            weightUnit: weightUnit,
            onValueTap: _showTargetWeightInputSheet,
          ),
          const SizedBox(height: 22),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppPalette.emerald,
              inactiveTrackColor: AppPalette.emeraldSoft,
              thumbColor: AppPalette.emerald,
              overlayColor: AppPalette.emerald.withValues(alpha: 0.14),
              trackHeight: 10,
              thumbShape: const _BorderedThumbShape(
                radius: 15,
                borderWidth: 3,
                borderColor: Colors.white,
              ),
            ),
            child: Slider(
              min: range.$1,
              max: range.$2,
              divisions: ((range.$2 - range.$1) * 2).round(),
              value: target.clamp(range.$1, range.$2).toDouble(),
              onChanged: _setTargetWeight,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_formatDecimal(minDisplay)} $unitStr'),
                Text('${_formatDecimal(maxDisplay)} $unitStr'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _GoalTimelineSelector(
            value: selectedGoalTimeline,
            onChanged: (value) => setState(() => selectedGoalTimeline = value),
          ),
          const SizedBox(height: 18),
          _CoachNote(text: helper),
        ],
      ),
    );
  }

  (double, double) get _targetWeightRange {
    final span = switch (selectedGoalCategory) {
      _GoalCategory.maintain || _GoalCategory.performance => 15.0,
      _ => 45.0,
    };
    final min = (weightKg - span).clamp(30.0, 220.0).toDouble();
    final max = (weightKg + span).clamp(30.0, 220.0).toDouble();
    return (min, max);
  }

  void _setTargetWeight(double value) {
    final range = _targetWeightRange;
    setState(() {
      targetWeightKg = value.clamp(range.$1, range.$2).toDouble();
    });
  }

  Future<void> _showHeightInputSheet() async {
    var cmText = _formatDecimal(heightCm);
    final totalInches = heightCm / 2.54;
    var feetText = '${totalInches ~/ 12}';
    var inchesText = '${(totalInches - (totalInches ~/ 12) * 12).round()}';

    void submit(BuildContext sheetContext) {
      final nextHeight = switch (lengthUnit) {
        _LengthUnit.cm => _parseLocalizedDouble(cmText),
        _LengthUnit.ft => () {
            final feet = int.tryParse(feetText.trim());
            final inches = int.tryParse(inchesText.trim());
            if (feet == null || inches == null) return null;
            return (feet * 12 + inches) * 2.54;
          }(),
      };
      if (nextHeight == null || nextHeight < 100 || nextHeight > 250) {
        ScaffoldMessenger.maybeOf(sheetContext)?.showSnackBar(
          const SnackBar(content: Text('Chiều cao hợp lệ từ 100 đến 250 cm.')),
        );
        return;
      }
      if (!mounted) return;
      setState(() => heightCm = nextHeight.toDouble());
      Navigator.of(sheetContext).pop();
    }

    return _showMeasureInputSheet(
      title: 'Nhập chiều cao',
      body: lengthUnit == _LengthUnit.cm
          ? [
              _MeasureInputField(
                initialValue: cmText,
                label: 'cm',
                decimal: true,
                onChanged: (value) => cmText = value,
              ),
            ]
          : [
              _MeasureInputField(
                initialValue: feetText,
                label: 'ft',
                onChanged: (value) => feetText = value,
              ),
              _MeasureInputField(
                initialValue: inchesText,
                label: 'in',
                onChanged: (value) => inchesText = value,
                autofocus: false,
              ),
            ],
      onSubmit: submit,
    );
  }

  Future<void> _showWeightInputSheet() async {
    final displayWeight =
        weightUnit == _WeightUnit.kg ? weightKg : weightKg * 2.20462;
    var weightText = _formatDecimal(displayWeight);

    void submit(BuildContext sheetContext) {
      final typed = _parseLocalizedDouble(weightText);
      if (typed == null) {
        ScaffoldMessenger.maybeOf(sheetContext)?.showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập cân nặng hợp lệ.')),
        );
        return;
      }
      final nextKg = weightUnit == _WeightUnit.kg ? typed : typed / 2.20462;
      if (nextKg < 30 || nextKg > 200) {
        ScaffoldMessenger.maybeOf(sheetContext)?.showSnackBar(
          const SnackBar(content: Text('Cân nặng hợp lệ từ 30 đến 200 kg.')),
        );
        return;
      }
      if (!mounted) return;
      setState(() => weightKg = nextKg.toDouble());
      Navigator.of(sheetContext).pop();
    }

    return _showMeasureInputSheet(
      title: 'Nhập cân nặng',
      body: [
        _MeasureInputField(
          initialValue: weightText,
          label: weightUnit == _WeightUnit.kg ? 'kg' : 'lb',
          decimal: true,
          onChanged: (value) => weightText = value,
        ),
      ],
      onSubmit: submit,
    );
  }

  Future<void> _showTargetWeightInputSheet() async {
    final displayWeight = weightUnit == _WeightUnit.kg
        ? _resolvedTargetWeightKg
        : _resolvedTargetWeightKg * 2.20462;
    var weightText = _formatDecimal(displayWeight);

    void submit(BuildContext sheetContext) {
      final typed = _parseLocalizedDouble(weightText);
      if (typed == null) {
        ScaffoldMessenger.maybeOf(sheetContext)?.showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập cân nặng hợp lệ.')),
        );
        return;
      }
      final nextKg = weightUnit == _WeightUnit.kg ? typed : typed / 2.20462;
      final range = _targetWeightRange;
      if (nextKg < range.$1 || nextKg > range.$2) {
        final minDisplay =
            weightUnit == _WeightUnit.kg ? range.$1 : range.$1 * 2.20462;
        final maxDisplay =
            weightUnit == _WeightUnit.kg ? range.$2 : range.$2 * 2.20462;
        ScaffoldMessenger.maybeOf(sheetContext)?.showSnackBar(
          SnackBar(
            content: Text(
              'Cân nặng mục tiêu hợp lệ từ ${_formatDecimal(minDisplay)} đến ${_formatDecimal(maxDisplay)} ${weightUnit == _WeightUnit.kg ? 'kg' : 'lb'}.',
            ),
          ),
        );
        return;
      }
      if (!mounted) return;
      _setTargetWeight(nextKg.toDouble());
      Navigator.of(sheetContext).pop();
    }

    return _showMeasureInputSheet(
      title: 'Nhập cân nặng mục tiêu',
      body: [
        _MeasureInputField(
          initialValue: weightText,
          label: weightUnit == _WeightUnit.kg ? 'kg' : 'lb',
          decimal: true,
          onChanged: (value) => weightText = value,
        ),
      ],
      onSubmit: submit,
    );
  }

  Future<void> _showMeasureInputSheet({
    required String title,
    required List<Widget> body,
    required ValueChanged<BuildContext> onSubmit,
  }) {
    if (measureInputOpen) return Future.value();
    measureInputOpen = true;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppPalette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            22,
            22,
            MediaQuery.of(sheetContext).viewInsets.bottom + 22,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  for (var i = 0; i < body.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(child: body[i]),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => onSubmit(sheetContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.text,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Cập nhật',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      measureInputOpen = false;
    });
  }

  Widget _fourWeekPromiseStep(BuildContext context) {
    return _StepFrame(
      title: 'Những thay đổi rõ rệt đã hứa trong 4 TUẦN!',
      blueWords: const {'4 TUẦN!'},
      subtitle: 'Đừng lo lắng về việc không có kết quả!',
      child: Column(
        children: [
          SizedBox(
            height: 330,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 0,
                  top: 40,
                  child: _BeforeAfterCard(
                    label: 'TRƯỚC',
                    image: _bodyImage,
                    faded: true,
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 8,
                  child: _BeforeAfterCard(
                    label: 'SAU',
                    image: _bodyImage,
                    selected: true,
                  ),
                ),
                const Positioned(
                  top: 142,
                  child: Icon(
                    Icons.arrow_circle_right_rounded,
                    size: 70,
                    color: Color(0xFF1677F2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _trainingFrequencyStep(BuildContext context) {
    final subtitle = trainingDays <= 2
        ? 'Tôi muốn bắt đầu nhẹ nhàng và giữ lịch thật dễ theo.'
        : trainingDays <= 4
            ? 'Tôi thích tập thể dục như một phần của lối sống.'
            : 'Tôi muốn đẩy tiến độ nhanh hơn với lịch đều đặn.';
    return _StepFrame(
      title: 'Bạn muốn tập luyện thường xuyên như thế nào?',
      child: Column(
        children: [
          const SizedBox(height: 38),
          _CalendarBadge(days: trainingDays),
          const SizedBox(height: 22),
          Text(
            '$trainingDays lần/tuần',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppPalette.mutedText,
                ),
          ),
          const SizedBox(height: 56),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppPalette.emerald,
              inactiveTrackColor: AppPalette.emeraldSoft,
              thumbColor: AppPalette.emerald,
              trackHeight: 14,
              thumbShape: const _BorderedThumbShape(
                radius: 16,
                borderWidth: 3,
                borderColor: Colors.white,
              ),
            ),
            child: Slider(
              min: 1,
              max: 7,
              divisions: 6,
              value: trainingDays.toDouble(),
              onChanged: (value) =>
                  setState(() => trainingDays = value.round()),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Ít hơn'),
                Text('Nhiều hơn'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _injuryStep(BuildContext context) {
    final items = [
      (label: 'Không có', icon: Icons.accessibility_new_rounded),
      (label: 'Vai', icon: Icons.accessibility_rounded),
      (label: 'Cổ tay', icon: Icons.pan_tool_alt_rounded),
      (label: 'Đầu gối', icon: Icons.airline_seat_legroom_reduced_rounded),
      (label: 'Cổ chân', icon: Icons.directions_walk_rounded),
      (label: 'Lưng dưới', icon: Icons.airline_seat_recline_extra_rounded),
    ];
    return _StepFrame(
      title: 'Bạn có bị chấn thương gần đây không?',
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _IconChoiceRow(
                  label: item.label,
                  icon: item.icon,
                  selected: injuries.contains(item.label),
                  onTap: () {
                    setState(() {
                      if (item.label == 'Không có') {
                        injuries
                          ..clear()
                          ..add(item.label);
                        return;
                      }
                      injuries.remove('Không có');
                      if (injuries.contains(item.label)) {
                        injuries.remove(item.label);
                      } else {
                        injuries.add(item.label);
                      }
                    });
                  },
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _activityStep(BuildContext context) {
    const activities = [
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
    ];
    return _StepFrame(
      title: 'Bạn thích hoạt động nào?',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
        child: Wrap(
          spacing: 12,
          runSpacing: 14,
          children: activities.map((activity) {
            final selected = activityPreferences.contains(activity);
            return _ActivityChip(
              label: activity,
              selected: selected,
              onTap: () {
                setState(() {
                  if (selected) {
                    activityPreferences.remove(activity);
                  } else {
                    activityPreferences.add(activity);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _dietaryPreferenceStep(BuildContext context) {
    const items = [
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
    ];
    return _StepFrame(
      title: 'Bạn muốn bữa ăn của mình như thế nào?',
      subtitle:
          'CoreHealth sẽ dùng thông tin này để gợi ý meal plan hợp khẩu vị và dễ theo hơn.',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
        child: Wrap(
          spacing: 12,
          runSpacing: 14,
          children: items.map((item) {
            final selected = dietaryPreferences.contains(item);
            return _ActivityChip(
              label: item,
              selected: selected,
              onTap: () {
                setState(() {
                  if (item == 'Không yêu cầu đặc biệt') {
                    dietaryPreferences
                      ..clear()
                      ..add(item);
                    return;
                  }
                  dietaryPreferences.remove('Không yêu cầu đặc biệt');
                  if (selected) {
                    dietaryPreferences.remove(item);
                  } else {
                    dietaryPreferences.add(item);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _allergyStep(BuildContext context) {
    const items = [
      'Không có',
      'Hải sản',
      'Đậu phộng',
      'Sữa',
      'Trứng',
      'Gluten',
      'Đậu nành',
      'Hạt cây',
      'Cá',
    ];
    return _StepFrame(
      title: 'Bạn có dị ứng hoặc cần tránh thực phẩm nào không?',
      subtitle:
          'Dị ứng sẽ được ưu tiên cao hơn sở thích khi tạo thực đơn cho bạn.',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
        child: Wrap(
          spacing: 12,
          runSpacing: 14,
          children: items.map((item) {
            final selected = foodAllergies.contains(item);
            return _ActivityChip(
              label: item,
              selected: selected,
              onTap: () {
                setState(() {
                  if (item == 'Không có') {
                    foodAllergies
                      ..clear()
                      ..add(item);
                    return;
                  }
                  foodAllergies.remove('Không có');
                  if (selected) {
                    foodAllergies.remove(item);
                  } else {
                    foodAllergies.add(item);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _mealPracticalStep(BuildContext context) {
    const budgets = ['Tiết kiệm', 'Cân bằng', 'Premium'];
    const times = ['<15 phút', '15-30 phút', '30-45 phút'];
    return _StepFrame(
      title: 'Bữa ăn nên phù hợp với nhịp sống nào?',
      subtitle:
          'Ngân sách và thời gian nấu giúp meal plan thực tế hơn, dễ theo hơn.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CoachNote(
            text:
                'CoreHealth sẽ ưu tiên món ăn vừa với ví tiền và thời gian chuẩn bị của bạn.',
          ),
          const SizedBox(height: 22),
          Text('Ngân sách mỗi bữa',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
            child: Wrap(
              spacing: 12,
              runSpacing: 14,
              children: budgets.map((item) {
                return _ActivityChip(
                  label: item,
                  selected: mealBudget == item,
                  onTap: () => setState(() => mealBudget = item),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 26),
          Text('Thời gian nấu', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
            child: Wrap(
              spacing: 12,
              runSpacing: 14,
              children: times.map((item) {
                return _ActivityChip(
                  label: item,
                  selected: cookingTime == item,
                  onTap: () => setState(() => cookingTime = item),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nutritionPriorityStep(BuildContext context) {
    const items = [
      'Giàu protein',
      'Cân bằng macro',
      'Giảm calo',
      'Món Việt',
      'Meal prep',
      'Dễ mua nguyên liệu',
      'Ít tinh bột',
      'Nhiều rau',
    ];
    return _StepFrame(
      title: 'Bạn muốn meal plan ưu tiên điều gì?',
      subtitle:
          'Chọn các tiêu chí quan trọng nhất để CoreHealth gợi ý đúng khẩu vị và mục tiêu.',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
        child: Wrap(
          spacing: 12,
          runSpacing: 14,
          children: items.map((item) {
            final selected = nutritionPriorities.contains(item);
            return _ActivityChip(
              label: item,
              selected: selected,
              onTap: () {
                setState(() {
                  if (selected) {
                    nutritionPriorities.remove(item);
                  } else {
                    nutritionPriorities.add(item);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _experienceStep(BuildContext context) {
    final items = [
      (
        value: _FitnessExperience.never,
        title: 'Chưa từng thành công',
        icon: Icons.remove_rounded,
      ),
      (
        value: _FitnessExperience.lost,
        title: 'Đã thành công nhưng sau đó mất cơ',
        icon: Icons.trending_down_rounded,
      ),
      (
        value: _FitnessExperience.usedTo,
        title: 'Tôi đã từng khỏe mạnh, bây giờ thì không',
        icon: Icons.ssid_chart_rounded,
      ),
      (
        value: _FitnessExperience.advanced,
        title: 'Đã thành công và hướng đến mục tiêu cao hơn!',
        icon: Icons.trending_up_rounded,
      ),
    ];
    return _StepFrame(
      title: 'Trải nghiệm trước đây của bạn với xây dựng cơ bắp như thế nào?',
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
        physics: const NeverScrollableScrollPhysics(),
        children: items
            .map(
              (item) => _ExperienceCard(
                title: item.title,
                icon: item.icon,
                selected: fitnessExperience == item.value,
                onTap: () => setState(() => fitnessExperience = item.value),
              ),
            )
            .toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Web-aligned extra survey steps (Tier 2b) — same value IDs as CoreHealth-FE.
  // ---------------------------------------------------------------------------

  Widget _singleChips(
    List<(String, String)> opts,
    String selected,
    void Function(String) onPick,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 14,
        children: opts
            .map((o) => _ActivityChip(
                  label: o.$2,
                  selected: selected == o.$1,
                  onTap: () => setState(() => onPick(o.$1)),
                ))
            .toList(),
      ),
    );
  }

  Widget _priorityStep(BuildContext context) => _StepFrame(
        title: 'Kế hoạch nên ưu tiên điều gì?',
        subtitle:
            'CoreHealth dùng để cân chỉnh độ chặt giữa dinh dưỡng và tập luyện.',
        child: _singleChips(
          const [
            ('balanced', 'Cân bằng'),
            ('nutrition', 'Ưu tiên dinh dưỡng'),
            ('training', 'Ưu tiên tập luyện'),
            ('health', 'Ưu tiên sức khỏe'),
          ],
          priority,
          (id) => priority = id,
        ),
      );

  Widget _workoutLocationStep(BuildContext context) => _StepFrame(
        title: 'Bạn tập ở đâu là chính?',
        subtitle: 'Nơi tập quyết định bài tập và thiết bị coach gợi ý.',
        child: _singleChips(
          const [
            ('gym', 'Phòng gym'),
            ('home', 'Tại nhà'),
            ('outdoor', 'Ngoài trời'),
          ],
          workoutLocation,
          (id) => workoutLocation = id,
        ),
      );

  Widget _equipmentStep(BuildContext context) {
    const opts = [
      ('full-gym', 'Đủ thiết bị gym'),
      ('dumbbells', 'Tạ đơn'),
      ('barbell', 'Tạ đòn'),
      ('machines', 'Máy tập'),
      ('bands', 'Dây kháng lực'),
      ('bodyweight', 'Bodyweight'),
      ('cardio-machine', 'Máy cardio'),
    ];
    return _StepFrame(
      title: 'Bạn có sẵn thiết bị nào?',
      subtitle: 'Chọn tất cả những gì bạn dùng được.',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
        child: Wrap(
          spacing: 12,
          runSpacing: 14,
          children: opts.map((o) {
            final selected = equipment.contains(o.$1);
            return _ActivityChip(
              label: o.$2,
              selected: selected,
              onTap: () => setState(() {
                if (selected) {
                  equipment.remove(o.$1);
                } else {
                  equipment.add(o.$1);
                }
              }),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _sessionMinutesStep(BuildContext context) {
    const opts = [30, 45, 60, 75, 90];
    return _StepFrame(
      title: 'Mỗi buổi tập kéo dài bao lâu?',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
        child: Wrap(
          spacing: 12,
          runSpacing: 14,
          children: opts
              .map((m) => _ActivityChip(
                    label: '$m phút',
                    selected: sessionMinutes == m,
                    onTap: () => setState(() => sessionMinutes = m),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _workoutTimeStep(BuildContext context) => _StepFrame(
        title: 'Bạn thích tập vào lúc nào?',
        child: _singleChips(
          const [
            ('morning', 'Buổi sáng'),
            ('afternoon', 'Buổi chiều'),
            ('evening', 'Buổi tối'),
            ('flexible', 'Linh hoạt'),
          ],
          preferredWorkoutTime,
          (id) => preferredWorkoutTime = id,
        ),
      );

  Widget _dietTypeStep(BuildContext context) => _StepFrame(
        title: 'Kiểu ăn bạn muốn theo?',
        subtitle: 'Định hình cấu trúc macro và món ăn trong thực đơn.',
        child: _singleChips(
          const [
            ('balanced', 'Cân bằng'),
            ('high-protein', 'Giàu protein'),
            ('mediterranean', 'Địa Trung Hải'),
            ('low-carb', 'Ít carb'),
            ('plant-forward', 'Ưu tiên thực vật'),
            ('keto', 'Keto'),
          ],
          dietType,
          (id) => dietType = id,
        ),
      );

  Widget _mealFrequencyStep(BuildContext context) => _StepFrame(
        title: 'Bạn muốn ăn mấy bữa mỗi ngày?',
        child: _singleChips(
          const [
            ('2 meals', '2 bữa'),
            ('3 meals', '3 bữa'),
            ('3 meals + 1 snack', '3 bữa + 1 phụ'),
            ('4 meals', '4 bữa'),
            ('flexible', 'Linh hoạt'),
          ],
          mealFrequency,
          (id) => mealFrequency = id,
        ),
      );

  Widget _paywallStep(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            PhoneLayout.of(context).horizontalPadding,
            12,
            PhoneLayout.of(context).horizontalPadding,
            0,
          ),
          child: AdaptiveContent(
            maxWidth: 520,
            child: Column(
              children: [
                Text(
                  'NHẬN KẾ HOẠCH\nCÁ NHÂN CỦA\nBẠN!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.12,
                      ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppPalette.emerald, Color(0xFF18C290)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Token Wallet',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Nhận 25 token miễn phí để thử AI',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _PlanOption(
                  title: 'Starter',
                  price: '49k',
                  weekly: '55 token để thử AI plan và scan',
                  selected: selectedPlan == SubscriptionPlan.meal,
                  onTap: () =>
                      setState(() => selectedPlan = SubscriptionPlan.meal),
                ),
                const SizedBox(height: 14),
                _PlanOption(
                  title: 'Basic',
                  price: '99k',
                  weekly: '120 token phổ biến nhất',
                  selected: selectedPlan == SubscriptionPlan.workout,
                  onTap: () =>
                      setState(() => selectedPlan = SubscriptionPlan.workout),
                ),
                const SizedBox(height: 14),
                _PlanOption(
                  title: 'Plus',
                  price: '149k',
                  weekly: '190 token cho plan và chat nhiều hơn',
                  selected: selectedPlan == SubscriptionPlan.max,
                  badge: 'Đề xuất',
                  onTap: () =>
                      setState(() => selectedPlan = SubscriptionPlan.max),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppPalette.emeraldSoft,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppPalette.emerald.withValues(alpha: 0.24),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppPalette.emeraldDeep,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tracking cơ bản miễn phí. AI action sẽ dùng token chung trong ví.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppPalette.emeraldDeep,
                                    fontWeight: FontWeight.w800,
                                    height: 1.25,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String get _bodyImage =>
      gender == Gender.female ? _femaleBodyImage : _maleBodyImage;

  static const List<String> _desiredBodyImages = [
    'assets/images/onboarding/size_body/male_body_firm.png',
    'assets/images/onboarding/size_body/male_body_muscle.png',
    'assets/images/onboarding/size_body/male_body_medium.png',
    'assets/images/onboarding/size_body/male_body_fat.png',
    'assets/images/onboarding/size_body/male_body_fat.png',
  ];

  static const List<String> _desiredBodyFatPercents = [
    '7%~10%',
    '11%~14%',
    '15%~18%',
    '19%~22%',
    '23%+',
  ];

  static String _desiredBodyImage(int index) {
    final safeIndex = index.clamp(0, _desiredBodyImages.length - 1).toInt();
    return _desiredBodyImages[safeIndex];
  }

  static String _desiredBodyFatPercent(int index) {
    final safeIndex =
        index.clamp(0, _desiredBodyFatPercents.length - 1).toInt();
    return _desiredBodyFatPercents[safeIndex];
  }

  static ({
    String title,
    String badge,
    String message,
    Color color,
  }) _desiredBodyInsight(int index) {
    return switch (index) {
      0 => (
          title: 'Mỡ cơ thể mục tiêu của bạn',
          badge: 'Mục tiêu rất săn chắc',
          message:
              'Mức này cần kỷ luật cao về ăn uống, tập luyện và phục hồi. Phù hợp hơn khi bạn đã có nền tảng tập ổn định.',
          color: AppPalette.emeraldDeep,
        ),
      1 => (
          title: 'Mỡ cơ thể mục tiêu của bạn',
          badge: 'Săn chắc, khả thi',
          message:
              'Đây là vùng mục tiêu cân bằng: cơ thể gọn hơn, vẫn đủ năng lượng để tập và duy trì thói quen lâu dài.',
          color: AppPalette.emeraldDeep,
        ),
      2 => (
          title: 'Mỡ cơ thể mục tiêu của bạn',
          badge: 'Dễ duy trì',
          message:
              'Mức này thực tế với phần lớn người mới bắt đầu. Kế hoạch sẽ ưu tiên giảm mỡ chậm, đều và ít áp lực.',
          color: AppPalette.blue,
        ),
      3 => (
          title: 'Mỡ cơ thể hiện tại hoặc mốc chuyển tiếp',
          badge: 'Nên giảm dần',
          message:
              'Nếu đây là dáng bạn đang hướng tới, CoreHealth sẽ vẫn ưu tiên sức khỏe. Mục tiêu tốt hơn là giảm từng bước về vùng dễ duy trì.',
          color: AppPalette.orange,
        ),
      _ => (
          title: 'Mỡ cơ thể hiện tại hoặc mốc chuyển tiếp',
          badge: 'Không nên xem là đích cuối',
          message:
              'Vùng này thường phù hợp để ghi nhận điểm bắt đầu hơn là mục tiêu dài hạn. Kế hoạch sẽ đề xuất giảm mỡ an toàn và vừa sức.',
          color: AppPalette.orange,
        ),
    };
  }

  static _BodyShape _desiredShapeFromIndex(int index) {
    return switch (index) {
      0 => _BodyShape.toned,
      1 => _BodyShape.muscular,
      2 => _BodyShape.average,
      3 => _BodyShape.soft,
      _ => _BodyShape.soft,
    };
  }
}

enum _StepKind { form, choice, measure, story, section, loading }

class _SurveyStep {
  const _SurveyStep(this.title, this.kind, {this.build, this.canContinue});
  final String title;
  final _StepKind kind;

  /// Renders this step. Single source of truth — no separate index switch.
  final Widget Function(BuildContext)? build;

  /// Whether the user may advance from this step. Null = always allowed.
  final bool Function()? canContinue;
}

class _SurveyTopBar extends StatelessWidget {
  const _SurveyTopBar({
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
    required this.inverted,
  });

  final int currentStep;
  final int totalSteps;
  final VoidCallback onBack;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final progress = (currentStep + 1) / totalSteps;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(
              Icons.chevron_left_rounded,
              color: inverted ? Colors.white : AppPalette.text,
              size: 34,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: inverted
                    ? Colors.white.withValues(alpha: 0.22)
                    : AppPalette.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  inverted ? Colors.white : AppPalette.emerald,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _SectionIntroStep extends StatelessWidget {
  const _SectionIntroStep({
    required this.kicker,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String kicker;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final layout = PhoneLayout.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 620),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 22 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          layout.horizontalPadding,
          0,
          layout.horizontalPadding,
          28,
        ),
        child: AdaptiveContent(
          maxWidth: 520,
          child: Stack(
            children: [
              Align(
                alignment: const Alignment(0.98, 0.02),
                child: _SectionArrowMark(icon: icon),
              ),
              Align(
                alignment: const Alignment(-0.95, 0.02),
                child: Padding(
                  padding: const EdgeInsets.only(right: 70),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kicker.toUpperCase(),
                        style: tt.headlineSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 28),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 280),
                        child: Text(
                          title.toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.visible,
                          style: tt.displayLarge?.copyWith(
                            color: Colors.white,
                            fontSize: layout.isTiny ? 38 : 44,
                            fontWeight: FontWeight.w900,
                            height: 1.12,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionArrowMark extends StatelessWidget {
  const _SectionArrowMark({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 78,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(18, 0),
            child: Icon(
              Icons.chevron_right_rounded,
              color: AppPalette.emerald.withValues(alpha: 0.72),
              size: 92,
            ),
          ),
          Transform.translate(
            offset: const Offset(-4, 0),
            child: Icon(
              Icons.chevron_right_rounded,
              color: AppPalette.emeraldSoft.withValues(alpha: 0.92),
              size: 92,
            ),
          ),
          Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.26),
            size: 30,
          ),
        ],
      ),
    );
  }
}

class _StepFrame extends StatelessWidget {
  const _StepFrame({
    required this.title,
    required this.child,
    this.subtitle,
    this.greenWords = const {},
    this.blueWords = const {},
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Set<String> greenWords;
  final Set<String> blueWords;
  final bool centeredTitle = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          centeredTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        _ColoredTitle(
          title: title,
          greenWords: greenWords,
          blueWords: blueWords,
          centered: centeredTitle,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 16),
          Text(
            subtitle!,
            textAlign: centeredTitle ? TextAlign.center : TextAlign.start,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppPalette.mutedText,
                  fontWeight: FontWeight.w500,
                  height: 1.34,
                ),
          ),
        ],
        const SizedBox(height: 40),
        child,
      ],
    );
  }
}

class _AccentSlash extends StatelessWidget {
  const _AccentSlash({required this.centered});

  final bool centered;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Align(
        alignment: centered ? Alignment.center : Alignment.centerLeft,
        child: Transform.rotate(
          angle: 0.28,
          child: Container(
            width: 22,
            height: 96,
            decoration: BoxDecoration(
              color: AppPalette.blueSoft.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}

class _ColoredTitle extends StatelessWidget {
  const _ColoredTitle({
    required this.title,
    required this.greenWords,
    required this.blueWords,
    required this.centered,
  });

  final String title;
  final Set<String> greenWords;
  final Set<String> blueWords;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.displaySmall?.copyWith(
          fontSize: PhoneLayout.of(context).isTiny ? 28 : 32,
          fontWeight: FontWeight.w700,
          height: 1.12,
        );
    final spans = <TextSpan>[];
    var remaining = title;
    final highlights = [...greenWords, ...blueWords]
      ..sort((a, b) => b.length.compareTo(a.length));
    while (remaining.isNotEmpty) {
      String? match;
      for (final item in highlights) {
        if (remaining.startsWith(item)) {
          match = item;
          break;
        }
      }
      if (match != null) {
        spans.add(
          TextSpan(
            text: match,
            style: TextStyle(
              color: greenWords.contains(match)
                  ? AppPalette.emeraldDeep
                  : const Color(0xFF1677F2),
            ),
          ),
        );
        remaining = remaining.substring(match.length);
      } else {
        spans.add(TextSpan(text: remaining[0]));
        remaining = remaining.substring(1);
      }
    }
    return Text.rich(
      TextSpan(children: spans),
      textAlign: centered ? TextAlign.center : TextAlign.start,
      style: base,
    );
  }
}

class _CoachNote extends StatelessWidget {
  const _CoachNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppPalette.blueSoft,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppPalette.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_rounded, color: AppPalette.blue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppPalette.mutedText,
                    fontWeight: FontWeight.w500,
                    height: 1.34,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalChoiceCard extends StatelessWidget {
  const _GoalChoiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.1) : AppPalette.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? accent : AppPalette.borderLight,
            width: selected ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppPalette.shadow,
              blurRadius: 16,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: selected ? 0.18 : 0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: accent, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: selected
                              ? AppPalette.emeraldDeep
                              : AppPalette.text,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppPalette.mutedText,
                          fontWeight: FontWeight.w600,
                          height: 1.28,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: selected ? accent : AppPalette.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? accent : AppPalette.borderLight,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 18)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetWeightCard extends StatelessWidget {
  const _TargetWeightCard({
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.onDecrease,
    required this.onIncrease,
    required this.weightUnit,
    this.onValueTap,
  });

  final double currentWeightKg;
  final double targetWeightKg;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final _WeightUnit weightUnit;
  final VoidCallback? onValueTap;

  @override
  Widget build(BuildContext context) {
    final isKg = weightUnit == _WeightUnit.kg;
    final currentDisplay = isKg ? currentWeightKg : currentWeightKg * 2.20462;
    final targetDisplay = isKg ? targetWeightKg : targetWeightKg * 2.20462;
    final delta = targetDisplay - currentDisplay;
    final unitStr = isKg ? 'kg' : 'lb';

    final deltaText = delta.abs() < 0.1
        ? 'Giữ ổn định'
        : '${delta > 0 ? '+' : '-'}${_formatDecimal(delta.abs())} $unitStr';
    final deltaColor = delta.abs() < 0.1
        ? AppPalette.blue
        : delta > 0
            ? AppPalette.emeraldDeep
            : AppPalette.orange;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.borderLight),
        boxShadow: const [
          BoxShadow(
            color: AppPalette.shadow,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _TargetMetric(
                  label: 'Hiện tại',
                  value: '${_formatDecimal(currentDisplay)} $unitStr',
                ),
              ),
              Container(width: 1, height: 42, color: AppPalette.borderLight),
              Expanded(
                child: _TargetMetric(
                  label: 'Mục tiêu',
                  value: '${_formatDecimal(targetDisplay)} $unitStr',
                  color: AppPalette.emeraldDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TargetAdjustButton(
                icon: Icons.remove_rounded,
                onTap: onDecrease,
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onValueTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Text(
                        '${_formatDecimal(targetDisplay)} $unitStr',
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: AppPalette.text,
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        deltaText,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: deltaColor,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      if (onValueTap != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppPalette.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppPalette.borderLight),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.keyboard_rounded,
                                size: 11,
                                color: AppPalette.mutedText,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Tự nhập',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppPalette.mutedText,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              _TargetAdjustButton(
                icon: Icons.add_rounded,
                onTap: onIncrease,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TargetMetric extends StatelessWidget {
  const _TargetMetric({
    required this.label,
    required this.value,
    this.color = AppPalette.text,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppPalette.mutedText,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
        ),
      ],
    );
  }
}

class _TargetAdjustButton extends StatelessWidget {
  const _TargetAdjustButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppPalette.surfaceElevated,
          shape: BoxShape.circle,
          border: Border.all(color: AppPalette.borderLight),
        ),
        child: Icon(icon, color: AppPalette.text),
      ),
    );
  }
}

class _GoalTimelineSelector extends StatelessWidget {
  const _GoalTimelineSelector({
    required this.value,
    required this.onChanged,
  });

  final _GoalTimeline value;
  final ValueChanged<_GoalTimeline> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      (_GoalTimeline.one, '1 tháng'),
      (_GoalTimeline.three, '3 tháng'),
      (_GoalTimeline.six, '6 tháng'),
      (_GoalTimeline.twelve, '12 tháng'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Timeline',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: items.map((item) {
            final selected = value == item.$1;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: item == items.last ? 0 : 8),
                child: GestureDetector(
                  onTap: () => onChanged(item.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppPalette.emeraldSoft
                          : AppPalette.surfaceElevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            selected ? AppPalette.emerald : AppPalette.border,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      item.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: selected
                                ? AppPalette.emeraldDeep
                                : AppPalette.text,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _GenderImageCard extends StatelessWidget {
  const _GenderImageCard({
    required this.title,
    required this.image,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String image;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 270,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 22),
        decoration: BoxDecoration(
          color: selected ? AppPalette.emeraldSoft : AppPalette.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: selected ? AppPalette.emerald : Colors.transparent,
            width: selected ? 2.2 : 0,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppPalette.shadow,
              blurRadius: 22,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -78,
              left: -36,
              right: -36,
              child: Image.asset(
                image,
                height: 292,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
            if (selected)
              const Positioned(
                top: 12,
                right: 12,
                child: _CheckDot(),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color:
                          selected ? AppPalette.emeraldDeep : AppPalette.text,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckDot extends StatelessWidget {
  const _CheckDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 31,
      height: 31,
      decoration: BoxDecoration(
        color: AppPalette.emerald,
        shape: BoxShape.circle,
        border: Border.all(color: AppPalette.surface, width: 2.4),
      ),
      child: const Icon(Icons.check_rounded, color: Colors.white, size: 19),
    );
  }
}

class _FocusOption extends StatelessWidget {
  const _FocusOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: selected ? AppPalette.emeraldSoft : AppPalette.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppPalette.emerald : AppPalette.borderLight,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? null
              : const [
                  BoxShadow(
                    color: AppPalette.shadow,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color:
                          selected ? AppPalette.emeraldDeep : AppPalette.text,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            if (selected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppPalette.emerald,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 15),
              ),
          ],
        ),
      ),
    );
  }
}

class _MeasureInputField extends StatelessWidget {
  const _MeasureInputField({
    required this.initialValue,
    required this.label,
    required this.onChanged,
    this.decimal = false,
    this.autofocus = true,
  });

  final String initialValue;
  final String label;
  final ValueChanged<String> onChanged;
  final bool decimal;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      autofocus: autofocus,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppPalette.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppPalette.borderLight),
        ),
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      textInputAction: TextInputAction.done,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
    );
  }
}

class _BodyFocusConnectorPainter extends CustomPainter {
  _BodyFocusConnectorPainter({
    required this.gender,
    required Set<String> focusParts,
  }) : focusParts = Set.unmodifiable(focusParts);

  static const _partOrder = ['Cánh tay', 'Vai', 'Ngực', 'Bụng', 'Chân'];
  static const _visibleBadgeCount = 6;
  static const _badgeWidth = 145.0;
  static const _badgeHeight = 60.0;
  static const _badgeGap = 10.0;
  static const _figureRight = -120.0;
  static const _figureTop = -130.0;
  static const _figureWidth = 440.0;
  static const _referenceWidth = 340.0;
  static const _referenceHeight = 560.0;

  final Gender gender;
  final Set<String> focusParts;

  @override
  void paint(Canvas canvas, Size size) {
    const scaleX = _figureWidth / _referenceWidth;
    final figureHeight = size.height - _figureTop + 140;
    final scaleY = figureHeight / _referenceHeight;
    final figureLeft = size.width - _figureWidth - _figureRight;
    const badgeGroupHeight = _visibleBadgeCount * (_badgeHeight + _badgeGap);
    final badgeTop = (size.height - badgeGroupHeight) / 2;
    final markers = _markersFor(gender);

    for (var index = 0; index < _partOrder.length; index++) {
      final part = _partOrder[index];
      final selected =
          focusParts.contains(part) || focusParts.contains('Toàn Thân');
      final marker = markers[index];
      final start = Offset(
        _badgeWidth + 4,
        badgeTop + index * (_badgeHeight + _badgeGap) + _badgeHeight / 2,
      );
      final end = Offset(
        figureLeft + marker.dx * scaleX,
        _figureTop + marker.dy * scaleY,
      );
      final control = Offset(
        start.dx + (end.dx - start.dx) * 0.48,
        start.dy,
      );
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
      final color = selected
          ? AppPalette.emerald
          : AppPalette.text.withValues(alpha: 0.18);

      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = selected ? 2.2 : 1.4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        start,
        selected ? 3.5 : 2.5,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BodyFocusConnectorPainter oldDelegate) {
    return oldDelegate.gender != gender ||
        oldDelegate.focusParts.length != focusParts.length ||
        !oldDelegate.focusParts.containsAll(focusParts);
  }

  static List<Offset> _markersFor(Gender gender) {
    if (gender == Gender.male) {
      return const [
        Offset(107.5, 206.9),
        Offset(123.5, 158.7),
        Offset(173.5, 164.9),
        Offset(173.1, 219.6),
        Offset(138.0, 380.1),
      ];
    }

    return const [
      Offset(85, 185),
      Offset(120, 140),
      Offset(150, 210),
      Offset(155, 280),
      Offset(135, 390),
    ];
  }
}

class _BodyFocusFigure extends StatelessWidget {
  const _BodyFocusFigure({
    required this.gender,
    required this.focusParts,
    required this.maleImage,
    required this.femaleImage,
  });

  final Gender gender;
  final Set<String> focusParts;
  final String maleImage;
  final String femaleImage;

  @override
  Widget build(BuildContext context) {
    final image = gender == Gender.female ? femaleImage : maleImage;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Heat spots are defined relative to a 340x560 reference frame
        const refW = 340.0;
        const refH = 560.0;
        final scaleX = constraints.maxWidth / refW;
        final scaleY = constraints.maxHeight / refH;

        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Image.asset(image, fit: BoxFit.contain),
            ),
            if (gender == Gender.male)
              ..._maleOverlayImagesFor(focusParts).map(
                (asset) {
                  final opacity = asset.endsWith('male_belly.png') ? 0.68 : 1.0;
                  return Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: opacity,
                        child: Image.asset(asset, fit: BoxFit.contain),
                      ),
                    ),
                  );
                },
              )
            else
              ..._heatSpotsFor(focusParts).map(
                (spot) => Positioned(
                  left: spot.left * scaleX,
                  top: spot.top * scaleY,
                  child: Container(
                    width: spot.width * scaleX,
                    height: spot.height * scaleY,
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withValues(alpha: 0.22),
                          blurRadius: 24,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ..._markersFor(gender).map(
              (dot) => Positioned(
                left: dot.dx * scaleX - 5,
                top: dot.dy * scaleY - 5,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppPalette.text.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<String> _maleOverlayImagesFor(Set<String> parts) {
    const overlays = {
      'Cánh tay': 'assets/images/onboarding/male_body/male_arm.png',
      'Vai': 'assets/images/onboarding/male_body/male_shoulder.png',
      'Ngực': 'assets/images/onboarding/male_body/male_chest.png',
      'Bụng': 'assets/images/onboarding/male_body/male_belly.png',
      'Chân': 'assets/images/onboarding/male_body/male_foot.png',
    };
    final all = parts.contains('Toàn Thân');
    return [
      for (final entry in overlays.entries)
        if (all || parts.contains(entry.key)) entry.value,
    ];
  }

  List<_HeatSpot> _heatSpotsFor(Set<String> parts) {
    // Positions relative to 340x560 reference frame
    final all = parts.contains('Toàn Thân');
    return [
      if (all || parts.contains('Cánh tay')) ...const [
        _HeatSpot(55, 175, 50, 130),
        _HeatSpot(235, 175, 50, 130),
      ],
      if (all || parts.contains('Vai')) const _HeatSpot(90, 130, 160, 45),
      if (all || parts.contains('Ngực')) const _HeatSpot(105, 175, 130, 55),
      if (all || parts.contains('Bụng')) const _HeatSpot(115, 235, 110, 75),
      if (all || parts.contains('Chân')) ...const [
        _HeatSpot(110, 340, 52, 160),
        _HeatSpot(178, 340, 52, 160),
      ],
    ];
  }

  List<Offset> _markersFor(Gender gender) {
    if (gender == Gender.male) {
      return const [
        Offset(107.5, 206.9), // Cánh tay
        Offset(123.5, 158.7), // Vai
        Offset(173.5, 164.9), // Ngực
        Offset(173.1, 219.6), // Bụng
        Offset(138.0, 380.1), // Chân
      ];
    }

    // Marker positions relative to 340x560 reference frame.
    return const [
      Offset(85, 185), // Cánh tay
      Offset(120, 140), // Vai
      Offset(150, 210), // Ngực
      Offset(155, 280), // Bụng
      Offset(135, 390), // Chân
    ];
  }
}

class _HeatSpot {
  const _HeatSpot(this.left, this.top, this.width, this.height);

  final double left;
  final double top;
  final double width;
  final double height;
}

class _PillChoice extends StatelessWidget {
  const _PillChoice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.centered = false,
  });

  final String label;
  final bool selected;
  final bool centered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        alignment: centered ? Alignment.center : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: selected ? AppPalette.emeraldSoft : AppPalette.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppPalette.emerald : AppPalette.borderLight,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppPalette.shadow,
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: selected ? AppPalette.emeraldDeep : AppPalette.mutedText,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _BorderedThumbShape extends SliderComponentShape {
  const _BorderedThumbShape({
    required this.radius,
    required this.borderWidth,
    required this.borderColor,
  });

  final double radius;
  final double borderWidth;
  final Color borderColor;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      Size.fromRadius(radius + borderWidth);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    // White border
    canvas.drawCircle(
      center,
      radius + borderWidth,
      Paint()..color = borderColor,
    );
    // Green fill
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = sliderTheme.thumbColor ?? AppPalette.emerald,
    );
  }
}

class _SegmentedBadge<T> extends StatelessWidget {
  const _SegmentedBadge({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final List<({T value, String label})> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 58,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: AppPalette.surfaceElevated,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppPalette.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) {
            final selected = option.value == value;
            return GestureDetector(
              onTap: () => onChanged(option.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 92,
                decoration: BoxDecoration(
                  color: selected ? AppPalette.text : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  option.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: selected ? Colors.white : AppPalette.subtleText,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _VerticalMeasurePicker extends StatefulWidget {
  const _VerticalMeasurePicker({
    required this.value,
    required this.unit,
    required this.display,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onDisplayTap,
  });

  final double value;
  final String unit;
  final String display;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final VoidCallback onDisplayTap;

  @override
  State<_VerticalMeasurePicker> createState() => _VerticalMeasurePickerState();
}

class _VerticalMeasurePickerState extends State<_VerticalMeasurePicker>
    with SingleTickerProviderStateMixin {
  late AnimationController _flingController;
  double _velocity = 0;

  @override
  void initState() {
    super.initState();
    _flingController = AnimationController.unbounded(vsync: this)
      ..addListener(_onFling);
  }

  @override
  void dispose() {
    _flingController.dispose();
    super.dispose();
  }

  void _onFling() {
    final next = _flingController.value.clamp(widget.min, widget.max);
    widget.onChanged(next);
    if (next <= widget.min || next >= widget.max) {
      _flingController.stop();
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _flingController.stop();
    final next =
        (widget.value - details.delta.dy * 0.4).clamp(widget.min, widget.max);
    widget.onChanged(next);
  }

  void _onDragEnd(DragEndDetails details) {
    _velocity = -details.primaryVelocity! * 0.4;
    _flingController.value = widget.value;
    _flingController.animateWith(
      FrictionSimulation(0.003, widget.value, _velocity),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: _onDragUpdate,
        onVerticalDragEnd: _onDragEnd,
        child: Stack(
          children: [
            // Value display above the green line
            Positioned(
              left: 0,
              right: 0,
              bottom: 130 + 12,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onDisplayTap,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppPalette.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppPalette.borderLight),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.keyboard_rounded,
                            size: 13,
                            color: AppPalette.mutedText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Chạm để tự nhập',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppPalette.mutedText,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          widget.display,
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
                                fontSize: 56,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.unit,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: AppPalette.mutedText,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Green indicator line at center
            Center(
              child: Container(
                height: 1.5,
                margin: const EdgeInsets.only(left: 100, right: 5),
                color: AppPalette.emeraldDeep,
              ),
            ),
            // Ruler on the right that scrolls with value
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 80,
              child: ClipRect(
                child: CustomPaint(
                  painter: _VerticalRulerPainter(
                    value: widget.value,
                    min: widget.min,
                    max: widget.max,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerticalRulerPainter extends CustomPainter {
  const _VerticalRulerPainter({
    required this.value,
    required this.min,
    required this.max,
  });

  final double value;
  final double min;
  final double max;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    const ppu = 8.0; // pixels per 1 cm

    final paint = Paint()..strokeCap = StrokeCap.round;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Only draw ticks visible in viewport
    final visibleRange = (size.height / 2 / ppu).ceil() + 2;
    final startCm = (value - visibleRange).floor();
    final endCm = (value + visibleRange).ceil();

    for (var cm = startCm; cm <= endCm; cm++) {
      if (cm < min || cm > max) continue;
      final y = centerY - (cm - value) * ppu;
      final major = cm % 10 == 0;
      final mid = cm % 5 == 0 && !major;

      final tickLength = major
          ? 44.0
          : mid
              ? 28.0
              : 16.0;

      paint
        ..color = major
            ? AppPalette.text.withValues(alpha: 0.75)
            : AppPalette.text.withValues(alpha: mid ? 0.4 : 0.2)
        ..strokeWidth = major
            ? 2.5
            : mid
                ? 1.8
                : 1.2;

      canvas.drawLine(
        Offset(size.width - tickLength, y),
        Offset(size.width - 4, y),
        paint,
      );

      if (major) {
        textPainter.text = TextSpan(
          text: '$cm',
          style: TextStyle(
            color: AppPalette.text.withValues(alpha: 0.6),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(size.width - tickLength - textPainter.width - 6,
              y - textPainter.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _VerticalRulerPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}

class _YearWheel extends StatelessWidget {
  const _YearWheel({required this.year, required this.onChanged});

  final int year;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final years = [year - 2, year - 1, year, year + 1, year + 2];
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.delta.dy > 2) {
          onChanged((year - 1).clamp(1930, 2016).toInt());
        }
        if (details.delta.dy < -2) {
          onChanged((year + 1).clamp(1930, 2016).toInt());
        }
      },
      child: Column(
        children: years.map((item) {
          final selected = item == year;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(item),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: selected ? 88 : 76,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 2),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppPalette.emeraldSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                border: selected
                    ? Border.all(color: AppPalette.emerald, width: 2)
                    : null,
              ),
              child: Text(
                '$item',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontSize: selected ? 42 : 34,
                      color: selected
                          ? AppPalette.emeraldDeep
                          : AppPalette.subtleText.withValues(
                              alpha: selected ? 1 : 0.45,
                            ),
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FadedBodyPreview extends StatelessWidget {
  const _FadedBodyPreview({required this.image, required this.opacity});

  final String image;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Image.asset(image, height: 210, fit: BoxFit.contain),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.value,
    required this.message,
    required this.color,
  });

  final String title;
  final String value;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPalette.blueSoft,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.smart_toy_rounded, color: AppPalette.blue),
              const SizedBox(width: 10),
              Expanded(
                child:
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(message, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _BodyShapeCard extends StatelessWidget {
  const _BodyShapeCard({
    required this.label,
    required this.image,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String image;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 118,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: selected ? AppPalette.emeraldSoft : AppPalette.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppPalette.emerald : AppPalette.borderLight,
            width: selected ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppPalette.shadow,
              blurRadius: 16,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              Positioned(
                right: 10,
                top: -24,
                bottom: -10,
                child: Image.asset(image, width: 146, fit: BoxFit.cover),
              ),
              Positioned(
                left: 24,
                top: 0,
                bottom: 0,
                right: 120,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: selected
                              ? AppPalette.emeraldDeep
                              : AppPalette.text,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ),
              if (selected)
                const Positioned(right: 16, top: 16, child: _CheckDot()),
            ],
          ),
        ),
      ),
    );
  }
}

class _HorizontalWeightRuler extends StatefulWidget {
  const _HorizontalWeightRuler({
    required this.valueKg,
    required this.onChanged,
  });

  final double valueKg;
  final ValueChanged<double> onChanged;

  @override
  State<_HorizontalWeightRuler> createState() => _HorizontalWeightRulerState();
}

class _HorizontalWeightRulerState extends State<_HorizontalWeightRuler>
    with SingleTickerProviderStateMixin {
  late AnimationController _flingController;

  @override
  void initState() {
    super.initState();
    _flingController = AnimationController.unbounded(vsync: this)
      ..addListener(_onFling);
  }

  @override
  void dispose() {
    _flingController.dispose();
    super.dispose();
  }

  void _onFling() {
    final next = _flingController.value.clamp(30.0, 200.0);
    widget.onChanged(next);
    if (next <= 30.0 || next >= 200.0) {
      _flingController.stop();
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _flingController.stop();
    final next = (widget.valueKg - details.delta.dx * 0.08).clamp(30.0, 200.0);
    widget.onChanged(next);
  }

  void _onDragEnd(DragEndDetails details) {
    _flingController.value = widget.valueKg;
    _flingController.animateWith(
      FrictionSimulation(
          0.003, widget.valueKg, -details.primaryVelocity! * 0.08),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: SizedBox(
        height: 100,
        width: double.infinity,
        child: ClipRect(
          child: CustomPaint(
            painter: _HorizontalRulerPainter(value: widget.valueKg),
          ),
        ),
      ),
    );
  }
}

class _HorizontalRulerPainter extends CustomPainter {
  const _HorizontalRulerPainter({required this.value});

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.width / 2;
    const ppu = 16.0; // pixels per 1 kg

    final paint = Paint()..strokeCap = StrokeCap.round;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final visibleRange = (size.width / 2 / ppu).ceil() + 2;
    final startKg = (value - visibleRange).floor();
    final endKg = (value + visibleRange).ceil();

    for (var kg = startKg; kg <= endKg; kg++) {
      if (kg < 30 || kg > 200) continue;
      final x = center + (kg - value) * ppu;
      final major = kg % 10 == 0;
      final mid = kg % 5 == 0 && !major;

      final tickHeight = major
          ? 44.0
          : mid
              ? 28.0
              : 16.0;

      paint
        ..color = major
            ? AppPalette.text.withValues(alpha: 0.75)
            : AppPalette.text.withValues(alpha: mid ? 0.4 : 0.2)
        ..strokeWidth = major
            ? 2.5
            : mid
                ? 1.8
                : 1.2;

      canvas.drawLine(
        Offset(x, size.height - 4),
        Offset(x, size.height - 4 - tickHeight),
        paint,
      );

      if (major) {
        textPainter.text = TextSpan(
          text: '$kg',
          style: TextStyle(
            color: AppPalette.text.withValues(alpha: 0.6),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2,
              size.height - 4 - tickHeight - textPainter.height - 4),
        );
      }
    }

    // Green indicator line at center
    paint
      ..color = AppPalette.emeraldDeep
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(center, 0),
      Offset(center, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _HorizontalRulerPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}

class _BmiCard extends StatelessWidget {
  const _BmiCard({
    required this.bmi,
    required this.color,
    required this.message,
  });

  final double bmi;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppPalette.blueSoft,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Text(
            _formatDecimal(bmi),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BMI hiện tại',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(message, style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BeforeAfterCard extends StatelessWidget {
  const _BeforeAfterCard({
    required this.label,
    required this.image,
    this.selected = false,
    this.faded = false,
  });

  final String label;
  final String image;
  final bool selected;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: faded ? 0.72 : 1,
      child: Container(
        width: 174,
        height: 274,
        decoration: BoxDecoration(
          color: AppPalette.surface,
          borderRadius: BorderRadius.circular(22),
          border:
              selected ? Border.all(color: AppPalette.emerald, width: 2) : null,
          boxShadow: const [
            BoxShadow(
              color: AppPalette.shadow,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(child: Image.asset(image, fit: BoxFit.cover)),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: selected ? AppPalette.emerald : AppPalette.surfaceElevated,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: selected ? Colors.white : AppPalette.text,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarBadge extends StatelessWidget {
  const _CalendarBadge({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 150,
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: AppPalette.shadow,
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 52,
            decoration: const BoxDecoration(
              color: AppPalette.emerald,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Ring(),
                _Ring(),
                _Ring(),
                _Ring(),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                '$days',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 68,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 28,
      decoration: BoxDecoration(
        color: AppPalette.mutedText,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}

class _IconChoiceRow extends StatelessWidget {
  const _IconChoiceRow({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: selected ? AppPalette.emeraldSoft : AppPalette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppPalette.emerald : AppPalette.borderLight,
            width: selected ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppPalette.shadow,
              blurRadius: 16,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? AppPalette.emeraldDeep : AppPalette.text),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color:
                          selected ? AppPalette.emeraldDeep : AppPalette.text,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            selected
                ? Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: AppPalette.emerald,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 16),
                  )
                : Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: AppPalette.surfaceElevated,
                      shape: BoxShape.circle,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _PotentialChartPainter extends CustomPainter {
  const _PotentialChartPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(28, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.62,
        size.width * 0.9,
        size.height * 0.18,
      );
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF3BC8F4), AppPalette.emerald, Colors.redAccent],
      ).createShader(Offset.zero & size)
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);
    final fill = Path.from(path)
      ..lineTo(size.width * 0.9, size.height * 0.76)
      ..lineTo(28, size.height * 0.78)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppPalette.emerald.withValues(alpha: 0.18),
            AppPalette.emerald.withValues(alpha: 0.02),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawCircle(
      Offset(42, size.height * 0.68),
      28,
      Paint()..color = AppPalette.surface,
    );
    canvas.drawCircle(
      Offset(size.width * 0.86, size.height * 0.18),
      28,
      Paint()..color = AppPalette.surface,
    );
    _paintIcon(canvas, '!', Offset(42, size.height * 0.68), Colors.orange);
    _paintIcon(canvas, '✓', Offset(size.width * 0.86, size.height * 0.18),
        AppPalette.emeraldDeep);
  }

  void _paintIcon(Canvas canvas, String text, Offset center, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 30,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ActivityChip extends StatelessWidget {
  const _ActivityChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppPalette.emeraldSoft : AppPalette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppPalette.emerald : AppPalette.border,
            width: selected ? 2.0 : 1.2,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: selected ? AppPalette.emeraldDeep : AppPalette.text,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? AppPalette.emeraldSoft : AppPalette.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? AppPalette.emerald : AppPalette.borderLight,
            width: selected ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppPalette.shadow,
              blurRadius: 16,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          children: [
            const Spacer(),
            Icon(icon,
                color: selected ? AppPalette.emeraldDeep : AppPalette.orange,
                size: 58),
            const Spacer(),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YesNoCard extends StatelessWidget {
  const _YesNoCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 150,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.11) : AppPalette.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? color : AppPalette.borderLight,
            width: selected ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppPalette.shadow,
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 18),
            Text(
              label,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutMiniCard extends StatelessWidget {
  const _WorkoutMiniCard({required this.image});

  final String image;
  final bool large = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: large ? 190 : 110,
      height: large ? 170 : 98,
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: AppPalette.shadow,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(image, fit: BoxFit.cover),
          if (large)
            const Positioned(
              left: 16,
              bottom: 14,
              child: Text(
                'NGÀY 1\n8 phút | 125 kcal',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  height: 1.08,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlanOption extends StatelessWidget {
  const _PlanOption({
    required this.title,
    required this.price,
    required this.weekly,
    required this.onTap,
    this.selected = false,
    this.badge,
  });

  final String title;
  final String price;
  final String weekly;
  final VoidCallback onTap;
  final bool selected;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(18, badge == null ? 20 : 42, 18, 18),
            decoration: BoxDecoration(
              color: selected
                  ? AppPalette.emeraldSoft
                  : AppPalette.surfaceElevated,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? AppPalette.emerald : Colors.transparent,
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppPalette.emerald.withValues(alpha: 0.14),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: selected
                                  ? AppPalette.emeraldDeep
                                  : AppPalette.text,
                              fontWeight: FontWeight.w900,
                              height: 1.12,
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          price,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: selected
                                        ? AppPalette.emeraldDeep
                                        : AppPalette.text,
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white.withValues(alpha: 0.72)
                              : AppPalette.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: selected
                                ? AppPalette.emerald.withValues(alpha: 0.28)
                                : AppPalette.borderLight,
                          ),
                        ),
                        child: Text(
                          weekly,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: selected
                                        ? AppPalette.emeraldDeep
                                        : AppPalette.mutedText,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                  ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color:
                            selected ? AppPalette.emerald : AppPalette.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? AppPalette.emerald
                              : AppPalette.borderLight,
                        ),
                      ),
                      child: selected
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 17)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              right: 16,
              top: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppPalette.emerald,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge!,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BottomCta extends StatelessWidget {
  const _BottomCta({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: enabled
                  ? const LinearGradient(
                      colors: [Color(0xFF404040), Color(0xFF040404)],
                    )
                  : null,
              color: enabled ? null : const Color(0xFFC9C9C9),
              borderRadius: BorderRadius.circular(999),
              boxShadow: enabled
                  ? const [
                      BoxShadow(
                        color: AppPalette.shadowHeavy,
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ]
                  : null,
            ),
            child: ElevatedButton(
              onPressed: enabled ? onPressed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                label,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _feetDisplay(double cm) {
  final totalInches = cm / 2.54;
  final feet = totalInches ~/ 12;
  final inches = (totalInches - feet * 12).round();
  return '$feet\'$inches"';
}

double? _parseLocalizedDouble(String raw) {
  return double.tryParse(raw.trim().replaceAll(',', '.'));
}

String _formatDecimal(double value) {
  return value.toStringAsFixed(1).replaceAll('.', ',');
}
