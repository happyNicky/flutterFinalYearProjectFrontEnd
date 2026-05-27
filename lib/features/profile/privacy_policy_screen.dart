import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/localization/language_provider.dart';

class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

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
          context.tr('privacy_policy', ref: ref),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: May 26, 2026',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 24),
            _buildSection(context, '1. Introduction', 'Welcome to our News App. We respect your privacy and are committed to protecting your personal data. This privacy policy will inform you as to how we look after your personal data when you visit our application.'),
            _buildSection(context, '2. The Data We Collect', 'We may collect, use, store and transfer different kinds of personal data about you, including:\n• Identity Data (first name, last name, username)\n• Contact Data (email address)\n• Usage Data (information about how you use our app and read articles)'),
            _buildSection(context, '3. How We Use Your Data', 'We will only use your personal data when the law allows us to. Most commonly, we will use your personal data to:\n• Provide and improve our news services\n• Manage your account and saved articles\n• Send you push notifications for breaking news if you have opted in'),
            _buildSection(context, '4. Data Security', 'We have put in place appropriate security measures to prevent your personal data from being accidentally lost, used, or accessed in an unauthorized way, altered, or disclosed.'),
            _buildSection(context, '5. Contact Us', 'If you have any questions about this privacy policy or our privacy practices, please contact us at privacy@newsapp.com.'),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            content,
            style: textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
