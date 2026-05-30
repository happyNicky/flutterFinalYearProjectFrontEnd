import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final categories = [
      {'name': 'Technology', 'icon': LucideIcons.laptop},
      {'name': 'Business', 'icon': LucideIcons.briefcase},
      {'name': 'Science', 'icon': LucideIcons.microscope},
      {'name': 'Politics', 'icon': LucideIcons.landmark},
      {'name': 'Sport', 'icon': LucideIcons.trophy},
      {'name': 'Environment', 'icon': LucideIcons.leaf},
    ];

    final searchController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: TextField(
                controller: searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    context.push('/explore-articles', extra: {'query': value.trim()});
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Search articles, topics...',
                  prefixIcon: const Icon(LucideIcons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(LucideIcons.arrowRight),
                    onPressed: () {
                      final val = searchController.text.trim();
                      if (val.isNotEmpty) {
                        context.push('/explore-articles', extra: {'query': val});
                      }
                    },
                  ),
                  filled: true,
                  fillColor: colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colorScheme.primary, width: 2),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text('Categories', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return GestureDetector(
                    onTap: () {
                      context.push('/explore-articles', extra: {'category': cat['name'] as String});
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(cat['icon'] as IconData, color: colorScheme.primary, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            cat['name'] as String,
                            style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
