class DbItem {
  final String id;
  final String title;
  final String author;
  final DateTime createdAt;

  const DbItem({
    required this.id,
    required this.title,
    required this.author,
    required this.createdAt,
  });

  factory DbItem.fromJson(Map<String, dynamic> json) {
    return DbItem(
      id: (json['id'] ?? '').toString(),
      title: json['title'] as String? ?? 'Без названия',
      author: json['user_name'] as String? ?? json['author'] as String? ?? 'Аноним',
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'user_name': author,
    'created_at': createdAt.toIso8601String(),
  };
}
