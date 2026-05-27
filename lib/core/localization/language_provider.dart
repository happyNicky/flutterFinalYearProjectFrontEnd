import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('en') {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('app_language');
    if (lang != null) {
      state = lang;
    }
  }

  Future<void> setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', lang);
    state = lang;
  }

  bool get isAmharic => state == 'am';

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'good_morning': 'Good Morning,',
      'good_afternoon': 'Good Afternoon,',
      'good_evening': 'Good Evening,',
      'trending_now': 'Trending Now',
      'recommended_for_you': 'Recommended for you',
      'refresh': 'Refresh',
      'settings': 'Settings',
      'appearance': 'Appearance',
      'system_default': 'System Default',
      'light_mode': 'Light Mode',
      'dark_mode': 'Dark Mode',
      'app_preferences': 'App Preferences',
      'push_notifications': 'Push Notifications',
      'manage_alerts': 'Manage local and real-time news alerts',
      'language': 'Language',
      'english': 'English',
      'amharic': 'Amharic',
      'english_full': 'English (United States)',
      'amharic_full': 'አማርኛ (Amharic)',
      'about': 'About',
      'version': 'Version',
      'privacy_policy': 'Privacy Policy',
      'saved_articles': 'Saved Articles',
      'no_saved_articles': 'No saved articles yet',
      'tap_bookmark_hint': 'Tap the bookmark icon on any article to read it later.',
      'search': 'Search',
      'search_news_hint': 'Search news...',
      'explore': 'Explore',
      'profile': 'Profile',
      'logout': 'Log Out',
      'bookmarks': 'Bookmarks',
      'guest': 'Guest',
      'article_bookmarked': 'Article bookmarked',
      'bookmark_removed': 'Bookmark removed',
      'read_more_at': 'Read more at: ',
      'read_full_article': 'Read the full article: ',
      'no_articles_found': 'No articles found',
      'try_another_keyword': 'Try another keyword or category',
      'failed_trending': 'Failed to load trending news',
      'failed_recommended': 'Failed to load recommended news.',
      'failed_articles': 'Failed to load articles. Check connection.',
      'min_read': 'min read',
      'just_now': 'Just now',
      'd_ago': 'd ago',
      'h_ago': 'h ago',
      'm_ago': 'm ago',
      'notifications': 'Notifications',
      'no_notifications': 'No notifications yet',
      'notify_publish_hint': 'We will notify you when new articles are published.',
      'read_last_week': 'Read Last Week',
      'help_support': 'Help & Support',
      'location_recommendation': 'Location Recommendations',
      'location_consent_title': 'Enable Local Recommendations?',
      'location_consent_desc': 'We can tailor news recommendations based on your current city or country. Allow location access?',
      'enable': 'Enable',
      'cancel': 'Cancel',
      'location_enabled': 'Location recommendations active',
      'location_disabled': 'Using standard recommendations',
      'read_more': 'Read more',
    },
    'am': {
      'good_morning': 'እንደምን አደሩ፣',
      'good_afternoon': 'እንደምን ዋሉ፣',
      'good_evening': 'እንደምን አመሹ፣',
      'trending_now': 'አሁን በመታየት ላይ ያሉ',
      'recommended_for_you': 'ለእርስዎ የተመከሩ',
      'refresh': 'አድስ',
      'settings': 'ቅንብሮች',
      'appearance': 'ገጽታ',
      'system_default': 'የስርዓቱ ነባሪ',
      'light_mode': 'ደማቅ ሁነታ',
      'dark_mode': 'ጨለማ ሁነታ',
      'app_preferences': 'የመተግበሪያ ምርጫዎች',
      'push_notifications': 'ማሳወቂያዎችን ፍቀድ',
      'manage_alerts': 'የአካባቢ እና የእውነተኛ ጊዜ ዜናዎችን ያስተዳድሩ',
      'language': 'ቋንቋ',
      'english': 'እንግሊዝኛ',
      'amharic': 'አማርኛ',
      'english_full': 'እንግሊዝኛ (ዩናይትድ ስቴትስ)',
      'amharic_full': 'አማርኛ (Amharic)',
      'about': 'ስለ መተግበሪያው',
      'version': 'ስሪት',
      'privacy_policy': 'የግል መረጃ ጥበቃ ፖሊሲ',
      'saved_articles': 'የተቀመጡ ጽሑፎች',
      'no_saved_articles': 'እስካሁን ምንም የተቀመጡ ጽሑፎች የሉም',
      'tap_bookmark_hint': 'ማንኛውንም ጽሑፍ በኋላ ለማንበብ የዕልባት ምልክቱን ይጫኑ።',
      'search': 'ፈልግ',
      'search_news_hint': 'ዜና ፈልግ...',
      'explore': 'አሰስ',
      'profile': 'መገለጫ',
      'logout': 'ውጣ',
      'bookmarks': 'ዕልባቶች',
      'guest': 'እንግዳ',
      'article_bookmarked': 'ጽሑፉ ተቀምጧል',
      'bookmark_removed': 'ጽሑፉ ከዕልባት ተሰርዟል',
      'read_more_at': 'ተጨማሪ ያንብቡ በ: ',
      'read_full_article': 'ሙሉውን ጽሑፍ ያንብቡ: ',
      'no_articles_found': 'ምንም ጽሑፍ አልተገኘም',
      'try_another_keyword': 'ሌላ ቁልፍ ቃል ወይም ምድብ ይሞክሩ',
      'failed_trending': 'በመታየት ላይ ያሉ ዜናዎችን መጫን አልተቻለም',
      'failed_recommended': 'ለእርስዎ የተመከሩ ዜናዎችን መጫን አልተቻለም',
      'failed_articles': 'ጽሑፎችን መጫን አልተቻለም። ግንኙነትዎን ያረጋግጡ።',
      'min_read': 'ደቂቃ ንባብ',
      'just_now': 'አሁን',
      'd_ago': 'ቀን በፊት',
      'h_ago': 'ሰዓት በፊት',
      'm_ago': 'ደቂቃ በፊት',
      'notifications': 'ማሳወቂያዎች',
      'no_notifications': 'እስካሁን ምንም ማሳወቂያዎች የሉም',
      'notify_publish_hint': 'አዳዲስ ጽሑፎች ሲታተሙ እናሳውቅዎታለን።',
      'read_last_week': 'ባለፈው ሳምንት የተነበቡ',
      'help_support': 'እርዳታ እና ድጋፍ',
      'location_recommendation': 'የአካባቢ ምክሮች',
      'location_consent_title': 'የአካባቢ ምክሮችን ይፍቀዱ?',
      'location_consent_desc': 'አሁን ባሉበት ከተማ ወይም ሀገር ላይ በመመስረት የዜና ምክሮችን ማበጀት እንችላለን። የአካባቢ መዳረሻ ይፍቀዱ?',
      'enable': 'ፍቀድ',
      'cancel': 'አይሁን',
      'location_enabled': 'የአካባቢ ዜና ምክሮች ንቁ ሆነዋል',
      'location_disabled': 'መደበኛ የዜና ምክሮች ጥቅም ላይ እየዋሉ ነው',
      'read_more': 'ተጨማሪ ያንብቡ',
    }
  };

  String translate(String key) {
    return _localizedValues[state]?[key] ?? key;
  }
}

extension LocalizationExtension on BuildContext {
  String tr(String key, {WidgetRef? ref}) {
    if (ref != null) {
      return ref.watch(languageProvider.notifier).translate(key);
    }
    // Fallback if ref is not provided directly
    return key;
  }
}
