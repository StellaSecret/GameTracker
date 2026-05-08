import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/game.dart';
import '../models/game_mode.dart';
import '../models/game_session.dart';
import '../models/player.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/gt_card.dart';
import 'paywall_screen.dart';

class AddSessionScreen extends StatefulWidget {
  final Game game;
  final GameSession? existing;
  const AddSessionScreen({super.key, required this.game, this.existing});

  @override
  State<AddSessionScreen> createState() => _AddSessionScreenState();
}

class _AddSessionScreenState extends State<AddSessionScreen> {
  final _notesCtrl = TextEditingController();
  DateTime _playedAt = DateTime.now();
  final Set<String> _selectedPlayerIds = {};

  // ── Mode sans manches (legacy) ─────────────────────────────────────────────
  final Map<String, TextEditingController> _scoreCtrl = {};
  final Map<String, DuelResult> _duelResults = {};
  final Map<String, int> _ranks = {};

  // ── Mode manches ───────────────────────────────────────────────────────────
  bool _useRounds = false;

  /// rounds[i] = { playerId → score (points) ou DuelResult.index (duel) }
  final List<Map<String, TextEditingController>> _roundPointsCtrl = [];
  final List<Map<String, DuelResult>> _roundDuelResults = [];

  // ──────────────────────────────────────────────────────────────────────────

  bool get _isPoints => widget.game.mode == GameMode.points;
  bool get _isDuel => widget.game.mode == GameMode.duel;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    if (s == null) {
      return;
    }

    _playedAt = s.playedAt;
    _notesCtrl.text = s.notes ?? '';

    for (final entry in s.scores.entries) {
      _selectedPlayerIds.add(entry.key);
    }

