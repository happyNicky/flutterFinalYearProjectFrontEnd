import 'package:go_router/go_router.dart';
import 'package:flutter_news_app/features/splash/splash_screen.dart';
import 'package:flutter_news_app/features/auth/login_screen.dart';
import 'package:flutter_news_app/features/auth/signup_screen.dart';
import 'package:flutter_news_app/features/home/home_layout.dart';
import 'package:flutter_news_app/features/news/article_detail_screen.dart';
import 'package:flutter_news_app/features/explore/category_articles_screen.dart';
import 'package:flutter_news_app/features/news/notifications_screen.dart';
import 'package:flutter_news_app/features/profile/settings_screen.dart';
import 'package:flutter_news_app/features/profile/help_support_screen.dart';
import 'package:flutter_news_app/features/profile/privacy_policy_screen.dart';
import 'package:flutter_news_app/models/article_model.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
    GoRoute(path: '/home', builder: (context, state) => const HomeLayout()),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
    GoRoute(path: '/help-support', builder: (context, state) => const HelpSupportScreen()),
    GoRoute(path: '/privacy-policy', builder: (context, state) => const PrivacyPolicyScreen()),
    GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
    GoRoute(
      path: '/article',
      builder: (context, state) {
        final article = state.extra as Article;
        return ArticleDetailScreen(article: article);
      },
    ),
    GoRoute(
      path: '/explore-articles',
      builder: (context, state) {
        final extra = state.extra as Map<String, String>;
        final category = extra['category'];
        final query = extra['query'];
        return CategoryArticlesScreen(category: category, query: query);
      },
    ),
  ],
);
