import 'package:flutter/material.dart';

class OrientationLogo extends StatefulWidget {
  final bool animate;
  final double fontSize;
  final double iconSize;
  final bool showAura;

  const OrientationLogo({
    super.key,
    this.animate = false,
    this.fontSize = 36,
    this.iconSize = 42,
    this.showAura = false,
  });

  @override
  State<OrientationLogo> createState() => _OrientationLogoState();
}

class _OrientationLogoState extends State<OrientationLogo>
    with TickerProviderStateMixin {
  AnimationController? _animController;
  AnimationController? _pulseController;

  Animation<double>? _iconScaleAnimation;
  Animation<double>? _textFadeAnimation;
  Animation<Offset>? _textSlideAnimation;
  Animation<double>? _shimmerAnimation;
  Animation<double>? _pulseAnimation;

  static const Color brandRed = Color(0xFFE50914);

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _initAnimations();
    }
  }

  void _initAnimations() {
    // 1. One-shot cinematic reveal animation
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _iconScaleAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController!,
        curve: const Interval(0.0, 0.42, curve: Curves.easeOutBack),
      ),
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController!,
        curve: const Interval(0.20, 0.55, curve: Curves.easeOut),
      ),
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(-0.18, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController!,
        curve: const Interval(0.20, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    _shimmerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController!,
        curve: const Interval(0.40, 0.88, curve: Curves.easeInOut),
      ),
    );

    // 2. Continuous subtle breathing glow for the icon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _pulseAnimation = Tween<double>(begin: 0.35, end: 0.95).animate(
      CurvedAnimation(
        parent: _pulseController!,
        curve: Curves.easeInOut,
      ),
    );

    _pulseController!.repeat(reverse: true);
    _animController!.forward();
  }

  @override
  void dispose() {
    _animController?.dispose();
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return _buildStaticLogo();
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_animController, _pulseController]),
      builder: (context, child) {
        final shimmerVal = _shimmerAnimation?.value ?? 0.0;
        final pulseVal = _pulseAnimation?.value ?? 0.5;

        final logoContent = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Play Button Icon "O" with scale & glow
            Transform.scale(
              scale: _iconScaleAnimation?.value ?? 1.0,
              child: PlayButtonIcon(
                size: widget.iconSize,
                glowIntensity: widget.showAura ? pulseVal : 0.0,
              ),
            ),
            // Text "rientation" with slide & fade
            SlideTransition(
              position: _textSlideAnimation ??
                  const AlwaysStoppedAnimation(Offset.zero),
              child: FadeTransition(
                opacity: _textFadeAnimation ??
                    const AlwaysStoppedAnimation(1.0),
                child: Text(
                  'rientation',
                  style: TextStyle(
                    color: brandRed,
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    height: 1.0,
                    shadows: [
                      Shadow(
                        color: brandRed.withValues(alpha: 0.4 * pulseVal),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );

        // Apply cinematic light sweep across entire logo during shimmer interval
        if (shimmerVal > 0.02 && shimmerVal < 0.98) {
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              final alignStart = -2.2 + shimmerVal * 4.4;
              return LinearGradient(
                begin: Alignment(alignStart, -0.6),
                end: Alignment(alignStart + 1.2, 0.6),
                colors: const [
                  Colors.transparent,
                  Color(0x22FFFFFF),
                  Color(0xDDFFFFFF),
                  Color(0x22FFFFFF),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
              ).createShader(bounds);
            },
            child: logoContent,
          );
        }

        return logoContent;
      },
    );
  }

  Widget _buildStaticLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        PlayButtonIcon(size: widget.iconSize),
        Text(
          'rientation',
          style: TextStyle(
            color: brandRed,
            fontSize: widget.fontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

class PlayButtonIcon extends StatelessWidget {
  final double size;
  final double glowIntensity;

  const PlayButtonIcon({
    super.key,
    this.size = 42,
    this.glowIntensity = 0.0,
  });

  static const Color brandRed = Color(0xFFE50914);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PlayButtonPainter(glowIntensity: glowIntensity),
      ),
    );
  }
}

class _PlayButtonPainter extends CustomPainter {
  final double glowIntensity;

  _PlayButtonPainter({this.glowIntensity = 0.0});

  static const Color brandRed = Color(0xFFE50914);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw ambient glow if animated
    if (glowIntensity > 0) {
      final glowPaint = Paint()
        ..color = brandRed.withValues(alpha: 0.45 * glowIntensity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 * glowIntensity);
      canvas.drawCircle(center, radius + (2 * glowIntensity), glowPaint);
    }

    // Draw the circle with subtle 3D gradient
    final circlePaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.25, -0.35),
        radius: 0.9,
        colors: [
          Color(0xFFFF2A36), // Vibrant highlight
          brandRed,
          Color(0xFFB0060E), // Deep shadow
        ],
        stops: [0.0, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, circlePaint);

    // Draw thin specular rim on top
    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius - 0.5, rimPaint);

    // Draw the play triangle
    final trianglePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final trianglePath = Path();

    // Calculate triangle points - slightly offset to the right for visual centering
    final triangleWidth = size.width * 0.35;
    final triangleHeight = size.height * 0.45;

    final leftX = center.dx - triangleWidth * 0.3;
    final rightX = center.dx + triangleWidth * 0.7;

    trianglePath.moveTo(leftX, center.dy - triangleHeight / 2);
    trianglePath.lineTo(rightX, center.dy);
    trianglePath.lineTo(leftX, center.dy + triangleHeight / 2);
    trianglePath.close();

    canvas.drawPath(trianglePath, trianglePaint);
  }

  @override
  bool shouldRepaint(covariant _PlayButtonPainter oldDelegate) =>
      oldDelegate.glowIntensity != glowIntensity;
}
