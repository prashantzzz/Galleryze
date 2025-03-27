import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/photo_provider.dart';
import 'providers/category_provider.dart';
import 'screens/home_screen.dart';

class GalleryzeApp extends StatelessWidget {
  const GalleryzeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PhotoProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
      ],
      child: MaterialApp(
        title: 'Galleryze',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}