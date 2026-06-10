import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/game.dart';
import '../models/game_mode.dart';
import '../models/game_mode_l10n.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/gt_card.dart';

const _emojis = [
  '🎲', '♟️', '🃏', '🎯', '🎮', '🧩', '🎰', '🎱',
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
  bool _lowestScoreWins = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _descCtrl =
        TextEditingController(text: widget.existing?.description ?? '');
    _mode = widget.existing?.mode ?? GameMode.points;
    _emoji = widget.existing?.coverEmoji;
    _lowestScoreWins = widget.existing?.lowestScoreWins ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final isEditing = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l.editGameTitle : l.addGameTitle),
        actions: [
          if (isEditing)
            IconButton(
              key: const Key('btnDeleteGame'),
              icon: Icon(Icons.delete_rounded, color: c.error),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
          ),
          children: [
            // ── Emoji picker ──────────────────────────────────────────────
            GTSectionHeader(title: l.sectionIcon),
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
                                ? c.primary.withValues(alpha: 0.2)
                                : c.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  _emoji == e ? c.primary : c.cardBorder,
                              width: _emoji == e ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child:
                                Text(e, style: const TextStyle(fontSize: 24)),
                          ),
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Name ──────────────────────────────────────────────────────
            GTSectionHeader(title: l.sectionGameName),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('fieldGameName'),
              controller: _nameCtrl,
              decoration: InputDecoration(hintText: l.gameNameHint),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? l.gameNameRequired : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 20),

            // ── Description ───────────────────────────────────────────────
            GTSectionHeader(title: l.sectionDescription),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              decoration: InputDecoration(hintText: l.gameDescriptionHint),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // ── Mode ──────────────────────────────────────────────────────
            GTSectionHeader(title: l.sectionGameMode),
            const SizedBox(height: 12),
            ...GameMode.values.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _mode = m;
                      if (m != GameMode.points) {
                        _lowestScoreWins = false;
                      }
                    }),
                    child: GTCard(
                      borderColor: _mode == m ? c.primary : null,
                      child: Row(
                        children: [
                          Text(m.icon,
                              style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.label(l),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15)),
                                const SizedBox(height: 2),
                                Text(m.description(l),
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: c.textSecondary)),
                              ],
                            ),
                          ),
                          if (_mode == m)
                            Icon(Icons.radio_button_checked_rounded,
                                color: c.primary)
                          else
                            Icon(Icons.radio_button_unchecked_rounded,
                                color: c.textSecondary),
                        ],
                      ),
                    ),
                  ),
                )),

            // ── Scoring rule ──────────────────────────────────────────────
            if (_mode == GameMode.points) ...[
              const SizedBox(height: 8),
              GTCard(
                child: Row(
                  children: [
                    const Text('🔻', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.lowestScoreWinsLabel,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l.lowestScoreWinsExample,
                            style: TextStyle(
                                fontSize: 12, color: c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _lowestScoreWins,
                      onChanged: (v) =>
                          setState(() => _lowestScoreWins = v),
                      activeThumbColor: c.primary,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
            ElevatedButton(
              key: const Key('btnSubmitGame'),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(isEditing ? l.btnSave : l.btnCreateGame),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    final state = context.read<AppState>();
    if (widget.existing != null) {
      final updated = widget.existing!.copyWith(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        mode: _mode,
        coverEmoji: _emoji,
        lowestScoreWins: _lowestScoreWins,
      );
      await state.updateGame(updated);
    } else {
      final game = Game(
        name: _nameCtrl.text.trim(),
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        mode: _mode,
        coverEmoji: _emoji,
        lowestScoreWins: _lowestScoreWins,
      );
      await state.addGame(game);
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.surface,
        title: Text(l.deleteGameTitle),
        content: Text(l.deleteGameBody),
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
    if (confirm == true && mounted) {
      await context.read<AppState>().deleteGame(widget.existing!.id);
      if (mounted) {
        Navigator.popUntil(context, (r) => r.isFirst);
      }
    }
  }
}
