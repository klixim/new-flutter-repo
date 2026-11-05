import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showAddItemDialog(BuildContext context, AuthService authService) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Добавить запись в Supabase'),
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
            child: const Text('Добавить в БД'),
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
            tooltip: 'Обновить данные из Supabase',
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
                                // Имя пользователя
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
                                    color: const Color(0xFF3ECF8E).withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${user?.provider.toUpperCase()} via Supabase',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E8E5A),
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
                          Row(
                            children: [
                              Text(
                                'Список из базы данных',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF3ECF8E),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Supabase PostgreSQL • таблица items',
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
                              'В таблице items пока нет записей',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Нажмите "Добавить", чтобы внести первую запись в Supabase',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...items.map(
                      (item) => Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => authService.deleteItem(item.id),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF3ECF8E).withOpacity(0.2),
                              child: const Icon(
                                Icons.storage,
                                color: Color(0xFF1E8E5A),
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
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18),
                              color: Colors.grey,
                              tooltip: 'Удалить из Supabase',
                              onPressed: () => authService.deleteItem(item.id),
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
