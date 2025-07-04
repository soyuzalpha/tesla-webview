// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request all necessary permissions
  await Permission.camera.request();
  await Permission.location.request();
  await Permission.locationWhenInUse.request();
  await Permission.storage.request();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WebViewPage(),
    );
  }
}

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late InAppWebViewController webViewController;
  PullToRefreshController? pullToRefreshController;
  final GlobalKey webViewKey = GlobalKey();
  int progress = 0;
  bool isLoading = true;
  final picker = ImagePicker();

  final String targetUrl = "https://tesla-smartwork.transtama.com";
  // final String targetUrl = "http://192.168.3.143/transtama-tesla";
  // final String targetUrl =
  //     "https://d0b8-103-101-231-157.ngrok-free.app/transtama-tesla";

  @override
  void initState() {
    super.initState();
    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(color: Colors.red),
      onRefresh: () async {
        webViewController.reload();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await webViewController.canGoBack()) {
          webViewController.goBack();
          return false; // jangan keluar app
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
                initialOptions: InAppWebViewGroupOptions(
                  crossPlatform: InAppWebViewOptions(javaScriptEnabled: true),
                  android: AndroidInAppWebViewOptions(
                    allowFileAccess: true,
                    // mediaPlaybackRequiresUserGesture: false,
                  ),
                  ios: IOSInAppWebViewOptions(
                    allowsInlineMediaPlayback: true,
                  ),
                ),
                androidOnPermissionRequest:
                    (controller, origin, resources) async {
                  return PermissionRequestResponse(
                    resources: resources,
                    action: PermissionRequestResponseAction.GRANT,
                  );
                },
                onWebViewCreated: (controller) {
                  webViewController = controller;

                  // Add JavaScript handler for file upload
                  controller.addJavaScriptHandler(
                    handlerName: 'fileUpload',
                    callback: (args) async {
                      try {
                        // Show dialog to choose between camera and gallery
                        final source = await showDialog<ImageSource>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Select Image Source'),
                            content:
                                const Text('Choose how to select your image'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, ImageSource.camera),
                                child: const Text('Camera'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, ImageSource.gallery),
                                child: const Text('Gallery'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                        );

                        if (source != null) {
                          final pickedFile = await picker.pickImage(
                            source: source,
                            maxWidth: 1920,
                            maxHeight: 1080,
                            imageQuality: 85,
                          );

                          if (pickedFile != null) {
                            final bytes = await pickedFile.readAsBytes();
                            final base64Image = base64Encode(bytes);
                            final fileName = pickedFile.name;

                            // Return the image data to the web page
                            return {
                              'success': true,
                              'fileName': fileName,
                              'fileData': 'data:image/jpeg;base64,$base64Image',
                              'fileSize': bytes.length,
                            };
                          }
                        }
                        return {'success': false, 'error': 'No image selected'};
                      } catch (e) {
                        debugPrint('Error in file upload handler: $e');
                        return {'success': false, 'error': e.toString()};
                      }
                    },
                  );

                  // Add JavaScript handler for geolocation
                  controller.addJavaScriptHandler(
                    handlerName: 'getLocation',
                    callback: (args) async {
                      try {
                        // Request location permission
                        LocationPermission permission =
                            await Geolocator.checkPermission();
                        if (permission == LocationPermission.denied) {
                          permission = await Geolocator.requestPermission();
                        }

                        if (permission == LocationPermission.deniedForever) {
                          return {
                            'success': false,
                            'error': 'Location permission denied forever'
                          };
                        }

                        if (permission == LocationPermission.denied) {
                          return {
                            'success': false,
                            'error': 'Location permission denied'
                          };
                        }

                        // Get current location
                        Position position = await Geolocator.getCurrentPosition(
                          desiredAccuracy: LocationAccuracy.high,
                          timeLimit: const Duration(seconds: 10),
                        );

                        return {
                          'success': true,
                          'latitude': position.latitude,
                          'longitude': position.longitude,
                          'accuracy': position.accuracy,
                          'timestamp':
                              position.timestamp.millisecondsSinceEpoch,
                        };
                      } catch (e) {
                        debugPrint('Error getting location: $e');
                        return {'success': false, 'error': e.toString()};
                      }
                    },
                  );
                },
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

                // FIXED: Handle file chooser for web file inputs
                onCreateWindow: (controller, createWindowAction) async {
                  return true;
                },
                onCloseWindow: (controller) {
                  // Handle window close
                },
                onReceivedServerTrustAuthRequest:
                    (controller, challenge) async {
                  return ServerTrustAuthResponse(
                      action: ServerTrustAuthResponseAction.PROCEED);
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

                  // Inject JavaScript to handle file inputs and geolocation
                  await controller.evaluateJavascript(
                    source: '''
              // Override console methods for debugging
              console.log = function(message) {
                window.flutter_inappwebview.callHandler('debug', message);
              };
              console.error = function(message) {
                window.flutter_inappwebview.callHandler('debug', 'ERROR: ' + message);
              };
              console.warn = function(message) {
                window.flutter_inappwebview.callHandler('debug', 'WARNING: ' + message);
              };
              
              // Override geolocation API to use Flutter's native location
              if (navigator.geolocation) {
                const originalGetCurrentPosition = navigator.geolocation.getCurrentPosition;
                const originalWatchPosition = navigator.geolocation.watchPosition;
                
                navigator.geolocation.getCurrentPosition = function(successCallback, errorCallback, options) {
                  console.log('Geolocation getCurrentPosition called');
                  
                  window.flutter_inappwebview.callHandler('getLocation').then(function(result) {
                    if (result.success) {
                      const position = {
                        coords: {
                          latitude: result.latitude,
                          longitude: result.longitude,
                          accuracy: result.accuracy,
                          altitude: null,
                          altitudeAccuracy: null,
                          heading: null,
                          speed: null
                        },
                        timestamp: result.timestamp || Date.now()
                      };
                      console.log('Geolocation success:', position);
                      successCallback(position);
                    } else {
                      console.error('Geolocation error:', result.error);
                      if (errorCallback) {
                        errorCallback({
                          code: 1,
                          message: result.error
                        });
                      }
                    }
                  }).catch(function(error) {
                    console.error('Geolocation handler error:', error);
                    if (errorCallback) {
                      errorCallback({
                        code: 2,
                        message: 'Failed to get location'
                      });
                    }
                  });
                };
                
                navigator.geolocation.watchPosition = function(successCallback, errorCallback, options) {
                  console.log('Geolocation watchPosition called');
                  // For watchPosition, we'll call getCurrentPosition repeatedly
                  const watchId = setInterval(function() {
                    navigator.geolocation.getCurrentPosition(successCallback, errorCallback, options);
                  }, (options && options.timeout) || 10000);
                  
                  return watchId;
                };
                
                navigator.geolocation.clearWatch = function(watchId) {
                  clearInterval(watchId);
                };
              }
              
              // Handle file input clicks
              document.addEventListener('click', function(event) {
                if (event.target.type === 'file' && event.target.accept && event.target.accept.includes('image')) {
                  event.preventDefault();
                  
                  // Call Flutter file upload handler
                  window.flutter_inappwebview.callHandler('fileUpload').then(function(result) {
                    if (result.success) {
                      // Create a file-like object and trigger change event
                      const file = {
                        name: result.fileName,
                        size: result.fileSize,
                        type: 'image/jpeg',
                        lastModified: Date.now()
                      };
                      
                      // Create DataTransfer object to simulate file selection
                      const dataTransfer = new DataTransfer();
                      
                      // Convert base64 to blob
                      const base64Data = result.fileData.split(',')[1];
                      const byteCharacters = atob(base64Data);
                      const byteNumbers = new Array(byteCharacters.length);
                      for (let i = 0; i < byteCharacters.length; i++) {
                        byteNumbers[i] = byteCharacters.charCodeAt(i);
                      }
                      const byteArray = new Uint8Array(byteNumbers);
                      const blob = new Blob([byteArray], {type: 'image/jpeg'});
                      
                      // Create file from blob
                      const fileFromBlob = new File([blob], result.fileName, {type: 'image/jpeg'});
                      dataTransfer.items.add(fileFromBlob);
                      
                      // Set files to input
                      event.target.files = dataTransfer.files;
                      
                      // Trigger change event
                      const changeEvent = new Event('change', { bubbles: true });
                      event.target.dispatchEvent(changeEvent);
                      
                      console.log('File selected:', result.fileName);
                    } else {
                      console.error('File selection failed:', result.error);
                    }
                  }).catch(function(error) {
                    console.error('Error calling file upload handler:', error);
                  });
                }
              });
              
              // Log cookies and localStorage for debugging
              window.flutter_inappwebview.callHandler('debug', 'Cookies: ' + document.cookie);
              let localStorageItems = {};
              for (let i = 0; i < localStorage.length; i++) {
                const key = localStorage.key(i);
                localStorageItems[key] = localStorage.getItem(key);
              }
              window.flutter_inappwebview.callHandler('debug', 'LocalStorage: ' + JSON.stringify(localStorageItems));
              
              console.log('Flutter WebView JavaScript injection completed');
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
                      color: Colors.red,
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
