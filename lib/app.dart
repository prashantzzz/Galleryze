import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/category_screen.dart';
import 'screens/account_screen.dart';
import 'widgets/bottom_nav_bar.dart';

class GalleryzeApp extends StatefulWidget {
  const GalleryzeApp({Key? key}) : super(key: key);

  @override
  _GalleryzeAppState createState() => _GalleryzeAppState();
}

class _GalleryzeAppState extends State<GalleryzeApp> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const HomeScreen(),
    const CategoryScreen(),
    const AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Galleryze',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          color: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}
