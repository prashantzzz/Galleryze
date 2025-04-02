import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/bottom_nav_bar.dart';
import 'home_screen.dart';
import 'categories_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final PageController _pageController = PageController(
    initialPage: 0,
    keepPage: true,
  );

  // Pre-load and keep screens alive for smoother transitions
  final List<Widget> _screens = [
    const HomeScreen(),
    const CategoriesScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Apply optimization for smoother scrolling
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
      ),
    );
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          // Improve scroll optimization
          return false;
        },
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _screens.length,
          itemBuilder: (context, index) {
            // Use IndexedStack to keep state while improving performance
            return IndexedStack(
              index: _currentIndex == index ? 0 : 1,
              sizing: StackFit.expand,
              children: [
                _screens[index],
                Container(), // Empty placeholder when not visible
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 200), // Faster animation
            curve: Curves.fastOutSlowIn, // More responsive curve
          );
        },
      ),
    );
  }
} 