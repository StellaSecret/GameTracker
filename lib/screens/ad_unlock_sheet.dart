// lib/screens/ad_unlock_sheet.dart
//
// Bottom sheet shown when a free user taps the Stats button.
// Offers two paths:
//   1. Watch a rewarded ad → 5-minute temp unlock.
//   2. Go Premium → navigate to PaywallScreen.premium.
//
// A live countdown timer is displayed once the unlock is active.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import 'paywall_screen.dart';

class AdUnlockSheet extends StatefulWidget {
  const AdUnlockSheet({super.key});

  /// Opens the sheet. If the user earns the unlock, the sheet simply pops
  /// and whichever screen opened it (typically StatsScreen's locked view)
  /// rebuilds itself into the unlocked state via its AppState listener.
  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AdUnlockSheet(),
    );
  }

  @override
  State<AdUnlockSheet> createState() => _AdUnlockSheetState();
}

class _AdUnlockSheetState extends State<AdUnlockSheet> {
  bool _loading = false;
  String? _error;
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startCountdownIfActive();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdownIfActive() {
    final state = context.read<AppState>();
    final until = state.statsUnlockUntil;
    if (until == null || !DateTime.now().isBefore(until)) {
      return;
    }
    _remaining = until.difference(DateTime.now());
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final r = state.statsUnlockUntil?.difference(DateTime.now());
      if (r == null || r.isNegative) {
        _countdownTimer?.cancel();
        if (mounted) {
          setState(() => _remaining = Duration.zero);
        }
      } else {
        if (mounted) {
          setState(() => _remaining = r);
        }
      }
    });
  }

  Future<void> _watchAd() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final state = context.read<AppState>();
    final earned = await state.unlockStatsWithAd();
    if (!mounted) {
      return;
    }
    if (earned) {
      _startCountdownIfActive();
      setState(() => _loading = false);
      // Just pop the sheet — the screen underneath (StatsScreen, or
      // wherever the sheet was opened from) watches AppState via
      // Provider and will rebuild into its unlocked state on its own.
      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      final l = AppLocalizations.of(context)!;
      setState(() {
        _loading = false;
        _error = l.adUnlockError;
      });
    }
  }

  void _goPremium() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaywallScreen.premium()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final state = context.watch<AppState>();
    final alreadyUnlocked = state.canUseAdvancedStats;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: c.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Icon
          Text('📊', style: const TextStyle(fontSize: 56))
              .animate()
              .scale(duration: 350.ms, curve: Curves.elasticOut),
          const SizedBox(height: 12),

          // Title
          Text(
            l.adUnlockTitle,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          // Body
          Text(
            l.adUnlockBody,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: c.textSecondary),
          ),
          const SizedBox(height: 24),

          // Countdown (shown while unlock is active)
          if (alreadyUnlocked && _remaining > Duration.zero) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                l.adUnlockTimerLabel(
                  _remaining.inMinutes,
                  _remaining.inSeconds % 60,
                ),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.primary,
                ),
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 16),
          ],

          // Error message
          if (_error != null) ...[
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: c.error),
            ),
            const SizedBox(height: 12),
          ],

          // Watch ad button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('btnWatchAd'),
              onPressed: _loading ? null : _watchAd,
              icon: _loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: c.surface,
                      ),
                    )
                  : const Icon(Icons.play_circle_outline_rounded),
              label: Text(_loading ? l.adUnlockLoading : l.adUnlockWatchBtn),
              style: FilledButton.styleFrom(
                backgroundColor: c.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Go Premium button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('btnAdSheetGoPremium'),
              onPressed: _loading ? null : _goPremium,
              icon: const Icon(Icons.star_rounded),
              label: Text(l.adUnlockPremiumBtn),
              style: OutlinedButton.styleFrom(
                foregroundColor: c.accent,
                side: BorderSide(color: c.accent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
