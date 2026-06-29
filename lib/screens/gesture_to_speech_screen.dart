// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter_tts/flutter_tts.dart';
// import 'package:provider/provider.dart';
// import 'package:flutter/services.dart';
// import '../theme/theme_provider.dart';

// class GestureToSpeechScreen extends StatefulWidget {
//   const GestureToSpeechScreen({super.key});

//   @override
//   State<GestureToSpeechScreen> createState() => _GestureToSpeechScreenState();
// }

// class _GestureToSpeechScreenState extends State<GestureToSpeechScreen> {
//   CameraController? _controller;
//   List<CameraDescription>? _cameras;
//   String _resultText = "Waiting for gesture...";
//   bool _isProcessing = false;

//   // Livestream Variables
//   Timer? _timer;
//   bool _isLiveMode = false;

//   // Text to Speech Variables
//   final FlutterTts _flutterTts = FlutterTts();
//   bool _isAudioEnabled = true;
//   String _lastSpokenSign = "";

//   // ================== SERVER URL CONFIG ==================
//   static const String SERVER_URL = String.fromEnvironment(
//     'SERVER_URL',
//     defaultValue: 'https://myappGESCOM.com', // ← Your Render domain
//   );

//   static const String PREDICT_ENDPOINT = '$SERVER_URL/predict-gesture';
//   // =======================================================

//   @override
//   void initState() {
//     super.initState();
//     _initTts();
//     _initializeCamera();
//   }

//   Future<void> _initTts() async {
//     await _flutterTts.setLanguage("en-US");
//     await _flutterTts.setPitch(1.0);
//     await _flutterTts.setVolume(1.0);
//     await _flutterTts.setSpeechRate(0.5);
//   }

//   Future<void> _speak(String text) async {
//     if (text.isNotEmpty) {
//       await _flutterTts.speak(text);
//     }
//   }

//   Future<void> _stop() async {
//     await _flutterTts.stop();
//   }

//   Future<void> _initializeCamera() async {
//     try {
//       _cameras = await availableCameras();
//       if (_cameras != null && _cameras!.isNotEmpty) {
//         int cameraIndex = _cameras!.length > 1 ? 1 : 0;
//         _controller = CameraController(
//           _cameras![cameraIndex],
//           ResolutionPreset.high,
//           enableAudio: false,
//         );
//         await _controller!.initialize();
//         if (mounted) setState(() {});
//       }
//     } catch (e) {
//       print("Error initializing camera: $e");
//     }
//   }

//   void _toggleLiveDetection() {
//     if (_isLiveMode) {
//       _timer?.cancel();
//       setState(() {
//         _isLiveMode = false;
//         _resultText = "Stream Stopped";
//       });
//     } else {
//       setState(() {
//         _isLiveMode = true;
//         _resultText = "Starting live detection...";
//         _lastSpokenSign = "";
//       });
//       _captureAndPredict();
//       _timer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
//         _captureAndPredict();
//       });
//     }
//   }

//   Future<void> _captureAndPredict() async {
//     if (_controller == null || !_controller!.value.isInitialized) return;
//     if (_isProcessing) return;

//     _isProcessing = true;

//     try {
//       final image = await _controller!.takePicture();

//       var request = http.MultipartRequest('POST', Uri.parse(PREDICT_ENDPOINT));
//       request.files.add(await http.MultipartFile.fromPath('file', image.path));

//       final response = await request.send();

//       if (response.statusCode == 200) {
//         final respStr = await response.stream.bytesToString();
//         final jsonResponse = jsonDecode(respStr);

//         String detectedSign = jsonResponse['sign_detected'] ??
//                              jsonResponse['prediction'] ??
//                              "Unknown";

//         var confidenceRaw = jsonResponse['confidence'] ?? 0.0;
//         double conf = (confidenceRaw is num ? confidenceRaw.toDouble() : 0.0) * 100;

//         if (mounted) {
//           setState(() {
//             _resultText = conf > 60.0
//                 ? "Detected: $detectedSign (${conf.toStringAsFixed(1)}%)"
//                 : "Low confidence: $detectedSign (${conf.toStringAsFixed(1)}%)";
//           });

//           if (_isAudioEnabled && 
//               detectedSign != _lastSpokenSign && 
//               detectedSign != "Unknown" && 
//               conf > 60.0) {
//             _speak(detectedSign);
//             _lastSpokenSign = detectedSign;
//           }
//         }
//       } else {
//         if (mounted) {
//           setState(() => _resultText = "Server Error (${response.statusCode})");
//         }
//       }
//     } catch (e) {
//       print("Prediction Error: $e");
//       if (mounted) {
//         setState(() => _resultText = "Connection Error");
//       }
//     } finally {
//       _isProcessing = false;
//     }
//   }

