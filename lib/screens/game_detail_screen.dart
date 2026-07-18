import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/test_flags.dart';
import '../l10n/app_localizations.dart';
import '../models/game.dart';
import '../models/game_mode.dart';
import '../models/game_session.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/gt_card.dart';
import 'add_game_screen.dart';
import 'add_session_screen.dart';

class GameDetailScreen extends StatelessWidget {
  final String gameId;
  const GameDetailScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final state = context.watch<AppState>();
    final game = state.findGame(gameId);
    if (game == null) {
      return const SizedBox.shrink();
    }

    final sessions = List<GameSession>.from(game.sessions)
      ..sort((a, b) => b.playedAt.compareTo(a.playedAt));

    return Scaffold(
      appBar: AppBar(
        title: Text(game.coverEmoji != null
            ? '${game.coverEmoji} ${game.name}'
            : game.name),
        actions: [
          IconButton(
            key: const Key('btnEditGame'),
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AddGameScreen(existing: game)),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (game.description != null) ...[
                    Text(game.description!,
                        style: TextStyle(
                            color: c.textSecondary, fontSize: 14)),
                    const SizedBox(height: 16),
                  ],
                  _buildStats(context, game, state),
                  const SizedBox(height: 24),
                  GTSectionHeader(
                    title: l.gameDetailHistory(sessions.length),
                    trailing: sessions.isEmpty
                        ? null
                        : TextButton(
                            onPressed: () => _addSession(context, game),
                            child: Text(l.gameDetailAddSession),
                          ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          if (sessions.isEmpty)
            SliverToBoxAdapter(
              child: GTEmptyState(
                emoji: '🎮',
                title: l.emptyNoSession,
                subtitle: l.emptyNoSessionSub,
                action: ElevatedButton(
                  onPressed: () => _addSession(context, game),
                  child: Text(l.btnAddSession),
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                  16, 0, 16, 16 + MediaQuery.of(context).padding.bottom),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _SessionCard(
                      session: sessions[i],
                      game: game,
                    )
                        .animate(delay: testAwareDuration(Duration(milliseconds: i * 30)))
                        .fadeIn(duration: testAwareDuration(250.ms)),
                  ),
                  childCount: sessions.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addSession(context, game),
        icon: const Icon(Icons.add_rounded),
        label: Text(l.fabNewSession),
      ),
    );
  }

  Widget _buildStats(BuildContext context, Game game, AppState state) {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    if (game.sessions.isEmpty) {
      return const SizedBox.shrink();
    }
    final wins = game.winsByPlayer;

    return GTCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GTSectionHeader(title: l.leaderboardSection),
          const SizedBox(height: 16),
          if (wins.isEmpty)
            Text(l.noWinnerYet,
                style: TextStyle(color: c.textSecondary))
          else
            ..._buildLeaderboard(context, wins, game, state),
        ],
      ),
    );
  }

  List<Widget> _buildLeaderboard(BuildContext context,
      Map<String, int> wins, Game game, AppState state) {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final sorted = wins.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final records = game.recordsByPlayer;

    return sorted.asMap().entries.map((entry) {
      final rank = entry.key;
      final e = entry.value;
      final player = state.findPlayer(e.key);
      final name = player?.name ?? l.deletedPlayer;
      final color = rank == 0
          ? const Color(0xFFFFD700)
          : rank == 1
              ? const Color(0xFFC0C0C0)
              : rank == 2
                  ? const Color(0xFFCD7F32)
                  : c.textSecondary;

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                rank == 0
                    ? '🥇'
                    : rank == 1
                        ? '🥈'
                        : rank == 2
                            ? '🥉'
                            : '${rank + 1}.',
                style: TextStyle(fontSize: rank < 3 ? 20 : 14),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(name,
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: color)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  l.winCount(e.value),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary),
                ),
                if (game.mode == GameMode.points &&
                    records[e.key] != null)
                  Text(
                    l.recordLabel(records[e.key]!),
                    style: TextStyle(
                        fontSize: 11, color: c.textSecondary),
                  ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  void _addSession(BuildContext context, Game game) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => AddSessionScreen(game: game)),
    );
  }
}

