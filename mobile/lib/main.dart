import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://eyywkkxnzzwpjmgnsnqq.supabase.co');
const supabaseKey = String.fromEnvironment('SUPABASE_KEY', defaultValue: 'sb_publishable_FvDLO-hrPG_I2hznWMp8Tg_ixmUPw9m');
const databaseUrl = String.fromEnvironment('FIREBASE_DATABASE_URL');
const oauthUrl = String.fromEnvironment('OAUTH_URL');
const googleClient = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
    await sb.Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
  }
  if (databaseUrl.isNotEmpty) await Firebase.initializeApp();
  runApp(const MaterialApp(home: StudentsPage(), debugShowCheckedModeBanner: false));
}

Future<void> loginExternal(String provider) async {
  final server = Uri.tryParse(oauthUrl);
  if (server == null || server.scheme != 'https' || !server.hasAuthority) {
    throw StateError('Укажите HTTPS-адрес OAUTH_URL.');
  }
  final random = Random.secure();
  String encode(List<int> bytes) => base64UrlEncode(bytes).replaceAll('=', '');
  final verifier = encode(List.generate(32, (_) => random.nextInt(256)));
  final start = server.resolve('/login/$provider').replace(queryParameters: {
    'mobile': '1', 'challenge': encode(sha256.convert(utf8.encode(verifier)).bytes),
  });
  final result = Uri.parse(await FlutterWebAuth2.authenticate(
    url: start.toString(), callbackUrlScheme: 'studentsoauth',
  ));
  final ticket = result.queryParameters['ticket'];
  if (result.host != 'callback' || ticket == null) {
    throw StateError('Провайдер отклонил вход или вход был отменён.');
  }
  final response = await http.post(server.resolve('/exchange'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'ticket': ticket, 'verifier': verifier}),
  ).timeout(const Duration(seconds: 15));
  if (response.statusCode != 200) throw StateError('Код входа не принят.');
  final token = (jsonDecode(response.body) as Map)['token'] as String;
  await fb.FirebaseAuth.instance.signInWithCustomToken(token);
}

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});
  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  static const modes = [
    'Supabase · без Realtime', 'Supabase · с Realtime',
    'Firebase · без Realtime', 'Firebase · с Realtime',
  ];
  static const providers = {
    'github': 'GitHub', 'google': 'Google / Gmail', 'apple': 'Apple',
    'yandex': 'Яндекс ID', 'vk': 'VK ID',
  };
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final major = TextEditingController();
  final year = TextEditingController();
  int mode = 0, view = 0, request = 0;
  bool busy = false;
  String? account, uid, message;
  List<Map<String, dynamic>> rows = [];
  StreamSubscription<dynamic>? authChanges, dataChanges;
  sb.RealtimeChannel? channel;
  Future<void>? googleInit;

  bool get firebase => mode >= 2;
  bool get live => mode.isOdd;
  bool get configured => firebase
      ? databaseUrl.isNotEmpty : supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
  sb.SupabaseClient get supabase => sb.Supabase.instance.client;
  fb.FirebaseAuth get auth => fb.FirebaseAuth.instance;
  DatabaseReference get students =>
      FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: databaseUrl).ref('lab_students');
  Query get latest => students.limitToLast(100);

  @override
  void initState() {
    super.initState();
    observe();
  }

  void stopData() {
    unawaited(dataChanges?.cancel());
    dataChanges = null;
    final previous = channel;
    channel = null;
    if (previous != null) unawaited(supabase.removeChannel(previous).then<void>((_) {}));
  }

  void observe() {
    unawaited(authChanges?.cancel());
    final selected = mode;
    if (!configured) return;
    if (firebase) {
      authChanges = auth.authStateChanges().listen((user) {
        if (mounted && mode == selected) {
          showAccount(user?.uid, user?.displayName ?? user?.email ?? 'Пользователь');
        }
      }, onError: showError);
    } else {
      void update(sb.User? user) {
        final meta = user?.userMetadata;
        final label = meta?['full_name'] ?? meta?['name'] ?? meta?['user_name'] ??
            user?.email ?? 'Пользователь';
        if (mounted && mode == selected) showAccount(user?.id, label.toString());
      }
      authChanges = supabase.auth.onAuthStateChange.listen(
        (state) => update(state.session?.user), onError: showError,
      );
      update(supabase.auth.currentUser);
    }
  }

  void showAccount(String? id, String label) {
    if (uid == id) return;
    stopData();
    final current = ++view;
    setState(() {
      uid = id;
      account = id == null ? null : label;
      rows = [];
    });
    if (id == null) return;
    if (live && firebase) {
      dataChanges = latest.onValue.listen((event) {
        if (mounted && view == current) {
          request++;
          setState(() => rows = decode(event.snapshot));
        }
      }, onError: (Object error) {
        if (view == current) showError(error);
      });
    } else if (live) {
      channel = supabase.channel('mobile-students-$current')
        .onPostgresChanges(
          event: sb.PostgresChangeEvent.all, schema: 'public', table: 'lab_students',
          callback: (_) { if (view == current) unawaited(refresh()); },
        )
        .subscribe((status, error) {
          if (view != current || !mounted) return;
          if (status == sb.RealtimeSubscribeStatus.subscribed) unawaited(refresh());
          if (error != null) showError(error);
        });
    } else {
      unawaited(refresh());
    }
  }

  List<Map<String, dynamic>> decode(DataSnapshot snapshot) => snapshot.children
      .where((child) => child.value is Map)
      .map((child) => Map<String, dynamic>.from(child.value as Map))
      .toList().reversed.toList();

  Future<void> refresh() async {
    final current = view, read = ++request;
    try {
      final records = firebase
          ? decode(await latest.get())
          : await supabase.from('lab_students').select('name,major,gradYear')
              .order('id', ascending: false).limit(100);
      if (mounted && view == current && request == read) setState(() => rows = records);
    } catch (error) {
      if (view == current && request == read) showError(error);
    }
  }

  void showError(Object error) {
    if (mounted) setState(() => message = error.toString());
  }

  Future<void> run(Future<void> Function() task) async {
    if (busy) return;
    setState(() { busy = true; message = null; });
    try {
      await task();
    } catch (error) {
      showError(error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> login(String provider) async {
    if (!firebase) {
      final option = switch (provider) {
        'github' => sb.OAuthProvider.github,
        'google' => sb.OAuthProvider.google,
        _ => sb.OAuthProvider.apple,
      };
      await supabase.auth.signInWithOAuth(option, redirectTo: 'studentslab://auth');
      return;
    }
    if (provider == 'yandex' || provider == 'vk') {
      await loginExternal(provider);
    } else if (provider == 'google') {
      await (googleInit ??= GoogleSignIn.instance.initialize(
        serverClientId: googleClient.isEmpty ? null : googleClient,
      ));
      final user = await GoogleSignIn.instance.authenticate();
      await auth.signInWithCredential(fb.GoogleAuthProvider.credential(
        idToken: user.authentication.idToken,
      ));
    } else {
      await auth.signInWithProvider(
        provider == 'github' ? fb.GithubAuthProvider() : fb.AppleAuthProvider(),
      );
    }
  }

  Future<void> insert() async {
    if (!form.currentState!.validate()) return;
    final current = view;
    final row = {
      'name': name.text.trim(), 'major': major.text.trim(), 'gradYear': int.parse(year.text.trim()),
    };
    if (firebase) {
      await students.push().set(row);
    } else {
      await supabase.from('lab_students').insert(row);
    }
    if (!mounted || current != view) return;
    name.clear();
    major.clear();
    year.clear();
    if (!live) await refresh();
  }

  @override
  void dispose() {
    view++;
    stopData();
    unawaited(authChanges?.cancel());
    name.dispose();
    major.dispose();
    year.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Студенты')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      DropdownButton<int>(
        value: mode, isExpanded: true,
        items: List.generate(modes.length, (i) => DropdownMenuItem(value: i, child: Text(modes[i]))),
        onChanged: busy ? null : (value) {
          if (value == null || value == mode) return;
          stopData();
          view++;
          setState(() { mode = value; uid = null; account = null; message = null; rows = []; });
          observe();
        },
      ),
      if (!configured) const Text('Добавьте настройки подключения согласно README.'),
      if (configured && account == null)
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final entry in providers.entries)
            OutlinedButton(
              onPressed: busy || (!firebase && ['vk', 'yandex'].contains(entry.key))
                  ? null : () => run(() => login(entry.key)),
              child: Text(entry.value),
            ),
        ]),
      if (account != null) ...[
        Text('Вы вошли как $account', style: Theme.of(context).textTheme.titleLarge),
        OutlinedButton(onPressed: busy ? null : () => run(() async {
          if (firebase) {
            await auth.signOut();
          } else {
            await supabase.auth.signOut(scope: sb.SignOutScope.local);
          }
        }), child: const Text('Выйти')),
        Form(key: form, child: Column(children: [
          TextFormField(controller: name, maxLength: 100,
            decoration: const InputDecoration(labelText: 'Имя'), validator: requiredText),
          TextFormField(controller: major, maxLength: 120,
            decoration: const InputDecoration(labelText: 'Специальность'), validator: requiredText),
          TextFormField(controller: year, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Год выпуска'),
            validator: (text) {
              final value = int.tryParse(text?.trim() ?? '');
              return value == null || value < 1900 || value > 2200 ? 'От 1900 до 2200' : null;
            }),
          FilledButton(onPressed: busy ? null : () => run(insert), child: const Text('Добавить студента')),
        ])),
        TextButton(onPressed: busy ? null : refresh, child: const Text('Обновить список')),
        if (rows.isEmpty) const Text('В списке пока нет записей.'),
        for (final row in rows) ListTile(
          title: Text(row['name'].toString()),
          subtitle: Text('${row['major']} · выпуск ${row['gradYear']}'),
        ),
      ],
      if (busy) const LinearProgressIndicator(),
      if (message != null) Text(message!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
    ]),
  );

  String? requiredText(String? value) => (value ?? '').trim().isEmpty ? 'Заполните поле' : null;
}
