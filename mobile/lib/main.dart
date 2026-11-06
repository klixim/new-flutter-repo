import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

const databaseUrl = String.fromEnvironment(
  'FIREBASE_DATABASE_URL',
  defaultValue: 'https://students-reg-90638-default-rtdb.europe-west1.firebasedatabase.app',
);
const googleClient = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (databaseUrl.isNotEmpty) {
    try {
      await Firebase.initializeApp();
    } catch (_) {}
  }
  runApp(const MaterialApp(home: StudentsPage(), debugShowCheckedModeBanner: false));
}

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});
  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  static const modes = [
    'Firebase · без Realtime',
    'Firebase · с Realtime',
  ];
  static const providers = {
    'github': 'GitHub',
    'google': 'Google / Gmail',
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
  Future<void>? googleInit;

  bool get live => mode == 1;
  bool get configured => databaseUrl.isNotEmpty;
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
  }

  void observe() {
    unawaited(authChanges?.cancel());
    final selected = mode;
    if (!configured) return;
    authChanges = auth.authStateChanges().listen((user) {
      if (mounted && mode == selected) {
        showAccount(user?.uid, user?.displayName ?? user?.email ?? 'Пользователь');
      }
    }, onError: showError);
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
    if (live) {
      dataChanges = latest.onValue.listen((event) {
        if (mounted && view == current) {
          request++;
          setState(() => rows = decode(event.snapshot));
        }
      }, onError: (Object error) {
        if (view == current) showError(error);
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
      final records = decode(await latest.get());
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
    if (provider == 'google') {
      await (googleInit ??= GoogleSignIn.instance.initialize(
        serverClientId: googleClient.isEmpty ? null : googleClient,
      ));
      final user = await GoogleSignIn.instance.authenticate();
      await auth.signInWithCredential(fb.GoogleAuthProvider.credential(
        idToken: user.authentication.idToken,
      ));
    } else {
      await auth.signInWithProvider(fb.GithubAuthProvider());
    }
  }

  Future<void> insert() async {
    if (!form.currentState!.validate()) return;
    final current = view;
    final row = {
      'name': name.text.trim(), 'major': major.text.trim(), 'gradYear': int.parse(year.text.trim()),
    };
    await students.push().set(row);
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
      if (!configured) const Text('Добавьте настройки подключения Firebase согласно README.'),
      if (configured && account == null)
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final entry in providers.entries)
            OutlinedButton(
              onPressed: busy ? null : () => run(() => login(entry.key)),
              child: Text(entry.value),
            ),
        ]),
      if (account != null) ...[
        Text('Вы вошли как $account', style: Theme.of(context).textTheme.titleLarge),
        OutlinedButton(onPressed: busy ? null : () => run(() async {
          await auth.signOut();
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
