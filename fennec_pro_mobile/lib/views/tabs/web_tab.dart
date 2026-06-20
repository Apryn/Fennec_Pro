import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../theme/cyber_theme.dart';
import '../../main.dart';

class WebTab extends StatefulWidget {
  const WebTab({super.key});

  @override
  State<WebTab> createState() => _WebTabState();
}

class _WebTabState extends State<WebTab> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _loadingProgress = 0.0;
  int _lastExecutedSignalId = 0;

  @override
  void initState() {
    super.initState();
    
    // Add listener to trading state for signal execution
    FennecState.trading.addListener(_onTradingStateChanged);

    // Initialize WebViewController to load Olymp Trade Platform
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(CyberTheme.background)
      ..addJavaScriptChannel(
        'FennecBridge',
        onMessageReceived: (JavaScriptMessage message) {
          final parts = message.message.split(':');
          final eventType = parts[0];
          if (eventType == 'BALANCE_UPDATE') {
            final balance = int.tryParse(parts[1]) ?? 0;
            FennecState.trading.updateAccountBalance(balance);
          } else if (eventType == 'RESULT_DETECTED') {
            final result = parts[1];
            if (result == 'WIN') {
              FennecState.trading.simulateWin();
            } else if (result == 'LOSS') {
              FennecState.trading.simulateLoss();
            }
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress / 100.0;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            // Inject Anti-Ban Security script
            _injectAntiBanBridge();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint("Webview loading error: ${error.description}");
          },
        ),
      )
      ..loadRequest(Uri.parse('https://olymptrade.com/platform'));
  }

  @override
  void dispose() {
    FennecState.trading.removeListener(_onTradingStateChanged);
    super.dispose();
  }

  void _onTradingStateChanged() {
    final trading = FennecState.trading;
    if (trading.isAutoTradingActive && trading.signalId > _lastExecutedSignalId) {
      _lastExecutedSignalId = trading.signalId;
      _executeAutoTrade(trading.lastSignalDirection ?? "UP", trading.nextTrade);
    }
  }

  void _executeAutoTrade(String direction, int nominal) {
    _controller.runJavaScript(
      'if (window.fennecExecuteClick) { window.fennecExecuteClick("$direction", $nominal); }'
    );
  }

  void _injectAntiBanBridge() {
    const String bridgeScript = r"""
(function() {
  console.log("Fennec Pro Anti-Ban Security Bridge Loaded.");

  // 1. Monitor Account Balance
  function checkBalance() {
    const balanceElements = document.querySelectorAll('[class*="balance"], [class*="account-balance"], [data-test="balance"]');
    for (let el of balanceElements) {
      const text = el.textContent || "";
      if (text.includes("Rp") || text.includes("$") || /[0-9]/.test(text)) {
        const balanceVal = parseInt(text.replace(/[^0-9]/g, '')) || 0;
        if (balanceVal > 0) {
          FennecBridge.postMessage("BALANCE_UPDATE:" + balanceVal);
          break;
        }
      }
    }
  }

  const balanceObserver = new MutationObserver(checkBalance);
  balanceObserver.observe(document.body, { childList: true, subtree: true });
  checkBalance();

  // 2. Monitor Transaction Results (WIN/LOSS)
  const historyObserver = new MutationObserver((mutations) => {
    for (let mutation of mutations) {
      for (let node of mutation.addedNodes) {
        if (node.nodeType === 1) {
          const text = node.textContent || "";
          if (text.includes("Profit") || text.includes("Menang") || text.includes("Victory") || text.includes("Win")) {
            FennecBridge.postMessage("RESULT_DETECTED:WIN");
          } else if (text.includes("Rugi") || text.includes("Loss") || text.includes("Kalah")) {
            FennecBridge.postMessage("RESULT_DETECTED:LOSS");
          }
        }
      }
    }
  });
  historyObserver.observe(document.body, { childList: true, subtree: true });

  // 3. Humanized Event Dispatcher (Anti-Ban mouse simulation)
  window.fennecExecuteClick = function(direction, nominal) {
    console.log("Fennec Bridge triggering: " + direction + " with size " + nominal);

    // Enter Nominal
    let amountInput = document.querySelector('input[data-test="deal-amount-input"], [class*="deal-amount"] input');
    if (amountInput) {
      amountInput.focus();
      amountInput.value = nominal;
      amountInput.dispatchEvent(new Event('input', { bubbles: true }));
      amountInput.blur();
    }

    // Select Button based on direction
    let button;
    if (direction === 'UP') {
      button = document.querySelector('button[data-test="button-call"], [class*="button-call"], .button-up');
    } else {
      button = document.querySelector('button[data-test="button-put"], [class*="button-put"], .button-down');
    }

    if (!button) {
      console.error("Fennec could not find the call/put button selector.");
      return;
    }

    // Generate random human delay (1.5s - 3.5s) to avoid bot detection
    const randomDelay = Math.floor(Math.random() * 2000) + 1500;
    setTimeout(() => {
      const rect = button.getBoundingClientRect();
      const clickX = rect.left + (rect.width * (0.3 + Math.random() * 0.4));
      const clickY = rect.top + (rect.height * (0.3 + Math.random() * 0.4));

      // Trigger hover
      button.dispatchEvent(new MouseEvent('mouseenter', { bubbles: true, clientX: clickX, clientY: clickY }));
      button.dispatchEvent(new MouseEvent('mouseover', { bubbles: true, clientX: clickX, clientY: clickY }));

      // Click sequence
      setTimeout(() => {
        button.dispatchEvent(new MouseEvent('mousedown', { bubbles: true, clientX: clickX, clientY: clickY, button: 0 }));
        button.focus();
        button.dispatchEvent(new MouseEvent('mouseup', { bubbles: true, clientX: clickX, clientY: clickY, button: 0 }));
        button.click();
        console.log("Fennec automated click injected at (" + clickX + ", " + clickY + ")");
      }, 150);

    }, randomDelay);
  };
})();
""";
    _controller.runJavaScript(bridgeScript);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Simulated Web Browser Header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'OLYMP TRADE PLATFORM',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ),
              ),
              if (_isLoading)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(CyberTheme.neonYellow),
                  ),
                ),
            ],
          ),
        ),
        
        // URL Bar widget
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: CyberTheme.cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CyberTheme.borderDark, width: 1.0),
          ),
          child: const Row(
            children: [
              Icon(Icons.lock, size: 12, color: CyberTheme.neonGreen),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'https://olymptrade.com/platform',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: CyberTheme.colorTextSecondary, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),

        // Loading Linear Progress Bar
        if (_isLoading)
          LinearProgressIndicator(
            value: _loadingProgress,
            backgroundColor: CyberTheme.background,
            valueColor: const AlwaysStoppedAnimation<Color>(CyberTheme.neonGreen),
            minHeight: 2.0,
          ),
          
        const SizedBox(height: 4),

        // Native WebView Widget
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CyberTheme.borderDark, width: 1.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: WebViewWidget(controller: _controller),
            ),
          ),
        ),
      ],
    );
  }
}
