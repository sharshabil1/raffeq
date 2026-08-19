import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BreathingOrb extends StatefulWidget {
  final double size;
  final bool isListening;

  const BreathingOrb({
    super.key,
    this.size = 78,
    this.isListening = false,
  });

  @override
  State<BreathingOrb> createState() => _BreathingOrbState();
}

class _BreathingOrbState extends State<BreathingOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.isListening
          ? const Duration(milliseconds: 1400)
          : const Duration(milliseconds: 4200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.07).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant BreathingOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isListening != widget.isListening) {
      _controller.duration = widget.isListening
          ? const Duration(milliseconds: 1400)
          : const Duration(milliseconds: 4200);
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isListening = widget.isListening;
    final gradientColors = isListening
        ? const [Color(0xFFF0C6C2), AppColors.rose, Color(0xFF9B4A4D)]
        : const [Color(0xFFDCB7D0), AppColors.plum, AppColors.plumDeep];

    final shadowColor = isListening
        ? AppColors.rose.withOpacity(0.3)
        : AppColors.plum.withOpacity(0.25);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.36, -0.44),
            radius: 0.85,
            colors: gradientColors,
            stops: const [0.0, 0.55, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 36,
              spreadRadius: 4,
            ),
            BoxShadow(
              color: (isListening ? AppColors.rose : AppColors.plum)
                  .withOpacity(0.12),
              blurRadius: 0,
              spreadRadius: 10,
            ),
          ],
        ),
      ),
    );
  }
}
