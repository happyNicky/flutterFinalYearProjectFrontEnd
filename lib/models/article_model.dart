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

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id']?.toString() ?? json['url']?.toString() ?? '',
      title: json['title'] ?? 'No Title',
      content: json['content'] ?? json['description'] ?? '',
      category: json['category'] ?? 'General',
      author: json['author'] ?? 'Unknown Author',
      imageUrl: json['imageUrl'] ?? json['urlToImage'] ?? 'https://images.unsplash.com/photo-1504711434969-e33886168f5c?auto=format&fit=crop&w=800&q=80',
      publishedAt: json['publishedAt'] != null 
          ? DateTime.tryParse(json['publishedAt']) ?? DateTime.now() 
          : DateTime.now(),
      readTimeMinutes: json['readTimeMinutes'] ?? 5,
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
}
