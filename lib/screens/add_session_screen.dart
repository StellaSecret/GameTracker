// lib/screens/add_session_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game.dart';
import '../models/game_mode.dart';
import '../models/game_session.dart';
import '../models/player.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/gt_card.dart';

class AddSessionScreen extends StatefulWidget {
  final Game game;
  const AddSessionScreen({super.key, required this.game});

  @override
  State<AddSessionScreen> createState() => _AddSessionScreenState();
}

class _AddSessionScreenState extends State<AddSessionScreen> {
  final _notesCtrl = TextEditingController();
  DateTime _playedAt = DateTime.now();

  // For Points mode: playerId -> score controller
  final Map<String, TextEditingController> _scoreCtrl = {};

  // For Duel mode: playerId -> DuelResult
  final Map<String, DuelResult> _duelResults = {};

  // For Ranking mode: playerId -> rank (1-based)
  final Map<String, int> _ranks = {};

  // Selected players for this session
  final Set<String> _selectedPlayerIds = {};

  @override
  void dispose() {
    _notesCtrl.dispose();
    for (final c in _scoreCtrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final players = state.players;

    return Scaffold(
      appBar: AppBar(
        title: Text('Partie – ${widget.game.name}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Date picker
          GTCard(
            onTap: () => _pickDate(context),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Text(
                  _formatDate(_playedAt),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textSecondary),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Player selector
          const GTSectionHeader(title: 'JOUEURS'),
          const SizedBox(height: 10),
          if (players.isEmpty)
            GTCard(
              child: Column(
                children: [
                  const Text(
                    '⚠️ Aucun joueur créé.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/players'),
                    child: const Text('Créer des joueurs'),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: players.map((p) {
                final selected = _selectedPlayerIds.contains(p.id);
                return FilterChip(
                  label: Text(p.name),
                  selected: selected,
                  onSelected: (v) => _togglePlayer(p, v),
                  selectedColor: _hexColor(p.color).withOpacity(0.3),
                  checkmarkColor: _hexColor(p.color),
                  side: BorderSide(
                    color: selected
                        ? _hexColor(p.color)
                        : AppColors.cardBorder,
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 24),

          // Score entry (depends on mode)
          if (_selectedPlayerIds.isNotEmpty) ...[
            const GTSectionHeader(title: 'SCORES'),
            const SizedBox(height: 12),
            ...widget.game.mode == GameMode.points
                ? _buildPointsInputs(state)
                : widget.game.mode == GameMode.duel
                    ? _buildDuelInputs(state)
                    : _buildRankingInputs(state),
            const SizedBox(height: 20),
          ],

          // Notes
          const GTSectionHeader(title: 'NOTES (optionnel)'),
          const SizedBox(height: 8),
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(
              hintText: 'Anecdotes, conditions de jeu…',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _canSave() ? _save : null,
            child: const Text('Enregistrer la partie'),
          ),
        ],
      ),
    );
  }

  // ── Points mode ────────────────────────────────────────────────────────────

  List<Widget> _buildPointsInputs(AppState state) {
    return _selectedPlayerIds.map((id) {
      final player = state.findPlayer(id);
      if (player == null) return const SizedBox.shrink();
      _scoreCtrl.putIfAbsent(id, () => TextEditingController(text: '0'));
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            _PlayerAvatar(player: player),
            const SizedBox(width: 12),
            Expanded(
              child: Text(player.name,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
            SizedBox(
              width: 100,
              child: TextField(
                controller: _scoreCtrl[id],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  suffixText: 'pts',
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  // ── Duel mode ──────────────────────────────────────────────────────────────

  List<Widget> _buildDuelInputs(AppState state) {
    final players = _selectedPlayerIds
        .map((id) => state.findPlayer(id))
        .whereType<Player>()
        .toList();

    return players.map((player) {
      final result = _duelResults[player.id] ?? DuelResult.draw;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GTCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _PlayerAvatar(player: player),
                  const SizedBox(width: 10),
                  Text(player.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _DuelButton(
                    label: 'Victoire',
                    emoji: '🏆',
                    color: AppColors.success,
                    selected: result == DuelResult.win,
                    onTap: () => setState(
                        () => _duelResults[player.id] = DuelResult.win),
                  ),
                  const SizedBox(width: 8),
                  _DuelButton(
                    label: 'Nul',
                    emoji: '🤝',
                    color: AppColors.warning,
                    selected: result == DuelResult.draw,
                    onTap: () => setState(
                        () => _duelResults[player.id] = DuelResult.draw),
                  ),
                  const SizedBox(width: 8),
                  _DuelButton(
                    label: 'Défaite',
                    emoji: '💀',
                    color: AppColors.error,
                    selected: result == DuelResult.loss,
                    onTap: () => setState(
                        () => _duelResults[player.id] = DuelResult.loss),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  // ── Ranking mode ───────────────────────────────────────────────────────────

  List<Widget> _buildRankingInputs(AppState state) {
    final players = _selectedPlayerIds
        .map((id) => state.findPlayer(id))
        .whereType<Player>()
        .toList();
    final count = players.length;

    return players.map((player) {
      final rank = _ranks[player.id] ?? 1;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            _PlayerAvatar(player: player),
            const SizedBox(width: 12),
            Expanded(
              child: Text(player.name,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
            DropdownButton<int>(
              value: rank,
              dropdownColor: AppColors.surfaceElevated,
              underline: const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(12),
              items: List.generate(count, (i) {
                final r = i + 1;
                return DropdownMenuItem(
                  value: r,
                  child: Text(
                    _ordinal(r),
                    style: TextStyle(
                      color: r == 1
                          ? const Color(0xFFFFD700)
                          : AppColors.textPrimary,
                      fontWeight: r == 1 ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                );
              }),
              onChanged: (v) {
                if (v != null) setState(() => _ranks[player.id] = v);
              },
            ),
          ],
        ),
      );
    }).toList();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _togglePlayer(Player p, bool selected) {
    setState(() {
      if (selected) {
        _selectedPlayerIds.add(p.id);
        if (widget.game.mode == GameMode.duel) {
          _duelResults[p.id] = DuelResult.draw;
        }
        if (widget.game.mode == GameMode.ranking) {
          _ranks[p.id] = _selectedPlayerIds.length;
        }
      } else {
        _selectedPlayerIds.remove(p.id);
        _scoreCtrl.remove(p.id)?.dispose();
        _duelResults.remove(p.id);
        _ranks.remove(p.id);
      }
    });
  }

  bool _canSave() => _selectedPlayerIds.isNotEmpty;

  Future<void> _save() async {
    final state = context.read<AppState>();
    final Map<String, int> scores = {};

    switch (widget.game.mode) {
      case GameMode.points:
        for (final id in _selectedPlayerIds) {
          scores[id] =
              int.tryParse(_scoreCtrl[id]?.text ?? '0') ?? 0;
        }
        break;
      case GameMode.duel:
        for (final id in _selectedPlayerIds) {
          scores[id] =
              (_duelResults[id] ?? DuelResult.draw).index;
        }
        break;
      case GameMode.ranking:
        for (final id in _selectedPlayerIds) {
          scores[id] = _ranks[id] ?? 1;
        }
        break;
    }

    final session = GameSession(
      mode: widget.game.mode,
      scores: scores,
      playedAt: _playedAt,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    await state.addSession(widget.game.id, session);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _playedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_playedAt),
    );
    setState(() {
      _playedAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? _playedAt.hour,
        time?.minute ?? _playedAt.minute,
      );
    });
  }

  String _formatDate(DateTime d) {
    final months = [
      'jan', 'fév', 'mar', 'avr', 'mai', 'juin',
      'juil', 'août', 'sep', 'oct', 'nov', 'déc'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year} – ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _ordinal(int n) {
    if (n == 1) return '1er';
    return '${n}ème';
  }

  Color _hexColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }
}

class _PlayerAvatar extends StatelessWidget {
  final Player player;
  const _PlayerAvatar({required this.player});

  @override
  Widget build(BuildContext context) {
    Color color;
    try {
      color = Color(
          int.parse(player.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      color = AppColors.primary;
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: color.withOpacity(0.2),
      child: Text(
        player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
        style: TextStyle(
            color: color, fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }
}

class _DuelButton extends StatelessWidget {
  final String label;
  final String emoji;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _DuelButton({
    required this.label,
    required this.emoji,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.2) : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : AppColors.cardBorder,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? color : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
