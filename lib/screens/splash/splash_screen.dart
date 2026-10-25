import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/app_state.dart';
import '../../services/ad_service.dart';
import '../../services/app_open_ad_service.dart';
import '../../services/home_bootstrap.dart';
import '../home/home_shell.dart';

/// Boots the app: keeps splash fully visible while warming home, then
/// crossfades into [HomeShell] on the same stack (no white flash).
class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> with SingleTickerProviderStateMixin {
  static const _minDisplay = Duration(milliseconds: 2200);
  static const _transition = Duration(milliseconds: 820);

  late final AnimationController _transitionController;
  bool _showHome = false;

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(vsync: this, duration: _transition);
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareAndGo());
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  Future<void> _prepareAndGo() async {
    final started = DateTime.now();
    // Policy order: consent + SDK → request app-open (8s window).
    // Interstitial is prefetched after app-open, not shown here.
    final adsWarmup = () async {
      await AdService.instance.ensureReady();
      if (AdService.instance.canRequestAds) {
        await AppOpenAdManager.instance.loadAd();
      }
    }();

    try {
      final appState = context.read<AppState>();

      while (appState.loading) {
        await Future.delayed(const Duration(milliseconds: 40));
        if (!mounted) return;
        if (DateTime.now().difference(started) > const Duration(seconds: 3)) {
          break;
        }
      }

      try {
        await HomeBootstrap.preload(appState).timeout(
          const Duration(seconds: 3),
        );
      } catch (_) {}

      final elapsed = DateTime.now().difference(started);
      if (elapsed < _minDisplay) {
        await Future.delayed(_minDisplay - elapsed);
      }
      if (!mounted) return;

      final spent = DateTime.now().difference(started);
      final remaining = spent >= const Duration(seconds: 8)
          ? Duration.zero
          : const Duration(seconds: 8) - spent;

      if (remaining > Duration.zero) {
        try {
          await adsWarmup.timeout(remaining);
        } catch (_) {}
      }

      if (!mounted) return;
      if (!AdService.instance.isPro && AdService.instance.canRequestAds) {
        final left =
            const Duration(seconds: 8) - DateTime.now().difference(started);
        await AppOpenAdManager.instance.showAdIfAvailable(
          loadTimeout: left > Duration.zero
              ? left
              : const Duration(milliseconds: 500),
        );
      }
    } catch (_) {}
    if (!mounted) return;

    // After splash/app-open: warm interstitial for the next natural break.
    unawaited(AdService.instance.prefetchInterstitial());

    setState(() => _showHome = true);
    await _transitionController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final splashFade = CurvedAnimation(
      parent: _transitionController,
      curve: const Interval(0.0, 0.72, curve: Curves.easeInOutCubic),
    );
    final homeFade = CurvedAnimation(
      parent: _transitionController,
      curve: const Interval(0.18, 1.0, curve: Curves.easeOutCubic),
    );
    final homeSlide = CurvedAnimation(
      parent: _transitionController,
      curve: const Interval(0.18, 1.0, curve: Curves.easeOutCubic),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF120528),
      body: Stack(
        fit: StackFit.expand,
        children: [
          FadeTransition(
            opacity: Tween<double>(begin: 1, end: 0).animate(splashFade),
            child: const IgnorePointer(child: SplashView()),
          ),
          if (_showHome)
            FadeTransition(
              opacity: Tween<double>(begin: 0, end: 1).animate(homeFade),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.035),
                  end: Offset.zero,
                ).animate(homeSlide),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.985, end: 1).animate(homeSlide),
                  child: const ColoredBox(
                    color: AppColors.background,
                    child: HomeShell(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Visual splash only — navigation is owned by [AppEntry].
class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF120528),
            Color(0xFF1F0B4D),
            Color(0xFF3A148C),
            Color(0xFF5B21B6),
          ],
          stops: [0.0, 0.35, 0.72, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _AmbientOrbs(),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 4),
                const _BrandMark(),
                const SizedBox(height: 28),
                Text(
                  AppConstants.appName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    height: 1.1,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 420.ms, duration: 550.ms)
                    .slideY(
                      begin: 0.25,
                      end: 0,
                      delay: 420.ms,
                      duration: 550.ms,
                      curve: Curves.easeOutCubic,
                    ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 28,
                  child: DefaultTextStyle(
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.4,
                    ),
                    child: AnimatedTextKit(
                      isRepeatingAnimation: false,
                      totalRepeatCount: 1,
                      animatedTexts: [
                        TyperAnimatedText(
                          AppConstants.appTagline,
                          speed: const Duration(milliseconds: 42),
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 700.ms, duration: 450.ms),
                const Spacer(flex: 3),
                const SpinKitThreeBounce(
                  color: Colors.white,
                  size: 18,
                )
                    .animate()
                    .fadeIn(delay: 950.ms, duration: 500.ms)
                    .slideY(
                      begin: 0.4,
                      end: 0,
                      delay: 950.ms,
                      duration: 500.ms,
                      curve: Curves.easeOut,
                    ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 72),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: const LinearProgressIndicator(
                      minHeight: 3,
                      backgroundColor: Color(0x33FFFFFF),
                      color: Color(0xFFFBBF24),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 1050.ms, duration: 450.ms)
                    .scaleX(
                      begin: 0.35,
                      end: 1,
                      delay: 1050.ms,
                      duration: 450.ms,
                      curve: Curves.easeOutCubic,
                    ),
                const SizedBox(height: 44),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientOrbs extends StatelessWidget {
  const _AmbientOrbs();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: _GlowOrb(
              size: 220,
              colors: [
                const Color(0xFFF59E0B).withValues(alpha: 0.28),
                Colors.transparent,
              ],
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(0.92, 0.92),
                  end: const Offset(1.08, 1.08),
                  duration: 3200.ms,
                  curve: Curves.easeInOut,
                )
                .fade(
                  begin: 0.55,
                  end: 0.95,
                  duration: 3200.ms,
                ),
          ),
          Positioned(
            bottom: 80,
            left: -50,
            child: _GlowOrb(
              size: 260,
              colors: [
                const Color(0xFFA855F7).withValues(alpha: 0.30),
                Colors.transparent,
              ],
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1.05, 1.05),
                  end: const Offset(0.9, 0.9),
                  duration: 3800.ms,
                  curve: Curves.easeInOut,
                )
                .move(
                  begin: Offset.zero,
                  end: const Offset(18, -12),
                  duration: 3800.ms,
                ),
          ),
          Align(
            alignment: const Alignment(0, -0.12),
            child: _GlowOrb(
              size: 320,
              colors: [
                const Color(0xFFFBBF24).withValues(alpha: 0.16),
                const Color(0xFF9333EA).withValues(alpha: 0.08),
                Colors.transparent,
              ],
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fade(begin: 0.45, end: 0.9, duration: 2600.ms),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 178,
      height: 178,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(42),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.22),
            blurRadius: 48,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(42),
        child: Image.asset(
          AppConstants.appIconAsset,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 650.ms, curve: Curves.easeOut)
        .scale(
          begin: const Offset(0.72, 0.72),
          end: const Offset(1, 1),
          duration: 900.ms,
          curve: Curves.easeOutBack,
        )
        .then()
        .shimmer(
          delay: 200.ms,
          duration: 1400.ms,
          color: Colors.white.withValues(alpha: 0.28),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.035, 1.035),
          duration: 2200.ms,
          curve: Curves.easeInOut,
        );
  }
}
