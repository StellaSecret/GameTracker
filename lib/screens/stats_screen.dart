import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/game_mode.dart';
import '../models/stats_engine.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/gt_card.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final engine = StatsEngine(state.games);

    if (state.games.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('📊 Statistiques')),
        body: const GTEmptyState(
          emoji: '📊',
          title: 'Pas encore de stats',
          subtitle: 'Ajoutez des jeux et jouez des parties pour voir vos statistiques.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Statistiques'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Joueurs'),
            Tab(text: 'Jeux'),
            Tab(text: 'Global'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _PlayersTab(engine: engine, state: state),
          _GamesTab(engine: engine, state: state),
          _GlobalTab(engine: engine, state: state),
        ],
      ),
    );
  }
}

// ── Onglet Joueurs ────────────────────────────────────────────────────────

class _PlayersTab extends StatefulWidget {
  final StatsEngine engine;
  final AppState state;
  const _PlayersTab({required this.engine, required this.state});

  @override
  State<_PlayersTab> createState() => _PlayersTabState();
}

class _PlayersTabState extends State<_PlayersTab> {
  String? _selectedPlayerId;

  @override
  void initState() {
    super.initState();
    if (widget.state.players.isNotEmpty) {
      _selectedPlayerId = widget.state.players.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final players = widget.state.players;
    if (players.isEmpty) {
      return const GTEmptyState(
        emoji: '👥',
        title: 'Aucun joueur',
        subtitle: 'Créez des joueurs pour voir leurs statistiques.',
      );
    }

    final stats = _selectedPlayerId != null
        ? widget.engine.computePlayerStats(_selectedPlayerId!)
        : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Sélecteur de joueur
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: players.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final p = players[i];
              final selected = p.id == _selectedPlayerId;
              Color pColor;
              try {
                pColor = Color(int.parse(p.color.replaceFirst('#', '0xFF')));
              } catch (_) {
                pColor = AppColors.primary;
              }
              return GestureDetector(
                onTap: () => setState(() => _selectedPlayerId = p.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? pColor.withValues(alpha: 0.2) : AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: selected ? pColor : AppColors.cardBorder,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    p.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selected ? pColor : AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        if (stats != null) ...[
          if (stats.totalGames == 0)
            const GTEmptyState(
              emoji: '🎮',
              title: 'Aucune partie',
              subtitle: 'Ce joueur n\'a pas encore joué.',
            )
          else ...[
            // Chiffres clés
            const _SectionTitle('CHIFFRES CLÉS'),
            const SizedBox(height: 12),
            _KeyMetricsGrid(stats: stats),
            const SizedBox(height: 20),

            // Scores (mode points)
            if (stats.bestScore != null) ...[
              const _SectionTitle('SCORES'),
              const SizedBox(height: 12),
              _ScoresCard(stats: stats),
              const SizedBox(height: 20),
            ],

            // Séries
            const _SectionTitle('SÉRIES DE VICTOIRES'),
            const SizedBox(height: 12),
            _StreaksCard(stats: stats),
            const SizedBox(height: 20),

            // Jeu favori + taux par jeu
            if (stats.favoriteGameId != null) ...[
              const _SectionTitle('JEUX'),
              const SizedBox(height: 12),
              _FavoriteGameCard(stats: stats, state: widget.state),
              const SizedBox(height: 12),
              _WinRateByGameCard(stats: stats, state: widget.state),
              const SizedBox(height: 20),
            ],

            // Nemesis / Rival
            if (stats.nemesisId != null || stats.rivalId != null) ...[
              const _SectionTitle('RELATIONS'),
              const SizedBox(height: 12),
              Row(children: [
                if (stats.nemesisId != null)
                  Expanded(child: _NemesisCard(stats: stats, state: widget.state)),
                if (stats.nemesisId != null && stats.rivalId != null)
                  const SizedBox(width: 12),
                if (stats.rivalId != null)
                  Expanded(child: _RivalCard(stats: stats, state: widget.state)),
              ]),
            ],
          ],
        ],
        const SizedBox(height: 40),
      ],
    );
  }
}

// ── Onglet Jeux ───────────────────────────────────────────────────────────

class _GamesTab extends StatefulWidget {
  final StatsEngine engine;
  final AppState state;
  const _GamesTab({required this.engine, required this.state});

