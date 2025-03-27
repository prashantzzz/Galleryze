import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'app.dart';

void main() {
  // Ensure Flutter is initialized and handle any errors during startup
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Print platform info for debugging
    if (kDebugMode) {
      print('Platform: ${defaultTargetPlatform.toString()}');
      print('Debug mode: $kDebugMode');
      print('Is web: ${kIsWeb}');
    }
    
    runApp(const GalleryzeApp());
  }, (error, stack) {
    if (kDebugMode) {
      print('Error caught by Zone: $error');
      print('Stack trace: $stack');
    }
  });
}