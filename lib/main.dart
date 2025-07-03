// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.camera.request();
  await Permission.location.request();
  await Permission.storage.request();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: WebviewScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WebviewScreen extends StatefulWidget {
  const WebviewScreen({super.key});
  @override
  State<WebviewScreen> createState() => _WebviewScreenState();
}

class _WebviewScreenState extends State<WebviewScreen> {
  InAppWebViewController? webViewController;
  PullToRefreshController? pullToRefreshController;
  final GlobalKey webViewKey = GlobalKey();
  int progress = 0;
  bool isLoading = true;

  // final String targetUrl = "https://tesla-smartwork.transtama.com";
  // final String targetUrl = "http://192.168.3.143/transtama-tesla";
  final String targetUrl =
      "https://39bf-103-237-140-137.ngrok-free.app/transtama-tesla";

  @override
  void initState() {
    super.initState();
    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(color: Colors.red),
      onRefresh: () async {
        webViewController?.reload();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (webViewController != null) {
          if (await webViewController!.canGoBack()) {
            webViewController!.goBack();
            return false; // jangan keluar app
          }
        }
        return true; // keluar app kalau gak bisa goBack
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              InAppWebView(
                key: webViewKey,
                initialUrlRequest: URLRequest(url: WebUri(targetUrl)),
                initialSettings: InAppWebViewSettings(
                  mediaPlaybackRequiresUserGesture: false,
                  javaScriptEnabled: true,
                  javaScriptCanOpenWindowsAutomatically: true,
                  allowsInlineMediaPlayback: true,
                  useShouldOverrideUrlLoading: true,
                  allowFileAccessFromFileURLs: true,
                  allowUniversalAccessFromFileURLs: true,
                  geolocationEnabled: true,
                  supportZoom: true,
                  useOnLoadResource: true,
                  useShouldInterceptAjaxRequest: true,
                  useShouldInterceptFetchRequest: true,
                  incognito: false,
                  cacheEnabled: true,
                  clearCache: false,
                  preferredContentMode: UserPreferredContentMode.RECOMMENDED,
                  thirdPartyCookiesEnabled: true,
                  sharedCookiesEnabled: true,
                  // cookieEnabled: true,
                ),
                pullToRefreshController: pullToRefreshController,
                onWebViewCreated: (controller) {
                  webViewController = controller;
                  webViewController?.addJavaScriptHandler(
                    handlerName: 'debug',
                    callback: (args) {
                      debugPrint('From JavaScript: $args');
                      return {'received': true};
                    },
                  );
                },
                onLoadStart: (controller, url) {
                  setState(() {
                    isLoading = true;
                  });
                  debugPrint('Page started loading: $url');
                },
                onLoadStop: (controller, url) async {
                  pullToRefreshController?.endRefreshing();
                  setState(() {
                    isLoading = false;
                  });
                  debugPrint('Page finished loading: $url');

                  // Inject JavaScript to help debug login issues
                  await controller.evaluateJavascript(
                    source: '''
              console.log = function(message) {
                window.flutter_inappwebview.callHandler('debug', message);
              };
              console.error = function(message) {
                window.flutter_inappwebview.callHandler('debug', 'ERROR: ' + message);
              };
              console.warn = function(message) {
                window.flutter_inappwebview.callHandler('debug', 'WARNING: ' + message);
              };
              // Log cookies to help debug session issues
              window.flutter_inappwebview.callHandler('debug', 'Cookies: ' + document.cookie);
              // Log localStorage to help debug session issues
              let localStorageItems = {};
              for (let i = 0; i < localStorage.length; i++) {
                const key = localStorage.key(i);
                localStorageItems[key] = localStorage.getItem(key);
              }
              window.flutter_inappwebview.callHandler('debug', 'LocalStorage: ' + JSON.stringify(localStorageItems));
            ''',
                  );
                },
                onProgressChanged: (controller, progress) {
                  setState(() {
                    this.progress = progress;
                  });
                },
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  var uri = navigationAction.request.url;
                  debugPrint('Navigating to: $uri');
                  return NavigationActionPolicy.ALLOW;
                },
                androidOnGeolocationPermissionsShowPrompt: (
                  controller,
                  origin,
                ) async {
                  return GeolocationPermissionShowPromptResponse(
                    origin: origin,
                    allow: true,
                    retain: true,
                  );
                },
                // onShowFileChooser: (controller, fileChooserParams) async {
                //   final ImagePicker picker = ImagePicker();
                //   final XFile? image = await picker.pickImage(
                //     source: ImageSource.camera,
                //   );

                //   if (image == null) return null;

                //   final uri = Uri.file(image.path);
                //   return [uri];
                // },
                onConsoleMessage: (controller, consoleMessage) {
                  debugPrint('Console: ${consoleMessage.message}');
                },
                onLoadError: (controller, url, code, message) {
                  pullToRefreshController?.endRefreshing();
                  debugPrint('Error loading $url: $message');
                },
                onGeolocationPermissionsShowPrompt: (controller, origin) async {
                  return GeolocationPermissionShowPromptResponse(
                    origin: origin,
                    allow: true,
                    retain: true,
                  );
                },
                onPermissionRequest: (controller, request) async {
                  return PermissionResponse(
                    resources: request.resources,
                    action: PermissionResponseAction.GRANT,
                  );
                },
              ),
              progress < 100
                  ? LinearProgressIndicator(
                    value: progress / 100.0,
                    color: Colors.blue,
                    backgroundColor: Colors.white,
                  )
                  : Container(),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }
}
