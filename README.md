# Студенты (Firebase Realtime Database)

Учебный проект по мобильной и веб-разработке. Форма сохраняет имя студента, специальность и год выпуска. После входа отображается профиль пользователя, список студентов, форма добавления новой записи и кнопка «Выйти». Вся работа происходит исключительно с реальной облачной базой данных Firebase.

---

## 1. Запуск веб-приложения

### Локальный запуск
Для локального запуска веб-версии выполните в PowerShell:
```powershell
python preview.py
# или при наличии Node.js:
node preview.cjs
```
Сервер запустится по адресу [http://127.0.0.1:8085/](http://127.0.0.1:8085/) (или 8080).

### Публичный запуск на GitHub Pages
Страница развернута и доступна по адресу:
👉 **[https://klixim.github.io/new-flutter-repo/](https://klixim.github.io/new-flutter-repo/)**

### Режимы работы с базой данных
В приложении доступны 2 режима взаимодействия с Firebase:

| Вариант | Чтение | Добавление | Что происходит при записи из другой вкладки |
| --- | --- | --- | --- |
| **Firebase · без Realtime** | `get()` | `push()` | Список обновляется вручную по кнопке «Обновить список» |
| **Firebase · с Realtime** | `onValue()` | `push()` | Мгновенное обновление по WebSocket во всех открытых вкладках |

> **Проверка Realtime:** Откройте две вкладки сайта. В первой выберите «без Realtime», во второй — «с Realtime». Авторизуйтесь в обеих. При добавлении студента из первой вкладки во второй он появится мгновенно без перезагрузки страницы!

---

## 2. Пошаговая инструкция: Как подключить Firebase к https://klixim.github.io/new-flutter-repo/

Чтобы приложение на GitHub Pages работало с вашей собственной базой данных Firebase и авторизацией, выполните следующие шаги:

### Шаг 1. Создание проекта в Firebase Console
1. Перейдите в [Firebase Console](https://console.firebase.google.com/) и войдите под вашим Google-аккаунтом.
2. Нажмите **«Добавить проект»** (Add project).
3. Введите название проекта (например, `students-lab-app`), нажмите «Продолжить».
4. Google Analytics можно отключить (для учебного проекта не требуется) и нажмите **«Создать проект»**.

---

### Шаг 2. Регистрация Web App и получение конфигурации
1. На главной странице проекта в Firebase Console нажмите на иконку веба **`</>`** (или перейдите в **Project settings → General → Your apps → Add app → Web**).
2. В поле «Псевдоним приложения» (App nickname) укажите, например, `Students Web`.
3. Флажок «Firebase Hosting» ставить **не нужно** (хостинг осуществляется через GitHub Pages). Нажмите **«Зарегистрировать приложение»**.
4. В блоке `const firebaseConfig = { ... };` скопируйте значения параметров:
   - `apiKey`
   - `authDomain`
   - `projectId`
   - `storageBucket`
   - `messagingSenderId`
   - `appId`
5. Откройте файл `docs/index.html` в вашем репозитории и вставьте скопированные значения в объект `config.firebase`:
   ```javascript
   const config = {
     firebase: {
       apiKey: "ВАШ_API_KEY",
       authDomain: "ВАШ_PROJECT_ID.firebaseapp.com",
       projectId: "ВАШ_PROJECT_ID",
       storageBucket: "ВАШ_PROJECT_ID.firebasestorage.app",
       messagingSenderId: "ВАШ_SENDER_ID",
       appId: "ВАШ_APP_ID",
       databaseURL: "https://ВАШ_PROJECT_ID-default-rtdb.europe-west1.firebasedatabase.app", // см. Шаг 3
     },
     oauthServer: '',
   };
   ```

---

### Шаг 3. Создание и настройка Realtime Database
1. В левом меню Firebase Console перейдите в раздел **Build → Realtime Database** и нажмите **«Create Database»** (Создать базу данных).
2. Выберите регион (рекомендуется **Belgium / `europe-west1`** или `us-central`).
3. Выберите **«Start in locked mode»** (Начать в заблокированном режиме) и нажмите «Включить».
4. Скопируйте полученный URL базы данных (отображается над таблицей, вида `https://<project-id>-default-rtdb.europe-west1.firebasedatabase.app`) и вставьте его в поле `databaseURL` в `docs/index.html`.
5. Перейдите на вкладку **«Rules»** (Правила) в Realtime Database, замените содержимое на правила из файла `setup/database.rules.json`:
   ```json
   {
     "rules": {
       ".read": false,
       ".write": false,
       "lab_students": {
         ".read": "auth != null",
         "$student": {
           ".write": "auth != null && !data.exists() && newData.exists()",
           ".validate": "newData.hasChildren(['name', 'major', 'gradYear'])",
           "name": { ".validate": "newData.isString() && newData.val().matches(/.*\\S.*/) && newData.val().length <= 100" },
           "major": { ".validate": "newData.isString() && newData.val().matches(/.*\\S.*/) && newData.val().length <= 120" },
           "gradYear": { ".validate": "newData.isNumber() && newData.val() % 1 == 0 && newData.val() >= 1900 && newData.val() <= 2200" },
           "$other": { ".validate": false }
         }
       }
     }
   }
   ```
6. Нажмите **«Publish»** (Опубликовать).

> Данные правила разрешают авторизованным пользователям читать ветку `lab_students` и добавлять студентов с валидацией имени, специальности и года выпуска.

---

### Шаг 4. Настройка способов входа (Authentication)
1. В левом меню перейдите в **Build → Authentication** и нажмите **«Get started»** (Начать).
2. На вкладке **«Sign-in method»** включите необходимые провайдеры:
   - **Google**: Нажмите на Google, переведите переключатель в положение «Включено», укажите публичное имя проекта и email службы поддержки, затем нажмите «Сохранить».
   - **GitHub**:
     1. Включите GitHub. Firebase покажет вам **Authorization callback URL** (вида `https://<project-id>.firebaseapp.com/__/auth/handler`).
     2. В новой вкладке откройте [GitHub Developer Settings → OAuth Apps](https://github.com/settings/developers).
     3. Нажмите **«New OAuth App»**.
     4. Укажите:
        - Application name: `Students Lab`
        - Homepage URL: `https://klixim.github.io/new-flutter-repo/`
        - Authorization callback URL: вставьте скопированный из Firebase адрес `https://<project-id>.firebaseapp.com/__/auth/handler`.
     5. Нажмите «Register application», сгенерируйте Client Secret и скопируйте **Client ID** и **Client Secret** в соответствующие поля в Firebase Console, затем сохраните.
   - **Анонимный вход (Anonymous)**: Включите провайдер «Anonymous». Это позволит вам и преподавателю тестировать добавление студентов в один клик без ввода паролей или настройки OAuth.

---

### Шаг 5. ОБЯЗАТЕЛЬНО: Авторизация домена GitHub Pages
По умолчанию Firebase Auth блокирует всплывающие окна авторизации на неизвестных доменах (`auth/unauthorized-domain`).

1. В разделе **Authentication** перейдите на вкладку **«Settings»** (Настройки).
2. Выберите пункт меню **«Authorized domains»** (Авторизованные домены).
3. Нажмите **«Add domain»** (Добавить домен).
4. Введите домен GitHub Pages:
   ```text
   klixim.github.io
   ```
5. Нажмите «Добавить». Убедитесь, что в списке присутствуют:
   - `localhost` (для локальной проверки)
   - `klixim.github.io` (для GitHub Pages)
   - `<project-id>.firebaseapp.com`

---

### Шаг 6. Публикация изменений на GitHub
1. Сохраните изменения в репозитории:
   ```powershell
   git add docs/index.html mobile/ setup/ tests/ README.md
   git commit -m "Configure Firebase for GitHub Pages and remove demo mode"
   git push origin main
   ```
2. Проверьте настройки GitHub Pages в вашем репозитории:
   - Откройте страницу репозитория на GitHub: **Settings → Pages**.
   - В блоке **Build and deployment**:
     - **Source**: `Deploy from a branch`
     - **Branch**: `main`
     - **Folder**: `/docs`
   - Нажмите **Save**.
3. Через 1–2 минуты страница обновится по адресу:
   **[https://klixim.github.io/new-flutter-repo/](https://klixim.github.io/new-flutter-repo/)**

---

## 3. Мобильное приложение (Flutter)

Код мобильного приложения находится в каталоге `mobile/`.

1. Запустите получение зависимостей:
   ```powershell
   cd mobile
   flutter pub get
   ```
2. Для сборки с вашей базой данных передайте URL базы через `--dart-define`:
   ```powershell
   flutter run --dart-define=FIREBASE_DATABASE_URL=https://students-reg-90638-default-rtdb.europe-west1.firebasedatabase.app
   ```
3. Для полной интеграции с Firebase на Android добавьте файл `google-services.json` (скачивается в Project settings -> Your apps -> Android) в папку `mobile/android/app/`.

---

## 4. Как устроен Firebase Realtime
- **Чтение списка:** `get(latest)` выполняет однократный HTTP-запрос к Realtime Database REST API / протоколу и возвращает последние 100 записей.
- **Добавление записи:** `push(students, row)` генерирует уникальный лексикографический ключ на стороне сервера и сохраняет запись студента.
- **Realtime-подписка:** `onValue(latest, callback)` устанавливает постоянное двустороннее WebSocket-соединение с Firebase. При любом изменении ветки `lab_students` сервер автоматически отправляет актуальный срез данных подписчикам без необходимости повторных запросов со стороны клиента.
