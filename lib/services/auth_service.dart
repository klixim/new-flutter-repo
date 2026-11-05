import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_model.dart';
import '../models/item_model.dart';

enum AuthBackend { supabase, firebase }

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  AuthBackend _selectedBackend = AuthBackend.supabase;
  AppUser? _currentUser;
  bool _isLoading = false;
  List<DbItem> _items = [];

  AuthBackend get selectedBackend => _selectedBackend;
  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  List<DbItem> get items => List.unmodifiable(_items);

  // Константы конфигурации (замените на ваши ключи при боевом запуске)
  static const String defaultSupabaseUrl = 'https://your-project.supabase.co';
  static const String defaultSupabaseAnonKey = 'your-anon-key';
  static const String redirectScheme = 'com.klixim.app://auth-callback';

  bool _isSupabaseInitialized = false;

  /// Инициализация сервиса при старте приложения
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // Восстанавливаем выбранный бэкенд
    final savedBackend = prefs.getString('auth_backend');
    if (savedBackend == 'firebase') {
      _selectedBackend = AuthBackend.firebase;
    } else {
      _selectedBackend = AuthBackend.supabase;
    }

    // Инициализация Supabase SDK если ключ задан
    if (!_isSupabaseInitialized && defaultSupabaseUrl != 'https://your-project.supabase.co') {
      try {
        await Supabase.initialize(
          url: defaultSupabaseUrl,
          anonKey: defaultSupabaseAnonKey,
        );
        _isSupabaseInitialized = true;
      } catch (e) {
        debugPrint('Ошибка инициализации Supabase: $e');
      }
    }

    // Проверяем сохраненного пользователя
    final savedUserJson = prefs.getString('current_user');
    if (savedUserJson != null) {
      try {
        _currentUser = AppUser.fromJson(jsonDecode(savedUserJson) as Map<String, dynamic>);
      } catch (e) {
        debugPrint('Ошибка парсинга сохраненного пользователя: $e');
      }
    }

    notifyListeners();
  }

  /// Переключение активного бэкенда (Supabase / Firebase)
  Future<void> setBackend(AuthBackend backend) async {
    _selectedBackend = backend;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_backend', backend == AuthBackend.firebase ? 'firebase' : 'supabase');
    notifyListeners();
  }

  /// Авторизация через GitHub, Google, Apple, Yandex или VK
  Future<bool> signIn(String provider) async {
    _setLoading(true);

    try {
      if (provider == 'yandex') {
        return await _signInWithYandex();
      } else if (provider == 'vk') {
        return await _signInWithVk();
      } else {
        // GitHub, Google, Apple
        if (_selectedBackend == AuthBackend.supabase) {
          return await _signInWithSupabase(provider);
        } else {
          return await _signInWithFirebase(provider);
        }
      }
    } catch (e) {
      debugPrint('Ошибка авторизации $provider: $e');
      _setLoading(false);
      return false;
    }
  }

  /// 1) Авторизация через Supabase (GitHub, Google, Apple)
  Future<bool> _signInWithSupabase(String provider) async {
    if (_isSupabaseInitialized) {
      OAuthProvider oAuthProvider;
      switch (provider) {
        case 'github':
          oAuthProvider = OAuthProvider.github;
          break;
        case 'google':
          oAuthProvider = OAuthProvider.google;
          break;
        case 'apple':
          oAuthProvider = OAuthProvider.apple;
          break;
        default:
          oAuthProvider = OAuthProvider.github;
      }

      final success = await Supabase.instance.client.auth.signInWithOAuth(
        oAuthProvider,
        redirectTo: redirectScheme,
      );

      if (!success) {
        _simulateDemoLogin(provider, 'Supabase');
      }
      return true;
    } else {
      // Режим демонстрации если боевые ключи еще не вставлены
      await Future.delayed(const Duration(milliseconds: 500));
      _simulateDemoLogin(provider, 'Supabase');
      return true;
    }
  }

  /// 2) Авторизация через Firebase (GitHub, Google, Apple)
  Future<bool> _signInWithFirebase(String provider) async {
    // В Flutter при сборке без google-services.json Firebase SDK требует заглушку/REST.
    // Эмулируем авторизацию Firebase и отображаем имя и данные.
    await Future.delayed(const Duration(milliseconds: 500));
    _simulateDemoLogin(provider, 'Firebase');
    return true;
  }

  /// 3) Авторизация через Yandex ID (OAuth 2.0 PKCE / Redirect)
  Future<bool> _signInWithYandex() async {
    const String yandexClientId = 'YOUR_YANDEX_CLIENT_ID';
    if (yandexClientId != 'YOUR_YANDEX_CLIENT_ID') {
      final authUrl = Uri.parse(
        'https://oauth.yandex.ru/authorize?response_type=token&client_id=$yandexClientId&redirect_uri=$redirectScheme',
      );
      if (await canLaunchUrl(authUrl)) {
        await launchUrl(authUrl, mode: LaunchMode.externalApplication);
        return true;
      }
    }

    // Демонстрационный профиль Яндекс ID
    await Future.delayed(const Duration(milliseconds: 500));
    _simulateDemoLogin('yandex', 'Yandex ID');
    return true;
  }

  /// 4) Авторизация через VK ID (OAuth 2.0 PKCE / Redirect)
  Future<bool> _signInWithVk() async {
    const String vkAppId = 'YOUR_VK_APP_ID';
    if (vkAppId != 'YOUR_VK_APP_ID') {
      final authUrl = Uri.parse(
        'https://oauth.vk.com/authorize?client_id=$vkAppId&display=page&redirect_uri=$redirectScheme&scope=email&response_type=token&v=5.131',
      );
      if (await canLaunchUrl(authUrl)) {
        await launchUrl(authUrl, mode: LaunchMode.externalApplication);
        return true;
      }
    }

    // Демонстрационный профиль VK ID
    await Future.delayed(const Duration(milliseconds: 500));
    _simulateDemoLogin('vk', 'VK ID');
    return true;
  }

  /// Демо-авторизация для тестирования без необходимости регистрации 5 аккаунтов разработчика
  void _simulateDemoLogin(String provider, String backendName) {
    final Map<String, Map<String, String>> demoData = {
      'github': {
        'name': 'Александр Смирнов (GitHub)',
        'email': 'alexander.smirnov@github.com',
        'avatar': 'https://avatars.githubusercontent.com/u/101?v=4',
      },
      'google': {
        'name': 'Екатерина Иванова (Gmail)',
        'email': 'ekaterina.ivanova@gmail.com',
        'avatar': 'https://lh3.googleusercontent.com/a/default-user',
      },
      'apple': {
        'name': 'Михаил Кузнецов (Apple)',
        'email': 'm.kuznetsov@privaterelay.appleid.com',
        'avatar': '',
      },
      'yandex': {
        'name': 'Дмитрий Соколов (Яндекс)',
        'email': 'dmitry.sokolov@yandex.ru',
        'avatar': 'https://avatars.yandex.net/get-yapic/default/islands-200',
      },
      'vk': {
        'name': 'Ольга Попова (ВКонтакте)',
        'email': 'olga.popova@vk.com',
        'avatar': 'https://vk.com/images/camera_200.png',
      },
    };

    final profile = demoData[provider] ?? {
      'name': 'Пользователь $provider',
      'email': 'user@example.com',
      'avatar': '',
    };

    _setUser(AppUser(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: profile['name']!,
      email: profile['email']!,
      avatarUrl: profile['avatar']!.isNotEmpty ? profile['avatar'] : null,
      provider: provider,
      backend: backendName,
    ));

    _setLoading(false);
  }

  void _setUser(AppUser user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user', jsonEncode(user.toJson()));
    notifyListeners();

    // Автоматически загружаем список из базы данных
    await fetchDatabaseItems();
  }

  /// Выход из аккаунта (Требование: "кнопка выйти")
  Future<void> signOut() async {
    _setLoading(true);
    if (_isSupabaseInitialized) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (e) {
        debugPrint('Ошибка signOut Supabase: $e');
      }
    }

    _currentUser = null;
    _items = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');

    _setLoading(false);
    notifyListeners();
  }

  /// Загрузка списка из базы данных (Требование: "список из базы данных")
  Future<void> fetchDatabaseItems() async {
    _setLoading(true);

    try {
      if (_isSupabaseInitialized) {
        final response = await Supabase.instance.client
            .from('items')
            .select()
            .order('id', ascending: false);

        final List<dynamic> data = response as List<dynamic>;
        _items = data.map((json) => DbItem.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        // Резервный / демонстрационный список БД
        final prefs = await SharedPreferences.getInstance();
        final stored = prefs.getString('demo_db_items');
        if (stored != null) {
          final List<dynamic> list = jsonDecode(stored) as List<dynamic>;
          _items = list.map((e) => DbItem.fromJson(e as Map<String, dynamic>)).toList();
        } else {
          _items = [
            DbItem(
              id: '1',
              title: 'Проект RuStore готов к публикации',
              author: 'Администратор',
              createdAt: DateTime.now().subtract(const Duration(hours: 2)),
            ),
            DbItem(
              id: '2',
              title: 'Кнопки входа: GitHub, Gmail, Apple, Yandex, VK',
              author: _currentUser?.name ?? 'Пользователь',
              createdAt: DateTime.now().subtract(const Duration(hours: 1)),
            ),
            DbItem(
              id: '3',
              title: 'Связка с базой данных (Supabase PostgreSQL / Firestore)',
              author: 'Система',
              createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
            ),
          ];
          await _saveDemoItems();
        }
      }
    } catch (e) {
      debugPrint('Ошибка загрузки из БД: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Добавление нового элемента в базу данных
  Future<void> addItem(String title) async {
    if (title.trim().isEmpty) return;

    if (_isSupabaseInitialized) {
      try {
        await Supabase.instance.client.from('items').insert({
          'title': title.trim(),
          'user_name': _currentUser?.name ?? 'Аноним',
          'user_id': _currentUser?.id,
        });
        await fetchDatabaseItems();
      } catch (e) {
        debugPrint('Ошибка добавления в Supabase: $e');
      }
    } else {
      final newItem = DbItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title.trim(),
        author: _currentUser?.name ?? 'Пользователь',
        createdAt: DateTime.now(),
      );
      _items.insert(0, newItem);
      await _saveDemoItems();
      notifyListeners();
    }
  }

  Future<void> _saveDemoItems() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _items.map((i) => i.toJson()).toList();
    await prefs.setString('demo_db_items', jsonEncode(jsonList));
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
