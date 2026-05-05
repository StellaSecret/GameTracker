// lib/screens/group_screen.dart
// Premium feature: real-time group sync via Firestore.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/group_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gt_card.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final gs = state.groupService;

    if (!gs.isSignedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('👥 Groupes')),
        body: _SignInPrompt(
          onSignIn: () async {
            setState(() => _loading = true);
            await gs.signIn();
            setState(() => _loading = false);
          },
          loading: _loading,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('👥 Groupes'),
        actions: [
          if (state.isInGroup)
            TextButton.icon(
              onPressed: () => _leaveGroup(state),
              icon: const Icon(Icons.exit_to_app_rounded,
                  color: AppColors.error, size: 18),
              label: const Text('Quitter',
                  style: TextStyle(color: AppColors.error)),
            ),
        ],
      ),
      body: Column(
        children: [
          if (state.isInGroup) _ActiveGroupBanner(state: state),
          Expanded(
            child: StreamBuilder<List<GroupInfo>>(
              stream: gs.watchMyGroups(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text('Erreur: ${snap.error}',
                        style:
                            const TextStyle(color: AppColors.error)),
                  );
                }
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                final groups = snap.data!;
                if (groups.isEmpty) {
                  return GTEmptyState(
                    emoji: '👥',
                    title: 'Aucun groupe',
                    subtitle:
                        'Créez un groupe pour jouer en temps réel avec vos amis.',
                    action: ElevatedButton.icon(
                      onPressed: () => _createGroup(state),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Créer un groupe'),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: groups.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                  itemBuilder: (ctx, i) => _GroupCard(
                    info: groups[i],
                    isActive:
                        state.activeGroupId == groups[i].id,
                    onJoin: () => _joinGroup(state, groups[i].id),
                    onInvite: () =>
                        _showInvite(state, groups[i].id),
                  )
                      .animate(
                          delay: Duration(milliseconds: i * 50))
                      .fadeIn(duration: 250.ms)
                      .slideX(begin: 0.05),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createGroup(state),
        icon: const Icon(Icons.group_add_rounded),
        label: const Text('Nouveau groupe'),
      ),
    );
  }

  Future<void> _createGroup(AppState state) async {
    final name = await _askGroupName(context);
    if (name == null || name.isEmpty) {
      return;
    }
    setState(() => _loading = true);
    final id = await state.createAndJoinGroup(name);
    setState(() => _loading = false);
    if (id == null && mounted) {
      _showError('Impossible de créer le groupe.');
    }
  }

  Future<void> _joinGroup(AppState state, String groupId) async {
    setState(() => _loading = true);
    await state.joinGroup(groupId);
    setState(() => _loading = false);
  }

  Future<void> _leaveGroup(AppState state) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Quitter le groupe ?'),
        content: const Text(
            'Vos données locales seront conservées.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quitter',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await state.leaveGroup();
    }
  }

  Future<void> _showInvite(AppState state, String groupId) async {
    final emailCtrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Inviter un joueur',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('ID du groupe : $groupId',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: groupId));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('ID copié dans le presse-papier')),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 14),
              label: const Text('Copier l\'ID'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email du joueur',
                hintText: 'ami@exemple.com',
              ),
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final email = emailCtrl.text.trim();
                  if (email.isEmpty) {
                    return;
                  }
                  final ok = await state.groupService
                      .inviteMember(groupId, email);
                  if (!ctx.mounted) {
                    return;
                  }
                  Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok
                            ? '✓ Invitation envoyée à $email'
                            : '✗ Erreur lors de l\'invitation'),
                      ),
                    );
                  }
                },
                child: const Text('Inviter'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _askGroupName(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Nom du groupe'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration:
              const InputDecoration(hintText: 'ex: Soirée jeux'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}

class _SignInPrompt extends StatelessWidget {
  final VoidCallback onSignIn;
  final bool loading;

  const _SignInPrompt({required this.onSignIn, required this.loading});

  @override
  Widget build(BuildContext context) {
    return GTEmptyState(
      emoji: '🔐',
      title: 'Connexion requise',
      subtitle:
          'Connectez-vous avec Google pour accéder aux groupes temps réel.',
      action: loading
          ? const CircularProgressIndicator()
          : ElevatedButton.icon(
              onPressed: onSignIn,
              icon: const Icon(Icons.login_rounded),
              label: const Text('Se connecter avec Google'),
            ),
    );
  }
}

class _ActiveGroupBanner extends StatelessWidget {
  final AppState state;

  const _ActiveGroupBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.primary.withValues(alpha: 0.15),
      child: Row(
        children: [
          const Icon(Icons.wifi_tethering_rounded,
              color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sync temps réel actif · Groupe ${state.activeGroupId!.substring(0, 8)}…',
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final GroupInfo info;
  final bool isActive;
  final VoidCallback onJoin;
  final VoidCallback onInvite;

  const _GroupCard({
    required this.info,
    required this.isActive,
    required this.onJoin,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    return GTCard(
      borderColor: isActive ? AppColors.primary : null,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child:
                  Text('👥', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  '${info.memberEmails.length} membre${info.memberEmails.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (!isActive)
            OutlinedButton(
              onPressed: onJoin,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
              child: const Text('Rejoindre', style: TextStyle(fontSize: 12)),
            )
          else
            const GTBadge(
                label: 'Actif', color: AppColors.success, emoji: '●'),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.person_add_rounded,
                size: 18, color: AppColors.textSecondary),
            onPressed: onInvite,
            tooltip: 'Inviter',
          ),
        ],
      ),
    );
  }
}
