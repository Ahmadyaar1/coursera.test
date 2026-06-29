import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

class TextToSpeechScreen extends StatefulWidget {
  const TextToSpeechScreen({super.key});

  @override
  State<TextToSpeechScreen> createState() => _TextToSpeechScreenState();
}

class _TextToSpeechScreenState extends State<TextToSpeechScreen> {
  final FlutterTts flutterTts = FlutterTts();
  
  final TextEditingController _textController = TextEditingController();
  
  double _volume = 1.0;
  double _pitch = 1.0;
  double _speechRate = 0.5;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    await flutterTts.setVolume(_volume);
    await flutterTts.setPitch(_pitch);
    await flutterTts.setSpeechRate(_speechRate);
  }

  Future<void> _speak() async {
    if (_textController.text.isNotEmpty) {
      await flutterTts.speak(_textController.text);
    }
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
          icon: Icon(
            Icons.arrow_back,
            color: themeProvider.getPrimaryColor(),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Text to Speech',
          style: themeProvider.getTitleStyle(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text Input Section
            Text(
              'Enter text here.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: themeProvider.getSecondaryTextColor(),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeProvider.getCardColor(),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [themeProvider.getCardShadow()],
                border: themeProvider.isNeonMode ? Border.all(
                  color: themeProvider.getPrimaryColor().withOpacity(0.3),
                  width: 1,
                ) : null,
              ),
              child: TextField(
                controller: _textController,
                maxLines: 5,
                style: TextStyle(color: themeProvider.getTextColor()),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Type text here...',
                  hintStyle: TextStyle(color: themeProvider.getSecondaryTextColor()),
                ),
              ),
            ),
            
            // Reduced gap here
            const SizedBox(height: 20), 
            
            // Speech Settings
            Text(
              'Speech Settings',
              style: TextStyle(
                fontSize: 18, // Slightly smaller header
                fontWeight: FontWeight.bold,
                color: themeProvider.getTextColor(),
                shadows: themeProvider.isNeonMode ? [
                  Shadow(
                    blurRadius: 5,
                    color: themeProvider.getPrimaryColor(),
                  ),
                ] : null,
              ),
            ),
            
            // Reduced gap before first slider
            const SizedBox(height: 10), 
            
            // Volume
            _buildSettingSlider(
              context,
              label: 'Volume: $_volume',
              value: _volume,
              min: 0.0,
              max: 1.0,
              onChanged: (value) {
                setState(() {
                  _volume = double.parse(value.toStringAsFixed(1));
                });
                flutterTts.setVolume(_volume);
              },
            ),
            
            // Reduced gap between sliders
            const SizedBox(height: 10), 
            
            // Pitch
            _buildSettingSlider(
              context,
              label: 'Pitch: $_pitch',
              value: _pitch,
              min: 0.5,
              max: 2.0,
              onChanged: (value) {
                setState(() {
                  _pitch = double.parse(value.toStringAsFixed(1));
                });
                flutterTts.setPitch(_pitch);
              },
            ),
            
            // Reduced gap between sliders
            const SizedBox(height: 10), 
            
            // Speech Rate
            _buildSettingSlider(
              context,
              label: 'Speech Rate: $_speechRate',
              value: _speechRate,
              min: 0.0,
              max: 1.0,
              onChanged: (value) {
                setState(() {
                  _speechRate = double.parse(value.toStringAsFixed(1));
                });
                flutterTts.setSpeechRate(_speechRate);
              },
            ),
            
            // Reduced gap before button
            const SizedBox(height: 25), 
            
            // Speak Button (Reduced padding to look like a button, not a box)
            Center(
              child: ElevatedButton(
                onPressed: _speak,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.getPrimaryColor(),
                  // Reduced horizontal padding to make it look like a distinct button
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), 
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  shadowColor: themeProvider.isNeonMode ? themeProvider.getPrimaryColor() : null,
                  elevation: themeProvider.isNeonMode ? 10 : 0,
                ),
                child: Text(
                  'SPEAK',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.isNeonMode ? Colors.black : Colors.white,
                    shadows: themeProvider.isNeonMode ? [
                      Shadow(
                        blurRadius: 5,
                        color: Colors.white,
                      ),
                    ] : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: themeProvider.getCardColor(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                Icons.home,
                color: themeProvider.getPrimaryColor(),
                size: 30,
              ),
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSlider(
    BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    required Function(double) onChanged,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Container(
      // Reduced padding to make the box smaller
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: themeProvider.getCardColor(),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [themeProvider.getCardShadow()],
        border: themeProvider.isNeonMode ? Border.all(
          color: themeProvider.getPrimaryColor().withOpacity(0.3),
          width: 1,
        ) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14, // Slightly smaller font
              fontWeight: FontWeight.w500,
              color: themeProvider.getTextColor(),
            ),
          ),
          const SizedBox(height: 5), // Reduced gap between text and slider
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).toInt() * 10,
            onChanged: onChanged,
            activeColor: themeProvider.getPrimaryColor(),
            inactiveColor: themeProvider.getSecondaryTextColor().withOpacity(0.3),
            thumbColor: themeProvider.getPrimaryColor(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    flutterTts.stop();
    _textController.dispose();
    super.dispose();
  }
}