import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/game_mode.dart';
import '../models/stats_engine.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/gt_card.dart';
import 'ad_unlock_sheet.dart';

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
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final state = context.watch<AppState>();
    final engine = StatsEngine(state.games);

    if (state.games.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l.statsScreenTitle)),
        body: GTEmptyState(
          emoji: '📊',
          title: l.emptyNoStats,
          subtitle: l.emptyNoStatsSub,
        ),
      );
    }

    if (!state.canUseAdvancedStats) {
      return Scaffold(
        appBar: AppBar(title: Text(l.statsScreenTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🔒', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text(l.paywallLockedTitle,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(l.paywallLockedSub,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.textSecondary)),
                const SizedBox(height: 24),
                ElevatedButton(
                  key: const Key('btnUnlockStatsWithAd'),
                  onPressed: () => AdUnlockSheet.show(context),
                  child: Text(l.unlockWithAd),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.statsScreenTitle),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: c.primary,
          labelColor: c.primary,
          unselectedLabelColor: c.textSecondary,
          tabs: [
            Tab(text: l.tabPlayers),
            Tab(text: l.tabGames),
            Tab(text: l.tabGlobal),
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

// ── Players tab ───────────────────────────────────────────────────────────────

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
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final players = widget.state.players;

    if (players.isEmpty) {
      return GTEmptyState(
        emoji: '👥',
        title: l.emptyNoPlayerStats,
        subtitle: l.emptyNoPlayerStatsSub,
      );
    }

    final stats = _selectedPlayerId != null
        ? widget.engine.computePlayerStats(_selectedPlayerId!)
        : null;
    // Non-null alias used inside `if (stats != null) ...[...]` spreads where
    // flow analysis cannot promote the nullable type automatically.
    final s = stats;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
                pColor =
                    Color(int.parse(p.color.replaceFirst('#', '0xFF')));
              } catch (_) {
                pColor = c.primary;
              }
              return GestureDetector(
                onTap: () => setState(() => _selectedPlayerId = p.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? pColor.withValues(alpha: 0.2)
                        : c.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: selected ? pColor : c.cardBorder,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    p.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selected ? pColor : c.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        if (s != null) ...[
          if (s.totalGames == 0)
            GTEmptyState(
              emoji: '🎮',
              title: l.emptyNoSessionStats,
              subtitle: l.emptyNoSessionStatsSub,
            )
          else ...[
            _SectionTitle(l.statSectionKeyMetrics),
            const SizedBox(height: 12),
            _KeyMetricsGrid(stats: s),
            const SizedBox(height: 20),

            if (s.bestScore != null) ...[
              _SectionTitle(l.statSectionScores),
              const SizedBox(height: 12),
              _ScoresCard(stats: s),
              const SizedBox(height: 20),
            ],

            _SectionTitle(l.statSectionStreaks),
            const SizedBox(height: 12),
            _StreaksCard(stats: s),
            const SizedBox(height: 20),

            if (s.favoriteGameId != null) ...[
              _SectionTitle(l.statSectionGames),
              const SizedBox(height: 12),
              _FavoriteGameCard(stats: s, state: widget.state),
              const SizedBox(height: 12),
              _WinRateByGameCard(stats: s, state: widget.state),
              const SizedBox(height: 20),
            ],

            if (s.nemesisId != null || s.rivalId != null) ...[
              const SizedBox(height: 12),
              Row(children: [
                if (s.nemesisId != null)
                  Expanded(
                      child: _NemesisCard(
                          stats: s, state: widget.state)),
                if (s.nemesisId != null && s.rivalId != null)
                  const SizedBox(width: 12),
                if (s.rivalId != null)
                  Expanded(
                      child:
                          _RivalCard(stats: s, state: widget.state)),
              ]),
            ],
          ],
        ],
        const SizedBox(height: 40),
      ],
    );
  }
}

// ── Games tab ─────────────────────────────────────────────────────────────────

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
    final games = widget.state.games
        .where((g) => g.sessions.isNotEmpty)
        .toList();
    if (games.isNotEmpty) {
      _selectedGameId = games.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final games = widget.state.games
        .where((g) => g.sessions.isNotEmpty)
        .toList();

    if (games.isEmpty) {
      return GTEmptyState(
        emoji: '🎲',
        title: l.emptyNoGameStats,
        subtitle: l.emptyNoGameStatsSub,
      );
    }

    final stats = _selectedGameId != null
        ? widget.engine.computeGameStats(_selectedGameId!)
        : null;
    final game = _selectedGameId != null
        ? widget.state.findGame(_selectedGameId!)
        : null;
    final gs = stats;
    final gm = game;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
                onTap: () =>
                    setState(() => _selectedGameId = g.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? c.primary.withValues(alpha: 0.2)
                        : c.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: selected ? c.primary : c.cardBorder,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    '${g.coverEmoji ?? g.mode.icon} ${g.name}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color:
                          selected ? c.primary : c.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        if (gs != null && gm != null) ...[
          if (gs.dominantPlayerId != null) ...[
            _SectionTitle(l.statSectionDominant),
            const SizedBox(height: 12),
            _DominantPlayerCard(
              stats: gs,
              state: widget.state,
              totalSessions: gm.sessions.length,
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 20),
          ],

          if (gs.tightestSession != null) ...[
            _SectionTitle(l.statSectionTightest),
            const SizedBox(height: 12),
            _TightestGameCard(stats: gs, state: widget.state)
                .animate()
                .fadeIn(duration: 300.ms),
            const SizedBox(height: 20),
          ],

          if (gs.scoreHistory.isNotEmpty) ...[
            _SectionTitle(l.statSectionScoreHistory),
            const SizedBox(height: 12),
            _ScoreHistoryCard(stats: gs, state: widget.state)
                .animate()
                .fadeIn(duration: 300.ms),
            const SizedBox(height: 20),
          ],

          _SectionTitle(l.statSectionSummary),
          const SizedBox(height: 12),
          GTCard(
            child: Column(
              children: [
                _StatRow(
                    l.statSummarySessionsPlayed,
                    '${gm.sessions.length}'),
                const _Divider(),
                _StatRow(
                  l.statSummaryUniquePlayers,
                  '${gm.sessions.expand((s) => s.scores.keys).toSet().length}',
                ),
                if (gm.mode == GameMode.points &&
                    gm.sessions.isNotEmpty) ...[
                  const _Divider(),
                  _StatRow(
                    l.statSummaryMaxScore,
                    l.statSummaryMaxScoreVal(gm.sessions
                        .expand((s) => s.scores.values)
                        .fold(0, (a, b) => a > b ? a : b)),
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

// ── Global tab ────────────────────────────────────────────────────────────────

class _GlobalTab extends StatelessWidget {
  final StatsEngine engine;
  final AppState state;
  const _GlobalTab({required this.engine, required this.state});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final stats = engine.computeGlobalStats();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle(l.statSectionOverview),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: _BigStatCard(
                  '🎲', '${stats.totalGames}', l.statGlobalGames)),
          const SizedBox(width: 12),
          Expanded(
              child: _BigStatCard(
                  '🎮', '${stats.totalSessions}', l.statGlobalSessions)),
          const SizedBox(width: 12),
          Expanded(
              child: _BigStatCard(
                  '👥', '${state.players.length}', l.statGlobalPlayers)),
        ]).animate().fadeIn(duration: 300.ms),
        const SizedBox(height: 20),

        if (stats.globalRanking.isNotEmpty) ...[
          _SectionTitle(l.statSectionGlobalRanking),
          const SizedBox(height: 12),
          _GlobalRankingCard(stats: stats, state: state)
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.05),
          const SizedBox(height: 20),
        ],

        if (stats.mostActivePlayerId != null) ...[
          _SectionTitle(l.statSectionMostActive),
          const SizedBox(height: 12),
          _MostActiveCard(stats: stats, state: state)
              .animate()
              .fadeIn(duration: 300.ms),
          const SizedBox(height: 20),
        ],

        if (stats.absoluteRecord != null) ...[
          _SectionTitle(l.statSectionAbsoluteRecord),
          const SizedBox(height: 12),
          _AbsoluteRecordCard(stats: stats, state: state)
              .animate()
              .fadeIn(duration: 300.ms),
          const SizedBox(height: 20),
        ],

        if (stats.globalNemesisA != null || stats.globalRivalA != null) ...[
          _SectionTitle(l.statSectionRivalries),
          const SizedBox(height: 12),
          if (stats.globalNemesisA != null)
            _GlobalNemesisCard(stats: stats, state: state)
                .animate()
                .fadeIn(duration: 300.ms),
          if (stats.globalNemesisA != null && stats.globalRivalA != null)
            const SizedBox(height: 12),
          if (stats.globalRivalA != null)
            _GlobalRivalCard(stats: stats, state: state)
                .animate()
                .fadeIn(duration: 300.ms),
        ],
        const SizedBox(height: 40),
      ],
    );
  }
}

// ── Shared components ─────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => GTSectionHeader(title: title);
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Divider(color: c.cardBorder, height: 20, thickness: 1);
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(color: c.textSecondary, fontSize: 14)),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 14)),
      ],
    );
  }
}

