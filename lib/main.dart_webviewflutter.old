// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // More aggressive permission requesting
  await _requestAllPermissions();

  runApp(const MyApp());
}

Future<void> _requestAllPermissions() async {
  print('=== Starting Permission Requests ===');

  // Request location permission using permission_handler
  var locationStatus = await Permission.location.request();
  print('Permission.location status: $locationStatus');

  var locationWhenInUseStatus = await Permission.locationWhenInUse.request();
  print('Permission.locationWhenInUse status: $locationWhenInUseStatus');

  // Also check geolocator permissions
  LocationPermission geoPermission = await Geolocator.checkPermission();
  print('Geolocator permission: $geoPermission');

  if (geoPermission == LocationPermission.denied) {
    geoPermission = await Geolocator.requestPermission();
    print('Geolocator permission after request: $geoPermission');
  }

  // Check if location services are enabled
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  print('Location services enabled: $serviceEnabled');

  // Request other permissions
  await Permission.camera.request();
  await Permission.storage.request();

  print('=== Permission Requests Complete ===');
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
  late final WebViewController _controller;
  int progress = 0;
  bool isLoading = true;
  final ImagePicker _picker = ImagePicker();

  // final String targetUrl = "https://tesla-smartwork.transtama.com";
  // final String targetUrl = "http://192.168.3.143/transtama-tesla";
  final String targetUrl =
      "https://39bf-103-237-140-137.ngrok-free.app/transtama-tesla";

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(const Color(0x00000000))
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (int progress) {
                setState(() {
                  this.progress = progress;
                  if (progress == 100) {
                    isLoading = false;
                  }
                });
              },
              onPageStarted: (String url) {
                setState(() {
                  isLoading = true;
                  progress = 0;
                });
                debugPrint('Page started loading: $url');
              },
              onPageFinished: (String url) {
                setState(() {
                  isLoading = false;
                  progress = 100;
                });
                debugPrint('Page finished loading: $url');

                // Inject comprehensive JavaScript
                _controller.runJavaScript('''
              // Enhanced console logging
              const originalLog = console.log;
              const originalError = console.error;
              const originalWarn = console.warn;
              
              
              console.log = function(...args) {
                originalLog.apply(console, args);
                try {
                  window.flutter_inappwebview?.callHandler('debug', 'LOG: ' + args.join(' '));
                } catch(e) {}
              };
              
              console.error = function(...args) {
                originalError.apply(console, args);
                try {
                  window.flutter_inappwebview?.callHandler('debug', 'ERROR: ' + args.join(' '));
                } catch(e) {}
              };
              
              console.warn = function(...args) {
                originalWarn.apply(console, args);
                try {
                  window.flutter_inappwebview?.callHandler('debug', 'WARN: ' + args.join(' '));
                } catch(e) {}
              };
              
              console.log('JavaScript injection started');
              
              // Test if geolocation is available
              console.log('Navigator geolocation available:', !!navigator.geolocation);
              
              // Store original geolocation methods
              if (navigator.geolocation) {
                window.originalGetCurrentPosition = navigator.geolocation.getCurrentPosition.bind(navigator.geolocation);
                window.originalWatchPosition = navigator.geolocation.watchPosition.bind(navigator.geolocation);
                
                console.log('Original geolocation methods stored');
              }
              
              // Override geolocation methods
              if (navigator.geolocation) {
                navigator.geolocation.getCurrentPosition = function(success, error, options) {
                  console.log('getCurrentPosition called with options:', options);
                  
                  // Store callbacks globally
                  window.geolocationSuccess = success;
                  window.geolocationError = error;
                  
                  // Send request to Flutter
                  try {
                    window.geolocationHandler.postMessage(JSON.stringify({
                      action: 'getCurrentPosition',
                      options: options || {}
                    }));
                    console.log('Geolocation request sent to Flutter');
                  } catch(e) {
                    console.error('Failed to send geolocation request:', e);
                    if (error) {
                      error({
                        code: 2,
                        message: 'Failed to communicate with native layer'
                      });
                    }
                  }
                };
                
                navigator.geolocation.watchPosition = function(success, error, options) {
                  console.log('watchPosition called');
                  window.geolocationSuccess = success;
                  window.geolocationError = error;
                  
                  try {
                    window.geolocationHandler.postMessage(JSON.stringify({
                      action: 'watchPosition',
                      options: options || {}
                    }));
                  } catch(e) {
                    console.error('Failed to send watch position request:', e);
                  }
                  
                  return 1; // dummy watch ID
                };
                
                console.log('Geolocation methods overridden');
              }
              
              // Success callback from Flutter
              window.geolocationCallback = function(latitude, longitude, accuracy) {
                console.log('Received location from Flutter:', {
                  latitude: latitude,
                  longitude: longitude,
                  accuracy: accuracy
                });
                
                if (window.geolocationSuccess) {
                  const position = {
                    coords: {
                      latitude: latitude,
                      longitude: longitude,
                      accuracy: accuracy,
                      altitude: null,
                      altitudeAccuracy: null,
                      heading: null,
                      speed: null
                    },
                    timestamp: Date.now()
                  };
                  
                  console.log('Calling success callback with position:', position);
                  window.geolocationSuccess(position);
                  
                  // Also update koordinat field directly
                  const koordinatField = document.getElementById('koordinat');
                  if (koordinatField) {
                    const koordinatValue = latitude + ',' + longitude;
                    koordinatField.value = koordinatValue;
                    console.log('Updated koordinat field to:', koordinatValue);
                    
                    // Trigger events
                    koordinatField.dispatchEvent(new Event('change', { bubbles: true }));
                    koordinatField.dispatchEvent(new Event('input', { bubbles: true }));
                    
                    // Show success message
                    // window.showLocationMessage('✅ Location: ' + koordinatValue, 'success');
                  } else {
                    console.warn('koordinat field not found');
                  }
                } else {
                  console.warn('No success callback available');
                }
              };
              
              // Error callback from Flutter
              window.geolocationErrorCallback = function(code, message) {
                console.error('Geolocation error from Flutter:', { code: code, message: message });
                
                if (window.geolocationError) {
                  const error = {
                    code: code,
                    message: message,
                    PERMISSION_DENIED: 1,
                    POSITION_UNAVAILABLE: 2,
                    TIMEOUT: 3
                  };
                  
                  console.log('Calling error callback with:', error);
                  window.geolocationError(error);
                } else {
                  console.warn('No error callback available');
                }
                
                // Show error message to user
                window.showLocationMessage('❌ ' + message, 'error');
              };
              
              // Utility function to show messages
              window.showLocationMessage = function(text, type) {
                console.log('Showing message:', text, type);
                
                // Remove existing messages
                const existingMessages = document.querySelectorAll('.location-message');
                existingMessages.forEach(msg => msg.remove());
                
                // Create new message
                const messageDiv = document.createElement('div');
                messageDiv.className = 'location-message';
                messageDiv.textContent = text;
                messageDiv.style.cssText = 
                  'position: fixed; top: 10px; right: 10px; padding: 10px; ' +
                  'border-radius: 5px; z-index: 9999; max-width: 300px; color: white; ' +
                  'background: ' + (type === 'success' ? 'green' : 'red') + ';';
                
                document.body.appendChild(messageDiv);
                
                // Auto remove after 5 seconds
                setTimeout(() => {
                  if (messageDiv.parentNode) {
                    messageDiv.remove();
                  }
                }, 5000);
              };
              
              // Test geolocation immediately when page loads
              window.testGeolocation = function() {
                console.log('Testing geolocation...');
                
                if (!navigator.geolocation) {
                  console.error('Geolocation not supported');
                  window.showLocationMessage('❌ Geolocation not supported', 'error');
                  return;
                }
                
                console.log('Requesting current position...');
                navigator.geolocation.getCurrentPosition(
                  function(position) {
                    console.log('Test geolocation success:', position);
                  },
                  function(error) {
                    console.error('Test geolocation error:', error);
                  },
                  {
                    enableHighAccuracy: true,
                    timeout: 15000,
                    maximumAge: 0
                  }
                );
              };
              
              // Add manual location button
              window.addManualLocationButton = function() {
                const koordinatField = document.getElementById('koordinat');
                if (koordinatField && !document.getElementById('manual-location-btn')) {
                  const container = document.createElement('div');
                  container.style.marginTop = '10px';
                  
                  // const testBtn = document.createElement('button');
                  // testBtn.textContent = '🧪 Test Location';
                  // testBtn.style.cssText = 'margin-right: 10px; padding: 5px 10px; background: #17a2b8; color: white; border: none; border-radius: 3px; cursor: pointer;';
                  // testBtn.onclick = window.testGeolocation;
                  
                  // const manualBtn = document.createElement('button');
                  // manualBtn.id = 'manual-location-btn';
                  // manualBtn.textContent = '📍 Manual Entry';
                  // manualBtn.style.cssText = 'padding: 5px 10px; background: #28a745; color: white; border: none; border-radius: 3px; cursor: pointer;';
                  // manualBtn.onclick = function() {
                  //   const lat = prompt('Enter Latitude (e.g., -6.2088):');
                  //   const lng = prompt('Enter Longitude (e.g., 106.8456):');
                  //   if (lat && lng && !isNaN(parseFloat(lat)) && !isNaN(parseFloat(lng))) {
                  //     const koordinatValue = lat + ',' + lng;
                  //     koordinatField.value = koordinatValue;
                  //     koordinatField.dispatchEvent(new Event('change', { bubbles: true }));
                  //     window.showLocationMessage('✅ Manual location: ' + koordinatValue, 'success');
                  //   } else {
                  //     alert('Please enter valid latitude and longitude values');
                  //   }
                  // };
                  
                  // container.appendChild(testBtn);
                  // container.appendChild(manualBtn);
                  // koordinatField.parentNode.appendChild(container);
                  
                  console.log('Manual location buttons added');
                }
              };
              
              // File handling (unchanged)
              document.addEventListener('click', function(e) {
                if (e.target.type === 'file') {
                  e.preventDefault();
                  e.stopPropagation();
                  
                  const accept = e.target.accept || '';
                  let fileType = 'image';
                  
                  if (accept.includes('video')) {
                    fileType = 'video';
                  } else if (accept.includes('image')) {
                    fileType = 'image';
                  }
                  
                  window.currentFileInput = e.target;
                  window.fileHandler.postMessage(fileType);
                }
              }, true);
              
              window.fileCallback = function(dataUrl, fileName, mimeType) {
                if (window.currentFileInput) {
                  fetch(dataUrl)
                    .then(res => res.blob())
                    .then(blob => {
                      const file = new File([blob], fileName, { 
                        type: mimeType,
                        lastModified: Date.now()
                      });
                      const dt = new DataTransfer();
                      dt.items.add(file);
                      window.currentFileInput.files = dt.files;
                      
                      const event = new Event('change', { bubbles: true });
                      window.currentFileInput.dispatchEvent(event);
                      
                      const inputEvent = new Event('input', { bubbles: true });
                      window.currentFileInput.dispatchEvent(inputEvent);
                      
                      console.log('File set:', fileName, mimeType, file.size + ' bytes');
                    })
                    .catch(err => {
                      console.error('Error creating file:', err);
                    });
                }
              };
              
              // Initialize everything after a short delay
              setTimeout(() => {
                console.log('Initializing location features...');
                window.addManualLocationButton();
                
                // Auto-test geolocation after page loads
                setTimeout(() => {
                  console.log('Auto-testing geolocation...');
                  window.testGeolocation();
                }, 2000);
              }, 1000);
              
              console.log('JavaScript injection completed');
            ''');
              },
              onWebResourceError: (WebResourceError error) {
                setState(() {
                  isLoading = false;
                });
                debugPrint('WebView error: ${error.description}');
              },
              onNavigationRequest: (NavigationRequest request) {
                debugPrint('Navigating to: ${request.url}');
                return NavigationDecision.navigate;
              },
            ),
          )
          ..addJavaScriptChannel(
            'debug',
            onMessageReceived: (JavaScriptMessage message) {
              debugPrint('🌐 JS: ${message.message}');
            },
          )
          ..addJavaScriptChannel(
            'geolocationHandler',
            onMessageReceived: (JavaScriptMessage message) async {
              debugPrint('📍 Geolocation request: ${message.message}');
              await _handleGeolocationRequest(message.message);
            },
          );

    _controller.addJavaScriptChannel(
      'fileHandler',
      onMessageReceived: (JavaScriptMessage message) async {
        await _handleFileSelection(message.message);
      },
    );

    _controller.loadRequest(Uri.parse(targetUrl));
  }

  Future<void> _handleGeolocationRequest(String requestData) async {
    try {
      debugPrint('🔍 Processing geolocation request...');
      final request = jsonDecode(requestData);
      debugPrint('📋 Request details: $request');

      // Check location services first
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('🛰️ Location services enabled: $serviceEnabled');

      if (!serviceEnabled) {
        debugPrint('❌ Location services disabled');
        await _controller.runJavaScript('''
          window.geolocationErrorCallback(2, 'Location services are disabled. Please enable GPS in your device settings.');
        ''');
        return;
      }

      // Check permissions thoroughly
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('🔐 Current permission: $permission');

      if (permission == LocationPermission.denied) {
        debugPrint('🔄 Requesting permission...');
        permission = await Geolocator.requestPermission();
        debugPrint('🔐 Permission after request: $permission');
      }

      if (permission == LocationPermission.denied) {
        debugPrint('❌ Permission denied');
        await _controller.runJavaScript('''
          window.geolocationErrorCallback(1, 'Location permission denied. Please enable location access in your device settings.');
        ''');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Permission denied forever');
        await _controller.runJavaScript('''
          window.geolocationErrorCallback(1, 'Location permission permanently denied. Please go to Settings > Apps > [Your App] > Permissions and enable Location.');
        ''');
        return;
      }

      // Try to get location with multiple attempts
      debugPrint('📍 Attempting to get current position...');

      try {
        // First attempt with high accuracy
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        );

        debugPrint(
          '✅ Location obtained: ${position.latitude}, ${position.longitude}',
        );

        await _controller.runJavaScript('''
          window.geolocationCallback(${position.latitude}, ${position.longitude}, ${position.accuracy});
        ''');
      } catch (e) {
        debugPrint('⚠️ High accuracy failed: $e');

        try {
          // Second attempt with medium accuracy
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 8),
          );

          debugPrint(
            '✅ Location obtained (medium accuracy): ${position.latitude}, ${position.longitude}',
          );

          await _controller.runJavaScript('''
            window.geolocationCallback(${position.latitude}, ${position.longitude}, ${position.accuracy});
          ''');
        } catch (e2) {
          debugPrint('⚠️ Medium accuracy failed: $e2');

          try {
            // Third attempt with low accuracy
            Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 5),
            );

            debugPrint(
              '✅ Location obtained (low accuracy): ${position.latitude}, ${position.longitude}',
            );

            await _controller.runJavaScript('''
              window.geolocationCallback(${position.latitude}, ${position.longitude}, ${position.accuracy});
            ''');
          } catch (e3) {
            debugPrint('❌ All location attempts failed: $e3');
            await _controller.runJavaScript('''
              window.geolocationErrorCallback(3, 'Failed to get location after multiple attempts. Error: $e3');
            ''');
          }
        }
      }
    } catch (e) {
      debugPrint('💥 Geolocation handler error: $e');
      await _controller.runJavaScript('''
        window.geolocationErrorCallback(2, 'Location service error: $e');
      ''');
    }
  }

  // File handling methods (unchanged)
  Future<void> _handleFileSelection(String type) async {
    try {
      XFile? file;

      if (type == 'image') {
        final ImageSource? source = await _showImageSourceActionSheet();
        if (source != null) {
          file = await _picker.pickImage(source: source);
        }
      } else if (type == 'video') {
        final ImageSource? source = await _showVideoSourceActionSheet();
        if (source != null) {
          file = await _picker.pickVideo(source: source);
        }
      }

      if (file != null) {
        final bytes = await file.readAsBytes();
        final base64String = base64Encode(bytes);
        final mimeType = _getMimeType(file.path);
        final properFileName = _generateFileName(file.path, type);

        await _controller.runJavaScript('''
          if (window.fileCallback) {
            window.fileCallback('data:$mimeType;base64,$base64String', '$properFileName', '$mimeType');
          }
        ''');
      }
    } catch (e) {
      debugPrint('Error handling file selection: $e');
    }
  }

  String _generateFileName(String originalPath, String type) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = _getFileExtension(originalPath);

    if (type == 'image') {
      return 'image_$timestamp$extension';
    } else if (type == 'video') {
      return 'video_$timestamp$extension';
    } else {
      return 'file_$timestamp$extension';
    }
  }

  String _getFileExtension(String path) {
    final lowerPath = path.toLowerCase();
    if (lowerPath.endsWith('.jpg') || lowerPath.endsWith('.jpeg')) {
      return '.jpg';
    } else if (lowerPath.endsWith('.png')) {
      return '.png';
    } else if (lowerPath.endsWith('.mp4')) {
      return '.mp4';
    } else if (lowerPath.endsWith('.mov')) {
      return '.mov';
    }
    return '.jpg';
  }

  String _getMimeType(String path) {
    if (path.toLowerCase().endsWith('.jpg') ||
        path.toLowerCase().endsWith('.jpeg')) {
      return 'image/jpeg';
    } else if (path.toLowerCase().endsWith('.png')) {
      return 'image/png';
    } else if (path.toLowerCase().endsWith('.mp4')) {
      return 'video/mp4';
    } else if (path.toLowerCase().endsWith('.mov')) {
      return 'video/quicktime';
    }
    return 'application/octet-stream';
  }

  Future<ImageSource?> _showImageSourceActionSheet() async {
    return await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<ImageSource?> _showVideoSourceActionSheet() async {
    return await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.video_library),
                title: const Text('Video Gallery'),
                onTap: () {
                  Navigator.of(context).pop(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('Record Video'),
                onTap: () {
                  Navigator.of(context).pop(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _refresh() async {
    await _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await _controller.canGoBack()) {
          await _controller.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (progress < 100 && progress > 0)
                  LinearProgressIndicator(
                    value: progress / 100.0,
                    color: Colors.red,
                    backgroundColor: Colors.grey[300],
                  ),
                if (isLoading)
                  Container(
                    color: Colors.white,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
