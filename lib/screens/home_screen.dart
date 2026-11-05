import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showAddItemDialog(BuildContext context, AuthService authService) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Добавить запись в БД'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Название записи...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                authService.addItem(text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выход из профиля'),
        content: const Text('Вы действительно хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              authService.signOut();
            },
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final theme = Theme.of(context);
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Личный кабинет'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить данные',
            onPressed: () => authService.fetchDatabaseItems(),
          ),
          // Кнопка выйти в шапке
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Выйти',
            onPressed: () => _confirmSignOut(context, authService),
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: authService,
          builder: (context, _) {
            final items = authService.items;

            return RefreshIndicator(
              onRefresh: () => authService.fetchDatabaseItems(),
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // 1. Карточка профиля: показ имени (Требование ТЗ: "должно быть показано имя")
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            backgroundImage: (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                                ? NetworkImage(user.avatarUrl!)
                                : null,
                            child: (user?.avatarUrl == null || user!.avatarUrl!.isEmpty)
                                ? Text(
                                    (user?.name.isNotEmpty == true ? user!.name[0] : 'U').toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Здравствуйте,',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.hintColor,
                                  ),
                                ),
                                // Отображение имени пользователя
                                Text(
                                  user?.name ?? 'Пользователь',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user?.email ?? '',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.hintColor,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${user?.provider.toUpperCase()} (${user?.backend})',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Кнопка "Выйти" на карточке (Требование ТЗ: "кнопка выйти")
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('Выйти из аккаунта'),
                    onPressed: () => _confirmSignOut(context, authService),
                  ),

                  const SizedBox(height: 24),

                  // 3. Секция "Список из базы данных" (Требование ТЗ: "список из базы данных")
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Список из базы данных',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            authService.selectedBackend == AuthBackend.supabase
                                ? 'Таблица items (Supabase PostgreSQL)'
                                : 'Коллекция items (Firebase Firestore)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => _showAddItemDialog(context, authService),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Добавить'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (authService.isLoading && items.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (items.isEmpty)
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                            SizedBox(height: 12),
                            Text(
                              'В базе данных пока нет записей',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Нажмите "Добавить", чтобы внести первую запись',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...items.map(
                      (item) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Icon(
                              Icons.data_object,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Автор: ${item.author} • ${item.createdAt.day}.${item.createdAt.month}.${item.createdAt.year} ${item.createdAt.hour}:${item.createdAt.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(fontSize: 12, color: theme.hintColor),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.dividerColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '#${item.id.length > 5 ? item.id.substring(0, 5) : item.id}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
