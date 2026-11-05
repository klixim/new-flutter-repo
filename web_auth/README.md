# Веб-приложение авторизации и работы с базой данных (JavaScript)

Данное веб-приложение реализует требования первого этапа задачи:
- Кнопки авторизации: **GitHub**, **Gmail / Google**, **Apple**, а также российские сервисы **Яндекс ID** и **VK ID**.
- Поддержка двух бэкендов: **Supabase** и **Firebase**.
- После успешного входа:
  - Отображается **имя пользователя**, email и аватар.
  - Загружается **список записей из базы данных** (PostgreSQL в Supabase или Cloud Firestore в Firebase).
  - Предоставлена **кнопка выхода** («Выйти»).
  - Добавлена форма мгновенного добавления новых записей в БД с автообновлением списка.
- **Встроенный Demo-режим**: если у вас пока нет ключей от всех сервисов, приложение сразу же работает в браузере, эмулируя авторизацию любого провайдера и реактивную базу данных!

---

## 🚀 Быстрый запуск локально

1. Откройте терминал в папке проекта:
   ```powershell
   cd c:\MobileDevelopment\web_auth
   ```
2. Запустите встроенный веб-сервер Python:
   ```powershell
   python -m http.server 3000
   ```
3. Откройте в браузере адрес:
   **[http://localhost:3000](http://localhost:3000)**

---

## 🛠 Настройка провайдеров

### 1. Supabase (GitHub, Google, Apple + PostgreSQL)
1. Зарегистрируйтесь на [supabase.com](https://supabase.com) и создайте проект.
2. Перейдите в **Project Settings -> API** и скопируйте `Project URL` и `anon public key`.
3. Откройте **SQL Editor** в Supabase и выполните скрипт из файла [`supabase_schema.sql`](file:///c:/MobileDevelopment/web_auth/supabase_schema.sql):
   - Он создаст таблицу `items` и настроит политики безопасности (Row Level Security).
4. Перейдите в **Authentication -> Providers** в панели Supabase:
   - Включите **GitHub**: вставьте `Client ID` и `Client Secret` (создаются в GitHub Settings -> Developer settings -> OAuth Apps). Укажите Authorization callback URL из панели Supabase.
   - Включите **Google**: вставьте `Client ID` и `Client Secret` из Google Cloud Console.
   - Включите **Apple**: настройте Services ID и Private Key из Apple Developer Portal.
5. В веб-приложении нажмите **«Настройки API»** в правом верхнем углу и вставьте ваши URL и Anon Key.

### 2. Firebase (GitHub, Google, Apple + Cloud Firestore)
1. Перейдите в [Firebase Console](https://console.firebase.google.com/) и создайте проект.
2. В разделе **Build -> Authentication -> Sign-in method** включите провайдеры:
   - Google
   - GitHub
   - Apple
3. В разделе **Build -> Firestore Database** создайте базу данных и коллекцию `items`.
4. В **Project Settings** добавьте веб-приложение и скопируйте объект `firebaseConfig`.
5. Вставьте его в окно «Настройки API» в приложении.

### 3. Яндекс ID и VK ID
- **Яндекс ID**: создайте приложение в [Яндекс OAuth](https://oauth.yandex.ru/), выберите права доступа к логину, имени и email, вставьте Redirect URI (`http://localhost:3000/`) и укажите полученный Client ID в настройках.
- **VK ID**: создайте приложение в [VK Developers](https://dev.vk.com/), укажите Redirect URI и сохраните App ID в настройках.
