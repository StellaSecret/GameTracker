// lib/screens/games_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/game.dart';
import '../models/game_mode.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/gt_card.dart';
import 'game_detail_screen.dart';
import 'add_game_screen.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final games = state.games
        .where((g) => g.name.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎲 GameTracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Sync Google Drive',
            onPressed: () => _showSyncSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.people_alt_rounded),
            tooltip: 'Joueurs',
            onPressed: () =>
                Navigator.pushNamed(context, '/players'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Rechercher un jeu…',
                prefixIcon: Icon(Icons.search_rounded,
                    color: AppColors.textSecondary),
                isDense: true,
              ),
            ),
          ),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : games.isEmpty
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddGameScreen()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouveau jeu'),
      ),
    );
  }

  Widget _buildGamesList(List<Game> games, AppState state) {
    // Group by first letter
    final Map<String, List<Game>> grouped = {};
    for (final game in games) {
      final letter = game.name[0].toUpperCase();
      grouped.putIfAbsent(letter, () => []).add(game);
    }
    final letters = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: letters.length,
      itemBuilder: (context, idx) {
        final letter = letters[idx];
        final letterGames = grouped[letter]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
              child: Text(
                letter,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
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
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _SyncSheet(),
    );
  }
}

class _GameCard extends StatelessWidget {
  final Game game;

  const _GameCard({required this.game});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final sessionCount = game.sessions.length;
    final modeColor = _modeColor(game.mode);

    return GTCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GameDetailScreen(gameId: game.id)),
      ),
      child: Row(
        children: [
          // Emoji / icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: modeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: modeColor.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                game.coverEmoji ?? game.mode.icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Name + info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
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
                    const SizedBox(width: 8),
                    Text(
                      '$sessionCount partie${sessionCount != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textSecondary),
        ],
      ),
    );
  }

  Color _modeColor(GameMode mode) {
    switch (mode) {
      case GameMode.points:
        return AppColors.primary;
      case GameMode.duel:
        return AppColors.secondary;
      case GameMode.ranking:
        return AppColors.accent;
    }
  }
}

class _SyncSheet extends StatefulWidget {
  const _SyncSheet();

  @override
  State<_SyncSheet> createState() => _SyncSheetState();
}

class _SyncSheetState extends State<_SyncSheet> {
  bool _loading = false;
  String? _msg;
  final _emailCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
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
              const Text(
                'Google Drive',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (isSignedIn)
                GTBadge(
                    label: 'Connecté', color: AppColors.success, emoji: '✓'),
            ],
          ),
          const SizedBox(height: 16),
          if (!isSignedIn) ...[
            ElevatedButton.icon(
              onPressed: _loading ? null : () => _signIn(state),
              icon: const Icon(Icons.login_rounded),
              label: const Text('Se connecter avec Google'),
            ),
          ] else ...[
            Text(
              user?.email ?? '',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : () => _upload(state),
                    icon: const Icon(Icons.cloud_upload_rounded),
                    label: const Text('Envoyer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : () => _download(state),
                    icon: const Icon(Icons.cloud_download_rounded),
                    label: const Text('Récupérer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: const BorderSide(color: AppColors.accent),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'PARTAGER AVEC',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 1),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(
                        hintText: 'email@exemple.com',
                        isDense: true),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _loading ? null : () => _share(state),
                  icon: const Icon(Icons.share_rounded,
                      color: AppColors.primary),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () async {
                await state.driveService.signOut();
                if (mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Se déconnecter'),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.error),
            ),
          ],
          if (_msg != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
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
                    const Icon(Icons.info_rounded,
                        color: AppColors.primary, size: 18),
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
    setState(() {
      _loading = false;
      _msg = ok ? null : 'Connexion annulée.';
    });
  }

  Future<void> _upload(AppState state) async {
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
      _msg = ok ? '✓ Données importées.' : '✗ Aucune donnée ou erreur.';
    });
  }

  Future<void> _share(AppState state) async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() {
      _loading = true;
      _msg = 'Partage avec $email…';
    });
    final ok = await state.driveService.shareWith(email);
    setState(() {
      _loading = false;
      _msg =
          ok ? '✓ Partagé avec $email.' : '✗ Erreur lors du partage.';
    });
    _emailCtrl.clear();
  }
}
