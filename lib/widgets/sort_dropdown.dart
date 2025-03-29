import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/photo_provider.dart';

class SortDropdown extends StatelessWidget {
  const SortDropdown({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sort),
      onSelected: (value) {
        final provider = context.read<PhotoProvider>();
        switch (value) {
          case 'date':
            provider.setSortBy('date');
            break;
          case 'name':
            provider.setSortBy('name');
            break;
          case 'size':
            provider.setSortBy('size');
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'date',
          child: Text('Sort by Date'),
        ),
        const PopupMenuItem(
          value: 'name',
          child: Text('Sort by Name'),
        ),
        const PopupMenuItem(
          value: 'size',
          child: Text('Sort by Size'),
        ),
      ],
    );
  }
} 