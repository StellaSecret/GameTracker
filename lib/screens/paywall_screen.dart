import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../models/entitlement.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class PaywallScreen extends StatefulWidget {
  final String? reason;

  const PaywallScreen({super.key, this.reason});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  Offering? _offering;
  bool _loading = true;
  bool _purchasing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ps = context.read<AppState>().purchaseService;
      if (ps.isPremium && mounted) {
        Navigator.pop(context, true);
        return;
      }
      _load();
    });
  }

  Future<void> _load() async {
    final ps = context.read<AppState>().purchaseService;
    final offering = await ps.getOffering();
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
        title: Text('🌟 GameTracker Premium'),
        leading: IconButton(
          icon: Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.reason != null) ...[
                    Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: c.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: c.warning.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Text('⚠️', style: TextStyle(fontSize: 18)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.reason!,
                              style: TextStyle(
                                  color: c.warning, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Hero
                  const Text(
                    '🎲',
                    style: TextStyle(fontSize: 72),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .scale(duration: 400.ms, curve: Curves.elasticOut),
                  SizedBox(height: 16),
                  Text(
                    'Passez à Premium',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Jeux illimités, historique complet\net sync temps réel entre joueurs.',
                    style: TextStyle(
                        fontSize: 15, color: c.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Feature list
                  ..._features.asMap().entries.map((entry) {
                    final f = entry.value;
                    return _FeatureRow(
                      emoji: f.emoji,
                      title: f.title,
                      free: f.free,
                      premium: f.premium,
                    )
                        .animate(delay: Duration(milliseconds: entry.key * 80))
                        .fadeIn(duration: 300.ms)
                        .slideX(begin: 0.05);
                  }),
                  SizedBox(height: 32),

                  // Packages
                  if (_offering == null)
                    Center(
                      child: Text(
                        'Impossible de charger les offres.\nVérifiez votre connexion.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: c.textSecondary),
                      ),
                    )
                  else
                    ..._offering!.availablePackages.map((pkg) =>
                        _PackageButton(
                          package: pkg,
                          purchasing: _purchasing,
                          onTap: () => _purchase(pkg),
                        )),

                  if (_error != null) ...[
                    SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: c.error, fontSize: 13),
                    ),
                  ],

                  SizedBox(height: 16),
                  TextButton(
                    onPressed: _purchasing ? null : _restore,
                    child: Text('Restaurer les achats',
                        style: TextStyle(color: c.textSecondary)),
                  ),
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

  static final _features = <_FeatureData>[
    const _FeatureData('🎲', 'Jeux', free: '${Entitlement.freeGameLimit} jeux max', premium: 'Illimités'),
    const _FeatureData('📋', 'Historique', free: '${Entitlement.freeSessionLimit} parties/jeu', premium: 'Illimité'),
    const _FeatureData('🔄', 'Sync Drive', free: 'Backup manuel', premium: 'Backup manuel'),
    const _FeatureData('👥', 'Groupes temps réel', free: '—', premium: 'Inclus ✓'),
    const _FeatureData('📊', 'Statistiques avancées', free: '—', premium: 'Bientôt ✓'),
  ];
}

class _FeatureData {
  final String emoji;
  final String title;
  final String free;
  final String premium;

  const _FeatureData(this.emoji, this.title,
      {required this.free, required this.premium});
}

class _FeatureRow extends StatelessWidget {
  final String emoji, title, free, premium;

  const _FeatureRow({
    required this.emoji,
    required this.title,
    required this.free,
    required this.premium,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              free,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, color: c.textSecondary),
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              premium,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: c.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    final isMonthly =
        package.packageType == PackageType.monthly;
    final isAnnual =
        package.packageType == PackageType.annual;
    final isBadged = isAnnual;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: purchasing ? null : onTap,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 150),
              padding: EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: isAnnual
                    ? LinearGradient(
                        colors: [
                          c.primary.withValues(alpha: 0.3),
                          c.accent.withValues(alpha: 0.2),
                        ],
                      )
                    : null,
                color: isAnnual ? null : c.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isAnnual
                      ? c.primary
                      : c.cardBorder,
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
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        if (isAnnual)
                          Text(
                            '2 mois offerts',
                            style: TextStyle(
                                fontSize: 12, color: c.accent),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    package.storeProduct.priceString,
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  if (isAnnual) ...[
                    SizedBox(width: 4),
                    Text('/an',
                        style: TextStyle(
                            fontSize: 12,
                            color: c.textSecondary)),
                  ] else if (isMonthly) ...[
                    SizedBox(width: 4),
                    Text('/mois',
                        style: TextStyle(
                            fontSize: 12,
                            color: c.textSecondary)),
                  ],
                  const SizedBox(width: 12),
                  if (purchasing)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 16, color: c.textSecondary),
                ],
              ),
            ),
          ),
          if (isBadged)
            Positioned(
              top: -10,
              right: 16,
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: c.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'POPULAIRE',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.black),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
