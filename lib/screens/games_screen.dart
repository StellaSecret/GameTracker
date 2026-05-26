import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/game.dart';
import '../models/game_mode.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
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
    final c = AppColors.of(context);
    final state = context.watch<AppState>();
    final games = state.games
        .where((g) => g.name.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('🎲 GameTracker'),
        actions: [
          // Group sync badge (premium)
          if (state.isInGroup)
            Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.wifi_tethering_rounded,
                  color: c.primary, size: 20),
            ),
          IconButton(
            icon: Icon(
              context.watch<ThemeNotifier>().isDark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            tooltip: 'Changer le thème',
            onPressed: () => context.read<ThemeNotifier>().toggle(),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Statistiques',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StatsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.group_rounded),
            tooltip: 'Groupes',
            onPressed: () => _openGroups(context, state),
          ),
          IconButton(
            icon: Icon(Icons.sync_rounded),
            tooltip: 'Sync Drive',
            onPressed: () => _showSyncSheet(context),
          ),
          IconButton(
            icon: Icon(Icons.people_alt_rounded),
            tooltip: 'Joueurs',
            onPressed: () => Navigator.pushNamed(context, '/players'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Rechercher un jeu…',
                prefixIcon:
                    Icon(Icons.search_rounded, color: c.textSecondary),
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
                // Sync message banner
                if (state.syncMessage != null)
                  _SyncBanner(message: state.syncMessage!),
                // Free plan indicator
                if (!state.entitlement.isPremium)
                  _FreeBanner(state: state),
                Expanded(
                  child: games.isEmpty
                      ? GTEmptyState(
                          emoji: _search.isEmpty ? '🎲' : '🔍',
                          title: _search.isEmpty
                              ? 'Aucun jeu encore'
                              : 'Aucun résultat',
                          subtitle: _search.isEmpty
                              ? 'Ajoutez votre premier jeu avec le bouton +'
                              : 'Essayez un autre terme',
                        )
                      : _buildGamesList(games, state),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addGame(context, state),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouveau jeu'),
      ),
    );
  }

  void _addGame(BuildContext context, AppState state) {
    final error = state.canAddGame();
    if (error != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaywallScreen(reason: error),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddGameScreen()),
    );
  }

  void _openGroups(BuildContext context, AppState state) {
    if (!state.entitlement.canUseGroupSync) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const PaywallScreen(
            reason: 'Les groupes temps réel sont une fonctionnalité Premium.',
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
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + MediaQuery.of(context).padding.bottom),
      itemCount: letters.length,
      itemBuilder: (context, idx) {
        final c = AppColors.of(context);
        final letter = letters[idx];
        final letterGames = grouped[letter]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(4, 16, 4, 8),
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
                    .animate(delay: Duration(milliseconds: entry.key * 40))
                    .fadeIn(duration: 300.ms)
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
}

// ── Free plan banner ──────────────────────────────────────────────────────────

class _FreeBanner extends StatelessWidget {
  final AppState state;
  const _FreeBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final gameCount = state.games.length;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PaywallScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding:
            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: c.primary.withValues(alpha: 0.08),
        child: Row(
          children: [
            Icon(Icons.star_border_rounded,
                color: c.primary, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Plan gratuit · $gameCount/${state.entitlement.isPremium ? '∞' : '5'} jeux',
                style: TextStyle(
                    fontSize: 12, color: c.primary),
              ),
            ),
            Text('Passer à Premium →',
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
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: c.surfaceElevated,
      child: Text(message,
          style: TextStyle(
              fontSize: 12, color: c.textSecondary)),
    );
  }
}

// ── Game card (unchanged logic) ───────────────────────────────────────────────

class _GameCard extends StatelessWidget {
  final Game game;
  const _GameCard({required this.game});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final sessionCount = game.sessions.length;
    final modeColor = _modeColor(context, game.mode);

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
                      label: game.mode.label,
                      color: modeColor,
                      emoji: game.mode.icon,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '$sessionCount partie${sessionCount != 1 ? 's' : ''}',
                      style: TextStyle(
                          fontSize: 12, color: c.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: c.textSecondary),
        ],
      ),
    );
  }

  Color _modeColor(BuildContext context, GameMode mode) {
    final c = AppColors.of(context);
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

// ── Drive sync sheet (free backup) ───────────────────────────────────────────

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
              Text('☁️', style: TextStyle(fontSize: 24)),
              SizedBox(width: 8),
              Text('Google Drive',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              Spacer(),
              if (isSignedIn)
                GTBadge(
                    label: 'Connecté',
                    color: c.success,
                    emoji: '✓'),
            ],
          ),
          SizedBox(height: 6),
          Text(
            'Sauvegarde manuelle de vos données (plan gratuit & premium).',
            style:
                TextStyle(fontSize: 12, color: c.textSecondary),
          ),
          const SizedBox(height: 16),
          if (!isSignedIn)
            ElevatedButton.icon(
              onPressed: _loading ? null : () => _signIn(state),
              icon: Icon(Icons.login_rounded),
              label: Text('Se connecter avec Google'),
            )
          else ...[
            Text(user?.email ?? '',
                style: TextStyle(
                    color: c.textSecondary, fontSize: 13)),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : () => _upload(state),
                    icon: Icon(Icons.cloud_upload_rounded),
                    label: Text('Sauvegarder'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.primary,
                      side: BorderSide(color: c.primary),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : () => _download(state),
                    icon: Icon(Icons.cloud_download_rounded),
                    label: Text('Restaurer'),
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
              icon: Icon(Icons.logout_rounded),
              label: Text('Se déconnecter'),
              style:
                  TextButton.styleFrom(foregroundColor: c.error),
            ),
          ],
          if (_msg != null) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  if (_loading)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(Icons.info_rounded,
                        color: c.primary, size: 18),
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
    setState(() {
      _loading = true;
      _msg = 'Connexion…';
    });
    final ok = await state.driveService.signIn();
    if (ok) {
      // Injecte l'email Drive dans PurchaseService → active le premium dev
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
    setState(() {
      _loading = false;
      _msg = ok ? null : 'Connexion annulée.';
    });
  }

  Future<void> _upload(AppState state) async {
    // Protection : avertir si les données locales sont vides
    // pour éviter d'écraser un backup Drive existant par du vide
    final hasData = state.games.isNotEmpty || state.players.isNotEmpty;
    if (!hasData) {
      setState(() => _msg = '⚠️ Aucune donnée locale à sauvegarder.');
      return;
    }

    // Confirmation si premier upload (risque d'écrasement)
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Sauvegarder sur Drive ?'),
        content: Text(
          'Cela remplacera les données actuellement sur Drive '
          'par vos données locales (${state.games.length} jeu${state.games.length != 1 ? 'x' : ''}, '
          '${state.players.length} joueur${state.players.length != 1 ? 's' : ''}).',
          style: const TextStyle(color: Color(0xFF9999BB)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
    if (confirm != true) {
      return;
    }

    setState(() {
      _loading = true;
      _msg = 'Envoi vers Drive…';
    });
    final ok = await state.syncToDrive();
    setState(() {
      _loading = false;
      _msg = ok ? '✓ Sauvegardé sur Drive.' : '✗ Erreur lors de l\'envoi.';
    });
  }

  Future<void> _download(AppState state) async {
    setState(() {
      _loading = true;
      _msg = 'Téléchargement depuis Drive…';
    });
    final ok = await state.syncFromDrive();
    setState(() {
      _loading = false;
      _msg = ok
          ? '✓ Données restaurées et fusionnées.'
          : '✗ Aucune donnée ou erreur.';
    });
  }
}
