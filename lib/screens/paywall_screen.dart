import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/app_state.dart';
import '../services/purchase_service.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Which product to pitch
// ─────────────────────────────────────────────────────────────────────────────
enum PaywallTarget { premium, groupSync }

// ─────────────────────────────────────────────────────────────────────────────
// PaywallScreen
// ─────────────────────────────────────────────────────────────────────────────
class PaywallScreen extends StatefulWidget {
  final PaywallTarget target;
  final String? reason;

  const PaywallScreen({
    super.key,
    this.target = PaywallTarget.premium,
    this.reason,
  });

  // Named constructors for convenience at call sites.
  const PaywallScreen.premium({super.key, this.reason})
      : target = PaywallTarget.premium;

  const PaywallScreen.groupSync({super.key, this.reason})
      : target = PaywallTarget.groupSync;

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  Offering? _offering;
  bool _loading = true;
  bool _purchasing = false;
  String? _error;

  bool get _isGroupSync => widget.target == PaywallTarget.groupSync;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ps = context.read<AppState>().purchaseService;
      // Already unlocked — close immediately.
      final alreadyUnlocked = _isGroupSync
          ? ps.hasGroupSync
          : ps.isPremium;
      if (alreadyUnlocked && mounted) {
        Navigator.pop(context, true);
        return;
      }
      _load();
    });
  }

  Future<void> _load() async {
    final ps = context.read<AppState>().purchaseService;
    final offering = await ps.getOffering(
      productId: _isGroupSync
          ? PurchaseService.kGroupSyncId
          : PurchaseService.kPremiumId,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _offering = offering;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isGroupSync ? '👥 Groupes temps réel' : '🌟 GameTracker Premium'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Optional reason banner
                  if (widget.reason != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: c.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.warning.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Text('⚠️', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.reason!,
                              style: TextStyle(color: c.warning, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Hero emoji
                  Text(
                    _isGroupSync ? '👥' : '🎲',
                    style: const TextStyle(fontSize: 72),
                    textAlign: TextAlign.center,
                  ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 16),

                  // Title & subtitle
                  Text(
                    _isGroupSync ? 'Jouez ensemble' : 'Passez à Premium',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isGroupSync
                        ? 'Synchronisez vos scores en temps réel\nentre tous vos appareils.'
                        : 'Stats avancées et export CSV\nsans rien sacrifier sur le plan gratuit.',
                    style: TextStyle(fontSize: 15, color: c.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Feature comparison table
                  _FeatureTable(
                    features: _isGroupSync ? _groupSyncFeatures : _premiumFeatures,
                  ),
                  const SizedBox(height: 32),

                  // Packages from RevenueCat
                  if (_offering == null)
                    Center(
                      child: Text(
                        'Impossible de charger les offres.\nVérifiez votre connexion.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: c.textSecondary),
                      ),
                    )
                  else
                    ..._offering!.availablePackages.map((pkg) => _PackageButton(
                          package: pkg,
                          purchasing: _purchasing,
                          onTap: () => _purchase(pkg),
                        )),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.error, fontSize: 13),
                    ),
                  ],

                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _purchasing ? null : _restore,
                    child: Text('Restaurer les achats',
                        style: TextStyle(color: c.textSecondary)),
                  ),

                  // Cross-sell: if showing one paywall, mention the other
                  const SizedBox(height: 8),
                  _CrossSell(isGroupSync: _isGroupSync),
                ],
              ),
            ),
    );
  }

  Future<void> _purchase(Package package) async {
    setState(() {
      _purchasing = true;
      _error = null;
    });
    final ps = context.read<AppState>().purchaseService;
    final ok = await ps.purchase(package);
    if (!mounted) {
      return;
    }
    setState(() => _purchasing = false);
    if (ok) {
      Navigator.pop(context, true);
    } else if (ps.lastError != null) {
      setState(() => _error = ps.lastError);
    }
  }

  Future<void> _restore() async {
    setState(() {
      _purchasing = true;
      _error = null;
    });
    final ps = context.read<AppState>().purchaseService;
    final ok = await ps.restorePurchases();
    if (!mounted) {
      return;
    }
    setState(() => _purchasing = false);
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() =>
          _error = ps.lastError ?? 'Aucun achat trouvé à restaurer.');
    }
  }

  // ── Feature data ──────────────────────────────────────────────────────────

  static const _premiumFeatures = <_FeatureData>[
    _FeatureData('🎲', 'Jeux & parties',    free: 'Illimités ✓', value: 'Illimités ✓'),
    _FeatureData('🔄', 'Backup Drive',       free: 'Inclus ✓',    value: 'Inclus ✓'),
    _FeatureData('📊', 'Stats avancées',     free: '—',            value: 'Inclus ✓'),
    _FeatureData('📤', 'Export CSV',         free: '—',            value: 'Inclus ✓'),
    _FeatureData('👥', 'Groupes temps réel', free: 'Abonnement séparé', value: 'Abonnement séparé'),
  ];

  static const _groupSyncFeatures = <_FeatureData>[
    _FeatureData('🎲', 'Jeux & parties',    free: 'Illimités ✓', value: 'Illimités ✓'),
    _FeatureData('🔄', 'Backup Drive',       free: 'Inclus ✓',    value: 'Inclus ✓'),
    _FeatureData('👥', 'Sync temps réel',    free: '—',            value: 'Inclus ✓'),
    _FeatureData('🔁', 'Multi-appareils',    free: '—',            value: 'Inclus ✓'),
    _FeatureData('📊', 'Stats avancées',     free: '—',            value: 'Premium séparé'),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Feature comparison table
// ─────────────────────────────────────────────────────────────────────────────
class _FeatureTable extends StatelessWidget {
  final List<_FeatureData> features;
  const _FeatureTable({required this.features});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      children: [
        // Header row
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              const Expanded(child: SizedBox()),
              SizedBox(
                width: 80,
                child: Text('Gratuit',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: c.textSecondary)),
              ),
              SizedBox(
                width: 90,
                child: Text('Ce plan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: c.accent)),
              ),
            ],
          ),
        ),
        ...features.asMap().entries.map((entry) => _FeatureRow(
              data: entry.value,
            ).animate(delay: Duration(milliseconds: entry.key * 60))
              .fadeIn(duration: 250.ms)
              .slideX(begin: 0.05)),
      ],
    );
  }
}