  @override
  State<_GamesTab> createState() => _GamesTabState();
}

class _GamesTabState extends State<_GamesTab> {
  String? _selectedGameId;

  @override
  void initState() {
    super.initState();
    final games = widget.state.games.where((g) => g.sessions.isNotEmpty).toList();
    if (games.isNotEmpty) {
      _selectedGameId = games.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final games = widget.state.games.where((g) => g.sessions.isNotEmpty).toList();
    if (games.isEmpty) {
      return const GTEmptyState(
        emoji: '🎲',
        title: 'Aucune partie jouée',
        subtitle: 'Jouez des parties pour voir les stats par jeu.',
      );
    }

    final stats = _selectedGameId != null
        ? widget.engine.computeGameStats(_selectedGameId!)
        : null;
    final game = _selectedGameId != null
        ? widget.state.findGame(_selectedGameId!)
        : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Sélecteur de jeu
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: games.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final g = games[i];
              final selected = g.id == _selectedGameId;
              return GestureDetector(
                onTap: () => setState(() => _selectedGameId = g.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.cardBorder,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    '${g.coverEmoji ?? g.mode.icon} ${g.name}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.primary : AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        if (stats != null && game != null) ...[
          // Joueur dominant
          if (stats.dominantPlayerId != null) ...[
            const _SectionTitle('JOUEUR DOMINANT'),
            const SizedBox(height: 12),
            _DominantPlayerCard(
              stats: stats,
              state: widget.state,
              totalSessions: game.sessions.length,
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 20),
          ],

          // Partie la plus serrée
          if (stats.tightestSession != null) ...[
            const _SectionTitle('PARTIE LA PLUS SERRÉE'),
            const SizedBox(height: 12),
            _TightestGameCard(
              stats: stats,
              state: widget.state,
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 20),
          ],

          // Évolution des scores
          if (stats.scoreHistory.isNotEmpty) ...[
            const _SectionTitle('ÉVOLUTION DES SCORES'),
            const SizedBox(height: 12),
            _ScoreHistoryCard(
              stats: stats,
              state: widget.state,
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 20),
          ],

          // Stats rapides
          const _SectionTitle('RÉSUMÉ'),
          const SizedBox(height: 12),
          GTCard(
            child: Column(
              children: [
                _StatRow('Parties jouées', '${game.sessions.length}'),
                const _Divider(),
                _StatRow(
                  'Joueurs uniques',
                  '${game.sessions.expand((s) => s.scores.keys).toSet().length}',
                ),
                if (game.mode == GameMode.points && game.sessions.isNotEmpty) ...[
                  const _Divider(),
                  _StatRow(
                    'Score max all-time',
                    '${game.sessions.expand((s) => s.scores.values).fold(0, (a, b) => a > b ? a : b)} pts',
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),
        ],
        const SizedBox(height: 40),
      ],
    );
  }
}

// ── Onglet Global ─────────────────────────────────────────────────────────

class _GlobalTab extends StatelessWidget {
  final StatsEngine engine;
  final AppState state;
  const _GlobalTab({required this.engine, required this.state});

  @override
  Widget build(BuildContext context) {
    final stats = engine.computeGlobalStats();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Chiffres clés
        _SectionTitle('VUE D\'ENSEMBLE'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _BigStatCard('🎲', '${stats.totalGames}', 'Jeux')),
          const SizedBox(width: 12),
          Expanded(child: _BigStatCard('🎮', '${stats.totalSessions}', 'Parties')),
          const SizedBox(width: 12),
          Expanded(child: _BigStatCard('👥', '${state.players.length}', 'Joueurs')),
        ]).animate().fadeIn(duration: 300.ms),
        const SizedBox(height: 20),

        // Classement général
        if (stats.globalRanking.isNotEmpty) ...[
          const _SectionTitle('CLASSEMENT GÉNÉRAL'),
          const SizedBox(height: 12),
          _GlobalRankingCard(stats: stats, state: state)
              .animate().fadeIn(duration: 300.ms).slideY(begin: 0.05),
          const SizedBox(height: 20),
        ],

        // Joueur le plus actif
        if (stats.mostActivePlayerId != null) ...[
          const _SectionTitle('LE PLUS ACTIF'),
          const SizedBox(height: 12),
          _MostActiveCard(stats: stats, state: state)
              .animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 20),
        ],

        // Records absolus
        if (stats.absoluteRecord != null) ...[
          const _SectionTitle('RECORD ABSOLU'),
          const SizedBox(height: 12),
          _AbsoluteRecordCard(stats: stats, state: state)
              .animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 20),
        ],

        // Nemesis & Rival global
        if (stats.globalNemesisA != null || stats.globalRivalA != null) ...[
          const _SectionTitle('RIVALITÉS'),
          const SizedBox(height: 12),
          if (stats.globalNemesisA != null)
            _GlobalNemesisCard(stats: stats, state: state)
                .animate().fadeIn(duration: 300.ms),
          if (stats.globalNemesisA != null && stats.globalRivalA != null)
            const SizedBox(height: 12),
          if (stats.globalRivalA != null)
            _GlobalRivalCard(stats: stats, state: state)
                .animate().fadeIn(duration: 300.ms),
        ],
        const SizedBox(height: 40),
      ],
    );
  }
}

