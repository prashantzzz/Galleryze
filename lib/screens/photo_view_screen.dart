import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import '../models/photo_item.dart';

class PhotoViewScreen extends StatefulWidget {
  final PhotoItem photo;

  const PhotoViewScreen({
    Key? key,
    required this.photo,
  }) : super(key: key);

  @override
  _PhotoViewScreenState createState() => _PhotoViewScreenState();
}

class _PhotoViewScreenState extends State<PhotoViewScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  Uint8List? _fullImageData;
  bool _isLoading = true;
  double _dragStartY = 0.0;
  double _dragOffset = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuart,
      ),
    );
    _animationController.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFullImage();
    });
  }

  Future<void> _loadFullImage() async {
    try {
      _fullImageData = await widget.photo.fullData;
    } catch (e) {
      print('Error loading full image: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    setState(() {
      _dragStartY = details.globalPosition.dy;
      _isDragging = true;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset = details.globalPosition.dy - _dragStartY;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dragOffset.abs() > 100) {
      // If dragged far enough, close the screen
      _animationController.reverse().then((_) {
        Navigator.of(context).pop();
      });
    } else {
      // Otherwise, snap back
      setState(() {
        _dragOffset = 0.0;
        _isDragging = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate values for drag animation
    final double scale = _isDragging ? (1.0 - _dragOffset.abs() / 1000) : 1.0;
    final double opacity = _isDragging ? (1.0 - _dragOffset.abs() / 500) : 1.0;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.black.withOpacity(0.5),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              widget.photo.title,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          body: GestureDetector(
            onVerticalDragStart: _onDragStart,
            onVerticalDragUpdate: _onDragUpdate,
            onVerticalDragEnd: _onDragEnd,
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: Transform.translate(
                  offset: Offset(0, _dragOffset),
                  child: RepaintBoundary(
                    child: Hero(
                      tag: 'photo_${widget.photo.id}',
                      child: Container(
                        color: Colors.transparent,
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            child: _isLoading || _fullImageData == null
                              ? FutureBuilder<Uint8List?>(
                                  future: widget.photo.thumbData,
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return Image.memory(
                                        snapshot.data!,
                                        fit: BoxFit.contain,
                                        key: const ValueKey('thumbnail'),
                                        gaplessPlayback: true,
                                        filterQuality: FilterQuality.medium,
                                      );
                                    }
                                    return const CircularProgressIndicator(color: Colors.white);
                                  },
                                )
                              : PhotoView(
                                  imageProvider: MemoryImage(_fullImageData!),
                                  minScale: PhotoViewComputedScale.contained,
                                  maxScale: PhotoViewComputedScale.covered * 2,
                                  backgroundDecoration: const BoxDecoration(
                                    color: Colors.transparent,
                                  ),
                                  initialScale: PhotoViewComputedScale.contained,
                                  key: const ValueKey('fullimage'),
                                  loadingBuilder: (context, event) => const SizedBox.shrink(),
                                  tightMode: true,
                                  gaplessPlayback: true,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
} 