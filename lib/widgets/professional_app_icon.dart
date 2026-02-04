import 'package:flutter/material.dart';

class ProfessionalAppIcon extends StatefulWidget {
  final double size;
  final bool animate;

  const ProfessionalAppIcon({
    super.key,
    this.size = 128.0,
    this.animate = true,
  });

  @override
  ProfessionalAppIconState createState() => ProfessionalAppIconState();
}

class ProfessionalAppIconState extends State<ProfessionalAppIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _barAnimation;
  late Animation<double> _arrowAnimation;

  @override
  void initState() {
    super.initState();

    if (widget.animate) {
      _controller = AnimationController(
        duration: const Duration(seconds: 3),
        vsync: this,
      )..repeat();

      _barAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

      _arrowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A2540), Color(0xFF1a3a5a)],
        ),
        borderRadius: BorderRadius.circular(widget.size / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Inner circle
          Positioned.fill(
            child: Container(
              margin: EdgeInsets.all(widget.size * 0.05),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(widget.size),
              ),
            ),
          ),

          // Shine effect
          Positioned(
            top: widget.size * 0.1,
            left: widget.size * 0.1,
            child: Container(
              width: widget.size * 0.4,
              height: widget.size * 0.2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(widget.size),
              ),
            ),
          ),

          // Finance chart
          Align(
            alignment: Alignment.center,
            child: Container(
              width: widget.size * 0.6,
              height: widget.size * 0.6,
              padding: EdgeInsets.all(widget.size * 0.1),
              child: CustomPaint(
                size: Size.infinite,
                painter: _FinanceChartPainter(
                  animation: widget.animate ? _barAnimation : null,
                  arrowAnimation: widget.animate ? _arrowAnimation : null,
                ),
              ),
            ),
          ),

          // Currency symbols
          Positioned(
            bottom: widget.size * 0.15,
            left: widget.size * 0.2,
            child: Opacity(
              opacity: 0.6,
              child: Text(
                '\$',
                style: TextStyle(
                  fontSize: widget.size * 0.12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: widget.size * 0.15,
            right: widget.size * 0.2,
            child: Opacity(
              opacity: 0.6,
              child: Text(
                '₹',
                style: TextStyle(
                  fontSize: widget.size * 0.12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceChartPainter extends CustomPainter {
  final Animation<double>? animation;
  final Animation<double>? arrowAnimation;

  _FinanceChartPainter({this.animation, this.arrowAnimation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final basePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final arrowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Base platform
    final baseRect = Rect.fromLTWH(0, size.height - 10, size.width, 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(baseRect, const Radius.circular(4)),
      basePaint,
    );

    // Animation values
    final barHeight1 = animation != null
        ? (80 + (20 * animation!.value)).toDouble()
        : 90.0;
    final barHeight2 = animation != null
        ? (120 + (20 * animation!.value)).toDouble()
        : 130.0;
    final barHeight3 = animation != null
        ? (160 + (20 * animation!.value)).toDouble()
        : 170.0;

    // Left bar
    final bar1Rect = Rect.fromLTWH(
      20,
      size.height - barHeight1 - 10,
      20,
      barHeight1,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bar1Rect, const Radius.circular(4)),
      paint,
    );

    // Middle bar
    final bar2Rect = Rect.fromLTWH(
      50,
      size.height - barHeight2 - 10,
      20,
      barHeight2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bar2Rect, const Radius.circular(4)),
      paint,
    );

    // Right bar
    final bar3Rect = Rect.fromLTWH(
      80,
      size.height - barHeight3 - 10,
      20,
      barHeight3,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bar3Rect, const Radius.circular(4)),
      paint,
    );

    // Upward arrow
    final arrowOpacity = arrowAnimation?.value ?? 1.0;
    if (arrowOpacity > 0) {
      final arrowPath = Path()
        ..moveTo(45, 20)
        ..lineTo(75, -10)
        ..lineTo(105, 20)
        ..moveTo(75, -10)
        ..lineTo(75, -40);

      canvas.save();
      canvas.translate(0, 0);
      canvas.drawPath(
        arrowPath,
        arrowPaint..color = Colors.white.withValues(alpha: arrowOpacity),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

// Preview widget for testing the icon
class ProfessionalAppIconPreview extends StatelessWidget {
  const ProfessionalAppIconPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2540),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Professional App Icon'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ProfessionalAppIcon(size: 200),
            const SizedBox(height: 40),
            const Text(
              'FinFlow',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Professional Finance Management',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
