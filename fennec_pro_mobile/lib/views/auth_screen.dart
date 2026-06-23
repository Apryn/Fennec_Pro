import 'package:flutter/material.dart';
import '../theme/cyber_theme.dart';
import '../main.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _traderIdController = TextEditingController();

  @override
  void dispose() {
    _traderIdController.dispose();
    super.dispose();
  }

  void _handleActivate() {
    final id = _traderIdController.text;
    FennecState.auth.activate(id);
  }

  @override
  Widget build(BuildContext context) {
    final authController = FennecState.auth;

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: authController,
          builder: (context, child) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Fennec Fox custom vector logo
                    Container(
                      height: 140,
                      alignment: Alignment.center,
                      child: CustomPaint(
                        size: const Size(130, 130),
                        painter: FennecLogoPainter(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Titles
                    const Text(
                      'FENNEC PRO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'SECURE ACTIVATION',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4.0,
                        color: CyberTheme.neonGreen,
                        shadows: [
                          Shadow(
                            color: CyberTheme.neonGreen.withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Description
                    const Text(
                      'Masukkan Trader ID Olymp Trade Anda untuk mengaktifkan fitur otomatisasi Fennec Pro.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: CyberTheme.colorTextSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Trader ID input
                    const Text(
                      'TRADER ID OLYMP TRADE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: CyberTheme.colorTextMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _traderIdController,
                      keyboardType: TextInputType.number,
                      maxLength: 15,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        counterText: "",
                        hintText: "Contoh: 88888",
                        hintStyle: const TextStyle(color: CyberTheme.colorTextMuted),
                        fillColor: CyberTheme.cardBg,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: CyberTheme.neonGreen, width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: CyberTheme.borderDark, width: 1.0),
                        ),
                      ),
                      onChanged: (val) {
                        if (authController.authError != null) {
                          authController.clearError();
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Conditional Error Banners
                    if (authController.authError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: CyberTheme.neonRed.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: CyberTheme.neonRed, width: 1),
                        ),
                        child: Text(
                          authController.authError!,
                          style: const TextStyle(
                            color: Color(0xFFFF8A80),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    // Activate Button
                    ElevatedButton(
                      onPressed: _handleActivate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CyberTheme.neonGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                        shadowColor: CyberTheme.neonGreen.withValues(alpha: 0.4),
                      ),
                      child: const Text(
                        'AKTIVASI SEKARANG',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Footer details
                    const Text(
                      'Powered by Fennec Engine v4.2 • Secure SSL',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        color: CyberTheme.colorTextMuted,
                      ),
                    ),
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

// Custom painter to render the gorgeous geometric Cyber Fennec Fox face
class FennecLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);

    final Paint paint = Paint()..style = PaintingStyle.fill;
    final Paint strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 1. Draw Ear Left (Golden-amber Gradient)
    final Path earLeft = Path()
      ..moveTo(center.dx, h * 0.45)
      ..lineTo(w * 0.15, h * 0.15)
      ..lineTo(w * 0.35, h * 0.48)
      ..close();
    
    final Gradient earGradLeft = LinearGradient(
      colors: [CyberTheme.neonYellow, CyberTheme.background.withValues(alpha: 0.1)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    paint.shader = earGradLeft.createShader(Rect.fromLTWH(w * 0.15, h * 0.15, w * 0.35, h * 0.33));
    canvas.drawPath(earLeft, paint);
    strokePaint.color = CyberTheme.neonYellow;
    canvas.drawPath(earLeft, strokePaint);

    // 2. Draw Ear Right (Golden-amber Gradient)
    final Path earRight = Path()
      ..moveTo(center.dx, h * 0.45)
      ..lineTo(w * 0.85, h * 0.15)
      ..lineTo(w * 0.65, h * 0.48)
      ..close();
    
    final Gradient earGradRight = LinearGradient(
      colors: [CyberTheme.neonYellow, CyberTheme.background.withValues(alpha: 0.1)],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    );
    paint.shader = earGradRight.createShader(Rect.fromLTWH(w * 0.5, h * 0.15, w * 0.35, h * 0.33));
    canvas.drawPath(earRight, paint);
    strokePaint.color = CyberTheme.neonYellow;
    canvas.drawPath(earRight, strokePaint);

    // Remove shader for solid colors
    paint.shader = null;

    // 3. Draw Inner Ears Accent (Semi-transparent Electric Red)
    paint.color = CyberTheme.neonRed.withValues(alpha: 0.6);
    final Path innerEarLeft = Path()
      ..moveTo(w * 0.48, h * 0.45)
      ..lineTo(w * 0.25, h * 0.24)
      ..lineTo(w * 0.38, h * 0.47)
      ..close();
    canvas.drawPath(innerEarLeft, paint);

    final Path innerEarRight = Path()
      ..moveTo(w * 0.52, h * 0.45)
      ..lineTo(w * 0.75, h * 0.24)
      ..lineTo(w * 0.62, h * 0.47)
      ..close();
    canvas.drawPath(innerEarRight, paint);

    // 4. Draw Face Core Triangle (Solid Dark, Neon Green Outline)
    paint.color = CyberTheme.cardBg;
    final Path face = Path()
      ..moveTo(center.dx, h * 0.78)
      ..lineTo(w * 0.30, h * 0.48)
      ..lineTo(w * 0.70, h * 0.48)
      ..close();
    canvas.drawPath(face, paint);
    
    strokePaint.color = CyberTheme.neonGreen;
    strokePaint.strokeWidth = 2.0;
    canvas.drawPath(face, strokePaint);

    // 5. Draw Muzzle (Solid Neon Green nose triangle)
    paint.color = CyberTheme.neonGreen;
    final Path nose = Path()
      ..moveTo(center.dx, h * 0.78)
      ..lineTo(w * 0.43, h * 0.65)
      ..lineTo(w * 0.57, h * 0.65)
      ..close();
    canvas.drawPath(nose, paint);

    // 6. Draw Glowing Eyes (Neon Green small polygons)
    final Path eyeLeft = Path()
      ..moveTo(w * 0.38, h * 0.53)
      ..lineTo(w * 0.45, h * 0.55)
      ..lineTo(w * 0.42, h * 0.50)
      ..close();
    canvas.drawPath(eyeLeft, paint);

    final Path eyeRight = Path()
      ..moveTo(w * 0.62, h * 0.53)
      ..lineTo(w * 0.55, h * 0.55)
      ..lineTo(w * 0.58, h * 0.50)
      ..close();
    canvas.drawPath(eyeRight, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
