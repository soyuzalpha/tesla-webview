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
  List<String> debugLogs = [];

  // Location debugging state
  Position? lastKnownPosition;
  String locationStatus = "Not checked";
  int locationRequestCount = 0;

  final String targetUrl = "https://tesla-smartwork.transtama.com";

  void addDebugLog(String message) {
    setState(() {
      debugLogs.add("[${DateTime.now().toIso8601String()}] $message");
      if (debugLogs.length > 100) {
        debugLogs.removeAt(0);
      }
    });
    debugPrint(message);
  }

  // Enhanced location debugging method
  Future<void> checkLocationAvailability() async {
    addDebugLog("=== LOCATION AVAILABILITY CHECK ===");

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      addDebugLog("📍 Location services enabled: $serviceEnabled");

      if (!serviceEnabled) {
        setState(() {
          locationStatus = "Location services disabled";
        });
        addDebugLog("❌ Location services are disabled - Cannot get location");
        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      addDebugLog("🔐 Current permission status: $permission");

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        addDebugLog("🔐 Permission after request: $permission");
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          locationStatus = "Permission denied forever";
        });
        addDebugLog("❌ Location permission denied forever");
        return;
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          locationStatus = "Permission denied";
        });
        addDebugLog("❌ Location permission denied");
        return;
      }

      // Try to get current position
      addDebugLog("🎯 Attempting to get current position...");
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        lastKnownPosition = position;
        locationStatus = "Available";
      });

      addDebugLog("✅ LOCATION OBTAINED:");
      addDebugLog("   📍 Latitude: ${position.latitude}");
      addDebugLog("   📍 Longitude: ${position.longitude}");
      addDebugLog("   📍 Accuracy: ${position.accuracy}m");
      addDebugLog("   📍 Altitude: ${position.altitude}m");
      addDebugLog("   📍 Speed: ${position.speed}m/s");
      addDebugLog("   📍 Heading: ${position.heading}°");
      addDebugLog("   📍 Timestamp: ${position.timestamp}");
      addDebugLog("   📍 Is Mocked: ${position.isMocked}");
      addDebugLog("=== LOCATION CHECK COMPLETE ===");
    } catch (e) {
      setState(() {
        locationStatus = "Error: $e";
      });
      addDebugLog("❌ LOCATION ERROR: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(color: Colors.red),
      onRefresh: () async {
        webViewController.reload();
      },
    );

    // Check location availability on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkLocationAvailability();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await webViewController.canGoBack()) {
          webViewController.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        // appBar: AppBar(
        //   title: const Text('Tesla WebView - Location Debug'),
        //   backgroundColor: Colors.red,
        //   foregroundColor: Colors.white,
        //   actions: [
        //     IconButton(
        //       icon: const Icon(Icons.location_on),
        //       onPressed: checkLocationAvailability,
        //       tooltip: 'Check Location',
        //     ),
        //     IconButton(
        //       icon: const Icon(Icons.bug_report),
        //       onPressed: () {
        //         showDialog(
        //           context: context,
        //           builder: (context) => AlertDialog(
        //             title: Row(
        //               children: [
        //                 const Icon(Icons.bug_report),
        //                 const SizedBox(width: 8),
        //                 const Text('Debug Info'),
        //               ],
        //             ),
        //             content: SizedBox(
        //               width: double.maxFinite,
        //               height: 400,
        //               child: Column(
        //                 crossAxisAlignment: CrossAxisAlignment.start,
        //                 children: [
        //                   // Location Status Card
        //                   Card(
        //                     color: locationStatus == "Available"
        //                         ? Colors.green[100]
        //                         : Colors.red[100],
        //                     child: Padding(
        //                       padding: const EdgeInsets.all(8.0),
        //                       child: Column(
        //                         crossAxisAlignment: CrossAxisAlignment.start,
        //                         children: [
        //                           Text(
        //                             'Location Status: $locationStatus',
        //                             style: const TextStyle(
        //                                 fontWeight: FontWeight.bold),
        //                           ),
        //                           if (lastKnownPosition != null) ...[
        //                             Text('Lat: ${lastKnownPosition!.latitude}'),
        //                             Text(
        //                                 'Lng: ${lastKnownPosition!.longitude}'),
        //                             Text(
        //                                 'Accuracy: ${lastKnownPosition!.accuracy}m'),
        //                           ],
        //                           Text('Requests: $locationRequestCount'),
        //                         ],
        //                       ),
        //                     ),
        //                   ),
        //                   const SizedBox(height: 10),
        //                   const Text('Debug Logs:',
        //                       style: TextStyle(fontWeight: FontWeight.bold)),
        //                   const SizedBox(height: 5),
        //                   Expanded(
        //                     child: Container(
        //                       decoration: BoxDecoration(
        //                         border: Border.all(color: Colors.grey),
        //                         borderRadius: BorderRadius.circular(4),
        //                       ),
        //                       child: ListView.builder(
        //                         itemCount: debugLogs.length,
        //                         itemBuilder: (context, index) {
        //                           final log = debugLogs[index];
        //                           Color? bgColor;
        //                           if (log.contains('ERROR') ||
        //                               log.contains('❌')) {
        //                             bgColor = Colors.red[50];
        //                           } else if (log.contains('LOCATION') ||
        //                               log.contains('📍')) {
        //                             bgColor = Colors.blue[50];
        //                           } else if (log.contains('✅')) {
        //                             bgColor = Colors.green[50];
        //                           }

        //                           return Container(
        //                             color: bgColor,
        //                             child: Padding(
        //                               padding: const EdgeInsets.all(2.0),
        //                               child: Text(
        //                                 log,
        //                                 style: const TextStyle(
        //                                     fontSize: 10,
        //                                     fontFamily: 'monospace'),
        //                               ),
        //                             ),
        //                           );
        //                         },
        //                       ),
        //                     ),
        //                   ),
        //                 ],
        //               ),
        //             ),
        //             actions: [
        //               TextButton(
        //                 onPressed: () {
        //                   setState(() {
        //                     debugLogs.clear();
        //                   });
        //                   Navigator.pop(context);
        //                 },
        //                 child: const Text('Clear'),
        //               ),
        //               TextButton(
        //                 onPressed: () => Navigator.pop(context),
        //                 child: const Text('Close'),
        //               ),
        //             ],
        //           ),
        //         );
        //       },
        //     ),
        //   ],
        // ),
        body: SafeArea(
          child: Stack(
            children: [
              InAppWebView(
                key: webViewKey,
                initialUrlRequest: URLRequest(url: WebUri(targetUrl)),
                initialSettings: InAppWebViewSettings(
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
                  mediaPlaybackRequiresUserGesture: false,
                  allowsBackForwardNavigationGestures: true,
                  allowsLinkPreview: true,
                  isFraudulentWebsiteWarningEnabled: false,
                  disallowOverScroll: false,
                  allowsAirPlayForMediaPlayback: true,
                  allowsPictureInPictureMediaPlayback: true,
                ),
                pullToRefreshController: pullToRefreshController,
                androidOnPermissionRequest:
                    (controller, origin, resources) async {
                  addDebugLog(
                      "🔐 Android permission request: $resources from $origin");
                  return PermissionRequestResponse(
                    resources: resources,
                    action: PermissionRequestResponseAction.GRANT,
                  );
                },
                onWebViewCreated: (controller) {
                  webViewController = controller;
                  addDebugLog("🌐 WebView created successfully");

                  // Debug handler
                  controller.addJavaScriptHandler(
                    handlerName: 'debug',
                    callback: (args) {
                      addDebugLog(
                          "🔍 JS: ${args.isNotEmpty ? args[0] : 'Empty debug message'}");
                    },
                  );

                  // File upload handler
                  controller.addJavaScriptHandler(
                    handlerName: 'fileUpload',
                    callback: (args) async {
                      addDebugLog("📁 File upload handler called");
                      try {
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
                            addDebugLog(
                                "📁 Image selected: $fileName (${bytes.length} bytes)");

                            return {
                              'success': true,
                              'fileName': fileName,
                              'fileData': 'data:image/jpeg;base64,$base64Image',
                              'fileSize': bytes.length,
                            };
                          }
                        }
                        addDebugLog("📁 No image selected");
                        return {'success': false, 'error': 'No image selected'};
                      } catch (e) {
                        addDebugLog('📁 Error in file upload handler: $e');
                        return {'success': false, 'error': e.toString()};
                      }
                    },
                  );

                  // Enhanced geolocation handler with comprehensive debugging
                  controller.addJavaScriptHandler(
                    handlerName: 'getLocation',
                    callback: (args) async {
                      setState(() {
                        locationRequestCount++;
                      });

                      addDebugLog(
                          "🎯 === GEOLOCATION REQUEST #$locationRequestCount ===");
                      addDebugLog("🎯 Request args: $args");

                      try {
                        // Check and request location permissions
                        LocationPermission permission =
                            await Geolocator.checkPermission();
                        addDebugLog(
                            "🔐 Current location permission: $permission");

                        if (permission == LocationPermission.denied) {
                          permission = await Geolocator.requestPermission();
                          addDebugLog(
                              "🔐 Permission after request: $permission");
                        }

                        if (permission == LocationPermission.deniedForever) {
                          addDebugLog("❌ Location permission denied forever");
                          return {
                            'success': false,
                            'error': 'Location permission denied forever',
                            'code': 1
                          };
                        }

                        if (permission == LocationPermission.denied) {
                          addDebugLog("❌ Location permission denied");
                          return {
                            'success': false,
                            'error': 'Location permission denied',
                            'code': 1
                          };
                        }

                        // Check if location services are enabled
                        bool serviceEnabled =
                            await Geolocator.isLocationServiceEnabled();
                        addDebugLog(
                            "📍 Location service enabled: $serviceEnabled");

                        if (!serviceEnabled) {
                          addDebugLog("❌ Location services are disabled");
                          return {
                            'success': false,
                            'error': 'Location services are disabled',
                            'code': 2
                          };
                        }

                        addDebugLog("🎯 Getting current position...");

                        // Get current location with enhanced settings
                        Position position = await Geolocator.getCurrentPosition(
                          desiredAccuracy: LocationAccuracy.high,
                          timeLimit: const Duration(seconds: 15),
                          forceAndroidLocationManager: false,
                        );

                        setState(() {
                          lastKnownPosition = position;
                          locationStatus = "Available";
                        });

                        addDebugLog("✅ === POSITION OBTAINED ===");
                        addDebugLog("📍 Latitude: ${position.latitude}");
                        addDebugLog("📍 Longitude: ${position.longitude}");
                        addDebugLog("📍 Accuracy: ${position.accuracy}m");
                        addDebugLog("📍 Altitude: ${position.altitude}m");
                        addDebugLog("📍 Speed: ${position.speed}m/s");
                        addDebugLog("📍 Heading: ${position.heading}°");
                        addDebugLog("📍 Timestamp: ${position.timestamp}");
                        addDebugLog("📍 Is Mocked: ${position.isMocked}");
                        addDebugLog("✅ === POSITION DATA COMPLETE ===");

                        final result = {
                          'success': true,
                          'latitude': position.latitude,
                          'longitude': position.longitude,
                          'accuracy': position.accuracy,
                          'altitude': position.altitude,
                          'heading': position.heading,
                          'speed': position.speed,
                          'timestamp':
                              position.timestamp.millisecondsSinceEpoch,
                          'isMocked': position.isMocked,
                        };

                        addDebugLog(
                            "🎯 Returning location result to JS: $result");
                        return result;
                      } catch (e) {
                        addDebugLog('❌ Error getting location: $e');
                        setState(() {
                          locationStatus = "Error: $e";
                        });
                        return {
                          'success': false,
                          'error': e.toString(),
                          'code': 3
                        };
                      }
                    },
                  );

                  // Network request interceptor
                  controller.addJavaScriptHandler(
                    handlerName: 'networkRequest',
                    callback: (args) {
                      addDebugLog("🌐 Network request intercepted: $args");
                    },
                  );
                },
                onLoadStart: (controller, url) {
                  setState(() {
                    isLoading = true;
                  });
                  addDebugLog('🌐 Page started loading: $url');
                },
                onLoadStop: (controller, url) async {
                  pullToRefreshController?.endRefreshing();
                  setState(() {
                    isLoading = false;
                  });
                  addDebugLog('🌐 Page finished loading: $url');

                  // Enhanced JavaScript injection with comprehensive location debugging
                  await controller.evaluateJavascript(source: '''
                    // Enhanced console methods for debugging
                    const originalConsoleLog = console.log;
                    const originalConsoleError = console.error;
                    const originalConsoleWarn = console.warn;
                    
                    console.log = function(...args) {
                      const message = args.map(arg => typeof arg === 'object' ? JSON.stringify(arg) : String(arg)).join(' ');
                      window.flutter_inappwebview.callHandler('debug', 'LOG: ' + message);
                      originalConsoleLog.apply(console, args);
                    };
                    
                    console.error = function(...args) {
                      const message = args.map(arg => typeof arg === 'object' ? JSON.stringify(arg) : String(arg)).join(' ');
                      window.flutter_inappwebview.callHandler('debug', 'ERROR: ' + message);
                      originalConsoleError.apply(console, args);
                    };
                    
                    console.warn = function(...args) {
                      const message = args.map(arg => typeof arg === 'object' ? JSON.stringify(arg) : String(arg)).join(' ');
                      window.flutter_inappwebview.callHandler('debug', 'WARN: ' + message);
                      originalConsoleWarn.apply(console, args);
                    };
                    
                    // Location debugging counter
                    let locationRequestCounter = 0;
                    
                    // Enhanced geolocation override with comprehensive debugging
                    if (navigator.geolocation) {
                      console.log('🎯 Geolocation API detected, overriding...');
                      
                      const originalGetCurrentPosition = navigator.geolocation.getCurrentPosition;
                      const originalWatchPosition = navigator.geolocation.watchPosition;
                      const originalClearWatch = navigator.geolocation.clearWatch;
                      
                      navigator.geolocation.getCurrentPosition = function(successCallback, errorCallback, options) {
                        locationRequestCounter++;
                        console.log('🎯 === GEOLOCATION REQUEST #' + locationRequestCounter + ' ===');
                        console.log('🎯 Called with options:', options);
                        console.log('🎯 Success callback type:', typeof successCallback);
                        console.log('🎯 Error callback type:', typeof errorCallback);
                        
                        window.flutter_inappwebview.callHandler('debug', '🎯 Geolocation request #' + locationRequestCounter + ' - Options: ' + JSON.stringify(options || {}));
                        
                        window.flutter_inappwebview.callHandler('getLocation', options || {}).then(function(result) {
                          console.log('🎯 Flutter geolocation result:', result);
                          
                          if (result.success) {
                            const position = {
                              coords: {
                                latitude: result.latitude,
                                longitude: result.longitude,
                                accuracy: result.accuracy,
                                altitude: result.altitude,
                                altitudeAccuracy: null,
                                heading: result.heading,
                                speed: result.speed
                              },
                              timestamp: result.timestamp || Date.now()
                            };
                            
                            console.log('✅ === COORDINATES OBTAINED ===');
                            console.log('📍 Latitude:', position.coords.latitude);
                            console.log('📍 Longitude:', position.coords.longitude);
                            console.log('📍 Accuracy:', position.coords.accuracy + 'm');
                            console.log('📍 Altitude:', position.coords.altitude + 'm');
                            console.log('📍 Speed:', position.coords.speed + 'm/s');
                            console.log('📍 Heading:', position.coords.heading + '°');
                            console.log('📍 Timestamp:', new Date(position.timestamp).toISOString());
                            console.log('✅ === CALLING SUCCESS CALLBACK ===');
                            
                            window.flutter_inappwebview.callHandler('debug', '✅ Geolocation success #' + locationRequestCounter + ' - Lat: ' + position.coords.latitude + ', Lng: ' + position.coords.longitude + ', Acc: ' + position.coords.accuracy + 'm');
                            
                            if (successCallback) {
                              successCallback(position);
                              console.log('✅ Success callback executed');
                            } else {
                              console.warn('⚠️ No success callback provided');
                            }
                          } else {
                            console.error('❌ Geolocation failed:', result.error);
                            window.flutter_inappwebview.callHandler('debug', '❌ Geolocation failed #' + locationRequestCounter + ': ' + result.error);
                            
                            if (errorCallback) {
                              const error = {
                                code: result.code || 2,
                                message: result.error || 'Unknown error',
                                PERMISSION_DENIED: 1,
                                POSITION_UNAVAILABLE: 2,
                                TIMEOUT: 3
                              };
                              errorCallback(error);
                              console.log('❌ Error callback executed with code:', error.code);
                            } else {
                              console.warn('⚠️ No error callback provided');
                            }
                          }
                        }).catch(function(error) {
                          console.error('❌ Geolocation handler error:', error);
                          window.flutter_inappwebview.callHandler('debug', '❌ Geolocation handler error #' + locationRequestCounter + ': ' + error);
                          
                          if (errorCallback) {
                            errorCallback({
                              code: 2,
                              message: 'Failed to get location: ' + error,
                              PERMISSION_DENIED: 1,
                              POSITION_UNAVAILABLE: 2,
                              TIMEOUT: 3
                            });
                          }
                        });
                      };
                      
                      navigator.geolocation.watchPosition = function(successCallback, errorCallback, options) {
                        console.log('🎯 Geolocation watchPosition called with options:', options);
                        window.flutter_inappwebview.callHandler('debug', '🎯 watchPosition called with options: ' + JSON.stringify(options || {}));
                        
                        // Call getCurrentPosition immediately
                        navigator.geolocation.getCurrentPosition(successCallback, errorCallback, options);
                        
                        // Then set up interval for watching
                        const interval = (options && options.timeout) || 10000;
                        const watchId = setInterval(function() {
                          console.log('🎯 Watch position interval triggered');
                          navigator.geolocation.getCurrentPosition(successCallback, errorCallback, options);
                        }, interval);
                        
                        console.log('🎯 Watch ID created:', watchId);
                        window.flutter_inappwebview.callHandler('debug', '🎯 Watch ID created: ' + watchId);
                        return watchId;
                      };
                      
                      navigator.geolocation.clearWatch = function(watchId) {
                        console.log('🎯 Clearing watch ID:', watchId);
                        window.flutter_inappwebview.callHandler('debug', '🎯 Clearing watch ID: ' + watchId);
                        clearInterval(watchId);
                      };
                      
                      console.log('✅ Geolocation API override completed');
                    } else {
                      console.error('❌ Geolocation API not available');
                      window.flutter_inappwebview.callHandler('debug', '❌ Geolocation API not available in this browser');
                    }
                    
                    // Test location immediately
                    console.log('🎯 Testing location availability...');
                    if (navigator.geolocation) {
                      navigator.geolocation.getCurrentPosition(
                        function(position) {
                          console.log('✅ Initial location test successful');
                          console.log('📍 Test coordinates:', position.coords.latitude, position.coords.longitude);
                          window.flutter_inappwebview.callHandler('debug', '✅ Initial location test: ' + position.coords.latitude + ', ' + position.coords.longitude);
                        },
                        function(error) {
                          console.error('❌ Initial location test failed:', error);
                          window.flutter_inappwebview.callHandler('debug', '❌ Initial location test failed: ' + error.message);
                        },
                        {
                          enableHighAccuracy: true,
                          timeout: 10000,
                          maximumAge: 60000
                        }
                      );
                    }
                    
                    // Enhanced file input handling
                    document.addEventListener('click', function(event) {
                      if (event.target.type === 'file' && event.target.accept && event.target.accept.includes('image')) {
                        console.log('📁 File input clicked');
                        event.preventDefault();
                        
                        window.flutter_inappwebview.callHandler('fileUpload').then(function(result) {
                          if (result.success) {
                            console.log('📁 File upload success:', result.fileName);
                            
                            const base64Data = result.fileData.split(',')[1];
                            const byteCharacters = atob(base64Data);
                            const byteNumbers = new Array(byteCharacters.length);
                            for (let i = 0; i < byteCharacters.length; i++) {
                              byteNumbers[i] = byteCharacters.charCodeAt(i);
                            }
                            const byteArray = new Uint8Array(byteNumbers);
                            const blob = new Blob([byteArray], {type: 'image/jpeg'});
                            
                            const fileFromBlob = new File([blob], result.fileName, {
                              type: 'image/jpeg',
                              lastModified: Date.now()
                            });
                            
                            const dataTransfer = new DataTransfer();
                            dataTransfer.items.add(fileFromBlob);
                            event.target.files = dataTransfer.files;
                            
                            const changeEvent = new Event('change', { bubbles: true });
                            event.target.dispatchEvent(changeEvent);
                            
                            console.log('📁 File change event dispatched');
                          } else {
                            console.error('📁 File selection failed:', result.error);
                          }
                        }).catch(function(error) {
                          console.error('📁 Error calling file upload handler:', error);
                        });
                      }
                    });
                    
                    // Debug information
                    console.log('🌐 User Agent:', navigator.userAgent);
                    console.log('🌐 URL:', window.location.href);
                    console.log('🌐 Protocol:', window.location.protocol);
                    console.log('🔐 Cookies:', document.cookie);
                    console.log('🔐 Origin:', window.location.origin);
                    console.log('🔐 Host:', window.location.host);
                    
                    // Check if geolocation is available
                    if ('geolocation' in navigator) {
                      console.log('✅ Geolocation API is available');
                      window.flutter_inappwebview.callHandler('debug', '✅ Geolocation API is available');
                    } else {
                      console.error('❌ Geolocation API is not available');
                      window.flutter_inappwebview.callHandler('debug', '❌ Geolocation API is not available');
                    }
                    
                    // Check HTTPS requirement
                    if (window.location.protocol === 'https:') {
                      console.log('✅ HTTPS - Location should work');
                      window.flutter_inappwebview.callHandler('debug', '✅ HTTPS - Location should work');
                    } else {
                      console.warn('⚠️ HTTP - Location may not work in some browsers');
                      window.flutter_inappwebview.callHandler('debug', '⚠️ HTTP - Location may not work in some browsers');
                    }
                    
                    window.flutter_inappwebview.callHandler('debug', '✅ JavaScript injection completed - Protocol: ' + window.location.protocol);
                    console.log('✅ Flutter WebView JavaScript injection completed');
                  ''');
                },
                onProgressChanged: (controller, progress) {
                  setState(() {
                    this.progress = progress;
                  });
                },
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  var uri = navigationAction.request.url;
                  addDebugLog('🌐 Navigation to: $uri');
                  return NavigationActionPolicy.ALLOW;
                },
                androidOnGeolocationPermissionsShowPrompt:
                    (controller, origin) async {
                  addDebugLog(
                      "🔐 Android geolocation permission prompt for: $origin");
                  return GeolocationPermissionShowPromptResponse(
                    origin: origin,
                    allow: true,
                    retain: true,
                  );
                },
                onConsoleMessage: (controller, consoleMessage) {
                  String emoji = '';
                  switch (consoleMessage.messageLevel) {
                    case ConsoleMessageLevel.LOG:
                      emoji = '📝';
                      break;
                    case ConsoleMessageLevel.ERROR:
                      emoji = '❌';
                      break;
                    case ConsoleMessageLevel.WARNING:
                      emoji = '⚠️';
                      break;
                    case ConsoleMessageLevel.DEBUG:
                      emoji = '🔍';
                      break;
                    case ConsoleMessageLevel.TIP:
                      emoji = '💡';
                      break;
                  }
                  addDebugLog(
                      '$emoji Console [${consoleMessage.messageLevel}]: ${consoleMessage.message}');
                },
                onLoadError: (controller, url, code, message) {
                  pullToRefreshController?.endRefreshing();
                  addDebugLog(
                      '❌ Load error - URL: $url, Code: $code, Message: $message');
                },
                onGeolocationPermissionsShowPrompt: (controller, origin) async {
                  addDebugLog("🔐 Geolocation permission prompt for: $origin");
                  return GeolocationPermissionShowPromptResponse(
                    origin: origin,
                    allow: true,
                    retain: true,
                  );
                },
                onPermissionRequest: (controller, request) async {
                  addDebugLog("🔐 Permission request: ${request.resources}");
                  return PermissionResponse(
                    resources: request.resources,
                    action: PermissionResponseAction.GRANT,
                  );
                },
                onReceivedServerTrustAuthRequest:
                    (controller, challenge) async {
                  addDebugLog(
                      "🔐 Server trust auth request for: ${challenge.protectionSpace.host}");
                  return ServerTrustAuthResponse(
                    action: ServerTrustAuthResponseAction.PROCEED,
                  );
                },
                onReceivedHttpAuthRequest: (controller, challenge) async {
                  addDebugLog(
                      "🔐 HTTP auth request for: ${challenge.protectionSpace.host}");
                  return HttpAuthResponse(
                    action: HttpAuthResponseAction.PROCEED,
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
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.red,
                      ),
                    )
                  : Container(),
              // Location Status Overlay
              // Positioned(
              //   top: 10,
              //   left: 10,
              //   child: Container(
              //     padding:
              //         const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              //     decoration: BoxDecoration(
              //       color: locationStatus == "Available"
              //           ? Colors.green
              //           : Colors.red,
              //       borderRadius: BorderRadius.circular(20),
              //     ),
              //     child: Row(
              //       mainAxisSize: MainAxisSize.min,
              //       children: [
              //         Icon(
              //           locationStatus == "Available"
              //               ? Icons.location_on
              //               : Icons.location_off,
              //           color: Colors.white,
              //           size: 16,
              //         ),
              //         const SizedBox(width: 4),
              //         Text(
              //           locationStatus == "Available"
              //               ? "Location: ON"
              //               : "Location: OFF",
              //           style: const TextStyle(
              //             color: Colors.white,
              //             fontSize: 12,
              //             fontWeight: FontWeight.bold,
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
              // Request Counter
              // if (locationRequestCount > 0)
              //   Positioned(
              //     top: 10,
              //     right: 10,
              //     child: Container(
              //       padding:
              //           const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              //       decoration: BoxDecoration(
              //         color: Colors.blue,
              //         borderRadius: BorderRadius.circular(15),
              //       ),
              //       child: Text(
              //         "Requests: $locationRequestCount",
              //         style: const TextStyle(
              //           color: Colors.white,
              //           fontSize: 11,
              //           fontWeight: FontWeight.bold,
              //         ),
              //       ),
              //     ),
              //   ),
              // Current Coordinates Display
              // if (lastKnownPosition != null)
              //   Positioned(
              //     bottom: 10,
              //     left: 10,
              //     right: 10,
              //     child: Container(
              //       padding: const EdgeInsets.all(12),
              //       decoration: BoxDecoration(
              //         color: Colors.black87,
              //         borderRadius: BorderRadius.circular(8),
              //       ),
              //       child: Column(
              //         mainAxisSize: MainAxisSize.min,
              //         crossAxisAlignment: CrossAxisAlignment.start,
              //         children: [
              //           const Text(
              //             "📍 Current Location:",
              //             style: TextStyle(
              //               color: Colors.white,
              //               fontSize: 12,
              //               fontWeight: FontWeight.bold,
              //             ),
              //           ),
              //           const SizedBox(height: 4),
              //           Text(
              //             "Lat: ${lastKnownPosition!.latitude.toStringAsFixed(6)}",
              //             style: const TextStyle(
              //               color: Colors.greenAccent,
              //               fontSize: 11,
              //               fontFamily: 'monospace',
              //             ),
              //           ),
              //           Text(
              //             "Lng: ${lastKnownPosition!.longitude.toStringAsFixed(6)}",
              //             style: const TextStyle(
              //               color: Colors.greenAccent,
              //               fontSize: 11,
              //               fontFamily: 'monospace',
              //             ),
              //           ),
              //           Text(
              //             "Accuracy: ${lastKnownPosition!.accuracy.toStringAsFixed(1)}m",
              //             style: const TextStyle(
              //               color: Colors.yellowAccent,
              //               fontSize: 11,
              //               fontFamily: 'monospace',
              //             ),
              //           ),
              //           Text(
              //             "Updated: ${DateTime.fromMillisecondsSinceEpoch(lastKnownPosition!.timestamp.millisecondsSinceEpoch).toLocal().toString().split('.')[0]}",
              //             style: const TextStyle(
              //               color: Colors.grey,
              //               fontSize: 10,
              //             ),
              //           ),
              //         ],
              //       ),
              //     ),
              //   ),
            ],
          ),
        ),
        // floatingActionButton: FloatingActionButton(
        //   backgroundColor: Colors.red,
        //   onPressed: checkLocationAvailability,
        //   child: const Icon(Icons.my_location, color: Colors.white),
        // ),
      ),
    );
  }
}
