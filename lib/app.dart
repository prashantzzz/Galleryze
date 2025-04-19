import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/photo_provider.dart';
import 'providers/category_provider.dart';
import 'providers/image_classifier_provider.dart';
import 'screens/main_screen.dart';

class GalleryzeApp extends StatelessWidget {
  const GalleryzeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PhotoProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProxyProvider<PhotoProvider, ImageClassifierProvider>(
          create: (context) => ImageClassifierProvider(Provider.of<PhotoProvider>(context, listen: false)),
          update: (context, photoProvider, previous) => 
            previous ?? ImageClassifierProvider(photoProvider),
        ),
      ],
      child: MaterialApp(
        title: 'Galleryze',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          textTheme: GoogleFonts.blinkerTextTheme(Theme.of(context).textTheme),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
        ),
        home: const MainScreen(),
      ),
    );
  }
}