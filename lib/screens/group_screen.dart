// lib/screens/group_screen.dart
// Premium feature: real-time group sync via Firestore.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/app_state.dart';
import '../services/group_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gt_card.dart';
import 'paywall_screen.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final state = context.watch<AppState>();
    final gs = state.groupService;

    if (!state.entitlement.canUseGroupSync) {
      return Scaffold(
        appBar: AppBar(title: Text(l.groupsScreenTitle)),
        body: GTEmptyState(
          emoji: '🔒',
          title: l.paywallGroupSyncTitle,
          subtitle: l.paywallGroupSyncSub,
          action: ElevatedButton.icon(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const PaywallScreen.groupSync()),
            ),
            icon: const Icon(Icons.star_rounded),
            label: Text(l.freeBannerPremium),
          ),
        ),
      );
    }

    if (!gs.isSignedIn) {
      return Scaffold(
        appBar: AppBar(title: Text(l.groupsScreenTitle)),
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
        title: Text(l.groupsScreenTitle),
        actions: [
          if (state.isInGroup)
            TextButton.icon(
              onPressed: () => _leaveGroup(state),
              icon: Icon(Icons.exit_to_app_rounded,
                  color: c.error, size: 18),
              label: Text(l.groupsLeaveBtn,
                  style: TextStyle(color: c.error)),
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
                final c = AppColors.of(context);
                final l2 = AppLocalizations.of(context)!;
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      l2.groupsError(snap.error.toString()),
                      style: TextStyle(color: c.error),
                    ),
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
                    title: l2.groupsEmpty,
                    subtitle: l2.groupsEmptySub,
                    action: ElevatedButton.icon(
                      onPressed: () => _createGroup(state),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(l2.groupsBtnCreate),
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
                    onJoin: () =>
                        _joinGroup(state, groups[i].id),
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
        label: Text(l.fabNewGroup),
      ),
    );
  }

  Future<void> _createGroup(AppState state) async {
    final l = AppLocalizations.of(context)!;
    final name = await _askGroupName(context);
    if (name == null || name.isEmpty) {
      return;
    }
    setState(() => _loading = true);
    final id = await state.createAndJoinGroup(name);
    setState(() => _loading = false);
    if (id == null && mounted) {
      _showError(l.groupsCreateError);
    }
  }

  Future<void> _joinGroup(AppState state, String groupId) async {
    setState(() => _loading = true);
    await state.joinGroup(groupId);
    setState(() => _loading = false);
  }

  Future<void> _leaveGroup(AppState state) async {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.surface,
        title: Text(l.groupsLeaveTitle),
        content: Text(l.groupsLeaveBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.btnCancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.groupsLeaveBtn,
                style: TextStyle(color: c.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await state.leaveGroup();
    }
  }

  Future<void> _showInvite(AppState state, String groupId) async {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final emailCtrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final l2 = AppLocalizations.of(ctx)!;
        return Padding(
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l2.groupsInviteTitle,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(l2.groupsInviteGroupId(groupId),
                  style: TextStyle(
                      fontSize: 12, color: c.textSecondary)),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: groupId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.driveIdCopied)),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 14),
                label: Text(l2.groupsInviteCopyId),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                decoration: InputDecoration(
                  labelText: l2.groupsInviteEmailLabel,
                  hintText: l2.groupsInviteEmailHint,
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
                      final l3 = AppLocalizations.of(context)!;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok
                              ? l3.groupsInviteOk(email)
                              : l3.groupsInviteError),
                        ),
                      );
                    }
                  },
                  child: Text(l2.btnInvite),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _askGroupName(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.surface,
        title: Text(l.groupsCreateTitle),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: l.groupsCreateHint),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.btnCancel)),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, ctrl.text.trim()),
            child: Text(l.groupsCreateBtn),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _SignInPrompt extends StatelessWidget {
  final VoidCallback onSignIn;
  final bool loading;
  const _SignInPrompt({required this.onSignIn, required this.loading});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return GTEmptyState(
      emoji: '🔐',
      title: l.groupsSignInTitle,
      subtitle: l.groupsSignInSub,
      action: loading
          ? const CircularProgressIndicator()
          : ElevatedButton.icon(
              onPressed: onSignIn,
              icon: const Icon(Icons.login_rounded),
              label: Text(l.groupsSignInBtn),
            ),
    );
  }
}

class _ActiveGroupBanner extends StatelessWidget {
  final AppState state;
  const _ActiveGroupBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: c.primary.withValues(alpha: 0.15),
      child: Row(
        children: [
          Icon(Icons.wifi_tethering_rounded,
              color: c.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l.groupsActiveBanner(
                  state.activeGroupId!.substring(0, 8)),
              style: TextStyle(
                  fontSize: 13,
                  color: c.primary,
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
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    return GTCard(
      borderColor: isActive ? c.primary : null,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('👥', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  l.groupsMemberCount(info.memberEmails.length),
                  style: TextStyle(
                      fontSize: 12, color: c.textSecondary),
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
                foregroundColor: c.primary,
                side: BorderSide(color: c.primary),
              ),
              child: Text(l.groupsBtnJoin,
                  style: const TextStyle(fontSize: 12)),
            )
          else
            GTBadge(label: l.groupsActive, color: c.success, emoji: '●'),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.person_add_rounded,
                size: 18, color: c.textSecondary),
            onPressed: onInvite,
            tooltip: l.groupsTooltipInvite,
          ),
        ],
      ),
    );
  }
}
