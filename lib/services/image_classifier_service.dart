import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;

class ImageClassifierService {
  static const String CHECKPOINT_KEY = 'last_processed_timestamp';
  static const String DETECTION_MODEL_PATH = 'assets/ssd_mobilenet_v2_coco_quantized.tflite';
  static const String CLASSIFIER_MODEL_PATH = 'assets/mobilenet_v2_imagenet_quantized.tflite';
  static const String MAPPING_JSON_PATH = 'assets/CategorizedClasses.json';
  static const String COCO_LABELS_PATH = 'assets/coco-labels.txt';
  
  static const double CONFIDENCE_THRESHOLD = 0.35;
  
  // Method channel for TensorFlow Lite
  static const MethodChannel _channel = MethodChannel('com.galleryze/tflite');
  
  // Singleton instance
  static final ImageClassifierService _instance = ImageClassifierService._internal();
  factory ImageClassifierService() => _instance;
  ImageClassifierService._internal();
  
  // Mapping and labels
  Map<String, List<String>> _categoryMapping = {};
  List<String> _cocoLabels = [];
  
  // Initialization flag
  bool _isInitialized = false;
  bool _modelsLoaded = false;
  
  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Load category mapping
      final String mappingJson = await rootBundle.loadString(MAPPING_JSON_PATH);
      final Map<String, dynamic> mappingData = json.decode(mappingJson);
      
      // Convert to lowercase strings for case-insensitive matching
      _categoryMapping = {};
      mappingData.forEach((key, value) {
        if (value is List) {
          _categoryMapping[key] = value.map((item) => item.toString().toLowerCase()).toList();
        }
      });
      
      // Load COCO labels
      final String cocoLabelsText = await rootBundle.loadString(COCO_LABELS_PATH);
      _cocoLabels = cocoLabelsText.split('\n').map((s) => s.trim().toLowerCase()).toList();
      
      // Load models via method channel
      await _loadModels();
      
