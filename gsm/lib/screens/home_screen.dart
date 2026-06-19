import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import 'text_to_speech_screen.dart';
import 'speech_to_text_screen.dart';
import 'gesture_to_text_screen.dart';
import 'gesture_to_speech_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // Only home screen
  bool _isHome = true;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: themeProvider.getBackgroundColor(),
      body: _isHome ? const HomeScreenContent() : _getCurrentScreen(_currentIndex),
      bottomNavigationBar: _isHome 
          ? null // Hide bottom nav on home
          : BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _currentIndex,
              backgroundColor: themeProvider.getCardColor(),
              selectedItemColor: themeProvider.getPrimaryColor(),
              unselectedItemColor: themeProvider.getSecondaryTextColor(),
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
              ],
            ),
    );
  }

  Widget _getCurrentScreen(int index) {
    switch (index) {
      case 0:
        return const HomeScreenContent();
      default:
        return const HomeScreenContent();
    }
  }
}

class HomeScreenContent extends StatelessWidget {
  const HomeScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: themeProvider.getBackgroundColor(),
      appBar: AppBar(
        backgroundColor: themeProvider.getCardColor(),
        elevation: 0,
        title: Text(
          'GesCom',
          style: themeProvider.getTitleStyle(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: themeProvider.getPrimaryColor(),
            ),
            onPressed: () {
              themeProvider.toggleDarkMode();
            },
          ),
          IconButton(
            icon: Icon(
              Icons.flash_on,
              color: themeProvider.isNeonMode ? themeProvider.getPrimaryColor() : themeProvider.getSecondaryTextColor(),
            ),
            onPressed: () {
              themeProvider.toggleNeonMode();
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Quick Access Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'You Can Speak Now',
              style: TextStyle(
                fontSize: 20,
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
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildFeatureCard(
                  context,
                  title: 'Text to Speech',
                  description: 'Convert text to spoken audio',
                  icon: Icons.volume_up,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TextToSpeechScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 15),
                _buildFeatureCard(
                  context,
                  title: 'Speech to Text',
                  description: 'Convert speech to text',
                  icon: Icons.mic,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SpeechToTextScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 15),
                
                // Gesture to Text
                _buildFeatureCard(
                  context,
                  title: 'Gesture to Text',
                  description: 'Convert gestures to text',
                  icon: Icons.gesture,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GestureToTextScreen(),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 15),
                
                // --- UPDATED: Gesture to Speech is now Active ---
                _buildFeatureCard(
                  context,
                  title: 'Gesture to Speech',
                  description: 'Sign and speak aloud',
                  icon: Icons.volume_up_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GestureToSpeechScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    VoidCallback? onTap,
    bool isComingSoon = false,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return GestureDetector(
      onTap: isComingSoon ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: themeProvider.getCardColor(),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [themeProvider.getCardShadow()],
          border: themeProvider.isNeonMode ? Border.all(
            color: themeProvider.getPrimaryColor().withValues(alpha: 0.3),
            width: 1,
          ) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeProvider.getPrimaryColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: themeProvider.isNeonMode ? Border.all(
                  color: themeProvider.getPrimaryColor().withValues(alpha: 0.5),
                  width: 1,
                ) : null,
              ),
              child: Icon(
                icon,
                color: themeProvider.getPrimaryColor(),
                size: 24,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: themeProvider.getTextColor(),
                        ),
                      ),
                      if (isComingSoon)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: themeProvider.isNeonMode ? Border.all(
                              color: Colors.orange,
                              width: 1,
                            ) : null,
                          ),
                          child: Text(
                            'Coming Soon',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: themeProvider.getSecondaryTextColor(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}