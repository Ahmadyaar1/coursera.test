import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For clipboard functionality
import 'package:speech_to_text/speech_to_text.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

class SpeechToTextScreen extends StatefulWidget {
  const SpeechToTextScreen({super.key});

  @override
  State<SpeechToTextScreen> createState() => _SpeechToTextScreenState();
}

class _SpeechToTextScreenState extends State<SpeechToTextScreen> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _wordsSpoken = "";
  double _confidenceLevel = 0;

  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    initSpeech();
  }

  void initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _wordsSpoken = result.recognizedWords;
          _confidenceLevel = result.confidence;
        });
      },
    );
    setState(() {
      _isListening = true;
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _wordsSpoken));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Text copied to clipboard')),
    );
  }

  @override
  void dispose() {
    _speechToText.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.getBackgroundColor(),
      appBar: AppBar(
        backgroundColor: themeProvider.getCardColor(),
        iconTheme: IconThemeData(color: themeProvider.getTextColor()),
        title: Text(
          'Speech to Text',
          style: TextStyle(color: themeProvider.getTextColor()),
        ),
        elevation: 0,
        actions: [
          if (_wordsSpoken.isNotEmpty)
            IconButton(
              icon: Icon(Icons.copy, color: themeProvider.getPrimaryColor()),
              onPressed: _copyToClipboard,
              tooltip: 'Copy Text',
            ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _isListening 
                    ? themeProvider.getPrimaryColor().withValues(alpha:0.2) 
                    : themeProvider.getCardColor(),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isListening 
                      ? themeProvider.getPrimaryColor() 
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: themeProvider.getPrimaryColor(),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _speechEnabled && _isListening 
                        ? "Listening..." 
                        : (_speechEnabled ? "Tap mic to speak" : "Speech not available"),
                    style: TextStyle(
                      fontSize: 16,
                      color: themeProvider.getTextColor(),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),

            // Result Display Area
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: themeProvider.getCardColor(),
                  borderRadius: BorderRadius.circular(15),
                  border: themeProvider.isNeonMode 
                      ? Border.all(color: themeProvider.getPrimaryColor().withValues(alpha:0.3))
                      : null,
                  boxShadow: [themeProvider.getCardShadow()],
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _wordsSpoken.isEmpty ? "Your speech will appear here..." : _wordsSpoken,
                    style: TextStyle(
                      fontSize: 24,
                      color: themeProvider.getTextColor(),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 30),

            // Microphone Button
            GestureDetector(
              onTapDown: (_) {
                if (_speechEnabled) _startListening();
              },
              onTapUp: (_) {
                _stopListening();
              },
              onTapCancel: () {
                _stopListening();
              },
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: _isListening 
                      ? themeProvider.getPrimaryColor() 
                      : themeProvider.getCardColor(),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _isListening 
                          ? themeProvider.getPrimaryColor().withValues(alpha:0.5) 
                          : Colors.black.withValues(alpha:0.2),
                      blurRadius: _isListening ? 20 : 10,
                      spreadRadius: _isListening ? 2 : 0,
                    ),
                  ],
                  border: Border.all(
                    color: themeProvider.getPrimaryColor(),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.mic,
                  color: _isListening 
                      ? themeProvider.getCardColor() 
                      : themeProvider.getPrimaryColor(),
                  size: 40,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            Text(
              "Hold to speak",
              style: TextStyle(
                color: themeProvider.getSecondaryTextColor(),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}