import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sales_odoo_app/core/di/injection.dart';
import 'package:sales_odoo_app/core/network/session_manager.dart';

/// Splash animation for the 2S Home Wear logo  (~3s)
///
///  1. The vertical line draws top -> bottom (it is the symmetry axis)
///  2. "2" and "S" fade in together
///  3. HOME then WEAR rise out of an invisible mask line
///  4. Whole logo settles with a very subtle scale, then navigate
class SplashScreen extends StatefulWidget {
  final String? nextRoute;

  const SplashScreen({super.key, this.nextRoute});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _dir = 'assets/images';
  static const _layers = ['two', 's', 'line', 'home', 'wear'];

  // Positions inside the 1920x1920 canvas, as fractions (0..1).
  static const _lineTop = 0.158;
  static const _lineBottom = 0.648;
  static const _textMaskTop = 0.74;
  static const _textMaskBottom = 0.885;

  late final AnimationController _c;
  late final Animation<double> _line;
  late final Animation<double> _letters;
  late final Animation<double> _home;
  late final Animation<double> _wear;
  late final Animation<double> _settle;

  Animation<double> _t(double a, double b, Curve curve) => CurvedAnimation(
    parent: _c,
    curve: Interval(a, b, curve: curve),
  );

  @override
  void initState() {
    super.initState();

    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _line = _t(0.00, 0.25, Curves.easeInOutCubic);
    _letters = _t(0.22, 0.58, Curves.easeInOut);
    _home = _t(0.55, 0.80, Curves.easeOutCubic);
    _wear = _t(0.65, 0.90, Curves.easeOutCubic);
    _settle = _t(0.00, 1.00, Curves.easeOutCubic);

    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final bool isTestEnv = WidgetsBinding.instance.runtimeType
        .toString()
        .contains('Test');
    if (!isTestEnv) {
      try {
        await Future.wait([
          for (final n in _layers)
            precacheImage(AssetImage('$_dir/$n.png'), context),
        ]);
      } catch (_) {
        // Gracefully handle precaching errors
      }
    }

    if (!mounted) return;

    await _c.forward();

    await Future.delayed(const Duration(milliseconds: 350));

    if (!mounted) return;

    final session = sl<SessionManager>().currentUser;
    final targetRoute =
        widget.nextRoute ?? (session != null ? '/home' : '/login');

    context.go(targetRoute);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _img(String name, double size) {
    return Image.asset('$_dir/$name.png', width: size, height: size);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final size = (w * 0.6).clamp(0.0, 360.0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            // Vertical line: top -> bottom.
            final lineBottom =
                _lineTop + (_lineBottom - _lineTop) * _line.value;

            final line = ClipRect(
              clipper: _RectClipper(
                (s) => Rect.fromLTWH(0, 0, s.width, s.height * lineBottom),
              ),
              child: _img('line', size),
            );

            // "2" and "S": fade in together.
            final l = _letters.value.clamp(0.0, 1.0);

            final two = Opacity(opacity: l, child: _img('two', size));

            final sLetter = Opacity(opacity: l, child: _img('s', size));

            // HOME / WEAR: rise from behind a mask line.
            Widget word(String name, Animation<double> a) {
              return ClipRect(
                clipper: _RectClipper(
                  (s) => Rect.fromLTRB(
                    0,
                    s.height * _textMaskTop,
                    s.width,
                    s.height * _textMaskBottom,
                  ),
                ),
                child: FractionalTranslation(
                  translation: Offset(0, 0.14 * (1 - a.value)),
                  child: Opacity(
                    opacity: a.value.clamp(0.0, 1.0),
                    child: _img(name, size),
                  ),
                ),
              );
            }

            return Transform.scale(
              scale: 0.96 + 0.04 * _settle.value,
              child: SizedBox(
                width: size,
                height: size,
                child: Stack(
                  children: [
                    two,
                    sLetter,
                    line,
                    word('home', _home),
                    word('wear', _wear),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RectClipper extends CustomClipper<Rect> {
  _RectClipper(this.rect);

  final Rect Function(Size) rect;

  @override
  Rect getClip(Size size) => rect(size);

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => true;
}
