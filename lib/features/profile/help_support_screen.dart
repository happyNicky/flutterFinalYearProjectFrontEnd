import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/localization/language_provider.dart';

class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          context.tr('help_support', ref: ref),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Icon(LucideIcons.helpCircle, size: 64, color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'How can we help you?',
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'We are here to assist you with any questions or concerns you may have.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 32),
          _buildFaqItem(context, 'How do I save an article?', 'You can tap the bookmark icon on any article detail page to save it for later reading.'),
          _buildFaqItem(context, 'How do I change the app language?', 'Go to Profile > Settings > Language to choose between English and Amharic.'),
          _buildFaqItem(context, 'Why is my news content short?', 'Some publishers only provide a snippet of the full article. You can tap "Read Full Article" to view the complete story on their website.'),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          Text(
            'Contact Us',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(LucideIcons.mail, color: colorScheme.primary),
            ),
            title: const Text('Email Support'),
            subtitle: const Text('support@newsapp.com'),
            onTap: () {},
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(LucideIcons.phone, color: colorScheme.primary),
            ),
            title: const Text('Call Us'),
            subtitle: const Text('+1 800 123 4567'),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(answer, style: TextStyle(height: 1.5, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8))),
        ),
      ],
    );
  }
}
