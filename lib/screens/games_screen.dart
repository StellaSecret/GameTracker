import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;
import '../config/test_flags.dart';
import '../l10n/app_localizations.dart';
import '../models/game.dart';
import '../models/game_mode.dart';
import '../models/game_mode_l10n.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/gsi_button.dart';
import '../widgets/gt_card.dart';
import 'add_game_screen.dart';
import 'game_detail_screen.dart';
import 'group_screen.dart';
import 'paywall_screen.dart';
import 'stats_screen.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final state = context.watch<AppState>();
    final games = state.games
        .where((g) => g.name.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded),
            tooltip: 'Retour à l\'accueil',
            onPressed: () => _goToLandingPage(),
          ),
          if (state.isInGroup)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(Icons.wifi_tethering_rounded,
                  color: c.primary, size: 20),
            ),
          IconButton(
            key: const Key('navStats'),
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: l.navTooltipStats,
            onPressed: () {
              // Always navigate to StatsScreen — it decides for itself
              // whether to show the real stats or its own locked/paywall
              // view (with the "watch an ad to unlock" entry point).
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              );
            },
          ),
          IconButton(
            key: const Key('navGroups'),
            icon: const Icon(Icons.group_rounded),
            tooltip: l.navTooltipGroups,
            onPressed: () => _openGroups(context, state),
          ),
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: l.navTooltipDrive,
            onPressed: () => _showSyncSheet(context),
          ),
          IconButton(
            key: const Key('navPlayers'),
            icon: const Icon(Icons.people_alt_rounded),
            tooltip: l.navTooltipPlayers,
            onPressed: () => Navigator.pushNamed(context, '/players'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: l.searchHint,
                prefixIcon: Icon(Icons.search_rounded, color: c.textSecondary),
                isDense: true,
              ),
            ),
          ),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (state.syncMessage != null)
                  _SyncBanner(message: state.syncMessage!),
                if (!state.entitlement.isPremium)
                  _FreeBanner(state: state),
                Expanded(
                  child: games.isEmpty
                      ? GTEmptyState(
                          emoji: _search.isEmpty ? '🎲' : '🔍',
                          title: _search.isEmpty
                              ? l.emptyNoGame
                              : l.emptyNoResult,
                          subtitle: _search.isEmpty
                              ? l.emptyNoGameSub
                              : l.emptyNoResultSub,
                        )
                      : _buildGamesList(games, state),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('fabAddGame'),
        onPressed: () => _addGame(context, state),
        icon: const Icon(Icons.add_rounded),
        label: Text(l.fabNewGame),
      ),
    );
  }

  void _addGame(BuildContext context, AppState state) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddGameScreen()),
    );
  }

  void _openGroups(BuildContext context, AppState state) {
    if (!state.entitlement.canUseGroupSync) {
      final l = AppLocalizations.of(context)!;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaywallScreen.groupSync(
            reason: l.groupsEmptySub,
          ),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GroupScreen()),
    );
  }

  Widget _buildGamesList(List<Game> games, AppState state) {
    final Map<String, List<Game>> grouped = {};
    for (final game in games) {
      final letter = game.name[0].toUpperCase();
      grouped.putIfAbsent(letter, () => []).add(game);
    }
    final letters = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
          16, 8, 16, 16 + MediaQuery.of(context).padding.bottom),
      itemCount: letters.length,
      itemBuilder: (context, idx) {
        final c = AppColors.of(context);
        final letter = letters[idx];
        final letterGames = grouped[letter]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: c.primary,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            ...letterGames.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _GameCard(game: entry.value)
                    .animate(delay: testAwareDuration(Duration(milliseconds: entry.key * 40)))
                    .fadeIn(duration: testAwareDuration(300.ms))
                    .slideX(begin: 0.05, curve: Curves.easeOut),
              );
            }),
          ],
        );
      },
    );
  }

  void _showSyncSheet(BuildContext context) {
    final c = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _SyncSheet(),
    );
  }

  void _goToLandingPage() {
    if (kIsWeb) {
      // Navigate to the root URL (landing page)
      // Since the app is hosted at /GameTracker/app.html,
      // the landing page is at /GameTracker/
      html.window.location.href = '/GameTracker/';
    }
  }
}

// ── Free plan banner ──────────────────────────────────────────────────────────

class _FreeBanner extends StatelessWidget {
  final AppState state;
  const _FreeBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    if (state.entitlement.isPremium) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaywallScreen.premium()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: c.primary.withValues(alpha: 0.08),
        child: Row(
          children: [
            Icon(Icons.star_border_rounded, color: c.primary, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l.freeBannerCta,
                style: TextStyle(fontSize: 12, color: c.primary),
              ),
            ),
            Text(l.freeBannerPremium,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c.primary)),
          ],
        ),
      ),
    );
  }
}

// ── Sync message banner ───────────────────────────────────────────────────────

class _SyncBanner extends StatelessWidget {
  final String message;
  const _SyncBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: c.surfaceElevated,
      child: Text(message,
          style: TextStyle(fontSize: 12, color: c.textSecondary)),
    );
  }
}

// ── Game card ─────────────────────────────────────────────────────────────────

class _GameCard extends StatelessWidget {
  final Game game;
  const _GameCard({required this.game});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final sessionCount = game.sessions.length;
    final modeColor = _modeColor(game.mode, c);

