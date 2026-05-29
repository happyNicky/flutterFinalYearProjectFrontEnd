class Article {
  final String id;
  final String title;
  final String content;
  final String category;
  final String author;
  final String imageUrl;
  final DateTime publishedAt;
  final int readTimeMinutes;

  Article({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.author,
    required this.imageUrl,
    required this.publishedAt,
    required this.readTimeMinutes,
  });

  static DateTime _parsePublishedAt(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    if (value is List && value.length >= 3) {
      final year = (value[0] as num).toInt();
      final month = (value[1] as num).toInt();
      final day = (value[2] as num).toInt();
      final hour = value.length > 3 ? (value[3] as num).toInt() : 0;
      final minute = value.length > 4 ? (value[4] as num).toInt() : 0;
      final second = value.length > 5 ? (value[5] as num).toInt() : 0;
      return DateTime(year, month, day, hour, minute, second);
    }
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  factory Article.fromJson(Map<String, dynamic> json) {
    String pickBestContent(Map<String, dynamic> data) {
      final candidates = <String>[
        data['fullContent']?.toString() ?? '',
        data['articleContent']?.toString() ?? '',
        data['body']?.toString() ?? '',
        data['contentText']?.toString() ?? '',
        data['content']?.toString() ?? '',
        data['description']?.toString() ?? '',
      ].map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      if (candidates.isEmpty) return '';

      // Prefer the longest non-empty payload, which is usually full article text.
      final best = candidates.reduce((a, b) => a.length >= b.length ? a : b);

      // News APIs sometimes append " ... [+1234 chars]" to truncated snippets.
      return best.replaceAll(RegExp(r'\s*\[\+\d+\s+chars\]\s*$'), '').trim();
    }

    return Article(
      id: json['id']?.toString() ?? json['url']?.toString() ?? '',
      title: json['title'] ?? 'No Title',
      content: pickBestContent(json),
      category: json['category'] ?? 'General',
      author: json['author'] ?? 'Unknown Author',
      imageUrl: json['imageUrl'] ?? json['urlToImage'] ?? 'https://images.unsplash.com/photo-1504711434969-e33886168f5c?auto=format&fit=crop&w=800&q=80',
      publishedAt: _parsePublishedAt(json['publishedAt']),
      readTimeMinutes: (json['readTimeMinutes'] as num?)?.toInt() ?? 5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'author': author,
      'imageUrl': imageUrl,
      'publishedAt': publishedAt.toIso8601String(),
      'readTimeMinutes': readTimeMinutes,
    };
  }

  /// Compact payload for bookmark API (avoids oversized request bodies).
  Map<String, dynamic> toBookmarkJson() {
    const maxContentLength = 4000;
    final trimmedContent = content.length > maxContentLength
        ? '${content.substring(0, maxContentLength)}...'
        : content;
    final trimmedImage = imageUrl.length > 2000
        ? imageUrl.substring(0, 2000)
        : imageUrl;

    return {
      'id': id,
      'title': title,
      'content': trimmedContent,
      'category': category,
      'author': author,
      'imageUrl': trimmedImage,
      'publishedAt': publishedAt.toIso8601String(),
      'readTimeMinutes': readTimeMinutes,
    };
  }
}
