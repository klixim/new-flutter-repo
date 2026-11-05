class AppUser {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String provider; // 'github', 'google', 'apple', 'yandex', 'vk'
  final String backend;  // 'supabase', 'firebase', 'oauth'

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.provider,
    required this.backend,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Пользователь',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      provider: json['provider'] as String? ?? 'unknown',
      backend: json['backend'] as String? ?? 'supabase',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'avatarUrl': avatarUrl,
    'provider': provider,
    'backend': backend,
  };
}
