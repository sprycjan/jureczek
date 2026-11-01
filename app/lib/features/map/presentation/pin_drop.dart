import 'package:flutter/material.dart';

/// Wysokość, z której spada nowa pinezka – nad palcem, który ją postawił.
const pinDropLift = 80.0;

/// Wysokość jedynego odbicia po uderzeniu w mapę.
const pinDropBounce = 14.0;

const _dropDuration = Duration(milliseconds: 450);

/// Część animacji do pierwszego uderzenia w mapę (waga spadku w [_height]).
const _impactAt = 0.6;

/// Spadek, jedno odbicie i ponowne lądowanie; wartość to wysokość nad punktem.
final _height = TweenSequence<double>([
  TweenSequenceItem(
    tween: Tween(
      begin: pinDropLift,
      end: 0.0,
    ).chain(CurveTween(curve: Curves.easeInQuad)),
    weight: _impactAt * 100,
  ),
  TweenSequenceItem(
    tween: Tween(
      begin: 0.0,
      end: pinDropBounce,
    ).chain(CurveTween(curve: Curves.easeOutQuad)),
    weight: 20,
  ),
  TweenSequenceItem(
    tween: Tween(
      begin: pinDropBounce,
      end: 0.0,
    ).chain(CurveTween(curve: Curves.easeInQuad)),
    weight: 20,
  ),
]);

/// Nowa pinezka spadająca na mapę. Leży w [Stack] nad mapą, a dolny środek
/// obrazka ląduje w [anchor]. Przy uderzeniu w mapę woła [onImpact],
/// a po odbiciu – [onLanded].
class PinDrop extends StatefulWidget {
  const PinDrop({
    super.key,
    required this.image,
    required this.anchor,
    required this.size,
    required this.onImpact,
    required this.onLanded,
  });

  /// Ten sam obiekt dla wszystkich spadających pinezek, żeby obrazek
  /// był zdekodowany zawczasu (`precacheImage`), a nie w pierwszych klatkach.
  final ImageProvider image;
  final Offset anchor;
  final Size size;
  final VoidCallback onImpact;
  final VoidCallback onLanded;

  @override
  State<PinDrop> createState() => _PinDropState();
}

class _PinDropState extends State<PinDrop> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: _dropDuration,
  );
  late final _fadeIn = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.2),
  );

  @override
  void initState() {
    super.initState();
    _controller.addListener(_checkImpact);
    _controller.forward().then((_) => widget.onLanded());
  }

  void _checkImpact() {
    if (_controller.value < _impactAt) return;
    _controller.removeListener(_checkImpact);
    widget.onImpact();
  }

  @override
  void dispose() {
    _fadeIn.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return Positioned(
      left: widget.anchor.dx - size.width / 2,
      top: widget.anchor.dy - size.height,
      width: size.width,
      height: size.height,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, -_height.evaluate(_controller)),
            child: child,
          ),
          child: FadeTransition(
            opacity: _fadeIn,
            child: Image(image: widget.image, gaplessPlayback: true),
          ),
        ),
      ),
    );
  }
}
