/// Конфигурация подключения к Supabase (БД и Авторизация)
///
/// Значения можно передавать при сборке через аргументы компилятора:
/// flutter run --dart-define=SUPABASE_URL=https://xyz.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
/// или указать напрямую в константах ниже.
class SupabaseConfig {
  // URL вашего проекта Supabase
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://vvdptwtxrffeqmsqjhca.supabase.co', // Замените на URL вашего инстанса при необходимости
  );

  // Публичный анонимный ключ (anon / public key)
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ2ZHB0d3R4cmZmZXFtc3FqaGNhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDAsImV4cCI6MjAwMH0.placeholder',
  );

  // Название таблицы в PostgreSQL Supabase для списка
  static const String itemsTable = 'items';

  // Deep Link URI схемы для возврата после OAuth-авторизации
  static const String redirectUrl = 'com.klixim.app://auth-callback';

  /// Проверка, установлены ли боевые ключи проекта
  static bool get isConfigured {
    return supabaseUrl.isNotEmpty && 
           !supabaseUrl.contains('placeholder') &&
           supabaseAnonKey.isNotEmpty &&
           !supabaseAnonKey.contains('placeholder');
  }
}
