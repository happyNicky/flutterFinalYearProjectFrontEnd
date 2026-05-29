import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../auth/providers/auth_provider.dart';
import '../news/providers/news_provider.dart';
import '../news/providers/read_articles_provider.dart';
import '../../core/localization/language_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final authState = ref.watch(authProvider);
    final bookmarksState = ref.watch(bookmarksProvider);
    ref.watch(languageProvider); // Watch language to rebuild immediately

    final bookmarksCount = bookmarksState.maybeWhen(
      data: (list) => list.length.toString(),
      orElse: () => '0',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('profile', ref: ref)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: colorScheme.primary.withOpacity(0.1),
              child: Text(
                (authState.name?.isNotEmpty ?? false) ? authState.name![0].toUpperCase() : 'G',
                style: TextStyle(color: colorScheme.primary, fontSize: 36, fontWeight: FontWeight.bold),
              ),
            ),
            // padding for bottom nav
          ],
        ),
      ),
    );
  }

}