// ── Composants réutilisables ──────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => GTSectionHeader(title: title);
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Divider(
    color: AppColors.cardBorder, height: 20, thickness: 1,
  );
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
    ],
  );
}

class _BigStatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  const _BigStatCard(this.emoji, this.value, this.label);

  @override
  Widget build(BuildContext context) => GTCard(
    child: Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(
          fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        Text(label, style: const TextStyle(
          fontSize: 12, color: AppColors.textSecondary)),
      ],
    ),
  );
}

// ── Stats joueur ──────────────────────────────────────────────────────────

class _KeyMetricsGrid extends StatelessWidget {
  final PlayerStats stats;
  const _KeyMetricsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final pct = (stats.winRate * 100).toStringAsFixed(0);
    return GTCard(
      child: Row(
        children: [
          Expanded(child: GTStatTile(
            label: 'PARTIES',
            value: '${stats.totalGames}',
            color: AppColors.textPrimary,
          )),
          const SizedBox(width: 16),
          Expanded(child: GTStatTile(
            label: 'VICTOIRES',
            value: '${stats.totalWins}',
            color: AppColors.accent,
          )),
          const SizedBox(width: 16),
          Expanded(child: GTStatTile(
            label: 'TAUX',
            value: '$pct%',
            color: stats.winRate > 0.5
                ? AppColors.success
                : stats.winRate > 0.3
                    ? AppColors.warning
                    : AppColors.error,
          )),
        ],
      ),
    );
  }
}

class _ScoresCard extends StatelessWidget {
  final PlayerStats stats;
  const _ScoresCard({required this.stats});

  @override
  Widget build(BuildContext context) => GTCard(
    child: Row(
      children: [
        Expanded(child: GTStatTile(
          label: 'MEILLEUR',
          value: '${stats.bestScore}',
          color: AppColors.accent,
          subtitle: 'pts',
        )),
        const SizedBox(width: 16),
        Expanded(child: GTStatTile(
          label: 'PIRE',
          value: '${stats.worstScore}',
          color: AppColors.error,
          subtitle: 'pts',
        )),
        const SizedBox(width: 16),
        Expanded(child: GTStatTile(
          label: 'MOYENNE',
          value: stats.avgScore?.toStringAsFixed(1) ?? '—',
          color: AppColors.primary,
          subtitle: 'pts',
        )),
      ],
    ),
  );
}

class _StreaksCard extends StatelessWidget {
  final PlayerStats stats;
  const _StreaksCard({required this.stats});

  @override
  Widget build(BuildContext context) => GTCard(
    child: Row(
      children: [
        Expanded(child: GTStatTile(
          label: 'SÉRIE EN COURS',
          value: '${stats.currentStreak}',
          color: stats.currentStreak > 0 ? AppColors.accent : AppColors.textSecondary,
          subtitle: stats.currentStreak > 1 ? '🔥 en feu !' : 'victoires',
        )),
        const SizedBox(width: 16),
        Expanded(child: GTStatTile(
          label: 'MEILLEURE SÉRIE',
          value: '${stats.bestStreak}',
          color: AppColors.warning,
          subtitle: 'victoires',
        )),
      ],
    ),
  );
}