      _isInitialized = true;
      print('ImageClassifierService initialized successfully');
    } catch (e) {
      print('Error initializing ImageClassifierService: $e');
      rethrow;
    }
  }
  
  // Load TensorFlow Lite models
  Future<void> _loadModels() async {
    if (_modelsLoaded) return;
    
    try {
      // Copy models to a temporary directory that can be accessed by native code
      final tempDir = await getTemporaryDirectory();
      
      // Copy detection model
      final ByteData detectionModelData = await rootBundle.load(DETECTION_MODEL_PATH);
      final String detectionModelPath = '${tempDir.path}/detection_model.tflite';
      final File detectionModelFile = File(detectionModelPath);
      await detectionModelFile.writeAsBytes(
        detectionModelData.buffer.asUint8List(
          detectionModelData.offsetInBytes,
          detectionModelData.lengthInBytes,
        ),
      );
      
      // Copy classification model
      final ByteData classificationModelData = await rootBundle.load(CLASSIFIER_MODEL_PATH);
      final String classificationModelPath = '${tempDir.path}/classification_model.tflite';
      final File classificationModelFile = File(classificationModelPath);
      await classificationModelFile.writeAsBytes(
        classificationModelData.buffer.asUint8List(
          classificationModelData.offsetInBytes,
          classificationModelData.lengthInBytes,
        ),
      );
      
      // Copy COCO labels
      final String cocoLabelsPath = '${tempDir.path}/coco_labels.txt';
      final File cocoLabelsFile = File(cocoLabelsPath);
      await cocoLabelsFile.writeAsString(_cocoLabels.join('\n'));
      
      // Load models via method channel
      final result = await _channel.invokeMethod('loadModels', {
        'detectionModelPath': detectionModelPath,
        'classificationModelPath': classificationModelPath,
        'cocoLabelsPath': cocoLabelsPath,
      });
      
      if (result == true) {
        _modelsLoaded = true;
        print('TensorFlow Lite models loaded successfully');
      } else {
        throw Exception('Failed to load TensorFlow Lite models');
      }
    } catch (e) {
      print('Error loading TensorFlow Lite models: $e');
      rethrow;
    }
  }
  
  // Process a single image and return its category
  Future<String> processImage(String imagePath) async {
    if (!_isInitialized) await initialize();
    
    try {
      final File imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist: $imagePath');
      }
      
      // First run object detection via method channel
      final detectionResult = await _channel.invokeMethod('detectObjects', {
        'imagePath': imagePath,
        'confidenceThreshold': CONFIDENCE_THRESHOLD,
      });
      
      if (detectionResult != null && detectionResult is List && detectionResult.isNotEmpty) {
        // Process detection results
        for (final detection in detectionResult) {
          final String label = detection['label'].toString().toLowerCase();
          final double confidence = detection['confidence'];
          
          if (confidence >= CONFIDENCE_THRESHOLD) {
            // Check if label belongs to "Docs" or "People" categories
            for (final entry in _categoryMapping.entries) {
              if (entry.value.contains(label)) {
                if (entry.key == 'Docs' || entry.key == 'People') {
                  print('Detection found category: ${entry.key} for $imagePath');
                  return entry.key;
                }
              }
            }
          }
        }
      }
      
      // If no detection match, run classification via method channel
      final classificationResult = await _channel.invokeMethod('classifyImage', {
        'imagePath': imagePath,
      });
      
      if (classificationResult != null && classificationResult is Map) {
        final String label = classificationResult['label'].toString().toLowerCase();
        
        // Map the predicted label to one of our categories
        for (final entry in _categoryMapping.entries) {
          if (entry.value.contains(label)) {
            print('Classification assigned category: ${entry.key} for $imagePath');
            return entry.key;
          }
        }
      }
      
      // Default to "Others" if no mapping found
      return 'Others';
    } catch (e) {
      print('Error processing image $imagePath: $e');
      return 'Others'; // Default category on error
    }
  }
  
  // Process a folder of images with checkpointing
  Future<Map<String, List<String>>> processFolder(String folderPath) async {
    if (!_isInitialized) await initialize();
    
    final Map<String, List<String>> categorizedImages = {
      'Docs': [],
      'People': [],
      'Animal': [],
      'Nature': [],
      'Food': [],
      'Others': []
    };
    
    try {
      final Directory directory = Directory(folderPath);
      if (!await directory.exists()) {
        throw Exception('Folder does not exist: $folderPath');
      }
      
      // Get last processed timestamp from SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final double lastTimestamp = prefs.getDouble(CHECKPOINT_KEY) ?? 0.0;
      double newLastTimestamp = lastTimestamp;
      
      // Get all image files
      final List<FileSystemEntity> entities = await directory.list().toList();
      final List<File> imageFiles = entities
          .whereType<File>()
          .where((file) {
            final String extension = path.extension(file.path).toLowerCase();
            return ['.jpg', '.jpeg', '.png', '.bmp', '.gif'].contains(extension);
          })
          .toList();
      
      // Sort by modification time
      imageFiles.sort((a, b) {
        return a.statSync().modified.compareTo(b.statSync().modified);
      });
      
      // Process each image
      for (final File file in imageFiles) {
        final DateTime modTime = file.statSync().modified;
        final double modTimeMillis = modTime.millisecondsSinceEpoch.toDouble();
        
        // Skip already processed files
        if (modTimeMillis <= lastTimestamp) {
          continue;
        }
        
        // Process the image
        final String category = await processImage(file.path);
        categorizedImages[category]?.add(file.path);
        
        // Update the most recent timestamp
        if (modTimeMillis > newLastTimestamp) {
          newLastTimestamp = modTimeMillis;
        }
      }
      
      // Update checkpoint with latest timestamp
      if (newLastTimestamp > lastTimestamp) {
        await prefs.setDouble(CHECKPOINT_KEY, newLastTimestamp);
        print('Updated checkpoint timestamp to: $newLastTimestamp');
      }
      
      return categorizedImages;
    } catch (e) {
      print('Error processing folder $folderPath: $e');
      return categorizedImages;
    }
  }
  
  // Process images in a background isolate
  static Future<Map<String, List<String>>> processImagesInBackground(String folderPath) async {
    final ReceivePort receivePort = ReceivePort();
    await Isolate.spawn(_isolateProcessing, [receivePort.sendPort, folderPath]);
    
    // Get the result from the isolate
    final result = await receivePort.first as Map<String, List<String>>;
    return result;
  }
  
  // Isolate entry point
  static void _isolateProcessing(List<dynamic> args) async {
    final SendPort sendPort = args[0];
    final String folderPath = args[1];
    
    // Create a new instance of the service in this isolate
    final service = ImageClassifierService();
    await service.initialize();
    
    // Process the folder
    final result = await service.processFolder(folderPath);
    
    // Send the result back to the main isolate
    sendPort.send(result);
  }
  
  // Dispose resources
  Future<void> dispose() async {
    if (_modelsLoaded) {
      try {
        await _channel.invokeMethod('closeModels');
        _modelsLoaded = false;
      } catch (e) {
        print('Error closing TensorFlow Lite models: $e');
      }
    }
    _isInitialized = false;
  }
}
