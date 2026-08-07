import 'package:flutter/material.dart';
import '../theme/cyber_theme.dart';
import '../main.dart';
import '../services/background_service.dart';
import '../services/config_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _traderIdController = TextEditingController();
  bool _showIdGuide = false;

  @override
  void dispose() {
    _traderIdController.dispose();
    super.dispose();
  }

  void _handleActivate() {
    final id = _traderIdController.text;
    SecmonState.auth.activate(id);
  }

  @override
  Widget build(BuildContext context) {
    final authController = SecmonState.auth;

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
                        painter: SecmonLogoPainter(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Titles
                    const Text(
                      'SECMON',
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
                            color: CyberTheme.neonGreen.withOpacity(0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Description
                    const Text(
                      'Masukkan Trader ID Olymp Trade Anda untuk mengaktifkan fitur otomatisasi Secmon.',
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
                    const SizedBox(height: 8),
                    
                    // Toggleable Guide Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showIdGuide = !_showIdGuide;
                            });
                          },
                          icon: Icon(
                            _showIdGuide ? Icons.expand_less : Icons.help_outline,
                            color: CyberTheme.neonGreen,
                            size: 14,
                          ),
                          label: Text(
                            _showIdGuide ? 'Tutup Panduan' : 'Bagaimana cara mencari Trader ID?',
                            style: const TextStyle(
                              color: CyberTheme.neonGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    
                    // Collapsible Guide UI
                    if (_showIdGuide) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CyberTheme.cardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: CyberTheme.borderDark, width: 1.0),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cara Menemukan Trader ID Anda:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              '1. Buka dan masuk ke platform Olymp Trade.\n'
                              '2. Tekan ikon Profil / Akun Anda di bar navigasi.\n'
                              '3. Trader ID Anda adalah nomor unik (5-15 digit angka) yang tertera tepat di bawah nama profil Anda.',
                              style: TextStyle(
                                color: CyberTheme.colorTextSecondary,
                                fontSize: 11,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    
                    // Conditional Error Banners
                    if (authController.authError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: CyberTheme.neonRed.withOpacity(0.15),
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
                      onPressed: authController.isLoading ? null : _handleActivate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CyberTheme.neonGreen,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: CyberTheme.neonGreen.withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                        shadowColor: CyberTheme.neonGreen.withOpacity(0.4),
                      ),
                      child: authController.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                              ),
                            )
                          : const Text(
                              'AKTIVASI SEKARANG',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        BotForegroundService.launchUrl(ConfigService.affiliateUrl);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CyberTheme.neonGreen,
                        side: const BorderSide(color: CyberTheme.neonGreen, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'DAFTAR',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        BotForegroundService.launchUrl(ConfigService.supportUrl);
                      },
                      icon: const Icon(Icons.support_agent, size: 18),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CyberTheme.neonBlue,
                        side: const BorderSide(color: CyberTheme.neonBlue, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      label: const Text(
                        'HUBUNGI CS / SUPPORT (TELEGRAM)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Risk Disclaimer
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: CyberTheme.borderDark, width: 0.8),
                      ),
                      child: const Text(
                        '⚠️ PERINGATAN RISIKO: Secmon adalah sistem otomatisasi analisa. Trading pasar finansial mengandung risiko modal. Gunakan manajemen risiko dan modal secara bijak.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: CyberTheme.colorTextMuted,
                          height: 1.4,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Footer details
                    const Text(
                      'Powered by Secmon Engine v4.2 • Secure SSL',
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

// Custom painter to render the ultra premium thick Secmon 'S' Pulse emblem
class SecmonLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);

    final Paint glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = CyberTheme.neonGreen.withOpacity(0.40)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final Paint linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Shader lineShader = const LinearGradient(
      colors: [CyberTheme.neonGreen, CyberTheme.neonBlue],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    linePaint.shader = lineShader;

    // Bold & Thick 'S' Pulse Wave
    final Path sPulse = Path()
      ..moveTo(w * 0.78, h * 0.26)
      ..lineTo(w * 0.32, h * 0.26)
      ..lineTo(w * 0.22, h * 0.46)
      ..lineTo(center.dx, h * 0.50)
      ..lineTo(w * 0.78, h * 0.54)
      ..lineTo(w * 0.68, h * 0.74)
      ..lineTo(w * 0.22, h * 0.74);

    // Draw glowing background stroke
    canvas.drawPath(sPulse, glowPaint);
    // Draw sharp front stroke
    canvas.drawPath(sPulse, linePaint);

    // Precision pulse dot in center with halo
    final Paint dotHalo = Paint()
      ..style = PaintingStyle.fill
      ..color = CyberTheme.neonGreen.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(Offset(center.dx, h * 0.50), 7.0, dotHalo);

    final Paint dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = CyberTheme.neonGreen;
    canvas.drawCircle(Offset(center.dx, h * 0.50), 5.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
