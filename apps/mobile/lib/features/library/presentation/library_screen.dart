import 'package:flutter/material.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: const [
          SectionHeader(title: 'Library'),
          EmptyState(
            title: 'Library shell ready',
            message:
                'Favourites, Recents, Collections, and Song history arrive in Milestone 1.5.',
            icon: Icons.library_music_outlined,
          ),
        ],
      ),
    );
  }
}
