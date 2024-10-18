import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CheckoutScreen extends StatefulWidget {
  final String userId;

  CheckoutScreen({required this.userId});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late WebViewController _controller;
  bool isLoading = true;

  String get checkoutUrl {
    // Replace with your server endpoint that initiates the PayPal payment
    return 'https://your-server.com/paypal/checkout?user_id=${widget.userId}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Your Order'),
      ),
      body: Stack(
        children: [
          // WebView(
          //   initialUrl: checkoutUrl,
          //   javascriptMode: JavascriptMode.unrestricted,
          //   onWebViewCreated: (controller) {
          //     _controller = controller;
          //   },
          //   navigationDelegate: (NavigationRequest request) {
          //     if (request.url.contains('payment-success')) {
          //       // Handle payment success
          //       Navigator.pop(context, true); // Return to previous screen with success
          //     } else if (request.url.contains('payment-cancel')) {
          //       // Handle payment cancellation
          //       Navigator.pop(context, false); // Return to previous screen with cancellation
          //     }
          //     return NavigationDecision.navigate;
          //   },
          //   onPageFinished: (url) {
          //     setState(() {
          //       isLoading = false;
          //     });
          //   },
          // ),

          if (isLoading) Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
