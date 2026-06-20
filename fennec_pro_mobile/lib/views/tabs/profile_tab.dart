import 'package:flutter/material.dart';
import '../../theme/cyber_theme.dart';
import '../../main.dart';
import '../../controllers/trading_controller.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = FennecState.auth;
    final tradingController = FennecState.trading;

    return ListenableBuilder(
      listenable: authController,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Text(
                'PROFIL TRADER',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ),
              ),
            ),
            const Divider(color: CyberTheme.borderDark, thickness: 1.0),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: CyberTheme.standardCardDecoration(),
                  child: Column(
                    children: [
                      // Large custom avatar
                      ListenableBuilder(
                        listenable: tradingController,
                        builder: (context, child) {
                          final Color color = tradingController.activeAccentColor;
                          return Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [color, CyberTheme.neonBlue],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.4),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'TR',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Profile items
                      _buildDetailRow('Trader ID Olymp Trade', authController.currentTraderId),
                      _buildBadgeRow('Status Lisensi', 'VIP FENNEC ACCESS'),
                      _buildDetailRow('Affiliate Sub-ID', 'MY_SPECIFIC_SUB_ID', isAmber: true),
                      _buildDetailRow('Metode Koneksi', 'API Automated Websocket'),
                      
                      const SizedBox(height: 30),
                      
                      // Deactivation button
                      ElevatedButton(
                        onPressed: () {
                          // Double check validation or confirm log out
                          authController.deactivate();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CyberTheme.neonRed.withOpacity(0.1),
                          foregroundColor: CyberTheme.neonRed,
                          side: const BorderSide(color: CyberTheme.neonRed, width: 1.0),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const SizedBox(
                          width: double.infinity,
                          child: Text(
                            'KELUAR / DEAKTIVASI',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isAmber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: CyberTheme.colorTextMuted)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isAmber ? CyberTheme.neonYellow : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeRow(String label, String badgeText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: CyberTheme.colorTextMuted)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: CyberTheme.neonGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: CyberTheme.neonGreen.withOpacity(0.3), width: 1),
            ),
            child: Text(
              badgeText,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: CyberTheme.neonGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
