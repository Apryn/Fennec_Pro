import 'dart:async';
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
  String _loadedPlatformUrl = '';

  // Periodic bridge re-injection: setiap 30 detik pastikan JS bridge masih aktif.
  // Ini menangani kasus WebView SPA navigate internal (ganti aset, refresh chart)
  // yang bisa menghapus window.__fennecBridgeLoaded tanpa memicu onPageFinished.
  Timer? _bridgeKeepaliveTimer;
  DateTime? _lastExecutionTime;

  @override
  void initState() {
    super.initState();
    FennecState.trading.addListener(_onTradingStateChanged);
    _loadedPlatformUrl = FennecState.trading.platformUrl;

    // Periodic bridge keepalive: re-inject setiap 30 detik
    _bridgeKeepaliveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _injectAntiBanBridge();
    });

    // Initialize WebViewController to load Olymp Trade Platform
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent("Mozilla/5.0 (Linux; Android 13; SM-A205F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.3472.0 Mobile Safari/537.36")
      ..setBackgroundColor(CyberTheme.background)
      ..setOnConsoleMessage((JavaScriptConsoleMessage message) {
        debugPrint('[WebView JS] ${message.message}');
      })
      ..addJavaScriptChannel(
        'FennecBridge',
        onMessageReceived: (JavaScriptMessage message) {
          final parts = message.message.split(':');
          final eventType = parts[0];
          if (eventType == 'BALANCE_UPDATE') {
            final balance = int.tryParse(parts[1]) ?? 0;
            final isDemo = parts.length > 2 && parts[2] == 'DEMO';
            final currency = parts.length > 3 ? parts[3] : 'Rp';
            FennecState.trading.updateAccountBalance(balance, isDemo: isDemo, currency: currency);
          } else if (eventType == 'RESULT_DETECTED') {
            // Gunakan resolveCurrentTradeFromWebView — aman karena ada guard internal:
            // jika tidak ada trade pending (stale event dari trade lama), diabaikan.
            final result = parts[1];
            if (result == 'WIN') {
              FennecState.trading.resolveCurrentTradeFromWebView(isWin: true);
            } else if (result == 'LOSS') {
              FennecState.trading.resolveCurrentTradeFromWebView(isWin: false);
            }
          } else if (eventType == 'ACTIVE_ASSET') {
            final asset = parts[1];
            FennecState.trading.updateActiveAsset(asset);
          } else if (eventType == 'TICK_UPDATE') {
            final price = double.tryParse(parts[1]) ?? 0.0;
            if (price > 0) {
              FennecState.trading.addLivePriceTick(price);
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
            // Inject bridge early with 4s delay to capture results on faster loads
            Future.delayed(const Duration(seconds: 4), () {
              if (mounted) {
                _injectAntiBanBridge();
              }
            });
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
    _bridgeKeepaliveTimer?.cancel();
    super.dispose();
  }

  void _onTradingStateChanged() {
    final trading = FennecState.trading;

    // Cek apakah platform URL berubah
    final currentConfigUrl = trading.platformUrl;
    if (_loadedPlatformUrl != currentConfigUrl) {
      _loadedPlatformUrl = currentConfigUrl;
      _controller.loadRequest(Uri.parse('$currentConfigUrl/platform'));
      if (mounted) setState(() {});
    }

    // Eksekusi trade baru jika ada signal baru
    if (trading.isAutoTradingActive && trading.signalId > trading.lastExecutedSignalId) {
      trading.setLastExecutedSignalId(trading.signalId);
      _executeAutoTrade(trading.lastSignalDirection ?? "UP", trading.nextTrade);
    }
  }

  void _executeAutoTrade(String direction, int nominal) {
    final now = DateTime.now();
    if (_lastExecutionTime != null && now.difference(_lastExecutionTime!).inMilliseconds < 1500) {
      debugPrint('[Fennec] ⚠️ Double execution blocked in Dart (cooldown active)');
      return;
    }
    _lastExecutionTime = now;

    // Pastikan bridge sudah ter-inject sebelum eksekusi
    _injectAntiBanBridge();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _controller.runJavaScript(
          'if (window.fennecExecuteClick) { window.fennecExecuteClick("$direction", $nominal); }',
        );
      }
    });
  }

  void _injectAntiBanBridge() {
    const String bridgeScript = r"""
(function() {
  if (window.__fennecBridgeLoaded) return;
  window.__fennecBridgeLoaded = true;
  console.log("Fennec Pro Bridge v3.0 Loaded.");

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

  // 1. Monitor Account Balance dengan debounce
  // PENTING: characterData TIDAK digunakan di sini karena menyebabkan MutationObserver
  // fire ratusan kali per detik saat harga chart bergerak → penyebab lag utama!
  let _lastSentBalance = 0;
  let _balanceDebounceTimer = null;

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
      let cleanText = text.replace(/[^0-9.,]/g, '');
      if (cleanText.match(/[.,]\d{2}$/)) {
        cleanText = cleanText.substring(0, cleanText.length - 3);
      }
      const balanceVal = parseInt(cleanText.replace(/[^0-9]/g, '')) || 0;
      
      // Extract currency symbol dynamically
      let currencySymbol = "Rp";
      let temp = text.replace(/demo|real|account|balance|saldo|akun|rupiah/gi, '').trim();
      const match = temp.match(/([^0-9\s.,:;!?(){}\[\]+\-*/=<>#@&_]+)/);
      if (match) {
        const sym = match[1].trim();
        if (sym.length <= 3) {
          currencySymbol = sym;
        }
      }

      // Hanya kirim jika nilai berbeda atau mata uang berganti (hindari spam pesan yang sama)
      if (balanceVal > 0 && (balanceVal !== _lastSentBalance || currencySymbol !== window._lastSentCurrency)) {
        _lastSentBalance = balanceVal;
        window._lastSentCurrency = currencySymbol;
        const isDemo = text.toUpperCase().includes('D') || text.toLowerCase().includes('demo');
        FennecBridge.postMessage("BALANCE_UPDATE:" + balanceVal + ":" + (isDemo ? "DEMO" : "REAL") + ":" + currencySymbol);
      }
    }
  }

  // Dapatkan nama asset aktif dari DOM secara cerdas
  function getActiveAsset() {
    const assetKeywords = [
      'index', 'composite', 'otc', 'bitcoin', 'ethereum', 'gold', 'silver', 'altcoin', 
      'commodity', 'crypto', 'brent', 'platina', 'palladium', 'gas', 'copper', 
      'asia', 'europe', 'latam', 'mcdonald', 'tesla', 'apple', 'boeing', 'google', 
      'facebook', 'microsoft', 'amazon', 'netflix', 'alibaba', 'starbucks', 'nvidia', 
      'visa', 'intel'
    ];
    
    const skipWords = [
      'demo', 'real', 'account', 'akun', 'wallet', 'dompet', 'balance', 'saldo',
      'deposit', 'top up', 'topup', 'menu', 'help', 'bantuan', 'support', 'profile', 
      'user', 'settings', 'pengaturan', 'trade', 'history', 'riwayat', 'analisa', 
      'analysis', 'indicator', 'indikator', 'signals', 'sinyal', 'market', 'pasar',
      'withdraw', 'penarikan', 'transaction', 'transaksi', 'verification', 'verifikasi'
    ];

    const elements = document.querySelectorAll('button, span, div, h1, h2, h3, a');
    const candidates = [];
    const widthLimit = (window.innerWidth || 360) * 0.75;
    
    // 1. Scan header elements (top-left quadrant/bar) first using scoring heuristics
    for (let el of elements) {
      try {
        const rect = el.getBoundingClientRect();
        if (rect.width > 0 && rect.height > 0 && rect.top >= 0 && rect.top < 150 && rect.left >= 0 && rect.left < widthLimit) {
          const style = window.getComputedStyle(el);
          if (style.display !== 'none' && style.visibility !== 'hidden' && parseFloat(style.opacity) > 0) {
            const originalText = el.textContent || "";
            const cleaned = originalText.trim();
            if (cleaned.length < 3 || cleaned.length > 50) continue;
            
            let cleanName = cleaned.replace(/[+-]?\d+\s*%/g, ''); // remove percentage
            cleanName = cleanName.replace(/[▼▲▼▲▾▴›»]/g, ''); // remove arrow symbols
            cleanName = cleanName.replace(/\s+/g, ' ').trim();
            
            if (cleanName.length < 3 || cleanName.length > 35) continue;
            if (/^[0-9\s.,:$€£¥₽Rp]+$/.test(cleanName)) continue; // skip numbers/prices/times only
            
            const lowerClean = cleanName.toLowerCase();
            if (skipWords.some(word => lowerClean.includes(word))) continue;
            
            let score = 0;
            const hasPercentage = /%/.test(originalText);
            const isForex = /^[a-z]{3}\/[a-z]{3}(\s*\(?otc\)?)?$/i.test(cleanName);
            const isAssetKeyword = assetKeywords.some(kw => lowerClean.includes(kw));
            
            if (hasPercentage) score += 150;
            if (isForex) score += 100;
            if (isAssetKeyword) score += 80;
            
            // Penalty for distance from top-left (0, 40)
            const distance = Math.sqrt(Math.pow(rect.left, 2) + Math.pow(rect.top - 40, 2));
            score -= distance * 0.1;
            
            candidates.push({
              name: cleanName,
              score: score
            });
          }
        }
      } catch(e) {}
    }

    if (candidates.length > 0) {
      candidates.sort((a, b) => b.score - a.score);
      return candidates[0].name;
    }

    // 2. Fallback to broad scan if header scan fails
    for (let el of elements) {
      if (el.children.length === 0) {
        let text = (el.textContent || "").trim();
        if (text.length > 2 && text.length < 35) {
          const textLower = text.toLowerCase();
          const isForex = /^[a-z]{3}\/[a-z]{3}(?:\s+otc)?$/i.test(text);
          const isAssetKeyword = assetKeywords.some(kw => textLower.includes(kw));
          
          if (isForex || isAssetKeyword) {
            try {
              const rect = el.getBoundingClientRect();
              if (rect.width > 0 && rect.height > 0) {
                const style = window.getComputedStyle(el);
                if (style.display !== 'none' && style.visibility !== 'hidden') {
                  let cleanText = text.replace(/\s*\d+\s*%$/, '').trim();
                  cleanText = cleanText.replace(/\s+/g, ' ');
                  return cleanText;
                }
              }
            } catch(e) {}
          }
        }
      }
    }
    
    return "EUR/USD";
  }

  let _lastSentAsset = "";
  function checkActiveAsset() {
    const assetName = getActiveAsset();
    if (assetName && assetName !== _lastSentAsset) {
      _lastSentAsset = assetName;
      FennecBridge.postMessage("ACTIVE_ASSET:" + assetName);
    }
  }

  // Debounce: tunggu 500ms setelah DOM change terakhir baru cek balance
  // Ini mencegah ratusan cek balance per detik saat animasi chart berjalan
  function debouncedBalanceCheck() {
    if (_balanceDebounceTimer) clearTimeout(_balanceDebounceTimer);
    _balanceDebounceTimer = setTimeout(() => {
      checkBalance();
      checkActiveAsset();
    }, 500);
  }

  // Hanya observe childList + subtree, TANPA characterData
  // characterData menyebabkan observer fire setiap frame animasi chart
  const balanceObserver = new MutationObserver(debouncedBalanceCheck);
  balanceObserver.observe(document.body, { childList: true, subtree: true });
  checkBalance();
  checkActiveAsset();
  setInterval(checkBalance, 1000); // Cek balance setiap 1 detik untuk update instan
  setInterval(checkActiveAsset, 2000); // Cek asset setiap 2 detik

  // 2. Monitor Transaction Results (WIN/LOSS)
  // Detects results using DOM color scanning (green for profit/win, red for loss),
  // with a fallback to precise text matching to handle all cases reliably.
  function parseResultFromNode(node) {
    const text = (node.textContent || "").trim();
    if (text.length < 3 || text.length > 150) return null;
    const lower = text.toLowerCase();
    
    // Pastikan teks mengandung kata kunci hasil transaksi agar tidak salah mendeteksi candle atau harga running
    const hasMinusNumber = /-\s*(?:idr|rp|usd|eur|d|[$€£])\s*\d+/i.test(lower) || 
                           (/(?:^|[^a-z0-9])-\s*[1-9]\d*/i.test(lower) && !lower.includes("%") && !/-\s*0\.\d+/.test(lower));
    const hasPlusNumber = /\+\s*(?:idr|rp|usd|eur|d|[$€£])\s*\d+/i.test(lower) || 
                          (/\+\s*[1-9]\d*/i.test(lower) && !lower.includes("%") && !/\+\s*0\.\d+/.test(lower));

    const isTradeResultText = 
      hasMinusNumber ||
      hasPlusNumber ||
      lower.includes("expired") || 
      lower.includes("profit") || 
      lower.includes("keuntungan") || 
      lower.includes("rugi") || 
      lower.includes("kalah") || 
      lower.includes("failed") || 
      lower.includes("gagal") || 
      lower.includes("loss") || 
      lower.includes("menang") || 
      lower.includes("victory") || 
      lower.includes("win") || 
      lower.includes("won") || 
      lower.includes("sukses") ||
      lower.includes("transaksi") ||
      lower.includes("closed") ||
      lower.includes("deal");

    if (!isTradeResultText) {
      return null;
    }
    
    // 1. Check dominant color (Green / Red) from computed styles
    let isGreen = false;
    let isRed = false;
    try {
      const style = window.getComputedStyle(node);
      const colors = [style.color, style.backgroundColor];
      for (let c of colors) {
        if (!c) continue;
        const match = c.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/);
        if (match) {
          const r = parseInt(match[1]);
          const g = parseInt(match[2]);
          const b = parseInt(match[3]);
          // Green dominant
          if (g > 100 && g > r * 1.25 && g > b * 1.25) {
            isGreen = true;
          }
          // Red dominant
          if (r > 100 && r > g * 1.25 && r > b * 1.25) {
            isRed = true;
          }
        }
      }
    } catch (e) {}

    // 2. Check class names for color keywords
    const className = (node.className || "").toString().toLowerCase();
    if (className.includes("green") || className.includes("success") || className.includes("positive") || className.includes("win")) {
      isGreen = true;
    }
    if (className.includes("red") || className.includes("danger") || className.includes("error") || className.includes("negative") || className.includes("loss")) {
      isRed = true;
    }

    if (isGreen && !isRed) {
      return "WIN";
    }
    if (isRed && !isGreen) {
      return "LOSS";
    }

    // 3. Fallback to precise text matching if colors are inconclusive
    if (hasMinusNumber) {
      return "LOSS";
    }
    if (hasPlusNumber) {
      return "WIN";
    }
    if (lower === "expired") {
      return null;
    }
    if (lower.includes("rugi") || lower.includes("kalah") || lower.includes("failed") || lower.includes("gagal") || lower.includes("loss")) {
      return "LOSS";
    }
    if (lower.includes("menang") || lower.includes("victory") || lower.includes("win") || lower.includes("won") || lower.includes("sukses")) {
      return "WIN";
    }
    if (lower.includes("profit") || lower.includes("keuntungan")) {
      const zeroMatch = lower.match(/(?:profit|keuntungan)[:\s]*[^1-9]*0+(?:[^0-9]|$)/);
      if (zeroMatch) {
        return "LOSS";
      }
      return "WIN";
    }

    return null;
  }

  function findResultInSubtree(node) {
    const result = parseResultFromNode(node);
    if (result) return result;

    const children = node.getElementsByTagName("*");
    for (let child of children) {
      const childResult = parseResultFromNode(child);
      if (childResult) return childResult;
    }
    return null;
  }

  let _lastResultTime = 0;
  const historyObserver = new MutationObserver((mutations) => {
    for (let mutation of mutations) {
      for (let node of mutation.addedNodes) {
        if (node.nodeType !== 1) continue;
        
        const result = findResultInSubtree(node);
        if (result) {
          const now = Date.now();
          if (now - _lastResultTime > 2500) { // 2.5s throttle to prevent duplicate triggers
            _lastResultTime = now;
            console.log("[Fennec Bridge] DOM Result Detected via Color/Text: " + result + " (" + node.textContent.trim() + ")");
            FennecBridge.postMessage("RESULT_DETECTED:" + result);
            return;
          }
        }
      }
    }
  });
  historyObserver.observe(document.body, { childList: true, subtree: true });

  // 3. Monitor live asset price ticks dynamically
  let priceElementSelector = null;
  let priceElementCandidates = new Map();

  function scanForPriceTicks() {
    if (priceElementSelector) {
      const el = queryFirst(priceElementSelector);
      if (el) {
        const text = (el.textContent || "").trim();
        let cleanText = text.replace(/[^0-9.,]/g, '');
        if (cleanText) {
          const val = parseFloat(cleanText.replace(',', '.'));
          if (val > 0) {
            FennecBridge.postMessage("TICK_UPDATE:" + val);
            return;
          }
        }
      }
      priceElementSelector = null;
    }

    // Direct check of known selectors for quick bootstrap
    const KNOWN_PRICE_SELECTORS = [
      '[data-test="current-price"]',
      '[data-test="strike-price"]',
      '[class*="strike-value"]',
      '[class*="chart-quote"]',
      '[class*="current-quote"]',
      '[class*="deal-parameters"] [class*="value"]'
    ];
    for (let sel of KNOWN_PRICE_SELECTORS) {
      const el = document.querySelector(sel);
      if (el) {
        const text = (el.textContent || "").trim();
        let cleanText = text.replace(/[^0-9.,]/g, '');
        if (cleanText) {
          const val = parseFloat(cleanText.replace(',', '.'));
          if (val > 0) {
            priceElementSelector = sel;
            FennecBridge.postMessage("TICK_UPDATE:" + val);
            return;
          }
        }
      }
    }

    const leafNodes = [];
    function traverse(node) {
      if (node.nodeType === Node.ELEMENT_NODE) {
        try {
          const style = window.getComputedStyle(node);
          if (style.display === 'none' || style.visibility === 'hidden') return;
        } catch(e) {}
        if (node.children.length === 0) {
          leafNodes.push(node);
        } else {
          for (let child of node.children) {
            traverse(child);
          }
        }
      }
    }
    traverse(document.body);

    const nowCandidates = new Map();
    for (let el of leafNodes) {
      const text = (el.textContent || "").trim();
      if (/^\d+[\.,]\d+$/.test(text)) {
        if (text.includes('%') || text.length < 3) continue;
        const val = parseFloat(text.replace(',', '.'));
        if (val > 0) {
          nowCandidates.set(el, val);
        }
      }
    }

    for (let [el, val] of nowCandidates) {
      if (priceElementCandidates.has(el)) {
        const prevVal = priceElementCandidates.get(el);
        if (prevVal !== val) {
          priceElementSelector = getUniqueSelector(el);
          FennecBridge.postMessage("TICK_UPDATE:" + val);
          break;
        }
      }
    }
    priceElementCandidates = nowCandidates;
  }

  function getUniqueSelector(el) {
    if (el.id) return '#' + el.id;
    const parts = [];
    while (el && el.nodeType === Node.ELEMENT_NODE) {
      let selector = el.nodeName.toLowerCase();
      if (el.className) {
        const classes = el.className.split(/\s+/).filter(c => c.length > 0 && !c.includes(':'));
        if (classes.length > 0) {
          selector += '.' + classes.slice(0, 3).join('.');
        }
      }
      parts.unshift(selector);
      el = el.parentNode;
    }
    return parts.join(' > ');
  }

  setInterval(scanForPriceTicks, 1000);

  // 4. Humanized Event Dispatcher (Anti-Ban mouse simulation)
  let _lastClickTime = 0;
  window.fennecExecuteClick = function(direction, nominal) {
    const now = Date.now();
    if (now - _lastClickTime < 1500) {
      console.warn("Fennec Bridge: Double execution blocked in JS");
      return;
    }
    _lastClickTime = now;
    console.log("Fennec Bridge triggering: " + direction + " | size: " + nominal);

    // --- Inject nominal amount ---
    const amountInput = queryFirst(
      '[data-test="deal-amount-input"]',
      'input[data-test="deal-amount-input"]',
      '[data-test="amount-input"]',
      '[class*="deal-amount"] input',
      '[class*="amount-input"] input',
      'input[class*="amount"]',
      'input[class*="trade-size"]',
      'input[class*="bet-amount"]',
      '[data-cy="amount-input"]'
    );
    if (amountInput) {
      amountInput.focus();
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
        '[data-test="deal-up-button"]',
        'button[data-test="button-call"]',
        '[class*="deal-button_up"]',
        '[class*="deal-button-up"]',
        'button[class*="button-call"]',
        'button[class*="call"]',
        '.button-up',
        '[data-cy="btn-call"]',
        'button[class*="higher"]',
        '.trade-button-call'
      );
    } else {
      button = queryFirst(
        '[data-test="deal-down-button"]',
        'button[data-test="button-put"]',
        '[class*="deal-button_down"]',
        '[class*="deal-button-down"]',
        'button[class*="button-put"]',
        'button[class*="put"]',
        '.button-down',
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
      const clickX = rect.left + (rect.width  * (0.3 + Math.random() * 0.4));
      const clickY = rect.top  + (rect.height * (0.3 + Math.random() * 0.4));

      // Trigger a single click event with simulated coordinates.
      // This mimics a physical tap/click on React/Vue buttons while avoiding
      // double trade execution from duplicate event handlers (mousedown + click).
      button.focus();
      const clickEvt = new MouseEvent('click', {
        bubbles: true,
        cancelable: true,
        view: window,
        clientX: clickX,
        clientY: clickY,
        button: 0
      });
      button.dispatchEvent(clickEvt);
      console.log("Fennec: Injected single " + direction + " click at (" + Math.round(clickX) + ", " + Math.round(clickY) + ")");
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
