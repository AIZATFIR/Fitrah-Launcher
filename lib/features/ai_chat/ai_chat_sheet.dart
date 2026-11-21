import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/providers.dart';
import '../../services/ai_service.dart';
import '../../services/ai_action_proposal.dart';
import '../../services/ai_goal_plan_proposal.dart';
import '../../services/goal_plan_application_service.dart';
import '../../domain/goal_plan_proposal.dart';
import '../../services/voice_assistant_service.dart';

/// Embeddable chat panel — lives in the pull-up sheet under the Clock tab.
/// Transcript stays in process memory across panel open/close; never persisted.
class AiChatPanel extends ConsumerStatefulWidget {
  const AiChatPanel({
    super.key,
    this.scrollController,
    this.onExpandSheet,
    this.initialGoal,
    this.goalId,
    this.expectedGoalRevision,
    this.onOpenAiSettings,
  });
  final ScrollController? scrollController;
  final VoidCallback? onExpandSheet;
  final String? initialGoal;
  final String? goalId;
  final int? expectedGoalRevision;
  final VoidCallback? onOpenAiSettings;

  @override
  ConsumerState<AiChatPanel> createState() => _AiChatPanelState();
}

class _AiChatPanelState extends ConsumerState<AiChatPanel> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  final _listCtrl = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  void _append(ChatMessage m) {
    ref.read(aiTranscriptProvider.notifier).state = [
      ...ref.read(aiTranscriptProvider),
      m,
    ];
  }

  void _replaceLast(ChatMessage m) {
    final list = [...ref.read(aiTranscriptProvider)];
    if (list.isNotEmpty) list.removeLast();
    list.add(m);
    ref.read(aiTranscriptProvider.notifier).state = list;
  }

  Future<void> _send([String? customText]) async {
    final text = (customText ?? _ctrl.text).trim();
    if (text.isEmpty || _sending) return;

    if (customText == null) _ctrl.clear();
    final transcript = [...ref.read(aiTranscriptProvider)];
    ref.read(aiTranscriptProvider.notifier).state = [
      for (final message in transcript)
        message.isDeliveryFailure
            ? ChatMessage(
                role: message.role,
                text: message.text,
                isDeliveryFailure: true,
                isRetryAvailable: false,
              )
            : message,
    ];
    _append(ChatMessage(role: 'user', text: text));
    _append(ChatMessage(role: 'model', text: '', isLoading: true));
    setState(() => _sending = true);
    _scrollToBottom();

    try {
      final ai = ref.read(aiServiceProvider);
      final reply = await ai.send(
        text,
        allowActions: true,
        goalContext: widget.initialGoal,
        goalId: widget.goalId,
        expectedGoalRevision: widget.expectedGoalRevision,
      );
      final modeLabel = ai.activeMode.label;

      _replaceLast(
        ChatMessage(
          role: 'model',
          text: reply,
          modeLabel: modeLabel,
          proposals: ai.pendingActions,
          goalPlanProposal: ai.pendingGoalPlan,
          isDeliveryFailure: ai.hasRetryableTurn,
          isRetryAvailable: ai.hasRetryableTurn,
        ),
      );

      // Aura Voice Output (TTS)
      if (!ai.hasRetryableTurn) {
        ref.read(voiceAssistantServiceProvider).speak(reply);
      }
    } catch (e) {
      _replaceLast(
        ChatMessage(
          role: 'model',
          text: 'Belum bisa tersambung. Coba lagi sebentar.',
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
      _focus.requestFocus();
    }
  }

  Future<void> _retry(ChatMessage message) async {
    if (_sending || !message.isRetryAvailable) return;
    final messages = [...ref.read(aiTranscriptProvider)];
    final index = messages.indexOf(message);
    if (index < 0) return;
    messages[index] = ChatMessage(
      role: 'model',
      text: message.text,
      isDeliveryFailure: true,
      isRetryAvailable: true,
      isRetryLoading: true,
    );
    ref.read(aiTranscriptProvider.notifier).state = messages;
    setState(() => _sending = true);
    try {
      final ai = ref.read(aiServiceProvider);
      final reply = await ai.retry();
      messages[index] = ChatMessage(
        role: 'model',
        text: reply ?? message.text,
        modeLabel: ai.activeMode.label,
        proposals: ai.pendingActions,
        goalPlanProposal: ai.pendingGoalPlan,
        isDeliveryFailure: ai.hasRetryableTurn,
        isRetryAvailable: ai.hasRetryableTurn,
      );
      ref.read(aiTranscriptProvider.notifier).state = [...messages];
      if (!ai.hasRetryableTurn && reply != null) {
        ref.read(voiceAssistantServiceProvider).speak(reply);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  void _triggerVoiceInput() {
    final voice = ref.read(voiceAssistantServiceProvider);
    if (voice.isListening.value) {
      voice.stopListening();
    } else {
      widget.onExpandSheet?.call();
      voice.startListening(
        onResult: (spokenText) {
          if (spokenText.trim().isNotEmpty) {
            _ctrl.text = spokenText;
          }
        },
      );
    }
  }

  void _newChat() {
    ref.read(voiceAssistantServiceProvider).stopSpeaking();
    ref.read(aiServiceProvider).reset();
    ref.read(aiTranscriptProvider.notifier).state = <ChatMessage>[];
  }

  Future<void> _showBlueprintDialog(BuildContext context) async {
    int wakeH = 6;
    int sleepH = 22;
    final goalCtrl = TextEditingController();
    final now = DateTime.now();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Susun hari'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Rancang jadwal seimbang berbasis psikologis:\n'
              'Deep Work → Intentional Rest → Active Rest → Sleep.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (ctx, setS) => Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Jam Bangun',
                              style: TextStyle(fontSize: 12),
                            ),
                            Slider(
                              value: wakeH.toDouble(),
                              min: 3,
                              max: 10,
                              divisions: 7,
                              label: '${wakeH.toString().padLeft(2, '0')}:00',
                              activeColor: AppPalette.accent,
                              onChanged: (v) => setS(() => wakeH = v.toInt()),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${wakeH.toString().padLeft(2, '0')}:00',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Jam Tidur',
                              style: TextStyle(fontSize: 12),
                            ),
                            Slider(
                              value: sleepH.toDouble(),
                              min: 19,
                              max: 26,
                              divisions: 7,
                              label:
                                  '${(sleepH % 24).toString().padLeft(2, '0')}:00',
                              activeColor: AppPalette.accent,
                              onChanged: (v) => setS(() => sleepH = v.toInt()),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${(sleepH % 24).toString().padLeft(2, '0')}:00',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            TextField(
              controller: goalCtrl,
              decoration: const InputDecoration(
                labelText: 'Target/Tugas (pisahkan dengan koma)',
                hintText: 'misal: Belajar Matematika, Koding, Olahraga',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppPalette.accent,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final goals = goalCtrl.text
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
              final dateStr =
                  '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
              final goalsStr = goals.isEmpty
                  ? ''
                  : ' Goals: ${goals.join(', ')}.';
              final prompt =
                  'Bantu susun hari ini ($dateStr). '
                  'Bangun: ${wakeH.toString().padLeft(2, '0')}:00, '
                  'Tidur: ${(sleepH % 24).toString().padLeft(2, '0')}:00.$goalsStr';
              _send(prompt);
            },
            child: const Text('Minta saran'),
          ),
        ],
      ),
    );
    goalCtrl.dispose();
  }

  void _scrollToBottom() {
    widget.onExpandSheet?.call();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_listCtrl.hasClients) {
        _listCtrl.animateTo(
          _listCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).viewInsets.bottom;
    final messages = ref.watch(aiTranscriptProvider);
    final voice = ref.watch(voiceAssistantServiceProvider);
    final activeMode = ref.watch(aiServiceProvider).activeMode;

    return Column(
      children: [
        // Calm, goal-first header using the existing Bookpaper palette.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 420;
              return Row(
                children: [
                  if (compact)
                    const Expanded(
                      child: Text(
                        'Teman fokus',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else ...[
                    const Text(
                      'Teman fokus',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      activeMode.label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppPalette.textDim,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Tooltip(
                    message: 'Susun hari',
                    child: IconButton(
                      onPressed: () => _showBlueprintDialog(context),
                      icon: const Icon(
                        Icons.calendar_today_outlined,
                        size: 20,
                        color: AppPalette.accent,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  ),
                  if (widget.onOpenAiSettings != null)
                    IconButton(
                      tooltip: 'Pengaturan AI',
                      onPressed: widget.onOpenAiSettings,
                      icon: const Icon(Icons.tune_rounded, size: 20),
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                    ),
                  if (compact)
                    IconButton(
                      tooltip: 'Chat baru',
                      onPressed: messages.isEmpty ? null : _newChat,
                      icon: const Icon(Icons.add_comment_outlined, size: 20),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    )
                  else
                    TextButton.icon(
                      onPressed: messages.isEmpty ? null : _newChat,
                      icon: const Icon(Icons.add_comment_outlined, size: 15),
                      label: const Text(
                        'Chat baru',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppPalette.textDim,
                      ),
                    ),
                ],
              );
            },
          ),
        ),

        // Messages
        Expanded(
          child: messages.isEmpty
              ? _EmptyState(
                  onPrompt: _send,
                  initialGoal: widget.initialGoal,
                  onOpenAiSettings: widget.onOpenAiSettings,
                )
              : ListView.builder(
                  controller: _listCtrl,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  itemCount: messages.length,
                  itemBuilder: (_, i) => _Bubble(
                    msg: messages[i],
                    onRetry: () => _retry(messages[i]),
                    goalPlanService: ref.watch(
                      goalPlanApplicationServiceProvider,
                    ),
                    onProposalChanged: () {
                      if (mounted) setState(() {});
                    },
                  ),
                ),
        ),

        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppPalette.textDim,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Chat tidak disimpan oleh app setelah ditutup. Pesan dan tujuan Home (jika ada) dikirim ke provider pilihanmu; retensi mengikuti kebijakan provider.',
                  style: TextStyle(
                    color: AppPalette.textDim,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Input bar with Microphone Voice button
        Container(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 12 + pad),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppPalette.stroke)),
          ),
          child: Row(
            children: [
              // Mic Voice Input Button
              ValueListenableBuilder<bool>(
                valueListenable: voice.isListening,
                builder: (context, listening, _) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: voice.isSpeaking,
                    builder: (context, speaking, _) {
                      return IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: listening
                              ? Colors.redAccent
                              : (speaking ? AppPalette.accent : AppPalette.bg),
                          foregroundColor: listening || speaking
                              ? Colors.white
                              : AppPalette.accent,
                        ),
                        icon: Icon(
                          listening
                              ? Icons.mic
                              : (speaking ? Icons.volume_up : Icons.mic_none),
                          size: 20,
                        ),
                        onPressed: () {
                          if (speaking) {
                            voice.stopSpeaking();
                          } else {
                            _triggerVoiceInput();
                          }
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText:
                        'Ceritakan tujuanmu atau apa yang terasa berat...',
                    hintStyle: const TextStyle(
                      color: AppPalette.textDim,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: AppPalette.bg,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                child: _sending
                    ? const SizedBox(
                        width: 44,
                        height: 44,
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppPalette.accent,
                          ),
                        ),
                      )
                    : IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: AppPalette.accent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.all(10),
                        ),
                        icon: const Icon(Icons.send_rounded, size: 20),
                        onPressed: () => _send(),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Bubble ─────────────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.msg,
    required this.onRetry,
    required this.onProposalChanged,
    this.goalPlanService,
  });
  final ChatMessage msg;
  final VoidCallback onRetry;
  final VoidCallback onProposalChanged;
  final GoalPlanApplicationService? goalPlanService;

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: AppPalette.accent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 14,
                  color: AppPalette.accent,
                ),
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? AppPalette.accent.withValues(alpha: 0.15)
                    : AppPalette.bg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: Border.all(
                  color: isUser
                      ? AppPalette.accent.withValues(alpha: 0.3)
                      : AppPalette.stroke,
                  width: 1,
                ),
              ),
              child: msg.isLoading
                  ? const SizedBox(width: 40, height: 16, child: _ThreeDots())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MarkdownBody(
                          data: msg.text,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(
                              fontSize: 14,
                              color: AppPalette.text,
                            ),
                            strong: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppPalette.text,
                            ),
                            em: const TextStyle(
                              fontStyle: FontStyle.italic,
                              color: AppPalette.text,
                            ),
                            listBullet: const TextStyle(color: AppPalette.text),
                          ),
                        ),
                        if (msg.isDeliveryFailure) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 16,
                                color: AppPalette.textDim,
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                'Pesan belum terkirim',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppPalette.textDim,
                                ),
                              ),
                              if (msg.isRetryAvailable) ...[
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: msg.isRetryLoading
                                      ? null
                                      : onRetry,
                                  icon: msg.isRetryLoading
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.refresh, size: 16),
                                  label: const Text('Coba lagi'),
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(44, 36),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                        for (final proposal in msg.proposals)
                          _AiProposalCard(
                            proposal: proposal,
                            onChanged: onProposalChanged,
                          ),
                        if (msg.goalPlanProposal != null)
                          GoalPlanReviewCard(
                            proposal: msg.goalPlanProposal!,
                            service: goalPlanService,
                            onChanged: onProposalChanged,
                          ),
                      ],
                    ),
            ),
          ),
          if (isUser) const SizedBox(width: 34),
        ],
      ),
    );
  }
}

