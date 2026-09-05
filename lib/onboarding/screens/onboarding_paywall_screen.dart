import 'dart:io' show Platform;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/analytics_service.dart';
import '../../services/haptic_service.dart';
import '../../services/revenuecat_service.dart';
import '../../services/unified_subscription_service.dart';
import '../onboarding_strings.dart';
import '../onboarding_theme.dart';
import '../widgets/onb_widgets.dart';

/// Hard paywall in the v2 direction. Purchase logic mirrors `PaywallScreen`
/// (RevenueCat packages matched by identifier), only the presentation changes.
class OnboardingPaywallScreen extends StatefulWidget {
  const OnboardingPaywallScreen({
    super.key,
    required this.s,
    required this.bilanDayName,
    this.goalLine,
    required this.mealsPerDay,
    required this.workoutDays,
    required this.onPurchased,
    this.initialPlan = 'annual',
  });

  final OnbStrings s;
  final String bilanDayName;

  /// The user's own projection ("−8 kg d'ici le 12 nov."), when they set a target.
  final String? goalLine;

  /// Number of planned meals for Monday..Sunday (0..3), from the demo.
  final List<int> mealsPerDay;

  /// Weekday indexes (0 = Monday) with a planned session, from the demo.
  final Set<int> workoutDays;

  /// Runs after a successful purchase or restore; the caller saves and navigates.
  final Future<void> Function() onPurchased;
  final String initialPlan;

  @override
  State<OnboardingPaywallScreen> createState() => _OnboardingPaywallScreenState();
}

class _OnboardingPaywallScreenState extends State<OnboardingPaywallScreen> {
  List<Package> _packages = [];
  bool _busy = false;
  bool _loaded = false;
  bool _loadFailed = false;
  bool _trialEligible = true;
  late String _plan = widget.initialPlan;

  static const List<String> _plans = ['annual', 'monthly', 'weekly'];

