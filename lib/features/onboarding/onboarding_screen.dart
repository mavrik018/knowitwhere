import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../../widgets/mascot.dart';

/// First-launch hero: "Never lose it again" and the squirrel mascot.
/// Shown once; [onDone] records that and opens the app.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.night,
        // Onboarding keeps its own fixed look: pin the inherited text and
        // icon defaults so app-wide theme (ScreenUtil) sizes don't leak in.
        body: DefaultTextStyle.merge(
          style: const TextStyle(
            fontSize: 14,
            height: 1.43,
            letterSpacing: 0.25,
          ),
          child: IconTheme.merge(
            data: const IconThemeData(size: 24),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, viewport) {
                  final height = viewport.maxHeight;
                  // Scale the hero to the screen so small phones fit without
                  // scrolling; very large text still scrolls.
                  final titleSize = (height * 0.075).clamp(44.0, 64.0);
                  final stageHeight = (height * 0.50).clamp(220.0, 500.0);
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: height),
                      child: IntrinsicHeight(
                        // On iPad keep the phone composition in a centred
                        // column; narrower screens are unaffected.
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 560),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                20,
                                24,
                                24,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _HeroTitle(fontSize: titleSize),
                                  const Spacer(),
                                  SizedBox(
                                    height: stageHeight,
                                    child: const _MascotStage(),
                                  ),
                                  const SizedBox(height: 24),
                                  FilledButton(
                                    onPressed: onDone,
                                    // Pinned so theme changes don't alter onboarding.
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size.fromHeight(56),
                                      textStyle: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                          ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    child: const Text('Get started'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// NEVER / LOSE / IT AGAIN, one or two words per line, "LOSE" in orange.
class _HeroTitle extends StatelessWidget {
  const _HeroTitle({required this.fontSize});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: AppColors.cream,
      fontSize: fontSize,
      height: 0.98,
      fontWeight: FontWeight.w900,
      letterSpacing: -fontSize * 0.023,
    );
    final mark = fontSize / 64;
    return Semantics(
      header: true,
      label: 'Never lose it again',
      excludeSemantics: true,
      // Display type: grows a little with Dynamic Type, not 3x.
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NEVER', style: style),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LOSE', style: style.copyWith(color: AppColors.orange)),
                  const SizedBox(width: 6),
                  CustomPaint(
                    size: Size.square(34 * mark),
                    painter: const _Sparkle(),
                  ),
                ],
              ),
              Text('IT AGAIN', style: style),
              SizedBox(height: 10 * mark),
              CustomPaint(
                size: Size(190 * mark, 16 * mark),
                painter: const _Squiggle(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The squirrel with a speech bubble and a soft orange glow. Sized with
/// fractions of the space it gets (no LayoutBuilder), so the parent
/// SliverFillRemaining can measure it.
class _MascotStage extends StatelessWidget {
  const _MascotStage();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        Align(
          alignment: Alignment(1.3, 1),
          child: FractionallySizedBox(
            heightFactor: 0.95,
            child: AspectRatio(
              aspectRatio: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x55F4632A), Color(0x00F4632A)],
                  ),
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: FractionallySizedBox(
            heightFactor: 0.92,
            child: Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Mascot(),
            ),
          ),
        ),
        Align(
          alignment: Alignment(-1, -0.55),
          child: SizedBox(
            width: 180,
            child: _SpeechBubble('I’ll remember where you put it!'),
          ),
        ),
      ],
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 13,
          height: 1.25,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Three short strokes radiating up and to the right.
class _Sparkle extends CustomPainter {
  const _Sparkle();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.orange
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final origin = Offset(size.width * 0.1, size.height * 0.95);
    for (final angle in [-80.0, -45.0, -10.0]) {
      final rad = angle * math.pi / 180;
      final dir = Offset(math.cos(rad), math.sin(rad));
      canvas.drawLine(
        origin + dir * size.width * 0.45,
        origin + dir * size.width * 0.85,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_Sparkle oldDelegate) => false;
}

/// Hand-drawn style wavy underline.
class _Squiggle extends CustomPainter {
  const _Squiggle();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(2, size.height / 2);
    const waves = 6;
    final step = (size.width - 4) / waves;
    for (var i = 0; i < waves; i++) {
      final x = 2 + i * step;
      path.quadraticBezierTo(
        x + step / 2,
        i.isEven ? 0 : size.height,
        x + step,
        size.height / 2,
      );
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_Squiggle oldDelegate) => false;
}
