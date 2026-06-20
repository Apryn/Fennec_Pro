import 'package:flutter/material.dart';
import '../../theme/cyber_theme.dart';
import '../../main.dart';
import '../../controllers/trading_controller.dart';

class PersonaliseTab extends StatelessWidget {
  const PersonaliseTab({super.key});

  @override
  Widget build(BuildContext context) {
    final tradingController = FennecState.trading;

    return ListenableBuilder(
      listenable: tradingController,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Text(
                'PERSONALISASI TAMPILAN',
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
              child: ListView(
                children: [
                  const Text(
                    'Ubah aksen neon visual dashboard untuk menyesuaikan dengan overlay live stream Anda.',
                    style: TextStyle(
                      fontSize: 13,
                      color: CyberTheme.colorTextSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Color Selector Grid
                  _buildSectionCard(
                    title: 'WARNA AKSEN UTAMA',
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.5,
                      children: [
                        _buildThemeButton(
                          tradingController,
                          label: 'Cyber Green',
                          colorKey: 'neon-green',
                          color: CyberTheme.neonGreen,
                        ),
                        _buildThemeButton(
                          tradingController,
                          label: 'Electric Blue',
                          colorKey: 'electric-blue',
                          color: CyberTheme.neonBlue,
                        ),
                        _buildThemeButton(
                          tradingController,
                          label: 'Hot Pink',
                          colorKey: 'hot-pink',
                          color: CyberTheme.neonPink,
                        ),
                        _buildThemeButton(
                          tradingController,
                          label: 'Toxic Purple',
                          colorKey: 'toxic-purple',
                          color: CyberTheme.neonPurple,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Glow Strength Slider
                  _buildSectionCard(
                    title: 'GLOW STRENGTH',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Slider(
                          value: tradingController.glowStrength,
                          min: 0.0,
                          max: 20.0,
                          activeColor: tradingController.activeAccentColor,
                          inactiveColor: CyberTheme.borderDark,
                          onChanged: (val) {
                            tradingController.setGlowStrength(val);
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Minimal', style: TextStyle(fontSize: 10, color: CyberTheme.colorTextMuted)),
                              Text(
                                '${tradingController.glowStrength.toInt()} px',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: tradingController.activeAccentColor,
                                ),
                              ),
                              const Text('Maksimal', style: TextStyle(fontSize: 10, color: CyberTheme.colorTextMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // High Contrast Mode Toggle
                  _buildSectionCard(
                    title: 'TIKTOK OVERLAY PREVIEW',
                    child: SwitchListTile(
                      title: const Text(
                        'High Contrast Stream Mode',
                        style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Memperbesar ukuran dan ketebalan teks agar lebih terlihat di layar HP penonton live stream.',
                        style: TextStyle(fontSize: 11, color: CyberTheme.colorTextMuted, height: 1.4),
                      ),
                      value: tradingController.highContrastMode,
                      activeColor: tradingController.activeAccentColor,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        tradingController.setHighContrast(val);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: CyberTheme.standardCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: CyberTheme.colorTextMuted,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildThemeButton(
    TradingController controller, {
    required String label,
    required String colorKey,
    required Color color,
  }) {
    final bool isActive = controller.activeThemeColor == colorKey;
    
    return InkWell(
      onTap: () {
        controller.setThemeColor(colorKey);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF242933),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? color : CyberTheme.borderDark,
            width: isActive ? 1.5 : 1.0,
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : CyberTheme.colorTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
