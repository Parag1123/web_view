import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Browser',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _bookmarks = [];
  final TextEditingController _urlController = TextEditingController();
  late final WebViewController _webViewController;
  bool canGoBack = false;
  bool canGoForward = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initWebViewController();
  }

  void _initWebViewController() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) => _updateNavigationButtons(),
      ))
      ..loadRequest(Uri.parse('https://flutter.dev'));
  }

  void _updateNavigationButtons() async {
    bool back = await _webViewController.canGoBack();
    bool forward = await _webViewController.canGoForward();
    setState(() {
      canGoBack = back;
      canGoForward = forward;
    });
  }

  void _navigateToUrl(String url) {
    if (!url.startsWith('http')) url = 'https://$url';
    _webViewController.loadRequest(Uri.parse(url));
    _updateNavigationButtons();
  }

  void _clearUrl() {
    _urlController.clear();
  }

  void _bookmarkCurrentPage() async {
    final currentUrl = await _webViewController.currentUrl();
    if (currentUrl != null && !_bookmarks.contains(currentUrl.toString())) {
      setState(() {
        _bookmarks.add(currentUrl.toString());
      });
    }
  }

  void _shareUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not share $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Browser'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Browser'),
            Tab(text: 'Bookmarks'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _urlController,
                        decoration: const InputDecoration(hintText: 'Enter URL'),
                        onSubmitted: (value) => _navigateToUrl(value),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearUrl,
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: canGoBack
                          ? () async {
                              await _webViewController.goBack();
                              _updateNavigationButtons();
                            }
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: canGoForward
                          ? () async {
                              await _webViewController.goForward();
                              _updateNavigationButtons();
                            }
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.bookmark),
                      onPressed: _bookmarkCurrentPage,
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_browser),
                      onPressed: () => _navigateToUrl(_urlController.text),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: WebViewWidget(controller: _webViewController),
              ),
            ],
          ),
          ListView.builder(
            itemCount: _bookmarks.length,
            itemBuilder: (context, index) {
              final url = _bookmarks[index];
              return ListTile(
                title: Text(url),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.launch),
                      onPressed: () {
                        _tabController.index = 0;
                        _urlController.text = url;
                        _navigateToUrl(url);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () => _shareUrl(url),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}