class _AiProposalCard extends StatefulWidget {
  const _AiProposalCard({required this.proposal, required this.onChanged});
  final AiActionProposal proposal;
  final VoidCallback onChanged;

  @override
  State<_AiProposalCard> createState() => _AiProposalCardState();
}

class _AiProposalCardState extends State<_AiProposalCard> {
  bool _working = false;
  String? _error;

  String get _summary {
    return widget.proposal.summary;
  }

  Future<void> _approve() async {
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await widget.proposal.approve();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _working = false);
    widget.onChanged();
  }

  void _dismiss() {
    widget.proposal.dismiss();
    setState(() {});
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final proposal = widget.proposal;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            proposal.isApplied
                ? 'Diterapkan'
                : proposal.isPending
                ? 'Perubahan menunggu persetujuan'
                : 'Perubahan dibatalkan',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: proposal.isApplied
                  ? AppPalette.accent
                  : AppPalette.textDim,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _summary,
            style: const TextStyle(fontSize: 13, color: AppPalette.text),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Belum berhasil: $_error',
                style: const TextStyle(fontSize: 12, color: Colors.redAccent),
              ),
            ),
          if (proposal.isPending) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _working ? null : _dismiss,
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _working ? null : _approve,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppPalette.accent,
                      foregroundColor: Colors.black,
                    ),
                    child: _working
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Terapkan'),
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

