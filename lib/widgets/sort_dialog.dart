import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/photo_provider.dart';

class SortDialog extends StatelessWidget {
  const SortDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final photoProvider = Provider.of<PhotoProvider>(context);
    final currentSort = photoProvider.sortOption;
    
    return AlertDialog(
      title: const Text('Sort Photos'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSortOption(
            context,
            title: 'Date (Newest First)',
            isSelected: currentSort == SortOption.dateDesc,
            onTap: () {
              photoProvider.setSortOption(SortOption.dateDesc);
              Navigator.pop(context);
            },
          ),
          _buildSortOption(
            context,
            title: 'Date (Oldest First)',
            isSelected: currentSort == SortOption.dateAsc,
            onTap: () {
              photoProvider.setSortOption(SortOption.dateAsc);
              Navigator.pop(context);
            },
          ),
          _buildSortOption(
            context,
            title: 'Size (Largest First)',
            isSelected: currentSort == SortOption.sizeDesc,
            onTap: () {
              photoProvider.setSortOption(SortOption.sizeDesc);
              Navigator.pop(context);
            },
          ),
          _buildSortOption(
            context,
            title: 'Size (Smallest First)',
            isSelected: currentSort == SortOption.sizeAsc,
            onTap: () {
              photoProvider.setSortOption(SortOption.sizeAsc);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSortOption(
    BuildContext context, {
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(title),
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? Colors.blue : Colors.grey,
      ),
      onTap: onTap,
    );
  }
}