    if (s.hasRounds) {
      _useRounds = true;
      if (_isPoints) {
        for (final round in s.rounds) {
          final ctrl = <String, TextEditingController>{};
          for (final pid in _selectedPlayerIds) {
            ctrl[pid] = TextEditingController(
                text: '${round.scores[pid] ?? 0}');
          }
          _roundPointsCtrl.add(ctrl);
        }
      } else if (_isDuel) {
        for (final round in s.rounds) {
          final results = <String, DuelResult>{};
          for (final pid in _selectedPlayerIds) {
            results[pid] =
                DuelResult.values[round.scores[pid] ?? DuelResult.draw.index];
          }
          _roundDuelResults.add(results);
        }
      }
    } else {
      // Legacy single-score
      for (final entry in s.scores.entries) {
        if (_isPoints) {
          _scoreCtrl[entry.key] =
              TextEditingController(text: '${entry.value}');
        } else if (_isDuel) {
          _duelResults[entry.key] = DuelResult.values[entry.value];
        } else {
          _ranks[entry.key] = entry.value;
        }
      }
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    for (final c in _scoreCtrl.values) {
      c.dispose();
    }
    for (final round in _roundPointsCtrl) {
      for (final c in round.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  // ── Round management ───────────────────────────────────────────────────────

  void _addRound() {
    setState(() {
      if (_isPoints) {
        final ctrl = <String, TextEditingController>{};
        for (final pid in _selectedPlayerIds) {
          ctrl[pid] = TextEditingController(text: '0');
        }
        _roundPointsCtrl.add(ctrl);
      } else if (_isDuel) {
        final results = <String, DuelResult>{};
        for (final pid in _selectedPlayerIds) {
          results[pid] = DuelResult.draw;
        }
        _roundDuelResults.add(results);
      }
    });
  }

  void _removeRound(int index) {
    setState(() {
      if (_isPoints) {
        for (final c in _roundPointsCtrl[index].values) {
          c.dispose();
        }
        _roundPointsCtrl.removeAt(index);
      } else if (_isDuel) {
        _roundDuelResults.removeAt(index);
      }
    });
  }

  int get _roundCount =>
      _isPoints ? _roundPointsCtrl.length : _roundDuelResults.length;

  /// Running totals per player (points) or round wins (duel).
  Map<String, int> get _runningTotals {
    if (!_useRounds) {
      return {};
    }
    if (_isPoints) {
      final totals = <String, int>{};
      for (final round in _roundPointsCtrl) {
        for (final pid in _selectedPlayerIds) {
          totals[pid] =
              (totals[pid] ?? 0) + (int.tryParse(round[pid]?.text ?? '0') ?? 0);
        }
      }
      return totals;
    } else if (_isDuel) {
      final wins = <String, int>{};
      for (final pid in _selectedPlayerIds) {
        wins[pid] = 0;
      }
      for (final round in _roundDuelResults) {
        for (final pid in _selectedPlayerIds) {
          if ((round[pid] ?? DuelResult.draw) == DuelResult.win) {
            wins[pid] = (wins[pid] ?? 0) + 1;
          }
        }
      }
      return wins;
    }
    return {};
  }

  // ── Toggle rounds ──────────────────────────────────────────────────────────

  void _toggleRounds(bool value) {
    setState(() {
      _useRounds = value;
      if (value) {
        // Migrate existing single-score entries into round 0
        if (_isPoints && _selectedPlayerIds.isNotEmpty) {
          final ctrl = <String, TextEditingController>{};
          for (final pid in _selectedPlayerIds) {
            final existing = _scoreCtrl[pid]?.text ?? '0';
            ctrl[pid] = TextEditingController(text: existing);
          }
          _roundPointsCtrl.add(ctrl);
          // Clear legacy controllers
          for (final c in _scoreCtrl.values) {
            c.dispose();
          }
          _scoreCtrl.clear();
        } else if (_isDuel && _selectedPlayerIds.isNotEmpty) {
          final results = <String, DuelResult>{};
          for (final pid in _selectedPlayerIds) {
            results[pid] = _duelResults[pid] ?? DuelResult.draw;
          }
          _roundDuelResults.add(results);
          _duelResults.clear();
        }
      } else {
        // Collapse rounds into a single aggregated score
        if (_isPoints) {
          final totals = _runningTotals;
          for (final c in _scoreCtrl.values) {
            c.dispose();
          }
          _scoreCtrl.clear();
          for (final pid in _selectedPlayerIds) {
            _scoreCtrl[pid] =
                TextEditingController(text: '${totals[pid] ?? 0}');
          }
          for (final round in _roundPointsCtrl) {
            for (final c in round.values) {
              c.dispose();
            }
          }
          _roundPointsCtrl.clear();
        } else if (_isDuel) {
          // Keep the most-won result as the overall result
          final wins = _runningTotals;
          _duelResults.clear();
          for (final pid in _selectedPlayerIds) {
            final myWins = wins[pid] ?? 0;
            final total = _roundDuelResults.length;
            if (myWins > total ~/ 2) {
              _duelResults[pid] = DuelResult.win;
            } else if (myWins == total ~/ 2 && total % 2 == 0) {
              _duelResults[pid] = DuelResult.draw;
            } else {
              _duelResults[pid] = DuelResult.loss;
            }
          }
          _roundDuelResults.clear();
        }
      }
    });
  }

  // ── Player toggle ──────────────────────────────────────────────────────────

  void _togglePlayer(Player p, bool selected) {
    setState(() {
      if (selected) {
        _selectedPlayerIds.add(p.id);
        if (!_useRounds) {
          if (_isPoints) {
            _scoreCtrl.putIfAbsent(
                p.id, () => TextEditingController(text: '0'));
          } else if (_isDuel) {
            _duelResults[p.id] = DuelResult.draw;
          } else {
            _ranks[p.id] = _selectedPlayerIds.length;
          }
        } else {
          // Add player to every existing round
          if (_isPoints) {
            for (final round in _roundPointsCtrl) {
              round.putIfAbsent(
                  p.id, () => TextEditingController(text: '0'));
            }
          } else if (_isDuel) {
            for (final round in _roundDuelResults) {
              round.putIfAbsent(p.id, () => DuelResult.draw);
            }
          }
        }
      } else {
        _selectedPlayerIds.remove(p.id);
        _scoreCtrl.remove(p.id)?.dispose();
        _duelResults.remove(p.id);
        _ranks.remove(p.id);
        for (final round in _roundPointsCtrl) {
          round.remove(p.id)?.dispose();
        }
        for (final round in _roundDuelResults) {
          round.remove(p.id);
        }
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final players = state.players;
    final limitError = state.canAddSession(widget.game.id);

    return Scaffold(
      appBar: AppBar(title: Text('Partie – ${widget.game.name}')),
      body: limitError != null
          ? _LimitReached(reason: limitError)
          : ListView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + MediaQuery.of(context).padding.bottom,
              ),
              children: [
                // ── Date ───────────────────────────────────────────────────
                GTCard(
                  onTap: () => _pickDate(context),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Text(_formatDate(_playedAt),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textSecondary),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Players ────────────────────────────────────────────────
                const GTSectionHeader(title: 'JOUEURS'),
                const SizedBox(height: 10),
                if (players.isEmpty)
                  GTCard(
                    child: Column(
                      children: [
                        const Text('⚠️ Aucun joueur créé.',
                            style:
                                TextStyle(fontWeight: FontWeight.w600)),
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
                      final selected =
                          _selectedPlayerIds.contains(p.id);
                      final color = _hexColor(p.color);
                      return FilterChip(
                        label: Text(p.name),
                        selected: selected,
                        onSelected: (v) => _togglePlayer(p, v),
                        selectedColor: color.withValues(alpha: 0.3),
                        checkmarkColor: color,
                        side: BorderSide(
                          color: selected
                              ? color
                              : AppColors.cardBorder,
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 24),

                // ── Scores ─────────────────────────────────────────────────
                if (_selectedPlayerIds.isNotEmpty) ...[
                  // Rounds toggle (points + duel only)
                  if (_isPoints || _isDuel) ...[
                    _RoundsToggle(
                      value: _useRounds,
                      onChanged: _toggleRounds,
                    ),
                    const SizedBox(height: 16),
                  ],

                  const GTSectionHeader(title: 'SCORES'),
                  const SizedBox(height: 12),

                  if (_useRounds && (_isPoints || _isDuel))
                    _buildRoundsSection(state)
                  else ...[
                    ...widget.game.mode == GameMode.points
                        ? _buildPointsInputs(state)
                        : widget.game.mode == GameMode.duel
                            ? _buildDuelInputs(state)
                            : _buildRankingInputs(state),
                  ],
                  const SizedBox(height: 20),
                ],

                // ── Notes ──────────────────────────────────────────────────
                const GTSectionHeader(title: 'NOTES (optionnel)'),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                      hintText: 'Anecdotes, conditions de jeu…'),
                  maxLines: 2,
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _canSave() ? _save : null,
                  child: Text(widget.existing != null
                      ? 'Mettre à jour'
                      : 'Enregistrer la partie'),
                ),
              ],
            ),
    );
  }

  // ── Score builders ─────────────────────────────────────────────────────────

  Widget _buildRoundsSection(AppState state) {
    final totals = _runningTotals;
    return Column(
      children: [
        // Running totals header
        if (_roundCount > 0) _TotalsHeader(
          playerIds: _selectedPlayerIds.toList(),
          totals: totals,
          state: state,
          lowestScoreWins: widget.game.lowestScoreWins,
          isDuel: _isDuel,
        ),
        const SizedBox(height: 12),

        // Round cards
        ...List.generate(_roundCount, (i) => _RoundCard(
              roundIndex: i,
              playerIds: _selectedPlayerIds.toList(),
              state: state,
              isPoints: _isPoints,
              pointsControllers: _isPoints ? _roundPointsCtrl[i] : {},
              duelResults: _isDuel ? _roundDuelResults[i] : {},
              onDuelChanged: _isDuel
                  ? (pid, result) => setState(
                      () => _roundDuelResults[i][pid] = result)
                  : null,
              onPointsChanged: () => setState(() {}),
              onRemove: _roundCount > 1
                  ? () => _removeRound(i)
                  : null,
            )),

        // Add round button
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _addRound,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(_isPoints ? '+ Manche' : '+ Round'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPointsInputs(AppState state) {
    return _selectedPlayerIds.map((id) {
      final player = state.findPlayer(id);
      if (player == null) {
        return const SizedBox.shrink();
      }
      _scoreCtrl.putIfAbsent(
          id, () => TextEditingController(text: '0'));
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
              width: 110,
              child: TextField(
                controller: _scoreCtrl[id],
                keyboardType: const TextInputType.numberWithOptions(
                    signed: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^-?\d*')),
                ],
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                    suffixText: 'pts', isDense: true),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildDuelInputs(AppState state) {
    final players = _selectedPlayerIds
        .map((id) => state.findPlayer(id))
        .whereType<Player>()
        .toList();
    return players
        .map((player) => _DuelPlayerRow(
              player: player,
              result: _duelResults[player.id] ?? DuelResult.draw,
              onChanged: (r) =>
                  setState(() => _duelResults[player.id] = r),
            ))
        .toList();
  }

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
                      fontWeight: r == 1
                          ? FontWeight.w700
                          : FontWeight.normal,
                    ),
                  ),
                );
              }),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _ranks[player.id] = v);
                }
              },
            ),
          ],
        ),
      );
    }).toList();
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  bool _canSave() {
    if (_selectedPlayerIds.isEmpty) {
      return false;
    }
    if (_useRounds && _roundCount == 0) {
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    final state = context.read<AppState>();
    final isEdit = widget.existing != null;

    Map<String, int> scores;
    List<Round> rounds = [];

    if (_useRounds && (_isPoints || _isDuel)) {
      if (_isPoints) {
        final rawRounds = _roundPointsCtrl.map((ctrl) => Round(
              ctrl.map((pid, c) =>
                  MapEntry(pid, int.tryParse(c.text) ?? 0)),
            )).toList();
        scores = GameSession.aggregatePointsRounds(rawRounds);
        rounds = rawRounds;
      } else {
        // Duel with rounds
        final rawRounds = _roundDuelResults.map((r) =>
            Round(r.map((pid, res) => MapEntry(pid, res.index)))).toList();
        scores = GameSession.aggregateDuelRounds(rawRounds);
        rounds = rawRounds;
      }
    } else {
      scores = {};
      switch (widget.game.mode) {
        case GameMode.points:
          for (final id in _selectedPlayerIds) {
            scores[id] =
                int.tryParse(_scoreCtrl[id]?.text ?? '0') ?? 0;
          }
        case GameMode.duel:
          for (final id in _selectedPlayerIds) {
            scores[id] =
                (_duelResults[id] ?? DuelResult.draw).index;
          }
        case GameMode.ranking:
          for (final id in _selectedPlayerIds) {
            scores[id] = _ranks[id] ?? 1;
          }
      }
    }

    final session = GameSession(
      id: isEdit ? widget.existing!.id : null,
      mode: widget.game.mode,
      scores: scores,
      rounds: rounds,
      playedAt: _playedAt,
      notes: _notesCtrl.text.trim().isEmpty
          ? null
          : _notesCtrl.text.trim(),
    );

    if (isEdit) {
      await state.updateSession(widget.game.id, session);
    } else {
      await state.addSession(widget.game.id, session);
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  // ── Date picker ────────────────────────────────────────────────────────────

  Future<void> _pickDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _playedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_playedAt),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _playedAt = DateTime(
        date.year, date.month, date.day,
        time?.hour ?? _playedAt.hour,
        time?.minute ?? _playedAt.minute,
      );
    });
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatDate(DateTime d) {
    final months = [
      'jan', 'fév', 'mar', 'avr', 'mai', 'juin',
      'juil', 'août', 'sep', 'oct', 'nov', 'déc'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year} '
        '– ${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  String _ordinal(int n) => n == 1 ? '1er' : '$nème';

  Color _hexColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Sub-widgets
// ══════════════════════════════════════════════════════════════════════════════

// ── Rounds toggle ─────────────────────────────────────────────────────────────

class _RoundsToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _RoundsToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GTCard(
      child: Row(
        children: [
          const Text('🔢', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Saisie par manches',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                SizedBox(height: 2),
                Text('Calculer le total manche par manche',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

// ── Running totals header ─────────────────────────────────────────────────────

class _TotalsHeader extends StatelessWidget {
  final List<String> playerIds;
  final Map<String, int> totals;
  final AppState state;
  final bool lowestScoreWins;
  final bool isDuel;

  const _TotalsHeader({
    required this.playerIds,
    required this.totals,
    required this.state,
    required this.lowestScoreWins,
    required this.isDuel,
  });

  @override
  Widget build(BuildContext context) {
    // Find leader
    String? leaderId;
    if (totals.isNotEmpty) {
      if (isDuel) {
        final max = totals.values.reduce((a, b) => a > b ? a : b);
        final leaders =
            totals.entries.where((e) => e.value == max).toList();
        if (leaders.length == 1) {
          leaderId = leaders.first.key;
        }
      } else if (lowestScoreWins) {
        final min = totals.values.reduce((a, b) => a < b ? a : b);
        final leaders =
            totals.entries.where((e) => e.value == min).toList();
        if (leaders.length == 1) {
          leaderId = leaders.first.key;
        }
      } else {
        final max = totals.values.reduce((a, b) => a > b ? a : b);
        final leaders =
            totals.entries.where((e) => e.value == max).toList();
        if (leaders.length == 1) {
          leaderId = leaders.first.key;
        }
      }
    }

    return GTCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📊',
                  style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                isDuel ? 'Manches gagnées' : 'Totaux en cours',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary),
              ),
              if (lowestScoreWins && !isDuel) ...[
                const SizedBox(width: 6),
                const GTBadge(
                    label: 'moins = mieux',
                    color: AppColors.accent,
                    emoji: '🔻'),
              ],
            ],
          ),
          const SizedBox(height: 10),
          ...playerIds.map((pid) {
            final player = state.findPlayer(pid);
            final name = player?.name ?? pid;
            final total = totals[pid] ?? 0;
            final isLeader = pid == leaderId;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  if (isLeader)
                    const Text('👑 ',
                        style: TextStyle(fontSize: 13))
                  else
                    const SizedBox(width: 20),
                  Expanded(
                    child: Text(name,
                        style: TextStyle(
                          fontWeight: isLeader
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isLeader
                              ? AppColors.accent
                              : AppColors.textPrimary,
                        )),
                  ),
                  Text(
                    isDuel
                        ? '$total manche${total != 1 ? 's' : ''}'
                        : '$total pts',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isLeader
                          ? AppColors.accent
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Round card ────────────────────────────────────────────────────────────────

class _RoundCard extends StatelessWidget {
  final int roundIndex;
  final List<String> playerIds;
  final AppState state;
  final bool isPoints;
  final Map<String, TextEditingController> pointsControllers;
  final Map<String, DuelResult> duelResults;
  final void Function(String pid, DuelResult result)? onDuelChanged;
  final VoidCallback? onPointsChanged;
  final VoidCallback? onRemove;

  const _RoundCard({
    required this.roundIndex,
    required this.playerIds,
    required this.state,
    required this.isPoints,
    required this.pointsControllers,
    required this.duelResults,
    this.onDuelChanged,
    this.onPointsChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GTCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Manche ${roundIndex + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                if (onRemove != null)
                  GestureDetector(
                    onTap: onRemove,
                    child: const Icon(Icons.close_rounded,
                        size: 18, color: AppColors.textSecondary),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Scores per player
            ...playerIds.map((pid) {
              final player = state.findPlayer(pid);
              final name = player?.name ?? pid;
              if (isPoints) {
                final ctrl = pointsControllers[pid];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      if (player != null)
                        _PlayerAvatar(player: player)
                      else
                        const SizedBox(width: 36),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500)),
                      ),
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: ctrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  signed: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^-?\d*')),
                          ],
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                              suffixText: 'pts', isDense: true),
                          onChanged: (_) {
                            if (onPointsChanged != null) {
                              onPointsChanged!();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                // Duel round
                final result = duelResults[pid] ?? DuelResult.draw;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _DuelPlayerRow(
                    player: player ??
                        Player(id: pid, name: name, color: '#6C63FF'),
                    result: result,
                    onChanged: (r) {
                      if (onDuelChanged != null) {
                        onDuelChanged!(pid, r);
                      }
                    },
                    compact: true,
                  ),
                );
              }
            }),
          ],
        ),
      ),
    );
  }
}

// ── Duel player row ───────────────────────────────────────────────────────────

class _DuelPlayerRow extends StatelessWidget {
  final Player player;
  final DuelResult result;
  final ValueChanged<DuelResult> onChanged;
  final bool compact;

  const _DuelPlayerRow({
    required this.player,
    required this.result,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GTCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _PlayerAvatar(player: player),
            const SizedBox(width: 10),
            Text(player.name,
                style:
                    const TextStyle(fontWeight: FontWeight.w600)),
          ]),
          SizedBox(height: compact ? 6 : 10),
          Row(children: [
            _DuelButton(
              label: 'Victoire',
              emoji: '🏆',
              color: AppColors.success,
              selected: result == DuelResult.win,
              onTap: () => onChanged(DuelResult.win),
            ),
            const SizedBox(width: 8),
            _DuelButton(
              label: 'Nul',
              emoji: '🤝',
              color: AppColors.warning,
              selected: result == DuelResult.draw,
              onTap: () => onChanged(DuelResult.draw),
            ),
            const SizedBox(width: 8),
            _DuelButton(
              label: 'Défaite',
              emoji: '💀',
              color: AppColors.error,
              selected: result == DuelResult.loss,
              onTap: () => onChanged(DuelResult.loss),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Limit reached ─────────────────────────────────────────────────────────────

class _LimitReached extends StatelessWidget {
  final String reason;
  const _LimitReached({required this.reason});

  @override
  Widget build(BuildContext context) {
    return GTEmptyState(
      emoji: '🔒',
      title: 'Limite atteinte',
      subtitle: reason,
      action: ElevatedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PaywallScreen(reason: reason)),
        ),
        icon: const Icon(Icons.star_rounded),
        label: const Text('Passer à Premium'),
      ),
    );
  }
}

// ── Player avatar ─────────────────────────────────────────────────────────────

class _PlayerAvatar extends StatelessWidget {
  final Player player;
  const _PlayerAvatar({required this.player});

  @override
  Widget build(BuildContext context) {
    Color color;
    try {
      color =
          Color(int.parse(player.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      color = AppColors.primary;
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: color.withValues(alpha: 0.2),
      child: Text(
        player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
        style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 14),
      ),
    );
  }
}

// ── Duel button ───────────────────────────────────────────────────────────────

class _DuelButton extends StatelessWidget {
  final String label, emoji;
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
            color: selected
                ? color.withValues(alpha: 0.2)
                : AppColors.surfaceElevated,
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
                  color:
                      selected ? color : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
