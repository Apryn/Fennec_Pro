import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../theme/cyber_theme.dart';
import '../main.dart';
import '../controllers/trading_controller.dart';
import 'tabs/history_tab.dart';
import 'tabs/web_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/personalise_tab.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    // For breathing fade animation of the status banner
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
      lowerBound: 0.45,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _openConfigModal(BuildContext context) {
    final trading = FennecState.trading;
    final formatter = NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0);

    final baseController = TextEditingController(text: formatter.format(trading.baseTrade).trim());
    final martController = TextEditingController(text: formatter.format(trading.martingaleTrade).trim());
    final multiplierController = TextEditingController(text: '${trading.martingaleMultiplierPercent}%');
    final takeProfitController = TextEditingController(text: formatter.format(trading.takeProfitLimit).trim());
    final minBalanceController = TextEditingController(text: formatter.format(trading.minimumBalanceGuard).trim());

    bool localAutoDemo = trading.isAutoDemo;
    bool localAutoTrading = trading.isAutoTradingActive;
    String localMaxMart = trading.maxMartingaleLevels;
    String localResetMart = trading.resetMartingaleLevel;
    String localStopLoss = trading.stopLossLimit;

    int parseFormattedInt(String input) {
      final clean = input.replaceAll(RegExp(r'[^0-9]'), '');
      return int.tryParse(clean) ?? 0;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: CyberTheme.borderDark, width: 1.0),
              ),
              backgroundColor: CyberTheme.cardBg,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text(
                              'Konfigurasi Trading',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Simpan pengaturan sebelum menjalankan bot',
                          style: TextStyle(fontSize: 9, color: CyberTheme.colorTextMuted.withOpacity(0.85), fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: CyberTheme.colorTextMuted, size: 16),
                  ),
                ],
              ),
              content: SizedBox(
                width: 330,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Switch auto demo
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Beralih otomatis ke demo',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Pindah ke demo saat loss sesuai stop loss, kembali saat menang',
                                  style: TextStyle(fontSize: 7.5, color: CyberTheme.colorTextMuted.withOpacity(0.8)),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: localAutoDemo,
                            activeColor: CyberTheme.neonYellow,
                            onChanged: (val) {
                              setDialogState(() {
                                localAutoDemo = val;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Switch auto trade (Full Automation)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Otomatisasi Eksekusi (Auto-Trade)',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Klik otomatis UP/DOWN langsung di market dengan sistem jeda acak anti-ban',
                                  style: TextStyle(fontSize: 7.5, color: CyberTheme.colorTextMuted.withOpacity(0.8)),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: localAutoTrading,
                            activeColor: CyberTheme.neonYellow,
                            onChanged: (val) {
                              setDialogState(() {
                                localAutoTrading = val;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Nominal Transaksi Section (Base & Soft Martingale)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.015),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'NOMINAL TRANSAKSI SIMULASI',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w900, color: CyberTheme.colorTextMuted, letterSpacing: 0.8),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Base Trade', style: TextStyle(fontSize: 9, color: CyberTheme.colorTextMuted, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      TextField(
                                        controller: baseController,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [ThousandsSeparatorInputFormatter()],
                                        style: const TextStyle(fontSize: 11, color: Colors.white),
                                        decoration: InputDecoration(
                                          prefixText: 'Rp ',
                                          prefixStyle: const TextStyle(color: Colors.white70, fontSize: 11),
                                          fillColor: const Color(0xFF131722),
                                          filled: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Soft Martingale', style: TextStyle(fontSize: 9, color: CyberTheme.colorTextMuted, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      TextField(
                                        controller: martController,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [ThousandsSeparatorInputFormatter()],
                                        style: const TextStyle(fontSize: 11, color: Colors.white),
                                        decoration: InputDecoration(
                                          prefixText: 'Rp ',
                                          prefixStyle: const TextStyle(color: Colors.white70, fontSize: 11),
                                          fillColor: const Color(0xFF131722),
                                          filled: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Two Columns (Manajemen Risiko vs Kalkulator Martingale)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column: Manajemen Risiko
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Manajemen Risiko',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 3),
                                const Divider(color: CyberTheme.borderDark, height: 1),
                                const SizedBox(height: 8),

                                const Text('Martingale', style: TextStyle(fontSize: 9, color: CyberTheme.colorTextMuted, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: multiplierController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [PercentInputFormatter()],
                                  style: const TextStyle(fontSize: 11, color: Colors.white),
                                  decoration: InputDecoration(
                                    fillColor: const Color(0xFF131722),
                                    filled: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                const Text('Reset Martingale', style: TextStyle(fontSize: 9, color: CyberTheme.colorTextMuted, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  value: localResetMart,
                                  dropdownColor: CyberTheme.cardBg,
                                  style: const TextStyle(fontSize: 11, color: Colors.white),
                                  decoration: InputDecoration(
                                    fillColor: const Color(0xFF131722),
                                    filled: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                                  ),
                                  items: ['off', '1', '2', '3', '4', '5'].map((val) {
                                    return DropdownMenuItem<String>(
                                      value: val,
                                      child: Text(val),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setDialogState(() {
                                        localResetMart = val;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Right Column: Kalkulator Martingale
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Kalkulator Martingale',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 3),
                                const Divider(color: CyberTheme.borderDark, height: 1),
                                const SizedBox(height: 8),

                                const Text('Maks Martingale', style: TextStyle(fontSize: 9, color: CyberTheme.colorTextMuted, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  value: localMaxMart,
                                  dropdownColor: CyberTheme.cardBg,
                                  style: const TextStyle(fontSize: 11, color: Colors.white),
                                  decoration: InputDecoration(
                                    fillColor: const Color(0xFF131722),
                                    filled: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                                  ),
                                  items: ['always', '1', '2', '3', '4', '5', '6', '7', '8'].map((val) {
                                    return DropdownMenuItem<String>(
                                      value: val,
                                      child: Text(val == 'always' ? 'Always Signal' : val, style: const TextStyle(fontSize: 10.5)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setDialogState(() {
                                        localMaxMart = val;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 10),

                                const Text('Stop Loss', style: TextStyle(fontSize: 9, color: CyberTheme.colorTextMuted, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  value: localStopLoss,
                                  dropdownColor: CyberTheme.cardBg,
                                  style: const TextStyle(fontSize: 11, color: Colors.white),
                                  decoration: InputDecoration(
                                    fillColor: const Color(0xFF131722),
                                    filled: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                                  ),
                                  items: ['off', '1', '2', '3', '4', '5', '6', '7', '8'].map((val) {
                                    return DropdownMenuItem<String>(
                                      value: val,
                                      child: Text(val),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setDialogState(() {
                                        localStopLoss = val;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Take profit and min balance fields
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Hentikan profit setelah',
                                  style: TextStyle(fontSize: 9, color: CyberTheme.colorTextMuted, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: takeProfitController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                                  style: const TextStyle(fontSize: 11, color: Colors.white),
                                  decoration: InputDecoration(
                                    prefixText: 'Rp ',
                                    prefixStyle: const TextStyle(color: Colors.white70, fontSize: 11),
                                    fillColor: const Color(0xFF131722),
                                    filled: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Proteksi Saldo Minimum',
                                  style: TextStyle(fontSize: 9, color: CyberTheme.colorTextMuted, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: minBalanceController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                                  style: const TextStyle(fontSize: 11, color: Colors.white),
                                  decoration: InputDecoration(
                                    prefixText: 'Rp ',
                                    prefixStyle: const TextStyle(color: Colors.white70, fontSize: 11),
                                    fillColor: const Color(0xFF131722),
                                    filled: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(color: CyberTheme.colorTextSecondary, fontSize: 12)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final base = parseFormattedInt(baseController.text);
                    final mart = parseFormattedInt(martController.text);
                    final multiplier = parseFormattedInt(multiplierController.text);
                    final profitHalt = parseFormattedInt(takeProfitController.text);
                    final minBalance = parseFormattedInt(minBalanceController.text);

                    if (base > 0 && mart > 0 && multiplier > 0 && profitHalt > 0 && minBalance >= 0) {
                      trading.updateConfig(
                        base: base,
                        martingale: mart,
                        autoDemo: localAutoDemo,
                        multiplierPercent: multiplier,
                        maxMart: localMaxMart,
                        resetMart: localResetMart,
                        stopLoss: localStopLoss,
                        takeProfit: profitHalt,
                        autoTrading: localAutoTrading,
                        minBalance: minBalance,
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CyberTheme.neonYellow,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Simpan Pengaturan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final trading = FennecState.trading;
    final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0);

    return ListenableBuilder(
      listenable: trading,
      builder: (context, child) {
        // Prepare list of tab view pages
        final List<Widget> subpages = [
          _buildHomeDashboard(context, trading, currencyFormatter),
          const HistoryTab(),
          const WebTab(),
          const ProfileTab(),
          const PersonaliseTab(),
        ];

        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: IndexedStack(
                index: _currentIndex,
                children: subpages,
              ),
            ),
          ),
          bottomNavigationBar: Theme(
            data: Theme.of(context).copyWith(
              canvasColor: CyberTheme.cardBg,
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: trading.activeAccentColor,
              unselectedItemColor: CyberTheme.colorTextMuted,
              selectedFontSize: 9,
              unselectedFontSize: 9,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history_outlined),
                  activeIcon: Icon(Icons.history),
                  label: 'Riwayat',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.language_outlined),
                  activeIcon: Icon(Icons.language),
                  label: 'Web',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.palette_outlined),
                  activeIcon: Icon(Icons.palette),
                  label: 'Personalise',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHomeDashboard(BuildContext context, TradingController trading, NumberFormat formatter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // App header widget
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CustomPaint(
                  size: const Size(26, 26),
                  painter: HeaderLogoPainter(),
                ),
                const SizedBox(width: 8),
                const Text(
                  'FENNEC PRO',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF242933),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: CyberTheme.borderDark),
              ),
              child: const Row(
                children: [
                  StatusDot(color: CyberTheme.neonGreen),
                  SizedBox(width: 6),
                  Text(
                    'Server: Online',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Main Metrics Card (Rp Counter)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: CyberTheme.neonCardDecoration(
            accentColor: trading.isBotRunning ? trading.activeAccentColor : CyberTheme.borderDark,
            glowRadius: trading.glowStrength,
            showGlow: trading.isBotRunning,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trading.isDemoWallet
                    ? 'PROFIT HARI INI (DEMO WALLET)'
                    : 'PROFIT HARI INI (REAL WALLET)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: trading.isDemoWallet
                      ? CyberTheme.neonYellow
                      : CyberTheme.colorTextMuted,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'Rp',
                    style: TextStyle(
                      fontSize: trading.highContrastMode ? 20 : 16,
                      fontWeight: FontWeight.bold,
                      color: trading.activeAccentColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      formatter.format(trading.profit),
                      overflow: TextOverflow.ellipsis,
                      style: CyberTheme.digitalStyle(
                        fontSize: trading.highContrastMode ? 34 : 30,
                        color: trading.activeAccentColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: CyberTheme.borderDark, height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Trade Berikutnya:',
                    style: TextStyle(fontSize: 11, color: CyberTheme.colorTextSecondary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: trading.isMartingaleActive
                            ? CyberTheme.neonYellow.withOpacity(0.3)
                            : trading.activeAccentColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      'Rp ${formatter.format(trading.nextTrade)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: trading.isMartingaleActive ? CyberTheme.neonYellow : trading.activeAccentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Runtime grid (2 Columns)
        Row(
          children: [
            Expanded(
              child: _buildGridCard('Jam Sekarang', trading.liveTime),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGridCard('Durasi Berjalan', trading.formatDuration()),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Status banner
        AnimatedBuilder(
          animation: _fadeController,
          builder: (context, child) {
            return Opacity(
              opacity: trading.isBotRunning ? _fadeController.value : 1.0,
              child: child,
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF242933),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CyberTheme.borderDark),
            ),
            child: Row(
              children: [
                StatusDot(
                  color: trading.isBotRunning ? trading.activeAccentColor : CyberTheme.neonRed,
                  glow: trading.isBotRunning,
                ),
                const SizedBox(width: 10),
                Text(
                  trading.isBotRunning ? 'Status: Fennec sedang bekerja...' : 'Status: Fennec dihentikan.',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: CyberTheme.colorTextSecondary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Primary Control Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _openConfigModal(context),
                icon: const Icon(Icons.settings, size: 16, color: Colors.black),
                label: const Text('KONFIGURASI'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CyberTheme.neonYellow,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => trading.toggleBot(),
                icon: Icon(
                  trading.isBotRunning ? Icons.square : Icons.play_arrow,
                  size: 16,
                  color: trading.isBotRunning ? Colors.white : Colors.black,
                ),
                label: Text(trading.isBotRunning ? 'STOP BOT' : 'START BOT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: trading.isBotRunning ? CyberTheme.neonRed : CyberTheme.neonGreen,
                  foregroundColor: trading.isBotRunning ? Colors.white : Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
        
        const Spacer(),

        // Dev tools simulated win/loss triggers (DEBUG ONLY - hidden in release builds)
        if (kDebugMode) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1E28),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF424754), style: BorderStyle.none),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'DEVELOPER MODE (SIMULATION)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: CyberTheme.colorTextMuted, letterSpacing: 1.0),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: trading.isBotRunning ? () => trading.simulateWin() : null,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: CyberTheme.neonGreen.withOpacity(0.3)),
                          foregroundColor: CyberTheme.neonGreen,
                          backgroundColor: CyberTheme.neonGreen.withOpacity(0.05),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: const Text('Simulate WIN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: trading.isBotRunning ? () => trading.simulateLoss() : null,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: CyberTheme.neonRed.withOpacity(0.3)),
                          foregroundColor: CyberTheme.neonRed,
                          backgroundColor: CyberTheme.neonRed.withOpacity(0.05),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: const Text('Simulate LOSS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGridCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: CyberTheme.standardCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: CyberTheme.colorTextMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// Sub components
class StatusDot extends StatelessWidget {
  final Color color;
  final bool glow;
  const StatusDot({super.key, required this.color, this.glow = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: glow
            ? [
                BoxShadow(
                  color: color.withOpacity(0.8),
                  blurRadius: 6,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
    );
  }
}

// Vector mini logo painter for the dashboard header
class HeaderLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);

    final Paint paint = Paint()..style = PaintingStyle.fill;
    final Paint strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Face boundary triangle (Amber yellow outline, dark background)
    paint.color = CyberTheme.background;
    final Path face = Path()
      ..moveTo(center.dx, h * 0.85)
      ..lineTo(w * 0.15, h * 0.35)
      ..lineTo(w * 0.85, h * 0.35)
      ..close();
    canvas.drawPath(face, paint);
    
    strokePaint.color = CyberTheme.neonYellow;
    canvas.drawPath(face, strokePaint);

    // Muzzle triangle (Solid Neon Green)
    paint.color = CyberTheme.neonGreen;
    final Path nose = Path()
      ..moveTo(center.dx, h * 0.85)
      ..lineTo(w * 0.30, h * 0.55)
      ..lineTo(w * 0.70, h * 0.55)
      ..close();
    canvas.drawPath(nose, paint);

    // Forehead accent (Electric Red)
    paint.color = CyberTheme.neonRed;
    final Path forehead = Path()
      ..moveTo(w * 0.40, h * 0.45)
      ..lineTo(center.dx, h * 0.30)
      ..lineTo(w * 0.60, h * 0.45)
      ..close();
    canvas.drawPath(forehead, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Helper extension on Row to add space between children easily
extension RowSpacing on Row {
  Row get gap => Row(
        mainAxisAlignment: this.mainAxisAlignment,
        mainAxisSize: this.mainAxisSize,
        crossAxisAlignment: this.crossAxisAlignment,
        textDirection: this.textDirection,
        verticalDirection: this.verticalDirection,
        textBaseline: this.textBaseline,
        children: this.children.isNotEmpty
            ? (this.children
                .expand((child) => [child, SizedBox(width: this.gapWidth)])
                .toList()
                ..removeLast())
            : [],
      );

  double get gapWidth {
    if (this.children.isNotEmpty) {
      // Find spacing sizing from raw argument or use default
      return 12.0; // fallback default
    }
    return 0.0;
  }
}
// Helper expansion to add gaps to layouts
extension WidgetSpacing on Row {
  Row withSpacing(double width) {
    if (children.isEmpty) return this;
    List<Widget> spacedChildren = [];
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1) {
        spacedChildren.add(SizedBox(width: width));
      }
    }
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: textDirection,
      verticalDirection: verticalDirection,
      textBaseline: textBaseline,
      children: spacedChildren,
    );
  }
}

// Custom input formatter for thousand separator dots
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final clean = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final numValue = int.tryParse(clean);
    if (numValue == null) {
      return oldValue;
    }

    final formattedText = _formatter.format(numValue).trim();
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

// Custom input formatter to keep '%' sign at the end of the input
class PercentInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final clean = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) {
      return oldValue;
    }

    final formattedText = '$clean%';
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length - 1),
    );
  }
}

