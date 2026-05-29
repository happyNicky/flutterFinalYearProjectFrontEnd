import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/localization/language_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currentThemeMode = ref.watch(themeProvider);
    final activeLanguage = ref.watch(languageProvider); // Watch language to translate instantly

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          context.tr('settings', ref: ref),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Text(
            context.tr('appearance', ref: ref),
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: colorScheme.onSurface.withOpacity(0.08)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: Text(
                      context.tr('system_default', ref: ref),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    secondary: Icon(
                      LucideIcons.monitor,
                      color: colorScheme.onSurface,
                    ),
                    value: ThemeMode.system,
                    groupValue: currentThemeMode,
                    activeColor: colorScheme.primary,
                    onChanged: (mode) {
                      if (mode != null) {
                        ref.read(themeProvider.notifier).setThemeMode(mode);
                      }
                    },
                  ),
                  Divider(
                    color: colorScheme.onSurface.withOpacity(0.08),
                    height: 1,
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text(
                      context.tr('light_mode', ref: ref),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    secondary: Icon(
                      LucideIcons.sun,
                      color: colorScheme.onSurface,
                    ),
                    value: ThemeMode.light,
                    groupValue: currentThemeMode,
                    activeColor: colorScheme.primary,
                    onChanged: (mode) {
                      if (mode != null) {
                        ref.read(themeProvider.notifier).setThemeMode(mode);
                      }
                    },
                  ),
                  Divider(
                    color: colorScheme.onSurface.withOpacity(0.08),
                    height: 1,
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text(
                      context.tr('dark_mode', ref: ref),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    secondary: Icon(
                      LucideIcons.moon,
                      color: colorScheme.onSurface,
                    ),
                    value: ThemeMode.dark,
                    groupValue: currentThemeMode,
                    activeColor: colorScheme.primary,
                    onChanged: (mode) {
                      if (mode != null) {
                        ref.read(themeProvider.notifier).setThemeMode(mode);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            context.tr('app_preferences', ref: ref),
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingsOption(
            context,
            icon: LucideIcons.bellRing,
            title: context.tr('push_notifications', ref: ref),
            subtitle: context.tr('manage_alerts', ref: ref),
            trailing: Switch(
              value: true,
              onChanged: (val) {},
              activeColor: colorScheme.primary,
            ),
          ),
          _buildSettingsOption(
            context,
            icon: LucideIcons.languages,
            title: context.tr('language', ref: ref),
            subtitle: activeLanguage == 'am'
                ? 'አማርኛ (Amharic)'
                : 'English (United States)',
            onTap: () {
              showDialog(
                context: context,
                builder: (dialogContext) {
                  return Consumer(
                    builder: (context, ref, child) {
                      final activeLang = ref.watch(languageProvider);
                      return AlertDialog(
                        title: Text(context.tr('language', ref: ref)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RadioListTile<String>(
                              title: Text(context.tr('english_full', ref: ref)),
                              activeColor: colorScheme.primary,
                              value: 'en',
                              groupValue: activeLang,
                              onChanged: (val) {
                                if (val != null) {
                                  ref
                                      .read(languageProvider.notifier)
                                      .setLanguage(val);
                                  Navigator.pop(dialogContext);
                                }
                              },
                            ),
                            RadioListTile<String>(
                              title: Text(context.tr('amharic_full', ref: ref)),
                              activeColor: colorScheme.primary,
                              value: 'am',
                              groupValue: activeLang,
                              onChanged: (val) {
                                if (val != null) {
                                  ref
                                      .read(languageProvider.notifier)
                                      .setLanguage(val);
                                  Navigator.pop(dialogContext);
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            context.tr('about', ref: ref),
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingsOption(
            context,
            icon: LucideIcons.info,
            title: context.tr('version', ref: ref),
            subtitle: '1.0.0 (Build 1)',
          ),
          _buildSettingsOption(
            context,
            icon: LucideIcons.shieldCheck,
            title: context.tr('privacy_policy', ref: ref),
            onTap: () => context.push('/privacy-policy'),
          ),
        ],
      ),
      
    );
  }

  Widget _buildSettingsOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      
    );
  }
}
