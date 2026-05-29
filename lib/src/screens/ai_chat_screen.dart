import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/visuals.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  var _showHistory = false;
  var _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = CoreHealthScope.of(context);
      setState(() => _showHistory = controller.chatSessions.isNotEmpty);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(AppController controller) async {
    final text = _messageController.text.trim();
    if (text.isEmpty || controller.isWellnessChatLoading) return;
    _messageController.clear();
    await controller.sendSessionChatMessage(text);
    setState(() => _showHistory = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = CoreHealthScope.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Center(
            child: CoreHealthIconButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: Text(
          'AI Coach',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CoreHealthIconButton(
              icon: _showHistory
                  ? Icons.chat_bubble_outline_rounded
                  : Icons.history_rounded,
              onTap: () => setState(() => _showHistory = !_showHistory),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            if (!controller.profile.canAccessCoach(CoachType.wellness)) {
              return _LockedAiState(
                bottomInset: bottomInset,
                onClose: () => Navigator.of(context).pop(),
              );
            }

            final session = controller.activeChatSession;
            final loading = controller.isWellnessChatLoading;
            if (!_showHistory &&
                session != null &&
                session.history.isNotEmpty) {
              _scrollToBottom();
            }

            return Column(
              children: [
                _AiStatusHeader(
                  tokenBalance: controller.profile.tokenBalance,
                  sessionCount: controller.chatSessions.length,
                  onNewChat: () {
                    controller.startNewChatSession();
                    setState(() => _showHistory = false);
                  },
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _showHistory
                        ? _HistoryPanel(
                            key: const ValueKey('history'),
                            sessions: controller.chatSessions,
                            searchController: _searchController,
                            selectedCategory: _selectedCategory,
                            onSearchChanged: () => setState(() {}),
                            onCategoryChanged: (value) {
                              setState(() => _selectedCategory = value);
                            },
                            onSessionSelected: (sessionId) {
                              controller.selectChatSession(sessionId);
                              setState(() => _showHistory = false);
                            },
                            onDeleteSession: controller.deleteChatSession,
                          )
                        : _ChatPanel(
                            key: const ValueKey('chat'),
                            session: session,
                            loading: loading,
                            scrollController: _scrollController,
                            messageController: _messageController,
                            onSend: () => _sendMessage(controller),
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AiStatusHeader extends StatelessWidget {
  const _AiStatusHeader({
    required this.tokenBalance,
    required this.sessionCount,
    required this.onNewChat,
  });

  final int tokenBalance;
  final int sessionCount;
  final VoidCallback onNewChat;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        decoration: BoxDecoration(
          color: AppPalette.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppPalette.borderLight),
          boxShadow: const [
            BoxShadow(
              color: AppPalette.shadow,
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppPalette.emeraldSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: AppPalette.emeraldDeep,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CoreHealth AI đang sẵn sàng',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$sessionCount cuộc trò chuyện • $tokenBalance token',
                    style: tt.bodySmall?.copyWith(
                      color: AppPalette.mutedText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              tooltip: 'Cuộc trò chuyện mới',
              onPressed: onNewChat,
              style: IconButton.styleFrom(
                backgroundColor: AppPalette.emerald,
                foregroundColor: AppPalette.text,
              ),
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({
    super.key,
    required this.sessions,
    required this.searchController,
    required this.selectedCategory,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onSessionSelected,
    required this.onDeleteSession,
  });

  final List<ChatSession> sessions;
  final TextEditingController searchController;
  final String selectedCategory;
  final VoidCallback onSearchChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onSessionSelected;
  final ValueChanged<String> onDeleteSession;

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.trim().toLowerCase();
    final filteredSessions = sessions.where((session) {
      final matchesSearch = query.isEmpty ||
          session.title.toLowerCase().contains(query) ||
          session.history.any(
            (message) => message.text.toLowerCase().contains(query),
          );
      final matchesCategory =
          selectedCategory == 'All' || session.category == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: searchController,
            onChanged: (_) => onSearchChanged(),
            decoration: InputDecoration(
              hintText: 'Tìm trong lịch sử chat',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged();
                      },
                    ),
            ),
          ),
          const SizedBox(height: 12),
          _CategoryFilter(
            selectedCategory: selectedCategory,
            onChanged: onCategoryChanged,
          ),
          const SizedBox(height: 14),
          Expanded(
            child: filteredSessions.isEmpty
                ? const _EmptyHistoryState()
                : ListView.separated(
                    itemCount: filteredSessions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final session = filteredSessions[index];
                      return _HistoryTile(
                        session: session,
                        onTap: () => onSessionSelected(session.id),
                        onDelete: () => onDeleteSession(session.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({
    required this.selectedCategory,
    required this.onChanged,
  });

  final String selectedCategory;
  final ValueChanged<String> onChanged;

  static const _categories = [
    ('All', 'Tất cả'),
    ('Nutrition', 'Dinh dưỡng'),
    ('Workout', 'Tập luyện'),
    ('Form', 'Tư thế'),
    ('General', 'Chung'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (value, label) = _categories[index];
          final selected = selectedCategory == value;
          return ChoiceChip(
            selected: selected,
            label: Text(label),
            onSelected: (_) => onChanged(value),
            selectedColor: AppPalette.emeraldSoft,
            backgroundColor: AppPalette.surfaceElevated,
            side: BorderSide(
              color: selected
                  ? AppPalette.emerald.withValues(alpha: 0.35)
                  : AppPalette.borderLight,
            ),
            labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color:
                      selected ? AppPalette.emeraldDeep : AppPalette.mutedText,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                ),
          );
        },
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.session,
    required this.onTap,
    required this.onDelete,
  });

  final ChatSession session;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(session.ts);
    final dateLabel =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    final preview = session.history.isEmpty
        ? 'Cuộc trò chuyện mới'
        : session.history.last.text;
    final category = _categoryStyle(session.category);

    return Material(
      color: AppPalette.surface,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppPalette.borderLight),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppPalette.mint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.forum_rounded,
                  color: AppPalette.emeraldDeep,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            session.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateLabel,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppPalette.subtleText,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: category.$1,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            category.$3,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: category.$2,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppPalette.mutedText,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Xóa cuộc trò chuyện',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppPalette.subtleText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (Color, Color, String) _categoryStyle(String category) => switch (category) {
        'Workout' => (AppPalette.blueSoft, AppPalette.blue, 'Tập luyện'),
        'Nutrition' => (AppPalette.orangeSoft, AppPalette.orange, 'Dinh dưỡng'),
        'Form' => (AppPalette.emeraldSoft, AppPalette.emeraldDeep, 'Tư thế'),
        _ => (AppPalette.mint, AppPalette.emeraldDeep, 'Chung'),
      };
}

class _ChatPanel extends StatelessWidget {
  const _ChatPanel({
    super.key,
    required this.session,
    required this.loading,
    required this.scrollController,
    required this.messageController,
    required this.onSend,
  });

  final ChatSession? session;
  final bool loading;
  final ScrollController scrollController;
  final TextEditingController messageController;
  final VoidCallback onSend;

  static const _suggestions = [
    'Tối nay tôi nên ăn gì?',
    'Tạo lịch tập 20 phút tại nhà',
    'Tôi thiếu protein thì bù thế nào?',
    'Hôm nay mệt, có nên giảm cường độ không?',
  ];

  @override
  Widget build(BuildContext context) {
    final history = session?.history ?? const <ChatMessage>[];

    return Column(
      children: [
        Expanded(
          child: history.isEmpty
              ? _EmptyChatState(
                  suggestions: _suggestions,
                  onPickSuggestion: (text) => messageController.text = text,
                )
              : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  itemCount: history.length + (loading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == history.length) {
                      return const _TypingIndicator();
                    }
                    return _MessageBubble(
                      sessionId: session?.id,
                      msgIndex: index,
                      message: history[index],
                    );
                  },
                ),
        ),
        if (history.isNotEmpty && !loading)
          _SuggestionRail(
            suggestions: _suggestions,
            onPick: (text) => messageController.text = text,
          ),
        _ChatInput(
          controller: messageController,
          loading: loading,
          onSend: onSend,
        ),
      ],
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState({
    required this.suggestions,
    required this.onPickSuggestion,
  });

  final List<String> suggestions;
  final ValueChanged<String> onPickSuggestion;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(26, 44, 26, 24),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppPalette.emeraldSoft,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppPalette.emeraldDeep,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Bạn muốn tối ưu gì hôm nay?',
            textAlign: TextAlign.center,
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Hỏi về bữa ăn, lịch tập, macro, phục hồi hoặc cách điều chỉnh plan theo ngày thật của bạn.',
            textAlign: TextAlign.center,
            style: tt.bodyMedium?.copyWith(color: AppPalette.mutedText),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: suggestions
                .map(
                  (suggestion) => ActionChip(
                    label: Text(suggestion),
                    backgroundColor: AppPalette.surface,
                    side: const BorderSide(color: AppPalette.borderLight),
                    onPressed: () => onPickSuggestion(suggestion),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SuggestionRail extends StatelessWidget {
  const _SuggestionRail({
    required this.suggestions,
    required this.onPick,
  });

  final List<String> suggestions;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ActionChip(
            label: Text(suggestion),
            backgroundColor: AppPalette.surface,
            side: const BorderSide(color: AppPalette.borderLight),
            onPressed: () => onPick(suggestion),
          );
        },
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.controller,
    required this.loading,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 12 + bottomInset),
      decoration: const BoxDecoration(
        color: AppPalette.background,
        border: Border(top: BorderSide(color: AppPalette.borderLight)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !loading,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: const InputDecoration(
                hintText: 'Nhắn tin cho AI Coach...',
                prefixIcon: Icon(Icons.auto_awesome_rounded, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 52,
            height: 52,
            child: FilledButton(
              onPressed: loading ? null : onSend,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: AppPalette.emerald,
                disabledBackgroundColor: AppPalette.border,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Icon(
                loading ? Icons.hourglass_empty_rounded : Icons.send_rounded,
                color: loading ? AppPalette.subtleText : AppPalette.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.sessionId,
    required this.msgIndex,
    required this.message,
  });

  final String? sessionId;
  final int msgIndex;
  final ChatMessage message;

  (String, Map<String, dynamic>?) _parseAdjustment(String text) {
    if (!text.contains('---ADJUSTMENT---')) {
      return (text, null);
    }
    final parts = text.split('---ADJUSTMENT---');
    final displayText = parts[0].trim();
    try {
      final jsonStr = parts.length > 1 ? parts[1].trim() : '';
      if (jsonStr.isEmpty) return (displayText, null);
      
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      return (displayText, data);
    } catch (e) {
      return (displayText, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final tt = Theme.of(context).textTheme;
    
    final (displayText, adjustment) = _parseAdjustment(message.text);
    final hasApplied = message.text.contains('✅ Đã áp dụng thay đổi');
    final hasDeclined = message.text.contains('💼 Đã giữ nguyên kế hoạch');
    final isResolved = hasApplied || hasDeclined;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: AppPalette.emeraldSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: AppPalette.emeraldDeep,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? AppPalette.emerald : AppPalette.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 6),
                      bottomRight: Radius.circular(isUser ? 6 : 20),
                    ),
                    border:
                        isUser ? null : Border.all(color: AppPalette.borderLight),
                  ),
                  child: Text(
                    displayText,
                    style: tt.bodyMedium?.copyWith(
                      color: isUser ? AppPalette.text : AppPalette.text,
                      fontWeight: isUser ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (adjustment != null) ...[
                  const SizedBox(height: 8),
                  _AdjustmentCard(
                    sessionId: sessionId,
                    msgIndex: msgIndex,
                    adjustment: adjustment,
                    isResolved: isResolved,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdjustmentCard extends StatelessWidget {
  const _AdjustmentCard({
    required this.sessionId,
    required this.msgIndex,
    required this.adjustment,
    required this.isResolved,
  });

  final String? sessionId;
  final int msgIndex;
  final Map<String, dynamic> adjustment;
  final bool isResolved;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final reason = adjustment['reason'] as String? ?? 'AI Đề xuất thay đổi kế hoạch của bạn.';
    final mealChanges = adjustment['mealChanges'] as List? ?? adjustment['changes'] as List? ?? [];
    final workoutChanges = adjustment['workoutChanges'] as List? ?? [];
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppPalette.emeraldSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_fix_high_rounded, color: AppPalette.emeraldDeep, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Đề xuất điều chỉnh',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: AppPalette.emeraldDeep),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            reason,
            style: tt.bodyMedium?.copyWith(color: AppPalette.text, fontWeight: FontWeight.w700),
          ),
          if (mealChanges.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Dinh dưỡng (🍽️):', style: tt.bodySmall?.copyWith(color: AppPalette.mutedText, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            ...mealChanges.map((c) {
              final m = c as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppPalette.emerald)),
                    Expanded(
                      child: Text(
                        '${m['slot'] ?? ''}: ${m['name'] ?? ''} (${m['kcal'] ?? 0} kcal)',
                        style: tt.bodySmall?.copyWith(color: AppPalette.text),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          if (workoutChanges.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Tập luyện (💪):', style: tt.bodySmall?.copyWith(color: AppPalette.mutedText, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            ...workoutChanges.map((c) {
              final m = c as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppPalette.emerald)),
                    Expanded(
                      child: Text(
                        '${m['exercise'] ?? ''} (${m['duration'] ?? 15} phút)',
                        style: tt.bodySmall?.copyWith(color: AppPalette.text),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          if (!isResolved && sessionId != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      CoreHealthScope.of(context).applyAiAdjustment(sessionId!, msgIndex, adjustment);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppPalette.emerald,
                      foregroundColor: AppPalette.text,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Áp dụng', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      CoreHealthScope.of(context).declineAiAdjustment(sessionId!, msgIndex);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppPalette.text,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Giữ nguyên', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: AppPalette.emeraldSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: AppPalette.emeraldDeep,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => Row(
              children: List.generate(3, (index) {
                final delay = index * 0.3;
                final opacity =
                    (math.sin((_controller.value * math.pi) - delay) + 1) / 2;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppPalette.emeraldDeep.withValues(
                        alpha: opacity.clamp(0.2, 1.0),
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: AppPalette.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppPalette.borderLight),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: AppPalette.subtleText,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Chưa có lịch sử chat',
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Tin nhắn mới sẽ được lưu ở đây.',
            style: tt.bodySmall?.copyWith(color: AppPalette.mutedText),
          ),
        ],
      ),
    );
  }
}

class _LockedAiState extends StatelessWidget {
  const _LockedAiState({
    required this.bottomInset,
    required this.onClose,
  });

  final double bottomInset;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 40, 24, 24 + bottomInset),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppPalette.emeraldSoft,
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: AppPalette.emeraldDeep,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'AI Coach cần token để hoạt động',
            textAlign: TextAlign.center,
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Nạp token hoặc dùng thử CoreHealth Max để mở chat AI, scan món ăn và tạo kế hoạch cá nhân hóa.',
            textAlign: TextAlign.center,
            style: tt.bodyMedium?.copyWith(color: AppPalette.mutedText),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: onClose,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Quay lại'),
          ),
        ],
      ),
    );
  }
}
