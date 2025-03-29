import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/photo_provider.dart';

class SortDropdown extends StatelessWidget {
  const SortDropdown({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Map<String, bool>>(
      icon: const Icon(Icons.sort),
      tooltip: 'Sort photos',
      itemBuilder: (context) => [
        // Date sorting options
        const PopupMenuItem(
          value: {'date': true},
          child: Row(
            children: [
              Icon(Icons.arrow_upward),
              SizedBox(width: 8),
              Text('Date (Oldest first)'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: {'date': false},
          child: Row(
            children: [
              Icon(Icons.arrow_downward),
              SizedBox(width: 8),
              Text('Date (Newest first)'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        // Size sorting options
        const PopupMenuItem(
          value: {'size': true},
          child: Row(
            children: [
              Icon(Icons.arrow_upward),
              SizedBox(width: 8),
              Text('Size (Smallest first)'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: {'size': false},
          child: Row(
            children: [
              Icon(Icons.arrow_downward),
              SizedBox(width: 8),
              Text('Size (Largest first)'),
            ],
          ),
        ),
      ],
      onSelected: (Map<String, bool> value) {
        final provider = context.read<PhotoProvider>();
        final sortBy = value.keys.first;
        final ascending = value.values.first;
        provider.setSortBy(sortBy, ascending);
      },
    );
  }
} 