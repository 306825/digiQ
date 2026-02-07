import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

class PayfastWebViewScreen extends StatefulWidget {
  final String processUrl;
  final Map<String, String> payload;

  const PayfastWebViewScreen({
    super.key,
    required this.processUrl,
    required this.payload,
  });

  @override
  State<PayfastWebViewScreen> createState() => _PayfastWebViewScreenState();
}

class _PayfastWebViewScreenState extends State<PayfastWebViewScreen> {
  late final String _autoSubmitHtml;

  @override
  void initState() {
    super.initState();

    _autoSubmitHtml = _buildAutoSubmitHtml(
      widget.processUrl,
      widget.payload,
    );

    // Desktop handling
    if (defaultTargetPlatform == TargetPlatform.linux) {
      _openInExternalBrowser();
    }
  }

  @override
  Widget build(BuildContext context) {
    // On Linux we just show a loader while the browser opens
    if (defaultTargetPlatform == TargetPlatform.linux) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Secure Payment')),
      body: InAppWebView(
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          cacheEnabled: false,
          clearCache: true,
        ),
        initialData: InAppWebViewInitialData(
          data: _autoSubmitHtml,
          mimeType: "text/html",
          encoding: "utf-8",

          // 🔥 CRITICAL FIX (prevents your 404)
          baseUrl: WebUri(widget.processUrl),
        ),
        onLoadStart: (controller, url) {
          if (url == null) return;

          final uri = url.toString();
          debugPrint("🌍 Navigating to: $uri");

          if (uri.contains("/payment/success")) {
            Navigator.pop(context, true);
          }

          if (uri.contains("/payment/cancel")) {
            Navigator.pop(context, false);
          }
        },
      ),
    );
  }

  /// Opens PayFast properly on Linux/Desktop
  Future<void> _openInExternalBrowser() async {
    try {
      final tempFile = File('/tmp/payfast_payment.html');
      await tempFile.writeAsString(_autoSubmitHtml);

      final uri = Uri.file(tempFile.path);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("❌ Failed to launch PayFast on desktop: $e");
    }
  }

  /// Correct auto-submit form (no double encoding)
  String _buildAutoSubmitHtml(
    String action,
    Map<String, String> fields,
  ) {
    final inputs = fields.entries.map((e) {
      final safeValue = e.value.replaceAll('"', '&quot;');
      return '<input type="hidden" name="${e.key}" value="$safeValue" />';
    }).join('\n');

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>
  <h3 style="text-align:center">Redirecting to PayFast…</h3>

  <form id="payfastForm" action="$action" method="POST">
    $inputs
  </form>

  <script>
    setTimeout(function() {
      document.getElementById("payfastForm").submit();
    }, 200);
  </script>
</body>
</html>
''';
  }
}