  @override
  void initState() {
    super.initState();
    HapticService.instance.mediumImpact();
    AnalyticsService.logEvent('paywall_view', parameters: {'initial_plan': widget.initialPlan});
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loadFailed = false);
    try {
      await UnifiedSubscriptionService().initialize();
      final packages = await RevenueCatService().getAvailablePackages();
      // the trial is only real if the store has an intro offer and this Apple ID is still eligible
      var eligible = true;
      final annual = _findIn(packages, 'annual');
      if (annual != null && Platform.isIOS) {
        try {
          final id = annual.storeProduct.identifier;
          final map = await Purchases.checkTrialOrIntroductoryPriceEligibility([id]);
          eligible = map[id]?.status != IntroEligibilityStatus.introEligibilityStatusIneligible;
        } catch (e) {
          debugPrint('⚠️ OnboardingPaywall eligibility: $e');
        }
      }
      if (!mounted) return;
      setState(() {
        _packages = packages;
        _loaded = true;
        _loadFailed = packages.isEmpty;
        _trialEligible = eligible;
        if (_packageFor(_plan) == null) {
          _plan = _plans.firstWhere((p) => _packageFor(p) != null, orElse: () => _plan);
        }
      });
      AnalyticsService.logEvent('paywall_loaded', parameters: {'packages': packages.length, 'trial_eligible': eligible ? 1 : 0});
    } catch (e) {
      debugPrint('❌ OnboardingPaywall load packages: $e');
      if (mounted) {
        setState(() {
          _loaded = true;
          _loadFailed = true;
        });
      }
    }
  }

  static Package? _findIn(List<Package> packages, String plan) {
    for (final p in packages) {
      final id = p.identifier.toLowerCase();
      if (plan == 'weekly' && id.contains('weekly')) return p;
      if (plan == 'monthly' && id.contains('monthly')) return p;
      if (plan == 'annual' && (id.contains('annual') || id.contains('yearly'))) return p;
    }
    return null;
  }

  Package? _packageFor(String plan) => _findIn(_packages, plan);

  /// A plan row is shown while loading (list price) and, once loaded, only if the store sells it.
  bool _showPlan(String plan) => !_loaded || _packageFor(plan) != null;

  /// Only the annual plan is marketed with a trial; before the store answers we assume it.
  bool _hasTrial(String plan) {
    if (plan != 'annual') return false;
    if (!_loaded) return true;
    return _trialEligible && _packageFor(plan)?.storeProduct.introductoryPrice != null;
  }

  Future<void> _open(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('⚠️ OnboardingPaywall open $url: $e');
    }
  }

  String _price(String plan) => _packageFor(plan)?.storeProduct.priceString ?? widget.s.t('price_default_$plan');

  String _monthlyEquivalent() {
    final p = _packageFor('annual');
    if (p == null) return widget.s.t('price_default_monthly_equiv');
    try {
      final locale = widget.s.lang == 'fr' ? 'fr_FR' : (widget.s.lang == 'de' ? 'de_DE' : 'en_US');
      return NumberFormat.simpleCurrency(locale: locale, name: p.storeProduct.currencyCode).format(p.storeProduct.price / 12);
    } catch (_) {
      return widget.s.t('price_default_monthly_equiv');
    }
  }

  Future<void> _purchase() async {
    if (_busy) return;
    final s = widget.s;
    // never bill a product other than the row the user tapped
    final package = _packageFor(_plan);
    if (package == null) {
      _toast(s.t('store_unavailable'));
      _load();
      return;
    }
    setState(() => _busy = true);
    final productId = package.storeProduct.identifier;
    AnalyticsService.logEvent('purchase_started', parameters: {'plan': _plan, 'product_id': productId, 'has_trial': _hasTrial(_plan) ? 1 : 0});
    try {
      final info = await RevenueCatService().purchasePackage(package);
      if (!mounted) return;
      if (info == null) {
        AnalyticsService.logEvent('purchase_failed', parameters: {'plan': _plan, 'error_code': 'no_customer_info'});
        _toast(s.t('purchase_error'));
        return;
      }
      // paid but not entitled (product not attached to the entitlement): say it, do not open the app
      if (!info.entitlements.active.containsKey(RevenueCatService.premiumEntitlementId)) {
        AnalyticsService.logEvent('purchase_failed', parameters: {'plan': _plan, 'product_id': productId, 'error_code': 'no_entitlement'});
        _toast(s.t('purchase_no_entitlement'));
        return;
      }
      await UnifiedSubscriptionService().syncFromRevenueCat();
      AnalyticsService.logEvent('purchase_success', parameters: {'plan': _plan, 'product_id': productId, 'has_trial': _hasTrial(_plan) ? 1 : 0});
      HapticService.instance.heavyImpact();
      await widget.onPurchased();
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        AnalyticsService.logEvent('purchase_cancelled', parameters: {'plan': _plan});
      } else {
        AnalyticsService.logEvent('purchase_failed', parameters: {'plan': _plan, 'error_code': code.name});
        if (mounted) _toast(s.t('purchase_error'));
      }
    } catch (e) {
      debugPrint('❌ OnboardingPaywall purchase: $e');
      AnalyticsService.logEvent('purchase_failed', parameters: {'plan': _plan, 'error_code': 'exception'});
      if (mounted) _toast(s.t('purchase_error'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final ok = await UnifiedSubscriptionService().restorePurchases();
      if (!mounted) return;
      AnalyticsService.logEvent('restore_result', parameters: {'success': ok ? 1 : 0});
      if (ok) {
        await UnifiedSubscriptionService().syncFromRevenueCat();
        _toast(widget.s.t('restored_ok'));
        await widget.onPurchased();
      } else {
        _toast(widget.s.t('restored_none'));
      }
    } catch (e) {
      AnalyticsService.logEvent('restore_result', parameters: {'success': 0, 'error_code': 'exception'});
      if (mounted) _toast(widget.s.t('purchase_error'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final trial = _hasTrial(_plan);
    final cta = trial
        ? s.t('cta_trial')
        : (_plan == 'annual' ? s.t('cta_annual_paid') : (_plan == 'monthly' ? s.t('cta_monthly') : s.t('cta_weekly')));
    final foot = trial
        ? s.t('foot_annual', {'p': _price('annual')})
        : (_plan == 'annual'
            ? s.t('foot_annual_paid', {'p': _price('annual')})
            : (_plan == 'monthly' ? s.t('foot_monthly', {'p': _price('monthly')}) : s.t('foot_weekly', {'p': _price('weekly')})));

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: OnbColors.paper,
        body: Stack(
          children: [
            const Positioned.fill(child: OnbBackground(scene: false)),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(context.vw(6), context.vh(2.4), context.vw(6), context.vh(2)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    WipeText(s.t('offer_title'), style: OnbText.display(context, 7.8)),
                    SizedBox(height: context.vh(1.8)),
                    Expanded(
                      child: ShaderMask(
                        shaderCallback: (rect) => const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black, Colors.black, Colors.transparent],
                          stops: [0, 0.94, 1],
                        ).createShader(rect),
                        blendMode: BlendMode.dstIn,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.only(bottom: context.vh(3)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              PopIn(
                                  delay: const Duration(milliseconds: 250),
                                  child: _LockedWeek(s: s, mealsPerDay: widget.mealsPerDay, workoutDays: widget.workoutDays, trial: trial)),
                              SizedBox(height: context.vh(1.6)),
                              Text(widget.goalLine ?? s.t('offer_oneliner', {'day': widget.bilanDayName}),
                                  textAlign: TextAlign.center, style: OnbText.body(context, 3.4, color: OnbColors.mute, height: 1.45)),
                              SizedBox(height: context.vh(2.2)),
                              PopIn(delay: const Duration(milliseconds: 400), child: _Timeline(s: s, trial: trial, price: _price(_plan))),
                              SizedBox(height: context.vh(2.2)),
                              PopIn(
                                delay: const Duration(milliseconds: 520),
                                child: _loadFailed
                                    ? _StoreError(s: s, onRetry: _busy ? null : _load)
                                    : Column(
                                        children: [
                                          for (final (i, plan) in _plans.indexed)
                                            if (_showPlan(plan)) ...[
                                              if (i > 0) SizedBox(height: context.vw(1.8)),
                                              _PlanRow(
                                                name: s.t('plan_$plan'),
                                                sub: s.t('plan_${plan}_sub'),
                                                price: _price(plan),
                                                unit: plan == 'annual' ? s.t('plan_annual_eq', {'p': _monthlyEquivalent()}) : s.t('plan_${plan}_unit'),
                                                badge: plan == 'annual' && _hasTrial('annual') ? s.t('badge_trial') : null,
                                                selected: _plan == plan,
                                                onTap: () {
                                                  AnalyticsService.logEvent('paywall_plan_selected', parameters: {'plan': plan});
                                                  setState(() => _plan = plan);
                                                },
                                              ),
                                            ],
                                        ],
                                      ),
                              ),
                              SizedBox(height: context.vh(1.8)),
                              // restore + the two legal links App Review expects on a subscription screen
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _link(context, s.t('restore'), _busy ? null : _restore),
                                  _dot(context),
                                  _link(context, s.t('legal_terms'), () => _open(s.lang == 'fr' ? 'https://coach-ryze.com/terms.html' : 'https://coach-ryze.com/terms_en.html')),
                                  _dot(context),
                                  _link(context, s.t('legal_privacy'), () => _open(s.lang == 'fr' ? 'https://coach-ryze.com/privacy.html' : 'https://coach-ryze.com/privacy_en.html')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: context.vh(1.2)),
                    PopIn(
                      delay: const Duration(milliseconds: 600),
                      child: _busy
                          ? Container(
                              height: context.vw(14),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: OnbColors.acc, borderRadius: BorderRadius.circular(999)),
                              child: SizedBox(
                                  width: context.vw(5), height: context.vw(5), child: const CircularProgressIndicator(strokeWidth: 2.5, color: OnbColors.ink)),
                            )
                          : OnbButton(label: cta, gold: true, onPressed: _purchase),
                    ),
                    SizedBox(height: context.vh(1)),
                    Text(foot, textAlign: TextAlign.center, style: OnbText.body(context, 3.1, color: OnbColors.mute, height: 1.5)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _link(BuildContext context, String text, VoidCallback? onTap) => TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: context.vw(1.5), vertical: context.vw(2)), minimumSize: Size.zero),
      child: Text(text, style: OnbText.body(context, 3.1, color: OnbColors.mute).copyWith(decoration: TextDecoration.underline)),
    );

Widget _dot(BuildContext context) => Text('·', style: OnbText.body(context, 3.1, color: OnbColors.mute2));

/// The store did not answer: say it and offer to retry, never show a phantom price.
class _StoreError extends StatelessWidget {
  const _StoreError({required this.s, required this.onRetry});
  final OnbStrings s;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.vw(4)),
      decoration: BoxDecoration(color: OnbColors.surf, borderRadius: BorderRadius.circular(context.vw(4)), border: Border.all(color: OnbColors.line)),
      child: Column(
        children: [
          Text(s.t('store_unavailable'), textAlign: TextAlign.center, style: OnbText.body(context, 3.5, color: OnbColors.mute, height: 1.4)),
          SizedBox(height: context.vw(2)),
          TextButton(onPressed: onRetry, child: Text(s.t('retry'), style: OnbText.body(context, 3.6, weight: FontWeight.w600, color: OnbColors.ink))),
        ],
      ),
    );
  }
}

/// Seven-column week preview in the planner's own visual language, behind a veil.
class _LockedWeek extends StatelessWidget {
  const _LockedWeek({required this.s, required this.mealsPerDay, required this.workoutDays, this.trial = true});
  final bool trial;
  final OnbStrings s;
  final List<int> mealsPerDay;
  final Set<int> workoutDays;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final hasData = mealsPerDay.any((m) => m > 0) || workoutDays.isNotEmpty;
    const navy = Color(0xFF0B132B);

    Widget slot(IconData icon, bool on, {bool workout = false}) => Container(
          width: context.vw(7),
          height: context.vw(7),
          decoration: BoxDecoration(
            color: on ? (workout ? navy : Colors.white) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(context.vw(1.8)),
            border: Border.all(color: on ? (workout ? navy : navy.withValues(alpha: 0.3)) : const Color(0xFFE2E8F0)),
          ),
          child: on ? Icon(icon, size: context.vw(3.6), color: workout ? Colors.white : navy) : null,
        );

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(context.vw(4.6)), border: Border.all(color: OnbColors.line)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 2.2, sigmaY: 2.2),
            child: Padding(
              padding: EdgeInsets.all(context.vw(3)),
              child: Row(
                children: [
                  for (var d = 0; d < 7; d++) ...[
                    if (d > 0) SizedBox(width: context.vw(1)),
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(vertical: context.vw(1), horizontal: context.vw(1.4)),
                            decoration: BoxDecoration(
                                border: Border.all(color: d == now.weekday - 1 ? navy : Colors.transparent, width: 2),
                                borderRadius: BorderRadius.circular(context.vw(2))),
                            child: Column(
                              children: [
                                Text(s.dayShort[d],
                                    style: OnbText.body(context, 2.7, weight: FontWeight.w600, color: const Color(0xFF64748B), height: 1)),
                                SizedBox(height: context.vw(0.5)),
                                Text('${monday.add(Duration(days: d)).day}',
                                    style: OnbText.body(context, 3.5, weight: FontWeight.w700, color: navy, height: 1)),
                              ],
                            ),
                          ),
                          SizedBox(height: context.vw(1.2)),
                          slot(LucideIcons.sunrise, hasData ? mealsPerDay[d] >= 1 : true),
                          SizedBox(height: context.vw(1.2)),
                          slot(LucideIcons.sun, hasData ? mealsPerDay[d] >= 2 : true),
                          SizedBox(height: context.vw(1.2)),
                          slot(LucideIcons.sunset, hasData ? mealsPerDay[d] >= 3 : true),
                          SizedBox(height: context.vw(1.2)),
                          slot(LucideIcons.dumbbell, hasData ? workoutDays.contains(d) : (d == 0 || d == 2 || d == 4), workout: true),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [OnbColors.paper.withValues(alpha: 0.2), OnbColors.paper.withValues(alpha: 0.75)]),
              ),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: context.vw(4), vertical: context.vw(2.4)),
                  decoration: BoxDecoration(
                    color: OnbColors.ink,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [BoxShadow(color: OnbColors.ink.withValues(alpha: 0.5), blurRadius: context.vw(3.6), offset: Offset(0, context.vw(1.4)))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.lock, size: context.vw(3.8), color: Colors.white),
                      SizedBox(width: context.vw(2)),
                      Text(s.t(trial ? 'offer_veil' : 'offer_veil_paid'), style: OnbText.body(context, 3.4, weight: FontWeight.w600, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.s, this.trial = true, this.price = ''});
  final OnbStrings s;
  final bool trial;
  final String price;

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, String title, String sub, {bool now = false, bool last = false}) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: context.vw(7),
                  height: context.vw(7),
                  decoration: BoxDecoration(
                    color: now ? OnbColors.acc : OnbColors.surf,
                    shape: BoxShape.circle,
                    border: Border.all(color: now ? OnbColors.acc : OnbColors.line),
                    boxShadow: now ? [BoxShadow(color: OnbColors.accTint, spreadRadius: context.vw(0.9))] : null,
                  ),
                  child: Icon(icon, size: context.vw(3.4), color: now ? OnbColors.onAcc : OnbColors.mute),
                ),
                if (!last) Container(width: 1.5, height: context.vw(6), color: OnbColors.line),
              ],
            ),
            SizedBox(width: context.vw(3.2)),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: context.vw(0.9), bottom: context.vw(2.4)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: OnbText.body(context, 3.5, weight: FontWeight.w600, height: 1.2)),
                    SizedBox(height: context.vw(0.3)),
                    Text(sub, style: OnbText.body(context, 3, color: OnbColors.mute, height: 1.35)),
                  ],
                ),
              ),
            ),
          ],
        );
    if (!trial) {
      // no trial on this plan: one honest line, billed today
      return Column(children: [item(LucideIcons.creditCard, s.t('tl_now'), s.t('tl_paid_now_sub', {'p': price}), now: true, last: true)]);
    }
    return Column(
      children: [
        item(LucideIcons.lockOpen, s.t('tl_now'), s.t('tl_now_sub'), now: true),
        item(LucideIcons.bell, s.t('tl_2'), s.t('tl_2_sub')),
        item(LucideIcons.creditCard, s.t('tl_3'), s.t('tl_3_sub'), last: true),
      ],
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.name, required this.sub, required this.price, required this.unit, required this.selected, required this.onTap, this.badge});
  final String name;
  final String sub;
  final String price;
  final String unit;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : OnbColors.ink;
    final muted = selected ? Colors.white.withValues(alpha: 0.7) : OnbColors.mute;
    return GestureDetector(
      onTap: () {
        HapticService.instance.lightImpact();
        onTap();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: OnbCurves.spring,
            padding: EdgeInsets.symmetric(horizontal: context.vw(4), vertical: context.vw(3.6)),
            decoration: BoxDecoration(
              color: selected ? OnbColors.ink : OnbColors.surf,
              borderRadius: BorderRadius.circular(context.vw(4.2)),
              border: Border.all(color: selected ? OnbColors.ink : OnbColors.line),
              boxShadow:
                  selected ? [BoxShadow(color: OnbColors.ink.withValues(alpha: 0.5), blurRadius: context.vw(3.6), offset: Offset(0, context.vw(1.4)))] : null,
            ),
            child: Row(
              children: [
                Container(
                  width: context.vw(5.6),
                  height: context.vw(5.6),
                  decoration: BoxDecoration(
                      color: selected ? Colors.white : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: selected ? Colors.white : OnbColors.ink.withValues(alpha: 0.2), width: 1.5)),
                  child: selected
                      ? Center(
                          child: Container(
                              width: context.vw(2.6), height: context.vw(2.6), decoration: const BoxDecoration(color: OnbColors.ink, shape: BoxShape.circle)))
                      : null,
                ),
                SizedBox(width: context.vw(3)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: OnbText.body(context, 3.9, weight: FontWeight.w600, color: fg, height: 1.2)),
                      SizedBox(height: context.vw(0.4)),
                      Text(sub, style: OnbText.body(context, 3, color: muted, height: 1.2)),
                    ],
                  ),
                ),
                SizedBox(width: context.vw(2)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(price, style: OnbText.display(context, 4.6, color: fg, letterSpacingEm: -0.02, height: 1.1)),
                    Text(unit, style: OnbText.body(context, 2.9, color: muted, height: 1.2)),
                  ],
                ),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: -context.vw(2.2),
              right: context.vw(4),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: context.vw(2.4), vertical: context.vw(0.8)),
                decoration: BoxDecoration(color: OnbColors.acc, borderRadius: BorderRadius.circular(999)),
                child: Text(badge!, style: OnbText.body(context, 2.7, weight: FontWeight.w600, color: OnbColors.onAcc, height: 1.2)),
              ),
            ),
        ],
      ),
    );
  }
}
