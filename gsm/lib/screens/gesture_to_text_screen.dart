import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';          // ← Added for Clipboard
import '../theme/theme_provider.dart';

class GestureToTextScreen extends StatefulWidget {
  const GestureToTextScreen({super.key});

  @override
  State<GestureToTextScreen> createState() => _GestureToTextScreenState();
}

class _GestureToTextScreenState extends State<GestureToTextScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  String _resultText = "Waiting for gesture...";
  bool _isProcessing = false;

  // Live Stream Variables
  Timer? _timer;
  bool _isLiveMode = false;
  bool _serverReady = false;
  static const String _baseUrl = "https://gescom-xzws.onrender.com";
  final String serverUrl = "$_baseUrl/predict-gesture";

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _wakeUpServer();
  }

  Future<void> _wakeUpServer() async {
    if (mounted) setState(() => _resultText = "Warming up server...");
    try {
      final response = await http
          .get(Uri.parse(_baseUrl))
          .timeout(const Duration(seconds: 90));
      if (mounted) {
        setState(() {
          _serverReady = response.statusCode == 200;
          _resultText = _serverReady
              ? "Server ready — show your gesture"
              : "Server error — tap Start to retry";
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _serverReady = true; // let user try anyway
          _resultText = "Tap Start to begin";
        });
      }
    }
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
      debugPrint("Error initializing camera: $e");
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
      });
      _captureAndPredict();
      _timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
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

      var request = http.MultipartRequest('POST', Uri.parse(serverUrl));
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        image.path,
        contentType: MediaType('image', 'jpeg'),
      ));

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Server timeout'),
      );
      final respStr = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200) {
        final jsonResponse = jsonDecode(respStr);

        String sign = jsonResponse['sign_detected'] ??
                      jsonResponse['prediction'] ??
                      jsonResponse['class'] ?? "Unknown";

        var confidenceRaw = jsonResponse['confidence'] ?? jsonResponse['score'] ?? 0.0;
        double conf = (confidenceRaw is num ? confidenceRaw.toDouble() : 0.0) * 100;

        if (mounted) {
          setState(() {
            if (conf > 60.0) {
              _resultText = "Detected: $sign (${conf.toStringAsFixed(1)}%)";
            } else if (sign != "Unknown") {
              _resultText = "Low confidence: $sign (${conf.toStringAsFixed(1)}%)";
            }
          });
        }
      } else {
        if (mounted) setState(() => _resultText = "Server error (${streamedResponse.statusCode})");
      }
    } on TimeoutException {
      if (mounted) setState(() => _resultText = "Server waking up — please wait...");
    } catch (e) {
      debugPrint("Stream Error: $e");
      if (mounted) setState(() => _resultText = "Connection error — check network");
    } finally {
      _isProcessing = false;
    }
  }

  // ================== COPY FUNCTION ==================
  void _copyToClipboard() async {
    if (_resultText.contains("Detected:")) {
      await Clipboard.setData(ClipboardData(text: _resultText));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Copied to clipboard!"),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
  // ===================================================

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
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
        title: Text('Live Gesture Detection', style: themeProvider.getTitleStyle()),
      ),
      body: Column(
        children: [
          // Camera Area
          Expanded(
            flex: 2,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_controller != null && _controller!.value.isInitialized)
                  CameraPreview(_controller!)
                else
                  Center(child: CircularProgressIndicator(color: themeProvider.getPrimaryColor())),

                if (_isLiveMode)
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha:0.85),
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

          // Result Area with Copy Button
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: themeProvider.getCardColor(),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha:0.1), blurRadius: 10, offset: const Offset(0, -5)),
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

                // Result Text + Copy Button in one Row
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
                    onPressed: _serverReady ? _toggleLiveDetection : null,
                    icon: !_serverReady
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(_isLiveMode ? Icons.stop : Icons.play_arrow, size: 26),
                    label: Text(
                      !_serverReady
                          ? "Warming up server..."
                          : (_isLiveMode ? "Stop Detection" : "Start Live Detection"),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_serverReady
                          ? Colors.grey
                          : (_isLiveMode ? Colors.red : themeProvider.getPrimaryColor()),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: themeProvider.isNeonMode ? 10 : 2,
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