class _FavoriteGameCard extends StatelessWidget {
  final PlayerStats stats;
  final AppState state;
  const _FavoriteGameCard({required this.stats, required this.state});

  @override
  Widget build(BuildContext context) {
    final game = stats.favoriteGameId != null
        ? state.findGame(stats.favoriteGameId!)
        : null;
    final sessions = stats.gamesByGame[stats.favoriteGameId] ?? 0;
    final rate = sessions > 0
        ? ((stats.winRateByGame[stats.favoriteGameId] ?? 0) * 100).toStringAsFixed(0)
        : '0';

    return GTCard(
      borderColor: AppColors.accent.withValues(alpha: 0.4),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(
              game?.coverEmoji ?? game?.mode.icon ?? '🎲',
              style: const TextStyle(fontSize: 24),
            )),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🏠 Jeu favori', style: TextStyle(
                fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              Text(stats.favoriteGameName ?? '—', style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          )),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${stats.favoriteGameWins} victoires', style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent)),
            Text('$rate% de réussite', style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ],
      ),
    );
  }
}

class _WinRateByGameCard extends StatelessWidget {
  final PlayerStats stats;
  final AppState state;
  const _WinRateByGameCard({required this.stats, required this.state});

  @override
  Widget build(BuildContext context) {
    final entries = stats.winRateByGame.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return GTCard(
      child: Column(
        children: entries.map((e) {
          final game = state.findGame(e.key);
          final rate = e.value;
          final wins = stats.winsByGame[e.key] ?? 0;
          final total = stats.gamesByGame[e.key] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(game?.name ?? '—', style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('$wins/$total', style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(width: 8),
                  Text('${(rate * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: rate > 0.5 ? AppColors.success
                          : rate > 0.3 ? AppColors.warning
                          : AppColors.error)),
                ]),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: rate,
                    minHeight: 6,
                    backgroundColor: AppColors.cardBorder,
                    valueColor: AlwaysStoppedAnimation(
                      rate > 0.5 ? AppColors.success
                          : rate > 0.3 ? AppColors.warning
                          : AppColors.error),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NemesisCard extends StatelessWidget {
  final PlayerStats stats;
  final AppState state;
  const _NemesisCard({required this.stats, required this.state});

  @override
  Widget build(BuildContext context) {
    final nemesis = state.findPlayer(stats.nemesisId!);
    return GTCard(
      borderColor: AppColors.error.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Text('💀', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text('Nemesis', style: TextStyle(
              fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w700,
              letterSpacing: 1)),
          ]),
          const SizedBox(height: 10),
          Text(nemesis?.name ?? '—', style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w800)),
          Text('${stats.nemesisLosses} défaite${(stats.nemesisLosses ?? 0) > 1 ? 's' : ''} contre lui',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _RivalCard extends StatelessWidget {
  final PlayerStats stats;
  final AppState state;
  const _RivalCard({required this.stats, required this.state});

  @override
  Widget build(BuildContext context) {
    final rival = state.findPlayer(stats.rivalId!);
    return GTCard(
      borderColor: AppColors.warning.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Text('⚔️', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text('Rival', style: TextStyle(
              fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w700,
              letterSpacing: 1)),
          ]),
          const SizedBox(height: 10),
          Text(rival?.name ?? '—', style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w800)),
          Text('${stats.rivalGames} parties ensemble',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ── Stats jeu ─────────────────────────────────────────────────────────────

class _DominantPlayerCard extends StatelessWidget {
  final GameStats stats;
  final AppState state;
  final int totalSessions;
  const _DominantPlayerCard({
    required this.stats, required this.state, required this.totalSessions});

  @override
  Widget build(BuildContext context) {
    final player = state.findPlayer(stats.dominantPlayerId!);
    Color pColor = AppColors.primary;
    if (player != null) {
      try {
        pColor = Color(int.parse(player.color.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }
    final rate = totalSessions > 0
        ? ((stats.dominantWins ?? 0) / totalSessions * 100).toStringAsFixed(0)
        : '0';

    return GTCard(
      borderColor: pColor.withValues(alpha: 0.3),
      child: Row(children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: pColor.withValues(alpha: 0.2),
          child: Text(
            player?.name.isNotEmpty == true ? player!.name[0].toUpperCase() : '?',
            style: TextStyle(color: pColor, fontWeight: FontWeight.w700, fontSize: 18),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(player?.name ?? '—', style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800)),
            Text('Domine ce jeu', style: TextStyle(
              fontSize: 12, color: pColor)),
          ],
        )),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${stats.dominantWins}', style: TextStyle(
            fontSize: 28, fontWeight: FontWeight.w800, color: pColor)),
          Text('victoires ($rate%)', style: const TextStyle(
            fontSize: 11, color: AppColors.textSecondary)),
        ]),
      ]),
    );
  }
}

class _TightestGameCard extends StatelessWidget {
  final GameStats stats;
  final AppState state;
  const _TightestGameCard({required this.stats, required this.state});

  @override
  Widget build(BuildContext context) {
    final session = stats.tightestSession!;
    final sorted = session.scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return GTCard(
      borderColor: AppColors.secondary.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🔥', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text('Écart : ${stats.tightestGap} point${(stats.tightestGap ?? 0) > 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 12, color: AppColors.secondary,
                fontWeight: FontWeight.w700)),
            const Spacer(),
            Text(_formatDate(session.playedAt),
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ]),
          const SizedBox(height: 12),
          ...sorted.take(3).map((e) {
            final p = state.findPlayer(e.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Expanded(child: Text(p?.name ?? '—', style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500))),
                Text('${e.value} pts', style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700)),
              ]),
            );
          }),
        ],
      ),
    );
  }
}

