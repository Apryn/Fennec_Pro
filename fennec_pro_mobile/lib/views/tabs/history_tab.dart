import 'package:flutter/material.dart';
import '../../theme/cyber_theme.dart';
import '../../main.dart';
import '../../controllers/trading_controller.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  String _selectedFilter = 'ALL';

  void _copySummary(BuildContext context, TradingController controller) {
    final logs = controller.historyLogs;
    final totalTrades = logs.where((log) => log['result'] == 'WIN' || log['result'] == 'LOSS').length;
    final totalWins = logs.where((log) => log['result'] == 'WIN').length;
    final totalLosses = logs.where((log) => log['result'] == 'LOSS').length;
    final winRate = totalTrades == 0 ? 0.0 : (totalWins / totalTrades) * 100;
    
    // Net profit
    int netProfit = 0;
    for (var log in logs) {
      netProfit += (log['profitChange'] as int? ?? 0);
    }
    
    final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: '${controller.currencySymbol} ', decimalDigits: 0);
    final formattedProfit = (netProfit >= 0 ? "+" : "") + currencyFormatter.format(netProfit);

    final summary = """
📊 LAPORAN TRADING FENNEC PRO 📊
────────────────────────
📈 Win Rate: ${winRate.toStringAsFixed(1)}%
🔄 Total Trade: $totalTrades
🟢 Menang (WIN): $totalWins
🔴 Kalah (LOSS): $totalLosses
💰 Sesi Profit/Loss: $formattedProfit

Sent via Fennec Pro Bot 🚀
""";

    Clipboard.setData(ClipboardData(text: summary.trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Laporan trading berhasil disalin! 🚀'),
        backgroundColor: controller.activeAccentColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final bool isSelected = _selectedFilter == value;
    final tradingController = FennecState.trading;
    final themeColor = tradingController.activeAccentColor;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.black : CyberTheme.colorTextSecondary,
        ),
      ),
      selected: isSelected,
      showCheckmark: false,
      selectedColor: themeColor,
      backgroundColor: const Color(0xFF1E222D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? themeColor : CyberTheme.borderDark,
          width: 1,
        ),
      ),
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _selectedFilter = value;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tradingController = FennecState.trading;
    final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: '${tradingController.currencySymbol} ', decimalDigits: 0);

    return ListenableBuilder(
      listenable: tradingController,
      builder: (context, child) {
        final logs = tradingController.historyLogs;

        // Calculate analytics stats
        final totalTrades = logs.where((log) => log['result'] == 'WIN' || log['result'] == 'LOSS').length;
        final totalWins = logs.where((log) => log['result'] == 'WIN').length;
        final totalLosses = logs.where((log) => log['result'] == 'LOSS').length;
        final winRate = totalTrades == 0 ? 0.0 : (totalWins / totalTrades) * 100;

        // Filter logs
        final filteredLogs = logs.where((log) {
          if (_selectedFilter == 'ALL') return true;
          return log['result'] == _selectedFilter;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'RIWAYAT TRANSAKSI',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                  if (logs.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.copy_all, color: CyberTheme.colorTextSecondary, size: 20),
                      tooltip: 'Salin Ringkasan',
                      onPressed: () => _copySummary(context, tradingController),
                    ),
                ],
              ),
            ),
            const Divider(color: CyberTheme.borderDark, thickness: 1.0),
            
            // Filter Chips Row
            if (logs.isNotEmpty) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      _buildFilterChip('ALL', 'Semua'),
                      const SizedBox(width: 8),
                      _buildFilterChip('WIN', 'WIN'),
                      const SizedBox(width: 8),
                      _buildFilterChip('LOSS', 'LOSS'),
                      const SizedBox(width: 8),
                      _buildFilterChip('OPEN', 'PENDING'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],

            // Premium analytics panel
            if (logs.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: CyberTheme.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CyberTheme.borderDark, width: 1.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text(
                          'WIN RATE',
                          style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: CyberTheme.colorTextMuted, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${winRate.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: winRate >= 50.0 ? CyberTheme.neonGreen : CyberTheme.neonYellow,
                          ),
                        ),
                      ],
                    ),
                    Container(width: 1, height: 28, color: CyberTheme.borderDark),
                    _buildStatCol('TOTAL TRADE', '$totalTrades'),
                    Container(width: 1, height: 28, color: CyberTheme.borderDark),
                    _buildStatCol('WIN / LOSS', '$totalWins W / $totalLosses L'),
                  ],
                ),
              ),
            ],

            Expanded(
              child: filteredLogs.isEmpty
                  ? Center(
                      child: Text(
                        _selectedFilter == 'ALL'
                            ? 'Belum ada transaksi simulasi'
                            : 'Tidak ada transaksi dengan status $_selectedFilter',
                        style: const TextStyle(color: CyberTheme.colorTextMuted),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredLogs.length,
                      itemBuilder: (context, index) {
                        final item = filteredLogs[index];
                        final isWin = item['result'] == "WIN";
                        final isPending = item['result'] == "OPEN";
                        final diff = item['profitChange'] as int;
                        final formattedDiff = (diff >= 0 ? "+" : "") + currencyFormatter.format(diff);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: CyberTheme.cardBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isPending
                                  ? CyberTheme.neonYellow.withOpacity(0.3)
                                  : (isWin
                                      ? CyberTheme.neonGreen.withOpacity(0.3)
                                      : CyberTheme.neonRed.withOpacity(0.3)),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['asset'] ?? 'Asset',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Pukul ${item['time']} • Trade: ${currencyFormatter.format(item['tradeSize'])}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: CyberTheme.colorTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                isPending ? 'PENDING' : '${item['result']} ($formattedDiff)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isPending
                                      ? CyberTheme.neonYellow
                                      : (isWin ? CyberTheme.neonGreen : CyberTheme.neonRed),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCol(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: CyberTheme.colorTextMuted, letterSpacing: 0.8),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
