import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:connectivity_plus/connectivity_plus.dart';

import 'banner_ad_widget.dart';
import 'interstitial_ad_manager.dart';
import 'app_open_ad_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();

  // **Tampilkan Open Ads hanya saat aplikasi pertama kali dibuka**
  AppOpenAdManager().showAdIfAvailable();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WebViewScreen(),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() async {
    // Cek koneksi internet
    var connectivityResult = await Connectivity().checkConnectivity();
    bool hasInternet = connectivityResult != ConnectivityResult.none;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent("enzoXzodix")
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) {
            setState(() => _isLoading = false);
            InterstitialAdManager.showAd();
          },
          onWebResourceError: (error) async {
            if (!hasInternet) {
              _loadLocalErrorPage();
            }
          },
        ),
      );

    if (hasInternet) {
      _controller.loadRequest(Uri.parse('https://xdtoolts.xyz/'));
    } else {
      _loadLocalErrorPage();
    }
  }

  void _loadLocalErrorPage() async {
    String html = await rootBundle.loadString('assets/404.html');
    _controller.loadRequest(
      Uri.dataFromString(html, mimeType: 'text/html', encoding: Encoding.getByName('utf-8')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) Center(child: CircularProgressIndicator()),
        ],
      ),
      bottomNavigationBar: BannerAdWidget(),
    );
  }
}