class GoalPlanReviewCard extends StatefulWidget {
  const GoalPlanReviewCard({
    super.key,
    required this.proposal,
    required this.service,
    required this.onChanged,
  });
  final AiGoalPlanProposal proposal;
  final GoalPlanApplicationService? service;
  final VoidCallback onChanged;

  @override
  State<GoalPlanReviewCard> createState() => _GoalPlanReviewCardState();
}

class _GoalPlanReviewCardState extends State<GoalPlanReviewCard> {
  static const _days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  late final TextEditingController _title;
  late final TextEditingController _why;
  late final TextEditingController _targetDate;
  late final TextEditingController _assumptions;
  late final List<int> _weekdays;
  late final List<TextEditingController> _times;
  late final List<TextEditingController> _durations;
  List<String> _conflicts = const [];
  String? _error;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.proposal.proposal;
    _title = TextEditingController(text: initial.goal.title);
    _why = TextEditingController(text: initial.goal.why ?? '');
    _targetDate = TextEditingController(text: initial.goal.targetDate ?? '');
    _assumptions = TextEditingController(text: initial.assumptions.join('\n'));
    _weekdays = initial.blocks.map((b) => b.weekday).toList();
    _times = initial.blocks
        .map((b) => TextEditingController(text: _minuteText(b.startMinute)))
        .toList();
    _durations = initial.blocks
        .map((b) => TextEditingController(text: '${b.durationMinutes}'))
        .toList();
    _refreshConflicts();
  }

  @override
  void dispose() {
    _title.dispose();
    _why.dispose();
    _targetDate.dispose();
    _assumptions.dispose();
    for (final controller in [..._times, ..._durations]) {
      controller.dispose();
    }
    super.dispose();
  }

  PlanProposal _draft() {
    final date = _targetDate.text.trim();
    final blocks = <WeeklyPracticeBlock>[];
    for (var i = 0; i < _weekdays.length; i++) {
      final match = RegExp(
        r'^(\d{1,2}):(\d{2})$',
      ).firstMatch(_times[i].text.trim());
      if (match == null) {
        throw const FormatException('Waktu harus memakai format HH:MM.');
      }
      final hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      if (hour > 23 || minute > 59) {
        throw const FormatException(
          'Waktu harus berada antara 00:00 dan 23:59.',
        );
      }
      final duration = int.tryParse(_durations[i].text.trim());
      if (duration == null) {
        throw const FormatException('Durasi harus berupa angka menit.');
      }
      blocks.add(
        WeeklyPracticeBlock(
          weekday: _weekdays[i],
          startMinute: hour * 60 + minute,
          durationMinutes: duration,
        ),
      );
    }
    return PlanProposal(
      goal: GoalUnderstanding(
        title: _title.text,
        why: _why.text,
        targetDate: date.isEmpty ? null : date,
      ),
      assumptions: _assumptions.text
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList(),
      blocks: blocks,
      provider: widget.proposal.proposal.provider,
      model: widget.proposal.proposal.model,
    );
  }

  Future<void> _refreshConflicts() async {
    final service = widget.service;
    if (service == null) {
      if (mounted) {
        setState(
          () => _conflicts = const [
            'Penyimpanan durable tidak tersedia; gunakan pengaturan manual.',
          ],
        );
      }
      return;
    }
    try {
      final conflicts = await service.previewConflicts(
        _draft(),
        goalId: widget.proposal.goalId,
      );
      if (mounted) setState(() => _conflicts = conflicts);
    } catch (error) {
      if (mounted) setState(() => _conflicts = [error.toString()]);
    }
  }

  Future<void> _apply() async {
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final edited = _draft();
      final conflicts = await widget.service!.previewConflicts(
        edited,
        goalId: widget.proposal.goalId,
      );
      if (conflicts.isNotEmpty) {
        setState(() => _conflicts = conflicts);
        throw StateError('Perbaiki bentrok yang tercantum sebelum menerapkan.');
      }
      await widget.proposal.approve(edited);
      widget.onChanged();
    } catch (error) {
      _error = error.toString();
    }
    if (mounted) setState(() => _working = false);
  }

  void _cancel() {
    widget.proposal.dismiss();
    setState(() {});
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final proposal = widget.proposal;
    final editable = proposal.isPending;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            proposal.isApplied
                ? 'Rencana diterapkan'
                : editable
                ? 'Tinjau dan sesuaikan rencana'
                : 'Rencana dibatalkan',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          if (proposal.goalId != null) ...[
            const SizedBox(height: 3),
            const Text(
              'Ini akan memperbarui tujuan dan jadwal latihan yang sudah tersimpan.',
              style: TextStyle(fontSize: 12, color: AppPalette.textDim),
            ),
          ],
          const SizedBox(height: 8),
          TextField(
            controller: _title,
            enabled: editable && !_working,
            maxLength: 120,
            decoration: const InputDecoration(
              labelText: 'Tujuan',
              isDense: true,
            ),
            onChanged: (_) => _refreshConflicts(),
          ),
          TextField(
            controller: _why,
            enabled: editable && !_working,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Alasan (opsional)',
              isDense: true,
            ),
          ),
          TextField(
            controller: _targetDate,
            enabled: editable && !_working,
            decoration: const InputDecoration(
              labelText: 'Tanggal target YYYY-MM-DD (opsional)',
              isDense: true,
            ),
            onChanged: (_) => _refreshConflicts(),
          ),
          TextField(
            controller: _assumptions,
            enabled: editable && !_working,
            minLines: 1,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Asumsi (satu per baris)',
              isDense: true,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 12, bottom: 4),
            child: Text(
              'Latihan mingguan',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          for (var i = 0; i < _weekdays.length; i++)
            Row(
              children: [
                SizedBox(
                  width: 88,
                  child: DropdownButtonFormField<int>(
                    value: _weekdays[i],
                    decoration: const InputDecoration(isDense: true),
                    items: List.generate(
                      7,
                      (i) =>
                          DropdownMenuItem(value: i + 1, child: Text(_days[i])),
                    ),
                    onChanged: !editable || _working
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _weekdays[i] = value);
                            }
                            _refreshConflicts();
                          },
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _times[i],
                    enabled: editable && !_working,
                    decoration: const InputDecoration(
                      labelText: 'Jam',
                      hintText: '18:00',
                      isDense: true,
                    ),
                    onChanged: (_) => _refreshConflicts(),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 82,
                  child: TextField(
                    controller: _durations[i],
                    enabled: editable && !_working,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Menit',
                      isDense: true,
                    ),
                    onChanged: (_) => _refreshConflicts(),
                  ),
                ),
                if (editable)
                  IconButton(
                    tooltip: 'Hapus blok',
                    onPressed: _working || _weekdays.length <= 1
                        ? null
                        : () {
                            setState(() {
                              _weekdays.removeAt(i);
                              _times.removeAt(i).dispose();
                              _durations.removeAt(i).dispose();
                            });
                            _refreshConflicts();
                          },
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
              ],
            ),
          if (editable && _weekdays.length < 14)
            TextButton.icon(
              onPressed: _working
                  ? null
                  : () {
                      setState(() {
                        _weekdays.add(1);
                        _times.add(TextEditingController(text: '18:00'));
                        _durations.add(TextEditingController(text: '60'));
                      });
                      _refreshConflicts();
                    },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Tambah blok mingguan'),
            ),
          if (_conflicts.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final conflict in _conflicts)
              Text(
                conflict,
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 12,
                ),
              ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Belum berhasil: $_error',
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
          if (editable) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _working ? null : _cancel,
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed:
                        _working ||
                            widget.service == null ||
                            _conflicts.isNotEmpty
                        ? null
                        : _apply,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppPalette.accent,
                      foregroundColor: Colors.black,
                    ),
                    child: _working
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Terapkan'),
                  ),
                ),
              ],
            ),
          ],
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Blok berulang setiap minggu. Jadwal lama tidak dipindah atau dihapus.',
              style: TextStyle(color: AppPalette.textDim, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  String _minuteText(int minute) =>
      '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';
}

