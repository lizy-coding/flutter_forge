/// 文章模型类
class Article {
  final int id;
  final String title;
  final String content;
  final String author;
  final DateTime createdAt;

  Article({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.createdAt,
  });

  /// 从JSON创建文章对象
  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      author: json['author'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// 将文章对象转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'author': author,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Article{id: $id, title: $title, author: $author}';
  }
}
