# Flutter RuStore Application

Репозиторий Flutter-приложения с настроенным CI/CD на базе GitHub Actions для автоматической сборки APK и публикации в RuStore.

---

## 📁 Структура проекта

```text
├── .github/
│   └── workflows/
│       └── build_and_publish.yml  # GitHub Actions workflow: сборка APK и выгрузка в RuStore
├── android/
│   └── app/
│       └── src/main/
│           ├── AndroidManifest.xml # Манифест приложения
│           └── res/               # Иконки приложения (mipmap) и стили
├── assets/
│   └── icons/                     # Исходные иконки (192x192, 512x512)
├── lib/
│   └── main.dart                  # Исходный код Flutter-приложения
├── store_assets/
│   ├── icon_512.png               # Иконка 512x512 для RuStore Console
│   └── screenshots/               # Скриншоты для карточки приложения в RuStore
│       ├── screenshot_1_home.png
│       ├── screenshot_2_counter.png
│       ├── screenshot_3_dark.png
│       └── ai_mockup_screenshot.jpg
├── pubspec.yaml                   # Манифест зависимостей Flutter
└── analysis_options.yaml          # Настройки анализатора Dart/Flutter
```

---

## ⚙️ CI/CD: Сборка и публикация

При каждом `push` в ветку `main` или создании `pull_request` автоматически запускается GitHub Actions workflow:
1. Запускается виртуальная машина Ubuntu.
2. Устанавливается Java 17 и Flutter SDK.
3. Проверяются и генерируются платформенные файлы (`flutter create . --org com.klixim`).
4. Выполняется сборка релизного APK: `flutter build apk --release`.
5. Файл APK сохраняется в **GitHub Artifacts** (срок хранения 14 дней).
6. При наличии секретов `RUSTORE_KEY_ID` и `RUSTORE_PRIVATE_KEY` APK автоматически отправляется в RuStore.

---

## 📱 Требования RuStore к карточке приложения

| Ресурс | Требование | Где находится в репозитории |
|---|---|---|
| **Иконка** | PNG, 512x512 px, до 5 МБ | `store_assets/icon_512.png` |
| **Скриншоты** | PNG/JPEG, от 3 штук, соотношение от 1:2 до 2:1 | `store_assets/screenshots/` |
| **Релизный файл** | APK или AAB | Создается в GitHub Artifacts: `app-release.apk` |

---

## 🔑 Настройка секретов для RuStore

1. Войдите в [RuStore Консоль](https://console.rustore.ru/).
2. Перейдите в раздел **API RuStore** и сгенерируйте ключ.
3. В GitHub перейдите в **Settings** ➔ **Secrets and variables** ➔ **Actions**.
4. Создайте секреты:
   - `RUSTORE_KEY_ID`: Company ID из консоли.
   - `RUSTORE_PRIVATE_KEY`: Приватный RSA-ключ в формате Base64.