class _ThreeDots extends StatefulWidget {
  const _ThreeDots();

  @override
  State<_ThreeDots> createState() => _ThreeDotsState();
}

class _ThreeDotsState extends State<_ThreeDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_c.value - i * 0.2).clamp(0.0, 1.0);
            final opacity = (phase < 0.5 ? phase * 2 : (1 - phase) * 2).clamp(
              0.3,
              1.0,
            );
            return Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: AppPalette.accent.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.onPrompt,
    this.initialGoal,
    this.onOpenAiSettings,
  });
  final ValueChanged<String> onPrompt;
  final String? initialGoal;
  final VoidCallback? onOpenAiSettings;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - 48).clamp(0.0, double.infinity),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Apa tujuan yang ingin kamu jaga?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ceritakan tujuanmu atau hal yang terasa berat. Kita mulai dari satu langkah.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppPalette.textDim,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                if (initialGoal != null && initialGoal!.trim().isNotEmpty) ...[
                  Text(
                    'Tujuanmu: ${initialGoal!.trim()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppPalette.textDim,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => onPrompt(
                      'Bantu aku memahami langkah realistis yang bisa kupilih hari ini. '
                      'Tanyakan dulu jika ada informasi penting yang kamu perlukan. '
                      'Jangan menyimpan atau mengubah jadwal sebelum aku menyetujui usulan.',
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppPalette.accent,
                      alignment: Alignment.center,
                      minimumSize: const Size(48, 48),
                    ),
                    icon: const Icon(Icons.flag_outlined, size: 16),
                    label: const Text('Bantu aku menyusun langkah'),
                  ),
                  if (onOpenAiSettings != null)
                    TextButton.icon(
                      onPressed: onOpenAiSettings,
                      style: TextButton.styleFrom(
                        foregroundColor: AppPalette.textDim,
                        minimumSize: const Size(48, 44),
                      ),
                      icon: const Icon(Icons.tune_rounded, size: 16),
                      label: const Text('Atur provider & API key'),
                    ),
                ] else ...[
                  ...const [
                    'Aku ingin menang LKS nasional IT Software Solution',
                    'Aku kewalahan. Bantu pilih satu langkah hari ini',
                  ].map(
                    (s) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: TextButton(
                        onPressed: () => onPrompt(s),
                        style: TextButton.styleFrom(
                          foregroundColor: AppPalette.accent,
                          alignment: Alignment.center,
                          minimumSize: const Size(44, 44),
                        ),
                        child: Text(
                          s,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
