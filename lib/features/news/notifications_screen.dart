import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/article_model.dart';
import '../../services/translation_service.dart';
import '../../core/localization/language_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/read_articles_provider.dart';
import 'providers/translated_articles_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  String _timeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _openArticle(
    BuildContext context,
    WidgetRef ref,
    NotificationPayload notification,
  ) async {
    if (!notification.isArticleNotification) return;

    Article? article = notification.toArticle();
    article ??= findArticleById(ref as Ref<Object?>, notification.articleId!);

    if (article == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Article is no longer available in your feed.'),
          ),
        );
      }
      return;
    }

    final lang = ref.read(languageProvider);
    if (lang == 'am') {
      article = await TranslationService().translateArticle(article);
    }

    ref.read(notificationHistoryProvider.notifier).markAsRead(notification.id);
    ref.read(readArticlesProvider.notifier).markAsRead(article.id);

    if (context.mounted) {
      context.push('/article', extra: article);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final notifications = ref.watch(notificationHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (notifications.isNotEmpty)
            TextButton.icon(
              icon: Icon(
                LucideIcons.trash2,
                size: 16,
                color: colorScheme.error,
              ),
              label: Text(
                'Clear All',
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                ref.read(notificationHistoryProvider.notifier).clearHistory();
              },
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.bellOff,
                        size: 64,
                        color: colorScheme.primary.withOpacity(0.4),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No notifications yet',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Real-time news alerts and updates from our server will appear here as they are published.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final canOpen = notification.isArticleNotification;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.08),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    onTap: canOpen
                        ? () => _openArticle(context, ref, notification)
                        : null,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.bell,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _timeAgo(notification.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        canOpen
                            ? notification.message
                            : '${notification.message}\nTap actions on the right.',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        if (canOpen)
                          Icon(
                            LucideIcons.chevronRight,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                        IconButton(
                          tooltip: 'Mark as read',
                          icon: Icon(
                            LucideIcons.checkCheck,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          onPressed: () {
                            ref
                                .read(notificationHistoryProvider.notifier)
                                .markAsRead(notification.id);
                          },
                        ),
                        IconButton(
                          tooltip: 'Delete notification',
                          icon: Icon(
                            LucideIcons.trash2,
                            size: 18,
                            color: colorScheme.error,
                          ),
                          onPressed: () {
                            ref
                                .read(notificationHistoryProvider.notifier)
                                .deleteNotification(notification.id);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
