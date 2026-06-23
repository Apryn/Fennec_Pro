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
  String _loadedPlatformUrl = '';

  @override
  void initState() {
    super.initState();
    
    // Add listener to trading state for signal execution
    FennecState.trading.addListener(_onTradingStateChanged);

    _loadedPlatformUrl = FennecState.trading.platformUrl;

    // Initialize WebViewController to load Olymp Trade Platform
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent("Mozilla/5.0 (Linux; Android 13; SM-A205F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.3472.0 Mobile Safari/537.36")
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
          } else if (eventType == 'SELECTOR_ERROR') {
            debugPrint('[Fennec] ⚠️ Button selector failed for direction: ${parts[1]}. Update selectors in web_tab.dart.');
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
      ..loadRequest(Uri.parse('$_loadedPlatformUrl/platform'));
  }

  @override
  void dispose() {
    FennecState.trading.removeListener(_onTradingStateChanged);
    super.dispose();
  }

  void _onTradingStateChanged() {
    final trading = FennecState.trading;
    
    // Check if the platform URL changed
    final currentConfigUrl = trading.platformUrl;
    if (_loadedPlatformUrl != currentConfigUrl) {
      _loadedPlatformUrl = currentConfigUrl;
      _controller.loadRequest(Uri.parse('$currentConfigUrl/platform'));
      if (mounted) {
        setState(() {});
      }
    }

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
  if (window.__fennecBridgeLoaded) return;
  window.__fennecBridgeLoaded = true;
  console.log("Fennec Pro Anti-Ban Security Bridge v1.1 Loaded.");

  // Helper: Try multiple selectors and return the first match
  function queryFirst(...selectors) {
    for (let sel of selectors) {
      try {
        const el = document.querySelector(sel);
        if (el) return el;
      } catch(e) {}
    }
    return null;
  }

  // 1. Monitor Account Balance with multiple selector fallbacks
  function checkBalance() {
    const balanceEl = queryFirst(
      '[data-test="balance"]',
      '[class*="balance-value"]',
      '[class*="account-balance"]',
      '[class*="wallet-amount"]',
      '.balance span',
      '[class*="user-balance"]'
    );
    if (balanceEl) {
      const text = balanceEl.textContent || "";
      const balanceVal = parseInt(text.replace(/[^0-9]/g, '')) || 0;
      if (balanceVal > 0) {
        FennecBridge.postMessage("BALANCE_UPDATE:" + balanceVal);
      }
    }
  }

  const balanceObserver = new MutationObserver(() => checkBalance());
  balanceObserver.observe(document.body, { childList: true, subtree: true, characterData: true });
  checkBalance();

  // 2. Monitor Transaction Results (WIN/LOSS) with wider keyword coverage
  const WIN_KEYWORDS  = ["profit", "menang", "victory", "win", "won", "sukses", "berhasil"];
  const LOSS_KEYWORDS = ["rugi", "loss", "kalah", "failed", "expire", "gagal"];

  const historyObserver = new MutationObserver((mutations) => {
    for (let mutation of mutations) {
      for (let node of mutation.addedNodes) {
        if (node.nodeType !== 1) continue;
        const text = (node.textContent || "").toLowerCase();
        if (WIN_KEYWORDS.some(kw => text.includes(kw))) {
          FennecBridge.postMessage("RESULT_DETECTED:WIN");
          return;
        } else if (LOSS_KEYWORDS.some(kw => text.includes(kw))) {
          FennecBridge.postMessage("RESULT_DETECTED:LOSS");
          return;
        }
      }
    }
  });
  historyObserver.observe(document.body, { childList: true, subtree: true });

  // 3. Humanized Event Dispatcher (Anti-Ban mouse simulation)
  window.fennecExecuteClick = function(direction, nominal) {
    console.log("Fennec Bridge triggering: " + direction + " | size: " + nominal);

    // --- Inject nominal amount ---
    const amountInput = queryFirst(
      'input[data-test="deal-amount-input"]',
      '[class*="deal-amount"] input',
      '[class*="amount-input"] input',
      'input[class*="trade-size"]',
      'input[class*="bet-amount"]',
      '[data-cy="amount-input"]'
    );
    if (amountInput) {
      amountInput.focus();
      // Use native input setter to bypass React/Vue controlled components
      const nativeInputValueSetter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value').set;
      nativeInputValueSetter.call(amountInput, nominal);
      amountInput.dispatchEvent(new Event('input', { bubbles: true }));
      amountInput.dispatchEvent(new Event('change', { bubbles: true }));
      amountInput.blur();
    }

    // --- Find call/put button ---
    let button;
    if (direction === 'UP') {
      button = queryFirst(
        'button[data-test="button-call"]',
        '[class*="button-call"]',
        '.button-up',
        'button[class*="call"]',
        '[data-cy="btn-call"]',
        'button[class*="higher"]',
        '.trade-button-call'
      );
    } else {
      button = queryFirst(
        'button[data-test="button-put"]',
        '[class*="button-put"]',
        '.button-down',
        'button[class*="put"]',
        '[data-cy="btn-put"]',
        'button[class*="lower"]',
        '.trade-button-put'
      );
    }

    if (!button) {
      console.error("Fennec: Could not find " + direction + " button. Selectors may need update.");
      FennecBridge.postMessage("SELECTOR_ERROR:" + direction);
      return;
    }

    // --- Human-like randomized delay (1.5s - 3.5s) ---
    const randomDelay = Math.floor(Math.random() * 2000) + 1500;
    setTimeout(() => {
      const rect = button.getBoundingClientRect();
      // Random click point within 30%-70% of button area
      const clickX = rect.left + (rect.width  * (0.3 + Math.random() * 0.4));
      const clickY = rect.top  + (rect.height * (0.3 + Math.random() * 0.4));

      const mkEvt = (type) => new MouseEvent(type, {
        bubbles: true, cancelable: true,
        view: window, clientX: clickX, clientY: clickY, button: 0
      });

      // Full human mouse event sequence
      button.dispatchEvent(mkEvt('mouseenter'));
      button.dispatchEvent(mkEvt('mouseover'));

      setTimeout(() => {
        button.dispatchEvent(mkEvt('mousedown'));
        button.focus();
        setTimeout(() => {
          button.dispatchEvent(mkEvt('mouseup'));
          button.dispatchEvent(mkEvt('click'));
          console.log("Fennec: Injected " + direction + " click at (" + Math.round(clickX) + ", " + Math.round(clickY) + ")");
        }, 80 + Math.floor(Math.random() * 70));
      }, 100 + Math.floor(Math.random() * 80));

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
                const SizedBox(
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
          child: Row(
            children: [
              const Icon(Icons.lock, size: 12, color: CyberTheme.neonGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${FennecState.trading.platformUrl}/platform',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: CyberTheme.colorTextSecondary, fontWeight: FontWeight.w500),
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
