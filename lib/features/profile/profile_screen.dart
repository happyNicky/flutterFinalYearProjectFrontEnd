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
            const SizedBox(height: 16),
            Text(authState.name ?? context.tr('guest', ref: ref), style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            Text(authState.email ?? 'guest@newsapp.com', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.w500)),
            const SizedBox(height: 32),
            _buildProfileStatRow(context, ref, bookmarksCount),
            const SizedBox(height: 32),
            _buildMenuItem(
              context,
              LucideIcons.bell,
              context.tr('notifications', ref: ref),
              onTap: () => context.push('/notifications'),
            ),
            _buildMenuItem(context, LucideIcons.helpCircle, context.tr('help_support', ref: ref), onTap: () => context.push('/help-support')),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.1),
                foregroundColor: Colors.red,
                elevation: 0,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              icon: const Icon(LucideIcons.logOut),
              label: Text(context.tr('logout', ref: ref), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 100), // padding for bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStatRow(BuildContext context, WidgetRef ref, String bookmarksCount) {
    final readCount = ref.watch(readArticlesProvider).length.toString();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStat(context, readCount, context.tr('read_last_week', ref: ref)),
        Container(width: 1, height: 40, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
        _buildStat(context, bookmarksCount, context.tr('saved_articles', ref: ref)),
      ],
    );
  }

  Widget _buildStat(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, {VoidCallback? onTap}) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: colorScheme.onSurface),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Icon(LucideIcons.chevronRight, color: colorScheme.onSurface.withOpacity(0.5)),
      onTap: onTap,
    );
  }
}
