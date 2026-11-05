import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Вход в приложение'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _authService,
          builder: (context, _) {
            if (_authService.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Выполняется авторизация...'),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Логотип и приветствие
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_person_outlined,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Добро пожаловать!',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Выберите сервис для быстрой авторизации',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Переключатель бэкенда (Supabase / Firebase)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _BackendChoiceButton(
                                title: '⚡ Supabase',
                                isSelected: _authService.selectedBackend == AuthBackend.supabase,
                                onTap: () => _authService.setBackend(AuthBackend.supabase),
                              ),
                            ),
                            Expanded(
                              child: _BackendChoiceButton(
                                title: '🔥 Firebase',
                                isSelected: _authService.selectedBackend == AuthBackend.firebase,
                                onTap: () => _authService.setBackend(AuthBackend.firebase),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Кнопки авторизации:
                      // 1. GitHub
                      _AuthButton(
                        label: 'Войти через GitHub',
                        iconData: Icons.code,
                        backgroundColor: const Color(0xFF24292E),
                        textColor: Colors.white,
                        onPressed: () => _authService.signIn('github'),
                      ),
                      const SizedBox(height: 12),

                      // 2. Gmail / Google
                      _AuthButton(
                        label: 'Войти через Gmail / Google',
                        iconData: Icons.mail_outline,
                        backgroundColor: isDark ? const Color(0xFF333333) : Colors.white,
                        textColor: isDark ? Colors.white : const Color(0xFF3C4043),
                        borderColor: isDark ? Colors.grey[700] : Colors.grey[300],
                        iconColor: const Color(0xFFEA4335),
                        onPressed: () => _authService.signIn('google'),
                      ),
                      const SizedBox(height: 12),

                      // 3. Apple
                      _AuthButton(
                        label: 'Войти с Apple',
                        iconData: Icons.apple,
                        backgroundColor: Colors.black,
                        textColor: Colors.white,
                        onPressed: () => _authService.signIn('apple'),
                      ),

                      // Разделитель
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: Row(
                          children: [
                            Expanded(child: Divider(color: theme.dividerColor)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Text(
                                'Российские сервисы',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.hintColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: theme.dividerColor)),
                          ],
                        ),
                      ),

                      // 4. Яндекс ID
                      _AuthButton(
                        label: 'Войти с Яндекс ID',
                        iconData: Icons.circle,
                        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                        textColor: isDark ? Colors.white : const Color(0xFF222222),
                        borderColor: isDark ? Colors.grey[700] : const Color(0xFFE5E5E5),
                        iconColor: const Color(0xFFFC3F1D),
                        onPressed: () => _authService.signIn('yandex'),
                      ),
                      const SizedBox(height: 12),

                      // 5. VK ID
                      _AuthButton(
                        label: 'Войти через VK ID',
                        iconData: Icons.alternate_email,
                        backgroundColor: const Color(0xFF0077FF),
                        textColor: Colors.white,
                        onPressed: () => _authService.signIn('vk'),
                      ),

                      const SizedBox(height: 24),
                      Text(
                        'После входа отобразится ваше имя, список из базы данных и кнопка выхода.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BackendChoiceButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _BackendChoiceButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).cardColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final String label;
  final IconData iconData;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final Color? iconColor;
  final VoidCallback onPressed;

  const _AuthButton({
    required this.label,
    required this.iconData,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    this.iconColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: borderColor != null ? 0 : 2,
          side: borderColor != null ? BorderSide(color: borderColor!, width: 1) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconData,
              size: 22,
              color: iconColor ?? textColor,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
