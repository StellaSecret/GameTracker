// lib/screens/add_game_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game.dart';
import '../models/game_mode.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/gt_card.dart';

const _emojis = [
  '🎲', '♟️', '🃏', '🎯', '🎮', '🧩', '🃏', '🎰', '🎱',
  '⚔️', '🏆', '👑', '🌍', '🚂', '🏙️', '🌺', '🐉', '🦁',
];

class AddGameScreen extends StatefulWidget {
  final Game? existing;
  const AddGameScreen({super.key, this.existing});

  @override
  State<AddGameScreen> createState() => _AddGameScreenState();
}

class _AddGameScreenState extends State<AddGameScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  GameMode _mode = GameMode.points;
  String? _emoji;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _descCtrl =
        TextEditingController(text: widget.existing?.description ?? '');
    _mode = widget.existing?.mode ?? GameMode.points;
    _emoji = widget.existing?.coverEmoji;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier le jeu' : 'Nouveau jeu'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_rounded, color: AppColors.error),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Emoji picker
            const GTSectionHeader(title: 'ICÔNE'),
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._emojis.map((e) => GestureDetector(
                        onTap: () => setState(() => _emoji = e),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: _emoji == e
                                ? AppColors.primary.withOpacity(0.2)
                                : AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _emoji == e
                                  ? AppColors.primary
                                  : AppColors.cardBorder,
                              width: _emoji == e ? 2 : 1,
                            ),
                          ),
                          child: Center(
                              child: Text(e,
                                  style: const TextStyle(fontSize: 24))),
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Name
            const GTSectionHeader(title: 'NOM DU JEU'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              decoration:
                  const InputDecoration(hintText: 'ex: Catan, 7 Wonders…'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Nom requis' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 20),
            // Description
            const GTSectionHeader(title: 'DESCRIPTION (optionnel)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                  hintText: 'Quelques mots sur le jeu…'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            // Mode
            const GTSectionHeader(title: 'MODE DE JEU'),
            const SizedBox(height: 12),
            ...GameMode.values.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _mode = m),
                    child: GTCard(
                      borderColor: _mode == m ? AppColors.primary : null,
                      child: Row(
                        children: [
                          Text(m.icon,
                              style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.label,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15)),
                                const SizedBox(height: 2),
                                Text(m.description,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          Radio<GameMode>(
                            value: m,
                            groupValue: _mode,
                            onChanged: (v) => setState(() => _mode = v!),
                            activeColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              child: Text(isEditing ? 'Enregistrer' : 'Créer le jeu'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final state = context.read<AppState>();
    if (widget.existing != null) {
      final updated = widget.existing!.copyWith(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        mode: _mode,
        coverEmoji: _emoji,
      );
      await state.updateGame(updated);
    } else {
      final game = Game(
        name: _nameCtrl.text.trim(),
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        mode: _mode,
        coverEmoji: _emoji,
      );
      await state.addGame(game);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Supprimer ce jeu ?'),
        content: const Text(
            'Toutes les parties seront supprimées. Cette action est irréversible.'),
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
    if (confirm == true && mounted) {
      await context.read<AppState>().deleteGame(widget.existing!.id);
      if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
    }
  }
}
