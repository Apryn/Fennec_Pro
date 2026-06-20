import 'package:flutter/material.dart';
import '../../theme/cyber_theme.dart';
import '../../main.dart';
import '../../controllers/trading_controller.dart';
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
            const SizedBox(height: 10),
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
                        final diff = item['profitChange'] as int;
                        final formattedDiff = (diff >= 0 ? "+" : "") + currencyFormatter.format(diff);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: CyberTheme.cardBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isWin
                                  ? CyberTheme.neonGreen.withOpacity(0.3)
                                  : CyberTheme.neonRed.withOpacity(0.3),
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
                                '${item['result']} ($formattedDiff)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isWin ? CyberTheme.neonGreen : CyberTheme.neonRed,
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
}