// ── Session Card ──────────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  final GameSession session;
  final Game game;
  const _SessionCard({required this.session, required this.game});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final state = context.read<AppState>();

    String dateStr;
    try {
      // Use the device locale for date formatting so it naturally follows l10n.
      final fmt = DateFormat.yMMMd(Localizations.localeOf(context).toString())
          .add_Hm();
      dateStr = fmt.format(session.playedAt);
    } catch (_) {
      dateStr =
          '${session.playedAt.day}/${session.playedAt.month}/${session.playedAt.year}';
    }

    return GTCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(dateStr,
                  style:
                      TextStyle(fontSize: 12, color: c.textSecondary)),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.edit_outlined,
                    size: 18, color: c.textSecondary),
                onPressed: () => _editSession(context, game),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: l.tooltipEditSession,
              ),
              const SizedBox(width: 12),
              IconButton(
                key: const Key('btnDeleteSession'),
                icon: Icon(Icons.delete_outline_rounded,
                    size: 18, color: c.textSecondary),
                onPressed: () => _confirmDelete(context, state),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: l.tooltipDeleteSession,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._buildScores(context, c, state),
          if (session.notes != null && session.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(session.notes!,
                style: TextStyle(
                    fontSize: 12,
                    color: c.textSecondary,
                    fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildScores(
      BuildContext context, AppColors c, AppState state) {
    final l = AppLocalizations.of(context)!;
    final sorted = session.scores.entries.toList();
    if (session.mode == GameMode.points) {
      sorted.sort((a, b) => b.value.compareTo(a.value));
    } else if (session.mode == GameMode.ranking) {
      sorted.sort((a, b) => a.value.compareTo(b.value));
    }

    return sorted.map((e) {
      final player = state.findPlayer(e.key);
      final name = player?.name ?? l.deletedPlayer;
      final isWinner = session.winner == e.key;

      String scoreText;
      Color? scoreColor;

      switch (session.mode) {
        case GameMode.points:
          scoreText = '${e.value} ${l.pointsSuffix}';
          scoreColor = isWinner ? c.accent : null;
        case GameMode.ranking:
          scoreText = _ordinal(context, e.value);
          scoreColor = e.value == 1 ? const Color(0xFFFFD700) : null;
        case GameMode.duel:
          if (session.hasRounds) {
            // e.value here is a ROUND-WIN COUNT (0, 1, 2...), not a
            // DuelResult index — see game_session.dart's own doc comment
            // on GameSession.scores. Feeding it straight into
            // DuelResult.values[e.value] (as the non-rounds branch below
            // does) silently produces the wrong label for any count other
            // than exactly 0/1/2 — e.g. 2 rounds won renders as "Loss"
            // (DuelResult.values[2]), 1 round won renders as "Draw"
            // (DuelResult.values[1]). session.winner is unaffected (it's
            // computed separately in GameSession.winnerFor, which does
            // branch on hasRounds correctly), so this bug only broke the
            // per-player result label, not the actual winner/highlight.
            final roundsWon = e.value;
            scoreText =
                l.duelRoundsWonLabel(roundsWon, session.rounds.length);
            scoreColor = isWinner
                ? c.success
                : session.winner == null
                    ? c.warning // tied round-win count = draw overall
                    : c.error;
          } else {
            final result = DuelResult.values[e.value];
            scoreText = result == DuelResult.win
                ? l.duelWin
                : result == DuelResult.draw
                    ? l.duelDraw
                    : l.duelLoss;
            scoreColor = result == DuelResult.win
                ? c.success
                : result == DuelResult.loss
                    ? c.error
                    : c.warning;
          }
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            if (isWinner)
              const Text('👑 ', style: TextStyle(fontSize: 13))
            else
              const SizedBox(width: 20),
            Expanded(
              child: Text(name,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
            ),
            Text(
              scoreText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: scoreColor ?? c.textPrimary,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _ordinal(BuildContext context, int n) {
    final l = AppLocalizations.of(context)!;
    return n == 1 ? l.ordinal1st : l.ordinalNth(n);
  }

  void _editSession(BuildContext context, Game game) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddSessionScreen(game: game, existing: session),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, AppState state) async {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.surface,
        title: Text(l.deleteSessionTitle),
        content: Text(l.deleteSessionBody,
            style: TextStyle(color: c.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.btnCancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.btnDelete,
                style: TextStyle(color: c.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await state.deleteSession(game.id, session.id);
    }
  }
}
