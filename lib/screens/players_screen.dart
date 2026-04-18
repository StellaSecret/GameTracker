// lib/screens/players_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/player.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/gt_card.dart';

class PlayersScreen extends StatelessWidget {
  const PlayersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final players = state.players;

    return Scaffold(
      appBar: AppBar(title: const Text('👥 Joueurs')),
      body: players.isEmpty
          ? GTEmptyState(
              emoji: '👤',
              title: 'Aucun joueur',
              subtitle: 'Ajoutez des joueurs pour suivre leurs scores.',
              action: ElevatedButton(
                onPressed: () => _showAddPlayer(context),
                child: const Text('Ajouter un joueur'),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: players.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) => _PlayerCard(player: players[i])
                  .animate(delay: Duration(milliseconds: i * 40))
                  .fadeIn(duration: 250.ms)
                  .slideX(begin: 0.05),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPlayer(context),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Nouveau joueur'),
      ),
    );
  }

  void _showAddPlayer(BuildContext context, [Player? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PlayerSheet(existing: existing),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final Player player;
  const _PlayerCard({required this.player});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    Color color;
    try {
      color = Color(int.parse(player.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      color = AppColors.primary;
    }

    // Count games played
    final gamesPlayed = state.games
        .where((g) => g.sessions.any((s) => s.scores.containsKey(player.id)))
        .length;
    final totalWins = state.games
        .fold<int>(0, (sum, g) => sum + (g.winsByPlayer[player.id] ?? 0));

    return GTCard(
      onTap: () => _showEdit(context),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withOpacity(0.2),
            child: Text(
              player.name[0].toUpperCase(),
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  '$gamesPlayed jeu${gamesPlayed != 1 ? 'x' : ''} · $totalWins victoire${totalWins != 1 ? 's' : ''}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded,
                size: 18, color: AppColors.textSecondary),
            onPressed: () => _showEdit(context),
          ),
        ],
      ),
    );
  }

  void _showEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PlayerSheet(existing: player),
    );
  }
}

class _PlayerSheet extends StatefulWidget {
  final Player? existing;
  const _PlayerSheet({this.existing});

  @override
  State<_PlayerSheet> createState() => _PlayerSheetState();
}

class _PlayerSheetState extends State<_PlayerSheet> {
  late final TextEditingController _nameCtrl;
  late String _color;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _color = widget.existing?.color ?? '#6C63FF';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isEditing ? 'Modifier le joueur' : 'Nouveau joueur',
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),

          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nom du joueur',
              hintText: 'ex: Alice, Bob…',
            ),
            textCapitalization: TextCapitalization.words,
            autofocus: true,
          ),
          const SizedBox(height: 20),

          const Text('COULEUR',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 1)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: AppColors.playerColors.map((c) {
              final hex =
                  '#${c.value.toRadixString(16).substring(2).toUpperCase()}';
              final selected = hex == _color;
              return GestureDetector(
                onTap: () => setState(() => _color = hex),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: selected
                        ? [BoxShadow(color: c.withOpacity(0.6), blurRadius: 8)]
                        : [],
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              if (isEditing)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_rounded,
                        color: AppColors.error, size: 18),
                    label: const Text('Supprimer',
                        style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
              if (isEditing) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(isEditing ? 'Enregistrer' : 'Ajouter'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    final state = context.read<AppState>();
    if (widget.existing != null) {
      await state.updatePlayer(
          widget.existing!.copyWith(name: _nameCtrl.text.trim(), color: _color));
    } else {
      await state
          .addPlayer(Player(name: _nameCtrl.text.trim(), color: _color));
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Supprimer ce joueur ?'),
        content: const Text(
            'Ses scores dans les parties existantes seront conservés.'),
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
    if (ok == true && mounted) {
      await context.read<AppState>().deletePlayer(widget.existing!.id);
      Navigator.pop(context);
    }
  }
}