//   void _copyToClipboard() async {
//     if (_resultText.contains("Detected:")) {
//       await Clipboard.setData(ClipboardData(text: _resultText));
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Copied to clipboard!"),
//             duration: Duration(seconds: 2),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     _controller?.dispose();
//     _flutterTts.stop();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final themeProvider = Provider.of<ThemeProvider>(context);

//     return Scaffold(
//       backgroundColor: themeProvider.getBackgroundColor(),
//       appBar: AppBar(
//         backgroundColor: themeProvider.getCardColor(),
//         elevation: 0,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: themeProvider.getPrimaryColor()),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Text('Live Gesture to Speech', style: themeProvider.getTitleStyle()),
//         actions: [
//           IconButton(
//             icon: Icon(_isAudioEnabled ? Icons.volume_up : Icons.volume_off),
//             onPressed: () => setState(() => _isAudioEnabled = !_isAudioEnabled),
//             color: themeProvider.getPrimaryColor(),
//           ),
//           IconButton(
//             icon: const Icon(Icons.stop, color: Colors.red),
//             onPressed: _stop,
//             tooltip: 'Stop Speaking',
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             flex: 2,
//             child: Stack(
//               fit: StackFit.expand,
//               children: [
//                 if (_controller != null && _controller!.value.isInitialized)
//                   CameraPreview(_controller!)
//                 else
//                   const Center(child: CircularProgressIndicator()),

//                 if (_isLiveMode)
//                   Positioned(
//                     top: 20,
//                     right: 20,
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                       decoration: BoxDecoration(
//                         color: Colors.red.withOpacity(0.85),
//                         borderRadius: BorderRadius.circular(6),
//                       ),
//                       child: const Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(Icons.fiber_manual_record, color: Colors.white, size: 12),
//                           SizedBox(width: 6),
//                           Text("LIVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//                         ],
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),

//           Container(
//             padding: const EdgeInsets.all(20),
//             width: double.infinity,
//             decoration: BoxDecoration(
//               color: themeProvider.getCardColor(),
//               borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
//               boxShadow: [
//                 BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5)),
//               ],
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "Result:",
//                   style: TextStyle(fontSize: 14, color: themeProvider.getSecondaryTextColor()),
//                 ),
//                 const SizedBox(height: 8),

//                 Row(
//                   children: [
//                     Expanded(
//                       child: Text(
//                         _resultText,
//                         style: TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                           color: themeProvider.getTextColor(),
//                         ),
//                       ),
//                     ),
//                     if (_resultText.contains("Detected:"))
//                       IconButton(
//                         icon: Icon(Icons.copy, color: themeProvider.getPrimaryColor(), size: 28),
//                         tooltip: "Copy to clipboard",
//                         onPressed: _copyToClipboard,
//                       ),
//                   ],
//                 ),

//                 const SizedBox(height: 20),

//                 SizedBox(
//                   width: double.infinity,
//                   height: 55,
//                   child: ElevatedButton.icon(
//                     onPressed: _toggleLiveDetection,
//                     icon: Icon(_isLiveMode ? Icons.stop : Icons.play_arrow, size: 24),
//                     label: Text(
//                       _isLiveMode ? "Stop Detection" : "Start Detection",
//                       style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                     ),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: _isLiveMode ? Colors.red : themeProvider.getPrimaryColor(),
//                       foregroundColor: Colors.white,
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }







import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // ✅ Added for MediaType
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../theme/theme_provider.dart';

class GestureToSpeechScreen extends StatefulWidget {
  const GestureToSpeechScreen({super.key});

  @override
  State<GestureToSpeechScreen> createState() => _GestureToSpeechScreenState();
}

