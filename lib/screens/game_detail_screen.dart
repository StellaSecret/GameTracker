// lib/screens/game_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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
    final state = context.watch<AppState>();
    final game = state.findGame(gameId);
    if (game == null) return const SizedBox.shrink();

    final sessions =
        List<GameSession>.from(game.sessions)
          ..sort((a, b) => b.playedAt.compareTo(a.playedAt));

    return Scaffold(
      appBar: AppBar(
        title: Text(game.coverEmoji != null
            ? '${game.coverEmoji} ${game.name}'
            : game.name),
        actions: [
          IconButton(
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
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 14)),
                    const SizedBox(height: 16),
                  ],
                  _buildStats(context, game, state),
                  const SizedBox(height: 24),
                  GTSectionHeader(
                    title: 'HISTORIQUE (${sessions.length})',
                    trailing: sessions.isEmpty
                        ? null
                        : TextButton(
                            onPressed: () =>
                                _addSession(context, game),
                            child: const Text('+ Ajouter'),
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
                title: 'Aucune partie',
                subtitle: 'Enregistrez votre première partie !',
                action: ElevatedButton(
                  onPressed: () => _addSession(context, game),
                  child: const Text('Ajouter une partie'),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _SessionCard(
                      session: sessions[i],
                      game: game,
                    ).animate(delay: Duration(milliseconds: i * 30))
                        .fadeIn(duration: 250.ms),
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
        label: const Text('Nouvelle partie'),
      ),
    );
  }

  Widget _buildStats(BuildContext context, Game game, AppState state) {
    if (game.sessions.isEmpty) return const SizedBox.shrink();
    final wins = game.winsByPlayer;

    return GTCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GTSectionHeader(title: 'CLASSEMENT'),
          const SizedBox(height: 16),
          if (wins.isEmpty)
            const Text('Pas encore de vainqueur.',
                style: TextStyle(color: AppColors.textSecondary))
          else
            ..._buildLeaderboard(wins, game, state),
        ],
      ),
    );
  }

  List<Widget> _buildLeaderboard(
      Map<String, int> wins, Game game, AppState state) {
    final sorted =
        wins.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final records = game.recordsByPlayer;
    final totals = game.totalPointsByPlayer;

    return sorted.asMap().entries.map((entry) {
      final rank = entry.key;
      final e = entry.value;
      final player = state.findPlayer(e.key);
      final name = player?.name ?? 'Inconnu';
      final color = rank == 0
          ? const Color(0xFFFFD700)
          : rank == 1
              ? const Color(0xFFC0C0C0)
              : rank == 2
                  ? const Color(0xFFCD7F32)
                  : AppColors.textSecondary;

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
                    fontWeight: FontWeight.w600,
                    color: color,
                  )),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${e.value} victoire${e.value != 1 ? 's' : ''}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
                if (game.mode == GameMode.points && records[e.key] != null)
                  Text(
                    'Record: ${records[e.key]}pts',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
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
      MaterialPageRoute(builder: (_) => AddSessionScreen(game: game)),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final GameSession session;
  final Game game;

  const _SessionCard({required this.session, required this.game});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final fmt = DateFormat('d MMM y – HH:mm', 'fr_FR');

    return GTCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                fmt.format(session.playedAt),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: AppColors.textSecondary),
                onPressed: () =>
                    _confirmDelete(context, state),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._buildScores(state),
          if (session.notes != null && session.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(session.notes!,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildScores(AppState state) {
    final sorted = session.scores.entries.toList();
    if (session.mode == GameMode.points) {
      sorted.sort((a, b) => b.value.compareTo(a.value));
    } else if (session.mode == GameMode.ranking) {
      sorted.sort((a, b) => a.value.compareTo(b.value));
    }

    return sorted.map((e) {
      final player = state.findPlayer(e.key);
      final name = player?.name ?? 'Inconnu';
      final isWinner = session.winner == e.key;

      String scoreText;
      Color? scoreColor;

      switch (session.mode) {
        case GameMode.points:
          scoreText = '${e.value} pts';
          scoreColor = isWinner ? AppColors.accent : null;
          break;
        case GameMode.ranking:
          scoreText = _ordinal(e.value);
          scoreColor =
              e.value == 1 ? const Color(0xFFFFD700) : null;
          break;
        case GameMode.duel:
          final result = DuelResult.values[e.value];
          scoreText = result == DuelResult.win
              ? 'Victoire'
              : result == DuelResult.draw
                  ? 'Match nul'
                  : 'Défaite';
          scoreColor = result == DuelResult.win
              ? AppColors.success
              : result == DuelResult.loss
                  ? AppColors.error
                  : AppColors.warning;
          break;
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
                color: scoreColor ?? AppColors.textPrimary,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _ordinal(int n) {
    if (n == 1) return '1er';
    return '${n}ème';
  }

  Future<void> _confirmDelete(
      BuildContext context, AppState state) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Supprimer cette partie ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await state.deleteSession(game.id, session.id);
    }
  }
}
