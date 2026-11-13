import 'package:flutter/material.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: const [
          SectionHeader(title: 'Explore'),
          EmptyState(
            title: 'Explore shell ready',
            message:
                'Countries, Genres, Languages, and Map tabs arrive in Milestone 1.3.',
            icon: Icons.explore_outlined,
          ),
        ],
      ),
    );
  }
}
