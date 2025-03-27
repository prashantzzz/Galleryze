import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'app.dart';

void main() {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Print platform info for debugging
  if (kDebugMode) {
    print('Platform: ${defaultTargetPlatform.toString()}');
    print('Debug mode: $kDebugMode');
  }
  
  runApp(const GalleryzeApp());
}