class _BigStatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  const _BigStatCard(this.emoji, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GTCard(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary)),
          Text(label,
              style: TextStyle(fontSize: 12, color: c.textSecondary)),
        ],
      ),
    );
  }
}

// ── Player stats cards ────────────────────────────────────────────────────────

class _KeyMetricsGrid extends StatelessWidget {
  final PlayerStats stats;
  const _KeyMetricsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final pct = (stats.winRate * 100).toStringAsFixed(0);
    return GTCard(
      child: Row(
        children: [
          Expanded(child: GTStatTile(
            label: l.statLabelSessions,
            value: '${stats.totalGames}',
            color: c.textPrimary,
          )),
          const SizedBox(width: 16),
          Expanded(child: GTStatTile(
            label: l.statLabelWins,
            value: '${stats.totalWins}',
            color: c.accent,
          )),
          const SizedBox(width: 16),
          Expanded(child: GTStatTile(
            label: l.statLabelRate,
            value: '$pct%',
            color: stats.winRate > 0.5
                ? c.success
                : stats.winRate > 0.3
                    ? c.warning
                    : c.error,
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
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    return GTCard(
      child: Row(
        children: [
          Expanded(child: GTStatTile(
            label: l.statLabelBest,
            value: '${stats.bestScore}',
            color: c.accent,
            subtitle: l.pointsSuffix,
          )),
          const SizedBox(width: 16),
          Expanded(child: GTStatTile(
            label: l.statLabelWorst,
            value: '${stats.worstScore}',
            color: c.error,
            subtitle: l.pointsSuffix,
          )),
          const SizedBox(width: 16),
          Expanded(child: GTStatTile(
            label: l.statLabelAvg,
            value: stats.avgScore?.toStringAsFixed(1) ?? '—',
            color: c.primary,
            subtitle: l.pointsSuffix,
          )),
        ],
      ),
    );
  }
}

class _StreaksCard extends StatelessWidget {
  final PlayerStats stats;
  const _StreaksCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    return GTCard(
      child: Row(
        children: [
          Expanded(child: GTStatTile(
            label: l.statLabelCurrentStreak,
            value: '${stats.currentStreak}',
            color: stats.currentStreak > 0 ? c.accent : c.textSecondary,
            subtitle: stats.currentStreak > 1
                ? l.statStreakOnFire
                : l.statLabelWins2,
          )),
          const SizedBox(width: 16),
          Expanded(child: GTStatTile(
            label: l.statLabelBestStreak,
            value: '${stats.bestStreak}',
            color: c.warning,
            subtitle: l.statLabelWins2,
          )),
        ],
      ),
    );
  }
}

class _FavoriteGameCard extends StatelessWidget {
  final PlayerStats stats;
  final AppState state;
  const _FavoriteGameCard({required this.stats, required this.state});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final game = stats.favoriteGameId != null
        ? state.findGame(stats.favoriteGameId!)
        : null;
    final sessions = stats.gamesByGame[stats.favoriteGameId] ?? 0;
    final rate = sessions > 0
        ? ((stats.winRateByGame[stats.favoriteGameId] ?? 0) * 100)
            .toStringAsFixed(0)
        : '0';

    return GTCard(
      borderColor: c.accent.withValues(alpha: 0.4),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                game?.coverEmoji ?? game?.mode.icon ?? '🎲',
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.statFavoriteGame,
                    style: TextStyle(
                        fontSize: 11,
                        color: c.textSecondary,
                        fontWeight: FontWeight.w600)),
                Text(stats.favoriteGameName ?? '—',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(l.statFavoriteWins(stats.favoriteGameWins ?? 0),
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: c.accent)),
              Text(l.statFavoriteRate(rate),
                  style:
                      TextStyle(fontSize: 12, color: c.textSecondary)),
            ],
          ),
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
    final c = AppColors.of(context);
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
                  Text(game?.name ?? '—',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('$wins/$total',
                      style: TextStyle(
                          fontSize: 12, color: c.textSecondary)),
                  const SizedBox(width: 8),
                  Text('${(rate * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: rate > 0.5
                              ? c.success
                              : rate > 0.3
                                  ? c.warning
                                  : c.error)),
                ]),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: rate,
                    minHeight: 6,
                    backgroundColor: c.cardBorder,
                    valueColor: AlwaysStoppedAnimation(rate > 0.5
                        ? c.success
                        : rate > 0.3
                            ? c.warning
                            : c.error),
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
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final nemesis = state.findPlayer(stats.nemesisId!);
    return GTCard(
      borderColor: c.error.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('💀', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(l.statNemesisLabel,
                style: TextStyle(
                    fontSize: 12,
                    color: c.error,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1)),
          ]),
          const SizedBox(height: 10),
          Text(nemesis?.name ?? '—',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800)),
          Text(
            l.statNemesisLosses(stats.nemesisLosses ?? 0),
            style: TextStyle(fontSize: 12, color: c.textSecondary),
          ),
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
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final rival = state.findPlayer(stats.rivalId!);
    return GTCard(
      borderColor: c.warning.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('⚔️', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(l.statRivalLabel,
                style: TextStyle(
                    fontSize: 12,
                    color: c.warning,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1)),
          ]),
          const SizedBox(height: 10),
          Text(rival?.name ?? '—',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800)),
          Text(
            l.statRivalGames(stats.rivalGames ?? 0),
            style: TextStyle(fontSize: 12, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Game stats cards ──────────────────────────────────────────────────────────

class _DominantPlayerCard extends StatelessWidget {
  final GameStats stats;
  final AppState state;
  final int totalSessions;
  const _DominantPlayerCard(
      {required this.stats,
      required this.state,
      required this.totalSessions});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final player = state.findPlayer(stats.dominantPlayerId!);
    Color pColor = c.primary;
    if (player != null) {
      try {
        pColor =
            Color(int.parse(player.color.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }
    final rate = totalSessions > 0
        ? ((stats.dominantWins ?? 0) / totalSessions * 100)
            .toStringAsFixed(0)
        : '0';

    return GTCard(
      borderColor: pColor.withValues(alpha: 0.3),
      child: Row(children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: pColor.withValues(alpha: 0.2),
          child: Text(
            player?.name.isNotEmpty == true
                ? player!.name[0].toUpperCase()
                : '?',
            style: TextStyle(
                color: pColor,
                fontWeight: FontWeight.w700,
                fontSize: 18),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(player?.name ?? '—',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              Text(l.statDominatesGame,
                  style: TextStyle(fontSize: 12, color: pColor)),
            ],
          ),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${stats.dominantWins}',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: pColor)),
          Text(l.statWinsPercent(rate),
              style: TextStyle(fontSize: 11, color: c.textSecondary)),
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
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final session = stats.tightestSession!;
    final sorted = session.scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return GTCard(
      borderColor: c.secondary.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🔥', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              l.statGap(stats.tightestGap ?? 0),
              style: TextStyle(
                  fontSize: 12,
                  color: c.secondary,
                  fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text(_formatDate(context, session.playedAt),
                style:
                    TextStyle(fontSize: 11, color: c.textSecondary)),
          ]),
          const SizedBox(height: 12),
          ...sorted.take(3).map((e) {
            final p = state.findPlayer(e.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Expanded(
                    child: Text(p?.name ?? '—',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500))),
                Text(l.statLastScore(e.value),
                    style: const TextStyle(
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
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final history = stats.scoreHistory;
    final allPoints = history.values.expand((p) => p).toList();
    if (allPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxVal =
        allPoints.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final minVal =
        allPoints.map((p) => p.value).reduce((a, b) => a < b ? a : b);

    return GTCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...history.entries.take(4).map((entry) {
            final player = state.findPlayer(entry.key);
            Color pColor = c.primary;
            if (player != null) {
              try {
                pColor = Color(
                    int.parse(player.color.replaceFirst('#', '0xFF')));
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
                    Text(player?.name ?? '—',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: pColor)),
                    const Spacer(),
                    if (points.isNotEmpty)
                      Text(
                        l.statLastScore(points.last.value),
                        style: TextStyle(
                            fontSize: 11, color: c.textSecondary),
                      ),
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
    required this.points,
    required this.color,
    required this.maxVal,
    required this.minVal,
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
      final y = size.height -
          (size.height * (points[i].value - minVal) / range);
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

    final lastX = size.width;
    final lastY = size.height -
        (size.height * (points.last.value - minVal) / range);
    canvas.drawCircle(Offset(lastX, lastY), 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Global stats cards ────────────────────────────────────────────────────────

class _GlobalRankingCard extends StatelessWidget {
  final GlobalStats stats;
  final AppState state;
  const _GlobalRankingCard({required this.stats, required this.state});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    const medals = ['🥇', '🥈', '🥉'];
    return GTCard(
      child: Column(
        children: stats.globalRanking
            .take(8)
            .toList()
            .asMap()
            .entries
            .map((entry) {
          final rank = entry.key;
          final e = entry.value;
          final player = state.findPlayer(e.key);
          Color pColor = c.textSecondary;
          if (player != null) {
            try {
              pColor = Color(
                  int.parse(player.color.replaceFirst('#', '0xFF')));
            } catch (_) {}
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              SizedBox(
                width: 30,
                child: Text(
                  rank < 3 ? medals[rank] : '${rank + 1}.',
                  style:
                      TextStyle(fontSize: rank < 3 ? 20 : 14),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 14,
                backgroundColor: pColor.withValues(alpha: 0.2),
                child: Text(
                  player?.name.isNotEmpty == true
                      ? player!.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                      color: pColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(player?.name ?? '—',
                      style: TextStyle(
                        fontWeight: rank == 0
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 15,
                        color: rank == 0
                            ? const Color(0xFFFFD700)
                            : c.textPrimary,
                      ))),
              Text(l.statGlobalRankingWins(e.value),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.textSecondary)),
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
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final player = state.findPlayer(stats.mostActivePlayerId!);
    Color pColor = c.primary;
    if (player != null) {
      try {
        pColor =
            Color(int.parse(player.color.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }
    return GTCard(
      borderColor: pColor.withValues(alpha: 0.3),
      child: Row(children: [
        const Text('🕹️', style: TextStyle(fontSize: 32)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(player?.name ?? '—',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),
              Text(
                l.statMostActiveSessions(stats.mostActiveSessions ?? 0),
                style:
                    TextStyle(fontSize: 13, color: c.textSecondary),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _AbsoluteRecordCard extends StatelessWidget {
  final GlobalStats stats;
  final AppState state;
  const _AbsoluteRecordCard(
      {required this.stats, required this.state});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final player = stats.absoluteRecordHolder != null
        ? state.findPlayer(stats.absoluteRecordHolder!)
        : null;
    return GTCard(
      borderColor: const Color(0xFFFFD700).withValues(alpha: 0.4),
      child: Row(children: [
        const Text('⭐', style: TextStyle(fontSize: 36)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${stats.absoluteRecord} pts',
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFFD700))),
              Text(player?.name ?? '—',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              Text(
                '${stats.absoluteRecordGame ?? ''}${stats.absoluteRecordDate != null ? ' · ${_formatDate(context, stats.absoluteRecordDate!)}' : ''}',
                style:
                    TextStyle(fontSize: 12, color: c.textSecondary),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _GlobalNemesisCard extends StatelessWidget {
  final GlobalStats stats;
  final AppState state;
  const _GlobalNemesisCard(
      {required this.stats, required this.state});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final playerA = state.findPlayer(stats.globalNemesisA!);
    final playerB = state.findPlayer(stats.globalNemesisB!);
    return GTCard(
      borderColor: c.error.withValues(alpha: 0.3),
      child: Row(children: [
        const Text('💀', style: TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.statGlobalNemesisSection,
                  style: TextStyle(
                      fontSize: 11,
                      color: c.error,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(
                l.statGlobalNemesisSentence(
                    playerA?.name ?? '—', playerB?.name ?? '—'),
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
              Text(
                l.statGlobalNemesisScore(stats.globalNemesisScore ?? 0),
                style:
                    TextStyle(fontSize: 12, color: c.textSecondary),
              ),
            ],
          ),
        ),
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
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final playerA = state.findPlayer(stats.globalRivalA!);
    final playerB = state.findPlayer(stats.globalRivalB!);
    return GTCard(
      borderColor: c.warning.withValues(alpha: 0.3),
      child: Row(children: [
        const Text('⚔️', style: TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.statGlobalRivalsSection,
                  style: TextStyle(
                      fontSize: 11,
                      color: c.warning,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(
                l.statGlobalRivalsSentence(
                    playerA?.name ?? '—', playerB?.name ?? '—'),
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
              Text(
                l.statGlobalRivalsGames(stats.globalRivalGames ?? 0),
                style:
                    TextStyle(fontSize: 12, color: c.textSecondary),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _formatDate(BuildContext context, DateTime d) {
  try {
    return DateFormat.yMMMd(
            Localizations.localeOf(context).toString())
        .format(d);
  } catch (_) {
    return '${d.day}/${d.month}/${d.year}';
  }
}