class _ScoreHistoryCard extends StatelessWidget {
  final GameStats stats;
  final AppState state;
  const _ScoreHistoryCard({required this.stats, required this.state});

  @override
  Widget build(BuildContext context) {
    final history = stats.scoreHistory;
    final allPoints = history.values.expand((p) => p).toList();
    if (allPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxVal = allPoints.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final minVal = allPoints.map((p) => p.value).reduce((a, b) => a < b ? a : b);

    return GTCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...history.entries.take(4).map((entry) {
            final player = state.findPlayer(entry.key);
            Color pColor = AppColors.primary;
            if (player != null) {
              try {
                pColor = Color(int.parse(player.color.replaceFirst('#', '0xFF')));
              } catch (_) {}
            }
            final points = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    CircleAvatar(radius: 8, backgroundColor: pColor),
                    const SizedBox(width: 8),
                    Text(player?.name ?? '—', style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: pColor)),
                    const Spacer(),
                    if (points.isNotEmpty)
                      Text('${points.last.value} pts (dernier)',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ]),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: CustomPaint(
                      size: const Size(double.infinity, 40),
                      painter: _SparklinePainter(
                        points: points,
                        color: pColor,
                        maxVal: maxVal.toDouble(),
                        minVal: minVal.toDouble(),
                      ),
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

class _SparklinePainter extends CustomPainter {
  final List<ScorePoint> points;
  final Color color;
  final double maxVal;
  final double minVal;

  const _SparklinePainter({
    required this.points, required this.color,
    required this.maxVal, required this.minVal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) {
      return;
    }
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final range = (maxVal - minVal).clamp(1.0, double.infinity);
    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < points.length; i++) {
      final x = size.width * i / (points.length - 1);
      final y = size.height - (size.height * (points[i].value - minVal) / range);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Dernier point en surbrillance
    final lastX = size.width;
    final lastY = size.height -
        (size.height * (points.last.value - minVal) / range);
    canvas.drawCircle(Offset(lastX, lastY), 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Stats globales ────────────────────────────────────────────────────────

class _GlobalRankingCard extends StatelessWidget {
  final GlobalStats stats;
  final AppState state;
  const _GlobalRankingCard({required this.stats, required this.state});

  @override
  Widget build(BuildContext context) {
    final medals = ['🥇', '🥈', '🥉'];
    return GTCard(
      child: Column(
        children: stats.globalRanking.take(8).toList().asMap().entries.map((entry) {
          final rank = entry.key;
          final e = entry.value;
          final player = state.findPlayer(e.key);
          Color pColor = AppColors.textSecondary;
          if (player != null) {
            try {
              pColor = Color(int.parse(player.color.replaceFirst('#', '0xFF')));
            } catch (_) {}
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              SizedBox(width: 30, child: Text(
                rank < 3 ? medals[rank] : '${rank + 1}.',
                style: TextStyle(fontSize: rank < 3 ? 20 : 14),
              )),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 14,
                backgroundColor: pColor.withValues(alpha: 0.2),
                child: Text(
                  player?.name.isNotEmpty == true ? player!.name[0].toUpperCase() : '?',
                  style: TextStyle(color: pColor, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(player?.name ?? '—', style: TextStyle(
                fontWeight: rank == 0 ? FontWeight.w700 : FontWeight.w500,
                fontSize: 15,
                color: rank == 0 ? const Color(0xFFFFD700) : AppColors.textPrimary,
              ))),
              Text('${e.value} victoire${e.value > 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

class _MostActiveCard extends StatelessWidget {
  final GlobalStats stats;
  final AppState state;
  const _MostActiveCard({required this.stats, required this.state});

  @override
  Widget build(BuildContext context) {
    final player = state.findPlayer(stats.mostActivePlayerId!);
    Color pColor = AppColors.primary;
    if (player != null) {
      try {
        pColor = Color(int.parse(player.color.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }
    return GTCard(
      borderColor: pColor.withValues(alpha: 0.3),
      child: Row(children: [
        const Text('🕹️', style: TextStyle(fontSize: 32)),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(player?.name ?? '—', style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800)),
            Text('${stats.mostActiveSessions} parties jouées',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        )),
      ]),
    );
  }
}

class _AbsoluteRecordCard extends StatelessWidget {
  final GlobalStats stats;
  final AppState state;
  const _AbsoluteRecordCard({required this.stats, required this.state});

  @override
  Widget build(BuildContext context) {
    final player = stats.absoluteRecordHolder != null
        ? state.findPlayer(stats.absoluteRecordHolder!)
        : null;
    return GTCard(
      borderColor: const Color(0xFFFFD700).withValues(alpha: 0.4),
      child: Row(children: [
        const Text('⭐', style: TextStyle(fontSize: 36)),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${stats.absoluteRecord} pts',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                color: Color(0xFFFFD700))),
            Text(player?.name ?? '—', style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600)),
            Text('${stats.absoluteRecordGame ?? ''}${stats.absoluteRecordDate != null ? ' · ${_formatDate(stats.absoluteRecordDate!)}' : ''}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        )),
      ]),
    );
  }
}

class _GlobalNemesisCard extends StatelessWidget {
  final GlobalStats stats;
  final AppState state;
  const _GlobalNemesisCard({required this.stats, required this.state});

  @override
  Widget build(BuildContext context) {
    final playerA = state.findPlayer(stats.globalNemesisA!);
    final playerB = state.findPlayer(stats.globalNemesisB!);
    return GTCard(
      borderColor: AppColors.error.withValues(alpha: 0.3),
      child: Row(children: [
        const Text('💀', style: TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('NEMESIS', style: TextStyle(
              fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w700,
              letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(
              '${playerA?.name ?? '—'} domine ${playerB?.name ?? '—'}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            Text('${stats.globalNemesisScore} victoires d\'affilée',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        )),
      ]),
    );
  }
}

class _GlobalRivalCard extends StatelessWidget {
  final GlobalStats stats;
  final AppState state;
  const _GlobalRivalCard({required this.stats, required this.state});

  @override
  Widget build(BuildContext context) {
    final playerA = state.findPlayer(stats.globalRivalA!);
    final playerB = state.findPlayer(stats.globalRivalB!);
    return GTCard(
      borderColor: AppColors.warning.withValues(alpha: 0.3),
      child: Row(children: [
        const Text('⚔️', style: TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('RIVAUX', style: TextStyle(
              fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w700,
              letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(
              '${playerA?.name ?? '—'} vs ${playerB?.name ?? '—'}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            Text('${stats.globalRivalGames} parties ensemble',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        )),
      ]),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────

String _formatDate(DateTime d) {
  final months = ['jan', 'fév', 'mar', 'avr', 'mai', 'juin',
      'juil', 'août', 'sep', 'oct', 'nov', 'déc'];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}
