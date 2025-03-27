import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/photo_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/photo_grid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'all';
  int _currentIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<PhotoProvider>(context, listen: false).loadPhotos();
    } catch (e) {
      // Handle errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading photos: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoProvider = Provider.of<PhotoProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final categories = categoryProvider.categories;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Galleryze',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              _showSortOptions(context);
            },
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('PRO'),
            onPressed: () {
              _showProUpgradeDialog();
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Category filter
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length + 1, // +1 for the "Add" button
              itemBuilder: (context, index) {
                if (index == categories.length) {
                  // Add button
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        _showAddCategoryDialog(context);
                      },
                      child: Chip(
                        avatar: const Icon(Icons.add, size: 18),
                        label: const Text('Add'),
                        backgroundColor: Colors.grey[200],
                      ),
                    ),
                  );
                }

                final category = categories[index];
                final isSelected = _selectedCategory == category.id;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    avatar: Icon(
                      category.icon,
                      color: isSelected ? Colors.white : category.color,
                      size: 18,
                    ),
                    label: Text(category.name),
                    selected: isSelected,
                    selectedColor: category.color,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category.id;
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),

          // Photo grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : PhotoGrid(
                    photos: _selectedCategory == 'all'
                        ? photoProvider.photos
                        : photoProvider.getPhotosByCategory(_selectedCategory),
                    onDragToCategory: (photoId, categoryId) {
                      photoProvider.addPhotoToCategory(photoId, categoryId);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          // Handle navigation
          switch (index) {
            case 0: // Home
              break;
            case 1: // Categories
              // Add categories management screen
              break;
            case 2: // Settings
              // Add settings screen
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void _showSortOptions(BuildContext context) {
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.arrow_upward),
                title: const Text('Date (Newest first)'),
                onTap: () {
                  photoProvider.setSortOption(SortOption.dateDesc);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_downward),
                title: const Text('Date (Oldest first)'),
                onTap: () {
                  photoProvider.setSortOption(SortOption.dateAsc);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_upward),
                title: const Text('Size (Largest first)'),
                onTap: () {
                  photoProvider.setSortOption(SortOption.sizeDesc);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_downward),
                title: const Text('Size (Smallest first)'),
                onTap: () {
                  photoProvider.setSortOption(SortOption.sizeAsc);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showProUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to PRO'),
        content: const Text(
          'Unlock premium features:\n\n'
          '• Unlimited categories\n'
          '• Advanced sorting options\n'
          '• Cloud backup\n'
          '• No ads',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('PRO features coming soon!'),
                ),
              );
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    Color selectedColor = Colors.blue;
    IconData selectedIcon = Icons.folder;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'Enter category name',
              ),
            ),
            const SizedBox(height: 16),
            const Text('Select a color:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: [
                _colorOption(Colors.blue, selectedColor, (color) {
                  selectedColor = color;
                }),
                _colorOption(Colors.red, selectedColor, (color) {
                  selectedColor = color;
                }),
                _colorOption(Colors.green, selectedColor, (color) {
                  selectedColor = color;
                }),
                _colorOption(Colors.orange, selectedColor, (color) {
                  selectedColor = color;
                }),
                _colorOption(Colors.purple, selectedColor, (color) {
                  selectedColor = color;
                }),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Select an icon:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 15,
              children: [
                _iconOption(Icons.folder, selectedIcon, (icon) {
                  selectedIcon = icon;
                }),
                _iconOption(Icons.favorite, selectedIcon, (icon) {
                  selectedIcon = icon;
                }),
                _iconOption(Icons.star, selectedIcon, (icon) {
                  selectedIcon = icon;
                }),
                _iconOption(Icons.photo, selectedIcon, (icon) {
                  selectedIcon = icon;
                }),
                _iconOption(Icons.movie, selectedIcon, (icon) {
                  selectedIcon = icon;
                }),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final newCategory = Category(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  icon: selectedIcon,
                  color: selectedColor,
                );
                categoryProvider.addCategory(newCategory);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _colorOption(Color color, Color selectedColor, Function(Color) onSelect) {
    final isSelected = color.value == selectedColor.value;
    return GestureDetector(
      onTap: () => onSelect(color),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.transparent,
            width: 2,
          ),
        ),
        child: isSelected
            ? const Center(
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                ),
              )
            : Container(),
      ),
    );
  }

  Widget _iconOption(IconData icon, IconData selectedIcon, Function(IconData) onSelect) {
    final isSelected = icon.codePoint == selectedIcon.codePoint;
    return GestureDetector(
      onTap: () => onSelect(icon),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            icon,
            color: isSelected ? Colors.blue : Colors.grey,
            size: 24,
          ),
        ),
      ),
    );
  }
}