    return GTCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => GameDetailScreen(gameId: game.id)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: modeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: modeColor.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                game.coverEmoji ?? game.mode.icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    GTBadge(
                      label: game.mode.label(l),
                      color: modeColor,
                      emoji: game.mode.icon,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l.sessionCount(sessionCount),
                      style: TextStyle(fontSize: 12, color: c.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: c.textSecondary),
        ],
      ),
    );
  }

  Color _modeColor(GameMode mode, AppColors c) {
    switch (mode) {
      case GameMode.points:
        return c.primary;
      case GameMode.duel:
        return c.secondary;
      case GameMode.ranking:
        return c.accent;
    }
  }
}

// ── Drive sync sheet ──────────────────────────────────────────────────────────

class _SyncSheet extends StatefulWidget {
  const _SyncSheet();

  @override
  State<_SyncSheet> createState() => _SyncSheetState();
}

class _SyncSheetState extends State<_SyncSheet> {
  bool _loading = false;
  String? _msg;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final state = context.watch<AppState>();
    final isSignedIn = state.driveService.isSignedIn;
    final user = state.driveService.currentUser;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('☁️', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(l.driveSheetTitle,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              const Spacer(),
              if (isSignedIn)
                GTBadge(label: l.driveConnected, color: c.success, emoji: '✓'),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l.driveSheetSubtitle,
            style: TextStyle(fontSize: 12, color: c.textSecondary),
          ),
          const SizedBox(height: 16),
          if (!isSignedIn) ...[
            GSIButton(
              onPressed: _loading ? () {} : () => _signIn(state),
              label: l.driveSignIn,
              isLoading: _loading,
            ),
            if (kIsWeb) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.driveWebWarning,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.driveAdBlockerTip,
                      style: TextStyle(color: c.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ] else ...[
            Text(user?.email ?? '',
                style: TextStyle(color: c.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : () => _upload(state),
                    icon: const Icon(Icons.cloud_upload_rounded),
                    label: Text(l.driveBackup),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.primary,
                      side: BorderSide(color: c.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : () => _download(state),
                    icon: const Icon(Icons.cloud_download_rounded),
                    label: Text(l.driveRestore),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.accent,
                      side: BorderSide(color: c.accent),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                final nav = Navigator.of(context);
                await state.driveService.signOut();
                if (mounted) {
                  nav.pop();
                }
              },
              icon: const Icon(Icons.logout_rounded),
              label: Text(l.driveSignOut),
              style: TextButton.styleFrom(foregroundColor: c.error),
            ),
          ],
          if (_msg != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  if (_loading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(Icons.info_rounded, color: c.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(_msg!,
                          style: const TextStyle(fontSize: 13))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _signIn(AppState state) async {
    final l = AppLocalizations.of(context)!;
    setState(() {
      _loading = true;
      _msg = l.driveConnecting;
    });
    final ok = await state.driveService.signIn();
    if (ok) {
      final driveEmail = state.driveService.currentUser?.email;
      if (driveEmail != null) {
        state.purchaseService.setConnectedEmail(driveEmail);
      }
      if (!kIsWeb) {
        await state.groupService.signInSilently();
        final fbEmail = state.groupService.userEmail;
        if (fbEmail != null) {
          state.purchaseService.setConnectedEmail(fbEmail);
        }
      }
    }
    if (!mounted) {
      return;
    }
    final l2 = AppLocalizations.of(context)!;
    setState(() {
      _loading = false;
      _msg = ok ? null : l2.driveCancelled;
    });
  }

  Future<void> _upload(AppState state) async {
    final l = AppLocalizations.of(context)!;
    final hasData = state.games.isNotEmpty || state.players.isNotEmpty;
    if (!hasData) {
      setState(() => _msg = l.driveNoData);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => _DriveUploadDialog(
          gamesCount: state.games.length,
          playersCount: state.players.length),
    );
    if (confirm != true) {
      return;
    }

    if (!mounted) {
      return;
    }
    final l2 = AppLocalizations.of(context)!;
    setState(() {
      _loading = true;
      _msg = l2.driveUploading;
    });
    final ok = await state.syncToDrive();
    if (!mounted) {
      return;
    }
    final l3 = AppLocalizations.of(context)!;
    setState(() {
      _loading = false;
      _msg = ok ? l3.driveUploadOk : l3.driveUploadError;
    });
  }

  Future<void> _download(AppState state) async {
    final l = AppLocalizations.of(context)!;
    setState(() {
      _loading = true;
      _msg = l.driveDownloading;
    });
    final ok = await state.syncFromDrive();
    if (!mounted) {
      return;
    }
    final l2 = AppLocalizations.of(context)!;
    setState(() {
      _loading = false;
      _msg = ok ? l2.driveDownloadOk : l2.driveDownloadError;
    });
  }
}

// Extracted dialog so l10n context is available inside builder
class _DriveUploadDialog extends StatelessWidget {
  final int gamesCount;
  final int playersCount;
  const _DriveUploadDialog(
      {required this.gamesCount, required this.playersCount});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: Text(l.driveUploadConfirmTitle),
      content: Text(
        l.driveUploadConfirmBody(gamesCount, playersCount),
        style: const TextStyle(color: Color(0xFF9999BB)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.btnCancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l.driveBackup),
        ),
      ],
    );
  }
}