class _GestureToSpeechScreenState extends State<GestureToSpeechScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  String _resultText = "Waiting for gesture...";
  bool _isProcessing = false;

  // Livestream Variables
  Timer? _timer;
  bool _isLiveMode = false;

  // Text to Speech Variables
  final FlutterTts _flutterTts = FlutterTts();
  bool _isAudioEnabled = true;
  String _lastSpokenSign = "";

  // ================== SERVER URL CONFIG ==================
  static const String SERVER_URL = String.fromEnvironment(
    'SERVER_URL',
    defaultValue: 'https://gescom-xzws.onrender.com', // ✅ Render URL
  );

  static const String PREDICT_ENDPOINT = '$SERVER_URL/predict-gesture';
  static const String API_KEY = 'gescom-secret-2024'; // ✅ API Key
  // =======================================================

  @override
  void initState() {
    super.initState();
    _initTts();
    _initializeCamera();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  Future<void> _stop() async {
    await _flutterTts.stop();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        int cameraIndex = _cameras!.length > 1 ? 1 : 0;
        _controller = CameraController(
          _cameras![cameraIndex],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _controller!.initialize();
        if (mounted) setState(() {});
      }
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  void _toggleLiveDetection() {
    if (_isLiveMode) {
      _timer?.cancel();
      setState(() {
        _isLiveMode = false;
        _resultText = "Stream Stopped";
      });
    } else {
      setState(() {
        _isLiveMode = true;
        _resultText = "Starting live detection...";
        _lastSpokenSign = "";
      });
      _captureAndPredict();
      _timer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
        _captureAndPredict();
      });
    }
  }

  Future<void> _captureAndPredict() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isProcessing) return;

    _isProcessing = true;

    try {
      final image = await _controller!.takePicture();

      var request = http.MultipartRequest('POST', Uri.parse(PREDICT_ENDPOINT));
      request.headers['x-api-key'] = API_KEY; // ✅ API Key header
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        image.path,
        contentType: MediaType('image', 'jpeg'), // ✅ Force JPEG MIME type
      ));

      final response = await request.send();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(respStr);

        String detectedSign = jsonResponse['sign_detected'] ??
                             jsonResponse['prediction'] ??
                             "Unknown";

        var confidenceRaw = jsonResponse['confidence'] ?? 0.0;
        double conf = (confidenceRaw is num ? confidenceRaw.toDouble() : 0.0) * 100;

        if (mounted) {
          setState(() {
            _resultText = conf > 60.0
                ? "Detected: $detectedSign (${conf.toStringAsFixed(1)}%)"
                : "Low confidence: $detectedSign (${conf.toStringAsFixed(1)}%)";
          });

          if (_isAudioEnabled &&
              detectedSign != _lastSpokenSign &&
              detectedSign != "Unknown" &&
              conf > 60.0) {
            _speak(detectedSign);
            _lastSpokenSign = detectedSign;
          }
        }
      } else if (response.statusCode == 401) {
        if (mounted) {
          setState(() => _resultText = "Unauthorized: Check API Key");
        }
      } else {
        final respStr = await response.stream.bytesToString();
        print("Server Error Body: $respStr");
        if (mounted) {
          setState(() => _resultText = "Server Error (${response.statusCode})");
        }
      }
    } catch (e) {
      print("Prediction Error: $e");
      if (mounted) {
        setState(() => _resultText = "Connection Error");
      }
    } finally {
      _isProcessing = false;
    }
  }

  void _copyToClipboard() async {
    if (_resultText.contains("Detected:")) {
      await Clipboard.setData(ClipboardData(text: _resultText));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Copied to clipboard!"),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.getBackgroundColor(),
      appBar: AppBar(
        backgroundColor: themeProvider.getCardColor(),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeProvider.getPrimaryColor()),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Live Gesture to Speech', style: themeProvider.getTitleStyle()),
        actions: [
          IconButton(
            icon: Icon(_isAudioEnabled ? Icons.volume_up : Icons.volume_off),
            onPressed: () => setState(() => _isAudioEnabled = !_isAudioEnabled),
            color: themeProvider.getPrimaryColor(),
          ),
          IconButton(
            icon: const Icon(Icons.stop, color: Colors.red),
            onPressed: _stop,
            tooltip: 'Stop Speaking',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_controller != null && _controller!.value.isInitialized)
                  CameraPreview(_controller!)
                else
                  const Center(child: CircularProgressIndicator()),

                if (_isLiveMode)
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fiber_manual_record, color: Colors.white, size: 12),
                          SizedBox(width: 6),
                          Text("LIVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: themeProvider.getCardColor(),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Result:",
                  style: TextStyle(fontSize: 14, color: themeProvider.getSecondaryTextColor()),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _resultText,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.getTextColor(),
                        ),
                      ),
                    ),
                    if (_resultText.contains("Detected:"))
                      IconButton(
                        icon: Icon(Icons.copy, color: themeProvider.getPrimaryColor(), size: 28),
                        tooltip: "Copy to clipboard",
                        onPressed: _copyToClipboard,
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: _toggleLiveDetection,
                    icon: Icon(_isLiveMode ? Icons.stop : Icons.play_arrow, size: 24),
                    label: Text(
                      _isLiveMode ? "Stop Detection" : "Start Detection",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isLiveMode ? Colors.red : themeProvider.getPrimaryColor(),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}