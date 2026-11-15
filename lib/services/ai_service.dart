import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../core/time_math.dart';
import '../data/repositories/activity_repository.dart';
import '../data/repositories/preset_repository.dart';
import '../models/activity.dart';
import 'ai_action_proposal.dart';
import 'secure_storage_service.dart';

/// Enum representing the active AI execution mode
enum AiExecutionMode {
  byokGeminiDirect('BYOK (Gemini Direct)'),
  serverOpenRouter('Server-Side (OpenRouter)'),
  demoFallback('Demo Mode');

  const AiExecutionMode(this.label);
  final String label;
}

// ── Tool schemas (OpenAI & Gemini function calling format) ───────────────────

const _tools = [
  {
    'type': 'function',
    'function': {
      'name': 'generate_blueprint',
      'description':
          'Generate a psychologically balanced full-day schedule (Fitrah Blueprint). '
          'Creates Deep Work blocks, Intentional Rest, Active Rest, Wind Down, and Sleep blocks '
          'based on circadian rhythm and ultradian cycle research. '
          'Call this when user asks to generate, plan, or blueprint their day.',
      'parameters': {
        'type': 'object',
        'required': ['date', 'wake_hour', 'sleep_hour'],
        'properties': {
          'date': {'type': 'string', 'description': 'ISO date yyyy-MM-dd'},
          'wake_hour': {
            'type': 'integer',
            'description': 'Wake-up hour (0-23), e.g. 6 for 6am',
          },
          'sleep_hour': {
            'type': 'integer',
            'description': 'Target sleep hour (0-23), e.g. 22 for 10pm',
          },
          'goals': {
            'type': 'array',
            'items': {'type': 'string'},
            'description':
                'Main goals/tasks for the day, e.g. ["Math study", "Exercise"]',
          },
        },
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'set_priority',
      'description':
          'Set importance level and/or deadline for an activity (for Eisenhower Matrix).',
      'parameters': {
        'type': 'object',
        'required': ['id'],
        'properties': {
          'id': {'type': 'integer'},
          'importance': {
            'type': 'integer',
            'description': '0 = low importance, 1 = high importance',
            'enum': [0, 1],
          },
          'deadline': {
            'type': 'string',
            'description': 'ISO date yyyy-MM-dd for deadline. Null to clear.',
          },
        },
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'list_activities',
      'description': 'List all activities for a given date.',
      'parameters': {
        'type': 'object',
        'properties': {
          'date': {
            'type': 'string',
            'description': 'ISO date yyyy-MM-dd. Defaults to today if omitted.',
          },
        },
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'create_activity',
      'description': 'Create a new time-block activity.',
      'parameters': {
        'type': 'object',
        'required': ['title', 'date', 'start_hour'],
        'properties': {
          'title': {'type': 'string'},
          'date': {'type': 'string', 'description': 'ISO date yyyy-MM-dd'},
          'start_hour': {
            'type': 'integer',
            'description': '0-23 (24h). 7=7am, 14=2pm.',
          },
          'start_minute': {
            'type': 'integer',
            'description': '0-59. Default 0.',
          },
          'duration_minutes': {
            'type': 'integer',
            'description': 'Duration minutes. Default 60.',
          },
          'description': {'type': 'string'},
          'recurrence': {
            'type': 'string',
            'enum': ['none', 'daily', 'weekly'],
          },
        },
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'update_activity',
      'description':
          'Update an existing activity. Only supply fields to change.',
      'parameters': {
        'type': 'object',
        'required': ['id'],
        'properties': {
          'id': {'type': 'integer'},
          'title': {'type': 'string'},
          'date': {'type': 'string'},
          'start_hour': {'type': 'integer'},
          'start_minute': {'type': 'integer'},
          'duration_minutes': {'type': 'integer'},
          'description': {'type': 'string'},
          'recurrence': {
            'type': 'string',
            'enum': ['none', 'daily', 'weekly'],
          },
        },
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'delete_activity',
      'description': 'Delete an activity by ID.',
      'parameters': {
        'type': 'object',
        'required': ['id'],
        'properties': {
          'id': {'type': 'integer'},
        },
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'schedule_adaptive_goal',
      'description':
          'Analyze a long-term target goal (e.g. LKS IT Software Solutions, Juara Competition, Master Skill) '
          'and adaptively schedule required daily practice/study blocks from current date until target event date. '
          'Calculates target daily hours and plots flexible recurring blocks into empty clock face slots.',
      'parameters': {
        'type': 'object',
        'required': ['goal_title', 'target_date', 'daily_hours'],
        'properties': {
          'goal_title': {
            'type': 'string',
            'description':
                'Title of goal/identity, e.g. "Juara 1 LKS IT Software Solutions"',
          },
          'target_date': {
            'type': 'string',
            'description': 'Target event date ISO yyyy-MM-dd (e.g. 2027-07-15)',
          },
          'daily_hours': {
            'type': 'number',
            'description': 'Required target practice hours per day, e.g. 3.0',
          },
          'preferred_time': {
            'type': 'string',
            'description':
                'Preferred time slot: "morning" | "afternoon" | "evening" | "flexible"',
          },
          'days_per_week': {
            'type': 'integer',
            'description': 'Days per week (1-7). Default 6.',
          },
        },
      },
    },
  },
];

// ── Chat message ──────────────────────────────────────────────────────────────

class ChatMessage {
  ChatMessage({
    required this.role,
    required this.text,
    this.isLoading = false,
    this.modeLabel,
    this.proposals = const [],
  });
  final String role; // 'user' | 'model'
  final String text;
  final bool isLoading;
  final String? modeLabel;
  final List<AiActionProposal> proposals;
}

// ── AiService ─────────────────────────────────────────────────────────────────

class AiService {
  AiService({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    required ActivityRepository activityRepo,
    required PresetRepository presetRepo,
    SecureStorageService? secureStorage,
    http.Client? httpClient,
  }) : _activityRepo = activityRepo,
       _presetRepo = presetRepo,
       _secureStorage = secureStorage ?? SecureStorageService(),
       _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final String apiKey;
  final String model;
  final ActivityRepository _activityRepo;
  final PresetRepository _presetRepo;
  final SecureStorageService _secureStorage;
  final http.Client _httpClient;

  // History for OpenAI format requests
  final List<Map<String, dynamic>> _history = [];
  bool _initialized = false;
  AiExecutionMode _activeMode = AiExecutionMode.demoFallback;
  List<AiActionProposal> _pendingActions = const [];

  AiExecutionMode get activeMode => _activeMode;
  List<AiActionProposal> get pendingActions => _pendingActions;

  /// Format system prompt for Persona "Aura"
  String _buildAuraSystemPrompt(
    String dateStr,
    String timeStr,
    String timezone,
    String presetList,
  ) {
    return '''Kamu adalah "Aura", seorang AI Time Secretary yang sangat empatik, hangat, efisien, dan ramah.

ATURAN PERILAKU:
1. Bersikap profesional namun hangat seperti sekretaris pribadi manusia sungguhan.
2. Selalu sadar konteks waktu pengguna saat ini: $dateStr $timeStr (Timezone: $timezone).
3. Buat respon yang ringkas, jelas, dan langsung pada poin utama (maksimal 2-3 kalimat).
4. Proaktif memberikan perhatian kecil terkait manajemen waktu, jam istirahat, atau pengingat jadwal jika diperlukan.

DOKTRIN MANAJEMEN WAKTU (CONCEPT PAPER FOCUS CLOCK):
- Berdasarkan Perilaku Psikologis Natural Manusia (Fitrah & Identity-Based Habits).
- Utamakan pembagian waktu seimbang: Deep Work (90-120 menit), Intentional Rest (istirahat total dari gawai/bengong sehat 20 menit), Active Rest/Sosial, Wind Down (45 menit), dan Sleep (siklus kelipatan 90 menit).
- Gunakan Eisenhower Matrix untuk memprioritaskan tugas ber-deadline.
- Presets pengguna saat ini: $presetList.

IDENTITAS & ADAPTIVE GOAL SCHEDULING:
- Bantu pengguna mengurai tujuan jangka panjang dan tanyakan detail yang mengubah jadwal. Jangan mengaku sudah menanamkan latihan berulang; setiap perubahan yang tersedia muncul sebagai usulan terpisah untuk ditinjau.
- Jangan buat blueprint harian massal atau jadwal adaptif berulang sampai app dapat meninjau konflik dan menerapkan seluruh rencana secara atomik.

PANGGILAN TOOL UNTUK BANTUAN:
- list_activities: untuk melihat jadwal aktif.
- Untuk semua perubahan jadwal, minta persetujuan eksplisit pengguna sebelum perubahan diterapkan.
- Jangan mengklaim perubahan sudah diterapkan sebelum pengguna menyetujuinya.
''';
  }

  Future<void> _ensureInit() async {
    if (_initialized) return;
    final now = DateTime.now();
    final timezone = DateTime.now().timeZoneName;
    final presets = await _presetRepo.getAll();
    final presetList = presets.isEmpty
        ? 'tidak ada'
        : presets
              .asMap()
              .entries
              .map((e) => '${e.key + 1}. "${e.value.name}"')
              .join(', ');
    final dateStr = _fmtDate(now);
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final systemPrompt = _buildAuraSystemPrompt(
      dateStr,
      timeStr,
      timezone,
      presetList,
    );

    _history.add({'role': 'system', 'content': systemPrompt});
    _initialized = true;
  }

  /// Send message via Hybrid Architecture (BYOK Gemini SDK or Server-Side Fallback)
  Future<String> send(String userMessage, {bool allowActions = false}) async {
    for (final action in _pendingActions) {
      action.dismiss();
    }
    _pendingActions = const [];
    await _ensureInit();
    _history.add({'role': 'user', 'content': userMessage});

    final userGeminiKey = (await _secureStorage.getGeminiApiKey()) ?? apiKey;

    // Determine Mode
    if (userGeminiKey.isNotEmpty && userGeminiKey.startsWith('AIza')) {
      _activeMode = AiExecutionMode.byokGeminiDirect;
      try {
        final reply = await _sendGeminiDirect(
          userMessage,
          userGeminiKey,
          allowActions: allowActions,
        );
        if (allowActions && _pendingActions.isEmpty) {
          return '${_guardUnapprovedActionClaim(reply)}\n\nMode Gemini belum bisa meninjau aksi interaktif; belum ada perubahan jadwal diterapkan.';
        }
        return reply;
      } catch (e) {
        // Fallback to server side if BYOK fails
        _activeMode = AiExecutionMode.serverOpenRouter;
        final reply = await _sendServerFallback(
          userMessage,
          allowActions: allowActions,
        );
        if (allowActions && _pendingActions.isEmpty) {
          return '${_guardUnapprovedActionClaim(reply)}\n\nBelum ada perubahan jadwal diterapkan.';
        }
        return reply;
      }
    } else {
      _activeMode = AiExecutionMode.serverOpenRouter;
      final reply = await _sendServerFallback(
        userMessage,
        allowActions: allowActions,
      );
      if (allowActions && _pendingActions.isEmpty) {
        return '${_guardUnapprovedActionClaim(reply)}\n\nBelum ada perubahan jadwal diterapkan.';
      }
      return reply;
    }
  }

  String _guardUnapprovedActionClaim(String reply) {
    final lowerReply = reply.toLowerCase();
    final claimsCompletedAction = RegExp(
      r'\b(?:jadwal|aktivitas|kegiatan)\b.{0,45}\b(?:berhasil|sudah|telah)\b.{0,35}\b(?:aku|saya)\s+(?:buat|bikin|atur|terapkan|jadwalkan|tambahkan|ubah|pindahkan|hapus)\b|\b(?:berhasil|sudah|telah)\b.{0,55}\b(?:aku|saya)\s+(?:buat|bikin|atur|terapkan|jadwalkan|tambahkan|ubah|pindahkan|hapus)\b|\b(?:aku|saya)\s+(?:sudah\s+)?(?:berhasil\s+)?(?:buat|bikin|atur|terapkan|jadwalkan|tambahkan|ubah|pindahkan|hapus)\b.{0,55}\b(?:jadwal|aktivitas|kegiatan|\w+)',
      caseSensitive: false,
    );
    final claimsEnglishAction = RegExp(
      r"\b(?:I(?:’|')ve|I have)\s+(?:scheduled|created|updated|deleted|applied)\b|\bschedule\s+(?:is|has been)\s+(?:set|updated|created)\b",
      caseSensitive: false,
    );
    if (claimsCompletedAction.hasMatch(lowerReply) ||
        claimsEnglishAction.hasMatch(lowerReply)) {
      return 'Aku belum menerapkan perubahan. Minta satu perubahan jadwal, lalu tinjau dan setujui sebelum disimpan.';
    }
    return reply;
  }

  // ── Mode 1: BYOK Client-Side via Google Generative AI SDK ────────────────
  Future<String> _sendGeminiDirect(
    String userMessage,
    String geminiKey, {
    required bool allowActions,
  }) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: geminiKey,
      );

      final systemPromptObj =
          _history.firstWhere(
                (m) => m['role'] == 'system',
                orElse: () => {'content': ''},
              )['content']
              as String;

      final promptText = '$systemPromptObj\n\nUser request: $userMessage';
      final content = [Content.text(promptText)];

      final response = await model.generateContent(content);
      final reply =
          response.text?.trim() ?? 'Halo, Aura di sini. Ada yang bisa dibantu?';

      _history.add({'role': 'assistant', 'content': reply});
      return reply;
    } catch (e) {
      // Fall back to HTTP endpoint if SDK fails
      return await _sendServerFallback(userMessage, allowActions: allowActions);
    }
  }

  // ── Mode 2: Server-Side Fallback via OpenRouter / Backend ─────────────────
  Future<String> _sendServerFallback(
    String userMessage, {
    required bool allowActions,
  }) async {
    final serverUrl = await _secureStorage.getBackendServerUrl();
    final openRouterKey = await _secureStorage.getOpenRouterKey();

    // Only the local, structured provider path can create proposals the app can review.
    const demoKey = String.fromEnvironment('DEMO_AI_KEY');
    final directKeyAvailable =
        (openRouterKey?.isNotEmpty ?? false) ||
        apiKey.isNotEmpty ||
        demoKey.isNotEmpty;
    if (allowActions && directKeyAvailable) {
      return _callOpenRouterDirect(openRouterKey, allowActions: true);
    }

    // 1. Try local/custom server endpoint `/api/chat/secretary`
    try {
      final uri = Uri.parse('$serverUrl/api/chat/secretary');
      final resp = await _httpClient
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'messages': _history,
              'userMessage': userMessage,
              'action_policy': 'read_only',
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final reply =
            (data['reply'] as String?)?.trim() ??
            'Siap, Aura sudah memproses jadwal Anda.';
        _history.add({'role': 'assistant', 'content': reply});
        return reply;
      }
    } catch (_) {
      // Server offline or not reached, try direct OpenRouter HTTP if available
    }

    // 2. Direct OpenRouter HTTP call
    return await _callOpenRouterDirect(openRouterKey, allowActions: false);
  }

  Future<String> _callOpenRouterDirect(
    String? openRouterKey, {
    required bool allowActions,
  }) async {
    const demoUrl = String.fromEnvironment(
      'DEMO_AI_URL',
      defaultValue: 'https://generativelanguage.googleapis.com/v1beta/openai',
    );
    const demoKey = String.fromEnvironment('DEMO_AI_KEY');
    const demoModel = String.fromEnvironment(
      'DEMO_AI_MODEL',
      defaultValue: 'gemini-2.5-flash',
    );

    final effectiveKey = (openRouterKey != null && openRouterKey.isNotEmpty)
        ? openRouterKey
        : (apiKey.isNotEmpty ? apiKey : demoKey);
    final effectiveUrl = (openRouterKey != null && openRouterKey.isNotEmpty)
        ? 'https://openrouter.ai/api/v1'
        : (apiKey.isNotEmpty ? baseUrl : demoUrl);
    final effectiveModel = (openRouterKey != null && openRouterKey.isNotEmpty)
        ? 'google/gemini-2.0-flash-exp:free'
        : (model.isNotEmpty ? model : demoModel);

    if (effectiveKey.isEmpty) {
      return 'Halo! Aura siap membantu. Silakan masukkan GEMINI_API_KEY Anda di Settings untuk mode BYOK, atau nyalakan Server Backend OpenRouter.';
    }

    // Agentic loop
    for (int loop = 0; loop < 5; loop++) {
      final response = await _callOpenAiFormatApi(
        effectiveUrl,
        effectiveKey,
        effectiveModel,
        allowActions: allowActions,
      );
      final choice = response['choices'][0];
      final msg = choice['message'] as Map<String, dynamic>;

      _history.add(msg);

      final toolCalls = msg['tool_calls'] as List?;
      if (toolCalls == null || toolCalls.isEmpty) {
        return (msg['content'] as String?)?.trim() ??
            'Aura siap mendampingi waktu Anda.';
      }

      final proposals = <AiActionProposal>[];
      var bulkSchedulingWasRequested = false;
      var writeWasBlocked = false;
      for (final tc in toolCalls) {
        final name = tc['function']['name'] as String;
        final args =
            jsonDecode(tc['function']['arguments'] as String)
                as Map<String, dynamic>;
        if (name == 'generate_blueprint' || name == 'schedule_adaptive_goal') {
          bulkSchedulingWasRequested = true;
          _history.add({
            'role': 'tool',
            'tool_call_id': tc['id'],
            'content': jsonEncode({
              'error':
                  'Bulk schedule needs atomic review and is not available yet.',
            }),
          });
          continue;
        }
        if (name == 'list_activities') {
          final result = await _executeTool(name, args);
          _history.add({
            'role': 'tool',
            'tool_call_id': tc['id'],
            'content': jsonEncode(result),
          });
          continue;
        }
        if (!allowActions) {
          writeWasBlocked = true;
          _history.add({
            'role': 'tool',
            'tool_call_id': tc['id'],
            'content': jsonEncode({
              'error': 'Read-only request. No changes applied.',
            }),
          });
          continue;
        }
        proposals.add(
          AiActionProposal(
            name: name,
            summary: await _summarizeToolProposal(name, args),
            arguments: args,
            apply: () async {
              final result = await _executeTool(name, args);
              if (result['error'] != null || result['success'] == false) {
                throw StateError(
                  (result['error'] ?? 'Perubahan tidak diterapkan').toString(),
                );
              }
              return result;
            },
          ),
        );
        _history.add({
          'role': 'tool',
          'tool_call_id': tc['id'],
          'content': jsonEncode({'status': 'awaiting_user_approval'}),
        });
      }
      if (proposals.isNotEmpty) {
        _pendingActions = List.unmodifiable(proposals);
        const reply =
            'Aura menyiapkan perubahan untuk ditinjau. Belum ada perubahan yang diterapkan.';
        return bulkSchedulingWasRequested
            ? '$reply\n\nRencana berulang/massal belum dapat diterapkan dengan aman; usulan satuan di bawah bisa kamu tinjau.'
            : reply;
      }
      if (bulkSchedulingWasRequested) {
        return 'Aku bisa bantu menyusun rencana di chat, tetapi jadwal massal/berulang belum dapat diterapkan dengan aman. Minta satu blok jadwal dulu agar bisa ditinjau sebelum disimpan.';
      }
      if (writeWasBlocked)
        return 'Permintaan ini hanya dalam mode baca; tidak ada perubahan jadwal diterapkan.';
    }

    return 'Proses penjadwalan selesais.';
  }

  Future<Map<String, dynamic>> _callOpenAiFormatApi(
    String url,
    String key,
    String modelName, {
    required bool allowActions,
  }) async {
    final uri = Uri.parse('$url/chat/completions');
    final body = jsonEncode({
      'model': modelName,
      'messages': _history,
      'tools': _tools.where((tool) {
        final name = (tool['function'] as Map<String, dynamic>)['name'];
        if (name == 'generate_blueprint' || name == 'schedule_adaptive_goal')
          return false;
        return allowActions || name == 'list_activities';
      }).toList(),
      'tool_choice': 'auto',
    });

    final resp = await _httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $key',
        if (url.contains('openrouter'))
          'HTTP-Referer': 'https://focusclock.app',
      },
      body: body,
    );

    if (resp.statusCode != 200) {
      throw Exception('API ${resp.statusCode}: ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  Future<String> _summarizeToolProposal(
    String name,
    Map<String, dynamic> args,
  ) async {
    if (name == 'create_activity') {
      final date = DateTime.parse(args['date'] as String);
      final start =
          (args['start_hour'] as num).toInt() * 60 +
          ((args['start_minute'] as num?)?.toInt() ?? 0);
      final duration = (args['duration_minutes'] as num?)?.toInt() ?? 60;
      final recurrence = args['recurrence'] as String? ?? 'none';
      final repeat = recurrence == 'none' ? '' : ' · berulang $recurrence';
      return 'Tambah “${args['title']}” · ${_fmtDate(date)} · ${_fmtRange(start, duration)} · $duration menit$repeat';
    }

    final id = (args['id'] as num?)?.toInt();
    final existing = id == null ? null : await _activityRepo.get(id);
    if (existing == null)
      return '${name.replaceAll('_', ' ')} · aktivitas #$id';

    final initialStart =
        (existing.ampmHalf == AmPmHalf.pm ? 720 : 0) + existing.startMinute;
    if (name == 'delete_activity') {
      return 'Hapus “${existing.title}” · ${_fmtDate(existing.date)} · ${_fmtRange(initialStart, existing.endMinute - existing.startMinute)}';
    }
    if (name == 'update_activity') {
      final startHour = args['start_hour'] as num?;
      final startMinute = args['start_minute'] as num?;
      final nextStart = startHour == null
          ? (startMinute == null
                ? initialStart
                : initialStart -
                      existing.startMinute % 60 +
                      startMinute.toInt())
          : startHour.toInt() * 60 +
                (startMinute?.toInt() ?? existing.startMinute % 60);
      var duration = (args['duration_minutes'] as num?)?.toInt();
      if (duration == null && existing.groupId != null) {
        final group = await _activityRepo.getGroup(existing.groupId!);
        duration = group.fold<int>(
          0,
          (sum, item) => sum + item.endMinute - item.startMinute,
        );
      }
      duration ??= existing.endMinute - existing.startMinute;
      final title = args['title'] as String? ?? existing.title;
      final date = args['date'] == null
          ? existing.date
          : DateTime.parse(args['date'] as String);
      return 'Ubah “${existing.title}” menjadi “$title” · ${_fmtDate(date)} · ${_fmtRange(nextStart, duration)}';
    }
    if (name == 'set_priority') {
      final changes = <String>[];
      if (args['importance'] != null) {
        changes.add(
          args['importance'] == 1 ? 'prioritas tinggi' : 'prioritas rendah',
        );
      }
      if (args.containsKey('deadline')) {
        final deadline = args['deadline'] as String?;
        changes.add(deadline == null ? 'hapus tenggat' : 'tenggat $deadline');
      }
      return 'Ubah “${existing.title}” · ${changes.join(' · ')}';
    }
    return name.replaceAll('_', ' ');
  }

  String _fmtRange(int startMinutes, int duration) {
    String time(int minute) {
      final normalized = minute % 1440;
      return '${(normalized ~/ 60).toString().padLeft(2, '0')}:${(normalized % 60).toString().padLeft(2, '0')}';
    }

    final dayOffset = (startMinutes + duration) ~/ 1440;
    return '${time(startMinutes)}–${time(startMinutes + duration)}${dayOffset > 0 ? ' (+$dayOffset hari)' : ''}';
  }

  // ── Tool executor ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _executeTool(
    String name,
    Map<String, dynamic> args,
  ) async {
    try {
      return switch (name) {
        'list_activities' => await _listActivities(args),
        'create_activity' => await _createActivity(args),
        'update_activity' => await _updateActivity(args),
        'delete_activity' => await _deleteActivity(args),
        'set_priority' => await _setPriority(args),
        'generate_blueprint' => await _generateBlueprint(args),
        'schedule_adaptive_goal' => await _scheduleAdaptiveGoal(args),
        _ => {'error': 'Unknown tool: $name'},
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _listActivities(
    Map<String, dynamic> args,
  ) async {
    final dateStr = args['date'] as String?;
    final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
    final activities = await _activityRepo.getByDate(dateOnly(date));
    return {
      'activities': activities
          .map(
            (a) => {
              'id': a.id,
              'title': a.title,
              'date': _fmtDate(a.date),
              'start': _fmtTime(a.ampmHalf, a.startMinute),
              'end': _fmtTime(a.ampmHalf, a.endMinute),
              'description': a.description,
              'recurrence': a.recurrence,
            },
          )
          .toList(),
    };
  }

  Future<int> _createSpan({
    required String title,
    required DateTime date,
    required int startHour,
    required int startMin,
    required int durationMinutes,
    String description = '',
    String recurrence = 'none',
    int colorValue = 0xFFFFD700,
  }) async {
    final startDt = DateTime(
      date.year,
      date.month,
      date.day,
      startHour,
      startMin,
    );
    final endDt = startDt.add(Duration(minutes: durationMinutes));
    final segments = splitSpan(startDt, endDt);
    final groupId = segments.length > 1 ? const Uuid().v4() : null;

    for (final s in segments) {
      final conflicts = await _activityRepo.getConflicting(
        s.date,
        s.half,
        s.start,
        s.end,
      );
      if (conflicts.isNotEmpty) {
        final c = conflicts.first;
        final cStart = _fmtTime(c.ampmHalf, c.startMinute);
        final cEnd = _fmtTime(c.ampmHalf, c.endMinute);
        throw Exception(
          'Waktu bentrok dengan "${c.title}" ($cStart\u2013$cEnd).',
        );
      }
    }

    final now = DateTime.now();
    final acts = [
      for (final s in segments)
        Activity()
          ..title = title
          ..startMinute = s.start
          ..endMinute = s.end
          ..ampmHalf = s.half
          ..date = s.date
          ..groupId = groupId
          ..description = description
          ..recurrence = recurrence
          ..colorValue = colorValue
          ..createdAt = now
          ..updatedAt = now,
    ];
    if (acts.length == 1) return _activityRepo.upsert(acts.first);
    await _activityRepo.replaceSpan(
      original: Activity()..title = title,
      segments: acts,
    );
    return acts.first.id;
  }

  Activity _copyActivity(Activity source) => Activity()
    ..id = source.id
    ..habitId = source.habitId
    ..presetId = source.presetId
    ..iconKey = source.iconKey
    ..title = source.title
    ..startMinute = source.startMinute
    ..endMinute = source.endMinute
    ..ampmHalf = source.ampmHalf
    ..date = source.date
    ..description = source.description
    ..colorValue = source.colorValue
    ..recurrence = source.recurrence
    ..groupId = source.groupId
    ..importance = source.importance
    ..deadline = source.deadline
    ..isCompleted = source.isCompleted
    ..actualDurationSeconds = source.actualDurationSeconds
    ..isLocked = source.isLocked
    ..excludedDates = List.of(source.excludedDates)
    ..createdAt = source.createdAt
    ..updatedAt = source.updatedAt;

  Future<Map<String, dynamic>> _createActivity(
    Map<String, dynamic> args,
  ) async {
    final title = args['title'] as String;
    final dateStr = args['date'] as String;
    final startHour = (args['start_hour'] as num).toInt();
    final startMin = (args['start_minute'] as num?)?.toInt() ?? 0;
    final duration = (args['duration_minutes'] as num?)?.toInt() ?? 60;
    final description = args['description'] as String? ?? '';
    final recurrence = args['recurrence'] as String? ?? 'none';

    final id = await _createSpan(
      title: title,
      date: DateTime.parse(dateStr),
      startHour: startHour,
      startMin: startMin,
      durationMinutes: duration,
      description: description,
      recurrence: recurrence,
    );
    return {'success': true, 'id': id, 'title': title};
  }

  Future<Map<String, dynamic>> _updateActivity(
    Map<String, dynamic> args,
  ) async {
    final id = (args['id'] as num).toInt();
    final existing = await _activityRepo.get(id);
    if (existing == null) return {'error': 'Activity $id not found'};
    final updated = _copyActivity(existing);

    if (args['title'] != null) updated.title = args['title'] as String;
    if (args['description'] != null) {
      updated.description = args['description'] as String;
    }
    if (args['recurrence'] != null) {
      updated.recurrence = args['recurrence'] as String;
    }
    if (args['date'] != null) {
      updated.date = dateOnly(DateTime.parse(args['date'] as String));
    }

    final timeChanged =
        args['start_hour'] != null ||
        args['start_minute'] != null ||
        args['duration_minutes'] != null;
    if (!timeChanged) {
      await _activityRepo.upsert(updated);
      return {'success': true, 'id': id};
    }

    final h = args['start_hour'] != null
        ? (args['start_hour'] as num).toInt()
        : (updated.ampmHalf == AmPmHalf.pm ? 12 : 0) +
              updated.startMinute ~/ 60;
    final m = args['start_minute'] != null
        ? (args['start_minute'] as num).toInt()
        : updated.startMinute % 60;

    int dur;
    if (args['duration_minutes'] != null) {
      dur = (args['duration_minutes'] as num).toInt();
    } else if (updated.groupId != null) {
      final group = await _activityRepo.getGroup(updated.groupId!);
      dur = group.fold(0, (s, g) => s + g.endMinute - g.startMinute);
    } else {
      dur = updated.endMinute - updated.startMinute;
    }

    final startDt = DateTime(
      updated.date.year,
      updated.date.month,
      updated.date.day,
      h,
      m,
    );
    final segments = splitSpan(startDt, startDt.add(Duration(minutes: dur)));
    final groupId = segments.length > 1
        ? (updated.groupId ?? const Uuid().v4())
        : null;

    for (final s in segments) {
      final conflicts = await _activityRepo.getConflicting(
        s.date,
        s.half,
        s.start,
        s.end,
        excludeId: id,
      );
      if (conflicts.isNotEmpty) {
        final c = conflicts.first;
        final cStart = _fmtTime(c.ampmHalf, c.startMinute);
        final cEnd = _fmtTime(c.ampmHalf, c.endMinute);
        throw Exception(
          'Waktu bentrok dengan "${c.title}" ($cStart\u2013$cEnd).',
        );
      }
    }

    final now = DateTime.now();
    await _activityRepo.replaceSpan(
      original: existing,
      segments: [
        for (final s in segments)
          Activity()
            ..title = updated.title
            ..habitId = updated.habitId
            ..presetId = updated.presetId
            ..iconKey = updated.iconKey
            ..startMinute = s.start
            ..endMinute = s.end
            ..ampmHalf = s.half
            ..date = s.date
            ..groupId = groupId
            ..description = updated.description
            ..recurrence = updated.recurrence
            ..colorValue = updated.colorValue
            ..importance = updated.importance
            ..deadline = updated.deadline
            ..createdAt = updated.createdAt
            ..updatedAt = now,
      ],
    );
    return {'success': true, 'id': id};
  }

  Future<Map<String, dynamic>> _deleteActivity(
    Map<String, dynamic> args,
  ) async {
    final id = (args['id'] as num).toInt();
    final ok = await _activityRepo.delete(id);
    return {'success': ok, 'id': id};
  }

  Future<Map<String, dynamic>> _setPriority(Map<String, dynamic> args) async {
    final id = (args['id'] as num).toInt();
    final existing = await _activityRepo.get(id);
    if (existing == null) return {'error': 'Activity $id not found'};

    if (args['importance'] != null) {
      await _activityRepo.setImportance(
        existing,
        (args['importance'] as num).toInt(),
      );
    }
    if (args.containsKey('deadline')) {
      final dl = args['deadline'] as String?;
      await _activityRepo.setDeadline(
        existing,
        dl != null ? DateTime.parse(dl) : null,
      );
    }
    return {'success': true, 'id': id};
  }

  Future<Map<String, dynamic>> _generateBlueprint(
    Map<String, dynamic> args,
  ) async {
    final dateStr = args['date'] as String;
    final date = DateTime.parse(dateStr);
    final wakeH = (args['wake_hour'] as num).toInt();
    final sleepH = (args['sleep_hour'] as num).toInt();
    final goals = (args['goals'] as List?)?.cast<String>() ?? [];

    final workStart = wakeH + 1;
    final blocks = <Map<String, dynamic>>[];

    blocks.add({
      'title': 'Rutinitas Pagi',
      'start_hour': wakeH,
      'start_minute': 0,
      'duration_minutes': 30,
      'description':
          'Minum air, peregangan ringan, dan tinjau rencana hari ini.',
      'color': 0xFFFFD700,
    });

    int cursor = workStart * 60;
    final goalLabels = goals.isNotEmpty ? goals : ['Deep Work Utama'];
    for (int i = 0; i < goalLabels.length && i < 3; i++) {
      final dwDur = 90;
      if (cursor + dwDur > sleepH * 60 - 120) break;

      blocks.add({
        'title': 'Deep Work: ${goalLabels[i]}',
        'start_hour': cursor ~/ 60,
        'start_minute': cursor % 60,
        'duration_minutes': dwDur,
        'description': 'Fokus penuh tanpa hambatan atau notifikasi.',
        'color': 0xFF4A9EFF,
      });
      cursor += dwDur;

      blocks.add({
        'title': 'Istirahat Sadar',
        'start_hour': cursor ~/ 60,
        'start_minute': cursor % 60,
        'duration_minutes': 20,
        'description':
            'Istirahat tanpa layar untuk aktivasi Default Mode Network (DMN).',
        'color': 0xFF6BCB77,
      });
      cursor += 20;

      if (i == 0 && cursor ~/ 60 >= 11) {
        blocks.add({
          'title': 'Makan Siang dan Istirahat',
          'start_hour': cursor ~/ 60,
          'start_minute': cursor % 60,
          'duration_minutes': 90,
          'description': 'Makan siang dan reset dopamin.',
          'color': 0xFFFF9F40,
        });
        cursor += 90;
      }
    }

    final windDownStart = sleepH * 60 - 60;
    if (windDownStart > cursor) {
      blocks.add({
        'title': 'Refleksi dan Persiapan Istirahat',
        'start_hour': windDownStart ~/ 60,
        'start_minute': windDownStart % 60,
        'duration_minutes': 45,
        'description': 'Jurnal dan evaluasi hari ini.',
        'color': 0xFF9B8FFF,
      });
    }

    blocks.add({
      'title': 'Tidur',
      'start_hour': sleepH,
      'start_minute': 0,
      'duration_minutes': ((wakeH + 24 - sleepH) * 60).clamp(270, 540),
      'description':
          'Kelipatan 90 menit untuk bangun tidur tanpa sleep inertia.',
      'color': 0xFF2E2E4E,
    });

    final created = <int>[];
    for (final b in blocks) {
      final id = await _createSpan(
        title: b['title'] as String,
        date: date,
        startHour: b['start_hour'] as int,
        startMin: b['start_minute'] as int,
        durationMinutes: b['duration_minutes'] as int,
        description: b['description'] as String,
        colorValue: b['color'] as int,
      );
      created.add(id);
    }

    return {
      'success': true,
      'blocks_created': created.length,
      'message':
          'Fitrah Blueprint berhasil dibuat: ${created.length} blok untuk $dateStr.',
    };
  }

  Future<Map<String, dynamic>> _scheduleAdaptiveGoal(
    Map<String, dynamic> args,
  ) async {
    final goalTitle = args['goal_title'] as String;
    final targetDateStr = args['target_date'] as String;
    final dailyHours = (args['daily_hours'] as num).toDouble();
    final preferredTime = (args['preferred_time'] as String?) ?? 'afternoon';
    final daysPerWeek = (args['days_per_week'] as num?)?.toInt() ?? 6;

    final today = DateTime.now();
    final targetDate = DateTime.parse(targetDateStr);
    final totalDays = targetDate.difference(today).inDays;
    if (totalDays <= 0) {
      return {'error': 'Target date must be in the future.'};
    }

    final totalTargetHours = (totalDays * (daysPerWeek / 7.0) * dailyHours)
        .round();

    int startHour = 14;
    if (preferredTime == 'morning') startHour = 8;
    if (preferredTime == 'evening') startHour = 19;

    final durationMins = (dailyHours * 60).round().clamp(30, 240);

    final primaryId = await _createSpan(
      title: 'Latihan $goalTitle',
      date: dateOnly(today),
      startHour: startHour,
      startMin: 0,
      durationMinutes: durationMins,
      description:
          'Latihan intensif & simulasi target $goalTitle. (Estimasi: $totalTargetHours jam total hingga ${_fmtDate(targetDate)}).',
      recurrence: daysPerWeek >= 6 ? 'daily' : 'weekday',
      colorValue: 0xFF4A9EFF,
    );

    await _createSpan(
      title: 'Hari-H: $goalTitle',
      date: dateOnly(targetDate),
      startHour: 8,
      startMin: 0,
      durationMinutes: 480,
      description: 'Hari pelaksanaan target $goalTitle!',
      recurrence: 'none',
      colorValue: 0xFFFFD700,
    );

    return {
      'success': true,
      'goal_title': goalTitle,
      'target_date': _fmtDate(targetDate),
      'days_remaining': totalDays,
      'total_hours_planned': totalTargetHours,
      'daily_hours': dailyHours,
      'primary_activity_id': primaryId,
      'message':
          'Jadwal latihan adaptif $goalTitle ($dailyHours jam/hari) berhasil ditanamkan ke dalam jam fokus hingga ${_fmtDate(targetDate)}.',
    };
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtTime(AmPmHalf half, int relMin) {
    final h = (half == AmPmHalf.pm ? 12 : 0) + relMin ~/ 60;
    final m = relMin % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  void reset() {
    _history.clear();
    _initialized = false;
    for (final action in _pendingActions) {
      action.dismiss();
    }
    _pendingActions = const [];
  }
}