class _FeatureData {
  final String emoji, title, free, value;
  const _FeatureData(this.emoji, this.title,
      {required this.free, required this.value});
}

class _FeatureRow extends StatelessWidget {
  final _FeatureData data;
  const _FeatureRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(data.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(data.title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          SizedBox(
            width: 80,
            child: Text(data.free,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: c.textSecondary)),
          ),
          SizedBox(
            width: 90,
            child: Text(data.value,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c.accent)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cross-sell nudge at the bottom
// ─────────────────────────────────────────────────────────────────────────────
class _CrossSell extends StatelessWidget {
  final bool isGroupSync;
  const _CrossSell({required this.isGroupSync});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final label = isGroupSync
        ? 'Vous cherchez les stats avancées ? Découvrez Premium.'
        : 'Vous voulez jouer en groupe ? Découvrez le sync temps réel.';
    return GestureDetector(
      onTap: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => isGroupSync
              ? const PaywallScreen.premium()
              : const PaywallScreen.groupSync(),
        ),
      ),
      child: Text(label,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 12,
              color: c.primary,
              decoration: TextDecoration.underline)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Package button (unchanged visual, same as before)
// ─────────────────────────────────────────────────────────────────────────────
class _PackageButton extends StatelessWidget {
  final Package package;
  final bool purchasing;
  final VoidCallback onTap;

  const _PackageButton({
    required this.package,
    required this.purchasing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isMonthly = package.packageType == PackageType.monthly;
    final isAnnual  = package.packageType == PackageType.annual;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: purchasing ? null : onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: isAnnual
                    ? LinearGradient(colors: [
                        c.primary.withValues(alpha: 0.3),
                        c.accent.withValues(alpha: 0.2),
                      ])
                    : null,
                color: isAnnual ? null : c.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isAnnual ? c.primary : c.cardBorder,
                  width: isAnnual ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAnnual
                              ? 'Annuel'
                              : isMonthly
                                  ? 'Mensuel'
                                  : package.storeProduct.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        if (isAnnual)
                          Text('2 mois offerts',
                              style: TextStyle(fontSize: 12, color: c.accent)),
                      ],
                    ),
                  ),
                  Text(package.storeProduct.priceString,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  if (isAnnual) ...[
                    const SizedBox(width: 4),
                    Text('/an',
                        style:
                            TextStyle(fontSize: 12, color: c.textSecondary)),
                  ] else if (isMonthly) ...[
                    const SizedBox(width: 4),
                    Text('/mois',
                        style:
                            TextStyle(fontSize: 12, color: c.textSecondary)),
                  ],
                  const SizedBox(width: 12),
                  if (purchasing)
                    const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 16, color: c.textSecondary),
                ],
              ),
            ),
          ),
          if (isAnnual)
            Positioned(
              top: -10,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: c.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('POPULAIRE',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.black)),
              ),
            ),
        ],
      ),
    );
  }
}
