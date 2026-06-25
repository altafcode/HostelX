import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/config/stripe_config.dart';
import '../../../core/theme/app_colors.dart';

class StripeCheckoutResult {
  final bool completed;
  final String? sessionId;

  const StripeCheckoutResult({
    required this.completed,
    this.sessionId,
  });
}

class StripeCheckoutWebViewScreen extends StatefulWidget {
  final String checkoutUrl;

  const StripeCheckoutWebViewScreen({
    super.key,
    required this.checkoutUrl,
  });

  @override
  State<StripeCheckoutWebViewScreen> createState() =>
      _StripeCheckoutWebViewScreenState();
}

class _StripeCheckoutWebViewScreenState
    extends State<StripeCheckoutWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            final uri = Uri.parse(request.url);
            final url = request.url.toLowerCase();

            if (url.startsWith(StripeConfig.checkoutSuccessUrl)) {
              Navigator.pop(
                context,
                StripeCheckoutResult(
                  completed: true,
                  sessionId: uri.queryParameters['session_id'],
                ),
              );
              return NavigationDecision.prevent;
            }

            if (url.startsWith(StripeConfig.checkoutCancelUrl)) {
              Navigator.pop(
                context,
                const StripeCheckoutResult(completed: false),
              );
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Checkout',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, size: 22, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(
            context,
            const StripeCheckoutResult(completed: false),
          ),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}
