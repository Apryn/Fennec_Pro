import 'package:flutter/material.dart';
import '../../theme/cyber_theme.dart';
import '../../main.dart';
import 'package:intl/intl.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final tradingController = FennecState.trading;
    final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return ListenableBuilder(
      listenable: tradingController,
      builder: (context, child) {
        final logs = tradingController.historyLogs;

        // Calculate analytics stats
        final totalTrades = logs.where((log) => log['result'] == 'WIN' || log['result'] == 'LOSS').length;
        final totalWins = logs.where((log) => log['result'] == 'WIN').length;
        final totalLosses = logs.where((log) => log['result'] == 'LOSS').length;
        final winRate = totalTrades == 0 ? 0.0 : (totalWins / totalTrades) * 100;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Text(
                'RIWAYAT TRANSAKSI',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ),
              ),
            ),
            const Divider(color: CyberTheme.borderDark, thickness: 1.0),
            const SizedBox(height: 6),

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
              child: logs.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada transaksi simulasi',
                        style: TextStyle(color: CyberTheme.colorTextMuted),
                      ),
                    )
                  : ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final item = logs[index];
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
                                  ? CyberTheme.neonYellow.withValues(alpha: 0.3)
                                  : (isWin
                                      ? CyberTheme.neonGreen.withValues(alpha: 0.3)
                                      : CyberTheme.neonRed.withValues(alpha: 0.3)),
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
