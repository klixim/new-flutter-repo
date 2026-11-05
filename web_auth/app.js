/**
 * Web Authentication & Database Integration Demo
 * Поддерживает:
 * - Supabase: GitHub, Google, Apple + PostgreSQL Table
 * - Firebase: GitHub, Google, Apple + Cloud Firestore
 * - OAuth 2.0 / SDK: Yandex ID, VK ID
 * - Demo / Fallback Mode: мгновенное тестирование без предварительной настройки ключей
 */

// Хранилище настроек конфигурации
const STORAGE_KEYS = {
  BACKEND: 'auth_demo_backend',
  SUPABASE_URL: 'auth_demo_sb_url',
  SUPABASE_KEY: 'auth_demo_sb_key',
  FIREBASE_CONFIG: 'auth_demo_fb_config',
  YANDEX_CLIENT_ID: 'auth_demo_ya_id',
  VK_APP_ID: 'auth_demo_vk_id',
  DEMO_DB_ITEMS: 'auth_demo_db_items_v1',
  CURRENT_USER_SESSION: 'auth_demo_session'
};

// Состояние приложения
let currentBackend = localStorage.getItem(STORAGE_KEYS.BACKEND) || 'supabase';
let supabaseClient = null;
let firebaseAuth = null;
let firestoreDb = null;
let currentUser = null;

// DOM Элементы
const elements = {
  // Screens
  authScreen: document.getElementById('authScreen'),
  userScreen: document.getElementById('userScreen'),
  backendSelectorCard: document.getElementById('backendSelectorCard'),
  demoBanner: document.getElementById('demoBanner'),
  statusMsg: document.getElementById('authStatusMessage'),
  
  // Toggles & Modal
  btnSelectSupabase: document.getElementById('btnSelectSupabase'),
  btnSelectFirebase: document.getElementById('btnSelectFirebase'),
  currentBackendDesc: document.getElementById('currentBackendDesc'),
  configToggleBtn: document.getElementById('configToggleBtn'),
  closeConfigBtn: document.getElementById('closeConfigBtn'),
  configModal: document.getElementById('configModal'),
  saveConfigBtn: document.getElementById('saveConfigBtn'),
  
  // Config Inputs
  cfgSupabaseUrl: document.getElementById('cfgSupabaseUrl'),
  cfgSupabaseAnonKey: document.getElementById('cfgSupabaseAnonKey'),
  cfgFirebaseConfig: document.getElementById('cfgFirebaseConfig'),
  cfgYandexClientId: document.getElementById('cfgYandexClientId'),
  cfgVkAppId: document.getElementById('cfgVkAppId'),

  // Auth Buttons
  btnGithub: document.getElementById('btnAuthGithub'),
  btnGoogle: document.getElementById('btnAuthGoogle'),
  btnApple: document.getElementById('btnAuthApple'),
  btnYandex: document.getElementById('btnAuthYandex'),
  btnVk: document.getElementById('btnAuthVk'),

  // User Profile
  userName: document.getElementById('userName'),
  userEmail: document.getElementById('userEmail'),
  userAvatar: document.getElementById('userAvatar'),
  avatarFallback: document.getElementById('avatarFallback'),
  userProviderBadge: document.getElementById('userProviderBadge'),
  btnLogout: document.getElementById('btnLogout'),

  // DB Elements
  dbSourceDesc: document.getElementById('dbSourceDesc'),
  dbItemsList: document.getElementById('dbItemsList'),
  dbLoading: document.getElementById('dbLoading'),
  addItemForm: document.getElementById('addItemForm'),
  newItemTitle: document.getElementById('newItemTitle'),
  btnRefreshDb: document.getElementById('btnRefreshDb')
};

// ==========================================
// 1. Инициализация и сохранение конфигураций
// ==========================================

function initConfigFields() {
  elements.cfgSupabaseUrl.value = localStorage.getItem(STORAGE_KEYS.SUPABASE_URL) || '';
  elements.cfgSupabaseAnonKey.value = localStorage.getItem(STORAGE_KEYS.SUPABASE_KEY) || '';
  elements.cfgFirebaseConfig.value = localStorage.getItem(STORAGE_KEYS.FIREBASE_CONFIG) || '';
  elements.cfgYandexClientId.value = localStorage.getItem(STORAGE_KEYS.YANDEX_CLIENT_ID) || '';
  elements.cfgVkAppId.value = localStorage.getItem(STORAGE_KEYS.VK_APP_ID) || '';

  const radios = document.getElementsByName('backendPref');
  for (const r of radios) {
    if (r.value === currentBackend) r.checked = true;
  }
}

function saveConfig() {
  const sbUrl = elements.cfgSupabaseUrl.value.trim();
  const sbKey = elements.cfgSupabaseAnonKey.value.trim();
  const fbCfg = elements.cfgFirebaseConfig.value.trim();
  const yaId = elements.cfgYandexClientId.value.trim();
  const vkId = elements.cfgVkAppId.value.trim();

  localStorage.setItem(STORAGE_KEYS.SUPABASE_URL, sbUrl);
  localStorage.setItem(STORAGE_KEYS.SUPABASE_KEY, sbKey);
  localStorage.setItem(STORAGE_KEYS.FIREBASE_CONFIG, fbCfg);
  localStorage.setItem(STORAGE_KEYS.YANDEX_CLIENT_ID, yaId);
  localStorage.setItem(STORAGE_KEYS.VK_APP_ID, vkId);

  const radios = document.getElementsByName('backendPref');
  for (const r of radios) {
    if (r.checked) {
      setBackend(r.value);
      break;
    }
  }

  elements.configModal.classList.add('hidden');
  initClients();
  showMessage('Настройки сохранены! Перезапуск клиентов...', 'info');
}

function setBackend(backend) {
  currentBackend = backend;
  localStorage.setItem(STORAGE_KEYS.BACKEND, backend);

  if (backend === 'supabase') {
    elements.btnSelectSupabase.classList.add('active');
    elements.btnSelectFirebase.classList.remove('active');
    elements.currentBackendDesc.textContent = 'Через Supabase Auth (GitHub, Google, Apple) + российские провайдеры (Yandex, VK)';
    elements.dbSourceDesc.textContent = 'Данные загружены из таблицы Supabase (PostgreSQL)';
  } else {
    elements.btnSelectFirebase.classList.add('active');
    elements.btnSelectSupabase.classList.remove('active');
    elements.currentBackendDesc.textContent = 'Через Firebase Auth (GitHub, Google, Apple) + российские провайдеры (Yandex, VK)';
    elements.dbSourceDesc.textContent = 'Данные загружены из коллекции Cloud Firestore';
  }

  updateDemoBadgeStatus();
}

function updateDemoBadgeStatus() {
  const isSbReady = !!(localStorage.getItem(STORAGE_KEYS.SUPABASE_URL) && localStorage.getItem(STORAGE_KEYS.SUPABASE_KEY));
  const isFbReady = !!localStorage.getItem(STORAGE_KEYS.FIREBASE_CONFIG);

  const isConfigured = (currentBackend === 'supabase' && isSbReady) || (currentBackend === 'firebase' && isFbReady);

  if (isConfigured) {
    elements.demoBanner.classList.add('hidden');
  } else {
    elements.demoBanner.classList.remove('hidden');
  }
}

// ==========================================
// 2. Инициализация Supabase и Firebase
// ==========================================

async function initClients() {
  const sbUrl = localStorage.getItem(STORAGE_KEYS.SUPABASE_URL);
  const sbKey = localStorage.getItem(STORAGE_KEYS.SUPABASE_KEY);

  if (sbUrl && sbKey && window.supabase) {
    try {
      supabaseClient = window.supabase.createClient(sbUrl, sbKey);
      
      // Проверяем существующую сессию Supabase
      const { data: { session } } = await supabaseClient.auth.getSession();
      if (session && session.user) {
        onAuthSuccess({
          name: session.user.user_metadata?.full_name || session.user.user_metadata?.name || session.user.email?.split('@')[0] || 'Пользователь Supabase',
          email: session.user.email || 'Не указан',
          avatarUrl: session.user.user_metadata?.avatar_url || null,
          provider: session.user.app_metadata?.provider || 'supabase',
          backend: 'supabase',
          id: session.user.id
        });
        return;
      }
    } catch (e) {
      console.warn('Ошибка инициализации Supabase:', e);
    }
  }

  // Firebase динамическая инициализация
  const fbConfigRaw = localStorage.getItem(STORAGE_KEYS.FIREBASE_CONFIG);
  if (fbConfigRaw) {
    try {
      const fbConfig = JSON.parse(fbConfigRaw);
      await loadFirebaseSDK(fbConfig);
    } catch (e) {
      console.warn('Ошибка инициализации Firebase:', e);
    }
  }

  // Проверка сохраненной демо/oauth сессии
  const savedSession = localStorage.getItem(STORAGE_KEYS.CURRENT_USER_SESSION);
  if (savedSession) {
    try {
      const user = JSON.parse(savedSession);
      onAuthSuccess(user, false);
    } catch (e) {}
  }
}

async function loadFirebaseSDK(config) {
  if (window.firebaseApp) return;
  try {
    const { initializeApp } = await import('https://www.gstatic.com/firebasejs/10.12.0/firebase-app.js');
    const { getAuth, onAuthStateChanged } = await import('https://www.gstatic.com/firebasejs/10.12.0/firebase-auth.js');
    const { getFirestore } = await import('https://www.gstatic.com/firebasejs/10.12.0/firebase-firestore.js');

    const app = initializeApp(config);
    window.firebaseApp = app;
    firebaseAuth = getAuth(app);
    firestoreDb = getFirestore(app);

    onAuthStateChanged(firebaseAuth, (user) => {
      if (user && currentBackend === 'firebase') {
        onAuthSuccess({
          name: user.displayName || user.email?.split('@')[0] || 'Пользователь Firebase',
          email: user.email || 'Не указан',
          avatarUrl: user.photoURL || null,
          provider: user.providerData?.[0]?.providerId || 'firebase',
          backend: 'firebase',
          id: user.uid
        });
      }
    });
  } catch (err) {
    console.error('Ошибка загрузки Firebase SDK:', err);
  }
}

// ==========================================
// 3. Обработка авторизации по провайдерам
// ==========================================

// Общий обработчик кликов по кнопкам
async function handleLogin(provider) {
  clearMessage();

  // 1. Российские провайдеры (Yandex и VK)
  if (provider === 'yandex') {
    return loginWithYandex();
  }
  if (provider === 'vk') {
    return loginWithVk();
  }

  // 2. Стандартные провайдеры (GitHub, Google, Apple)
  if (currentBackend === 'supabase') {
    await loginWithSupabase(provider);
  } else {
    await loginWithFirebase(provider);
  }
}

// Supabase Auth Flow
async function loginWithSupabase(provider) {
  if (!supabaseClient) {
    // Включаем демонстрационный режим с наглядными данными
    simulateDemoLogin(provider, 'Supabase');
    return;
  }

  try {
    showMessage(`Перенаправление на авторизацию ${provider}...`, 'info');
    const redirectTo = window.location.origin + window.location.pathname;

    const { error } = await supabaseClient.auth.signInWithOAuth({
      provider: provider, // 'github', 'google', 'apple'
      options: {
        redirectTo: redirectTo
      }
    });

    if (error) throw error;
  } catch (err) {
    showMessage(`Ошибка Supabase Auth: ${err.message}`, 'error');
  }
}

// Firebase Auth Flow
async function loginWithFirebase(provider) {
  if (!firebaseAuth) {
    // Включаем демонстрационный режим
    simulateDemoLogin(provider, 'Firebase');
    return;
  }

  try {
    showMessage(`Открытие окна авторизации ${provider}...`, 'info');
    const { signInWithPopup, GithubAuthProvider, GoogleAuthProvider, OAuthProvider } = 
      await import('https://www.gstatic.com/firebasejs/10.12.0/firebase-auth.js');

    let authProvider;
    if (provider === 'github') authProvider = new GithubAuthProvider();
    else if (provider === 'google') authProvider = new GoogleAuthProvider();
    else if (provider === 'apple') authProvider = new OAuthProvider('apple.com');

    const result = await signInWithPopup(firebaseAuth, authProvider);
    const user = result.user;

    onAuthSuccess({
      name: user.displayName || 'Пользователь Google/GitHub',
      email: user.email || 'user@example.com',
      avatarUrl: user.photoURL,
      provider: provider,
      backend: 'firebase',
      id: user.uid
    });
  } catch (err) {
    showMessage(`Ошибка Firebase Auth: ${err.message}`, 'error');
  }
}

// Yandex ID OAuth Flow
function loginWithYandex() {
  const clientId = localStorage.getItem(STORAGE_KEYS.YANDEX_CLIENT_ID);
  if (!clientId) {
    simulateDemoLogin('yandex', 'Yandex ID');
    return;
  }

  const redirectUri = window.location.origin + window.location.pathname;
  const yandexAuthUrl = `https://oauth.yandex.ru/authorize?response_type=token&client_id=${encodeURIComponent(clientId)}&redirect_uri=${encodeURIComponent(redirectUri)}&state=yandex_auth`;
  window.location.href = yandexAuthUrl;
}

// VK ID OAuth Flow
function loginWithVk() {
  const appId = localStorage.getItem(STORAGE_KEYS.VK_APP_ID);
  if (!appId) {
    simulateDemoLogin('vk', 'VK ID');
    return;
  }

  const redirectUri = window.location.origin + window.location.pathname;
  const vkAuthUrl = `https://oauth.vk.com/authorize?client_id=${encodeURIComponent(appId)}&display=page&redirect_uri=${encodeURIComponent(redirectUri)}&scope=email&response_type=token&v=5.131&state=vk_auth`;
  window.location.href = vkAuthUrl;
}

// Проверка OAuth Redirect Callback в URL Hash
async function checkOAuthCallbacks() {
  const hash = window.location.hash.substring(1);
  if (!hash) return;

  const params = new URLSearchParams(hash);
  const accessToken = params.get('access-token') || params.get('access_token');
  const state = params.get('state');

  if (accessToken) {
    // Очищаем хэш в URL
    window.history.replaceState(null, null, window.location.pathname);

    if (state === 'yandex_auth' || params.has('token_type')) {
      try {
        showMessage('Получение профиля Яндекс...', 'info');
        const res = await fetch(`https://login.yandex.ru/info?format=json`, {
          headers: { Authorization: `OAuth ${accessToken}` }
        });
        const info = await res.json();
        onAuthSuccess({
          name: info.real_name || info.display_name || info.first_name || 'Пользователь Яндекс',
          email: info.default_email || 'yandex_user@yandex.ru',
          avatarUrl: info.default_avatar_id ? `https://avatars.yandex.net/get-yapic/${info.default_avatar_id}/islands-200` : null,
          provider: 'yandex',
          backend: 'OAuth2 (Yandex ID)',
          id: info.id
        });
      } catch (e) {
        showMessage('Ошибка получения профиля Яндекс: ' + e.message, 'error');
      }
    }
  }
}

// Demo Login Simulation (мгновенный отклик при отсутствии боевых ключей)
function simulateDemoLogin(provider, backendName) {
  showMessage(`Вход через ${provider.toUpperCase()} (${backendName} Demo)...`, 'info');

  const demoProfiles = {
    github: {
      name: 'Александр Смирнов (GitHub Dev)',
      email: 'alex.developer@github.com',
      avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=120&h=120&q=80'
    },
    google: {
      name: 'Екатерина Иванова (Gmail)',
      email: 'ekaterina.ivanova@gmail.com',
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=120&h=120&q=80'
    },
    apple: {
      name: 'Михаил Кузнецов (Apple ID)',
      email: 'm.kuznetsov@privaterelay.appleid.com',
      avatarUrl: null
    },
    yandex: {
      name: 'Дмитрий Соколов (Яндекс ID)',
      email: 'dmitry.sokolov@yandex.ru',
      avatarUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?auto=format&fit=crop&w=120&h=120&q=80'
    },
    vk: {
      name: 'Ольга Попова (VK ID)',
      email: 'olga_popova@vk.com',
      avatarUrl: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&w=120&h=120&q=80'
    }
  };

  const profile = demoProfiles[provider] || {
    name: `Пользователь ${provider}`,
    email: `${provider}_user@example.com`,
    avatarUrl: null
  };

  setTimeout(() => {
    onAuthSuccess({
      name: profile.name,
      email: profile.email,
      avatarUrl: profile.avatarUrl,
      provider: provider,
      backend: backendName,
      id: 'demo_user_' + Math.random().toString(36).substring(7)
    });
  }, 400);
}

// ==========================================
// 4. Состояние после авторизации
// ==========================================

function onAuthSuccess(user, saveToStorage = true) {
  currentUser = user;
  if (saveToStorage) {
    localStorage.setItem(STORAGE_KEYS.CURRENT_USER_SESSION, JSON.stringify(user));
  }

  // Переключаем экраны
  elements.authScreen.classList.add('hidden');
  elements.backendSelectorCard.classList.add('hidden');
  elements.userScreen.classList.remove('hidden');

  // Отображаем имя пользователя (Требование ТЗ: "должно быть показано имя")
  elements.userName.textContent = user.name || 'Пользователь';
  elements.userEmail.textContent = user.email || '';
  elements.userProviderBadge.textContent = `${user.provider.toUpperCase()} via ${user.backend || currentBackend}`;

  // Аватар
  if (user.avatarUrl) {
    elements.userAvatar.src = user.avatarUrl;
    elements.userAvatar.classList.remove('hidden');
    elements.avatarFallback.classList.add('hidden');
  } else {
    elements.userAvatar.classList.add('hidden');
    elements.avatarFallback.classList.remove('hidden');
    elements.avatarFallback.textContent = (user.name || 'U')[0].toUpperCase();
  }

  // Загружаем список из базы данных (Требование ТЗ: "список из базы данных")
  loadDatabaseItems();
}

async function handleLogout() {
  // Выход из Supabase
  if (supabaseClient) {
    try { await supabaseClient.auth.signOut(); } catch (e) {}
  }

  // Выход из Firebase
  if (firebaseAuth) {
    try {
      const { signOut } = await import('https://www.gstatic.com/firebasejs/10.12.0/firebase-auth.js');
      await signOut(firebaseAuth);
    } catch (e) {}
  }

  currentUser = null;
  localStorage.removeItem(STORAGE_KEYS.CURRENT_USER_SESSION);

  // Возврат на экран авторизации (Требование ТЗ: "кнопка выйти")
  elements.userScreen.classList.add('hidden');
  elements.authScreen.classList.remove('hidden');
  elements.backendSelectorCard.classList.remove('hidden');
  clearMessage();
}

// ==========================================
// 5. Работа с Базой Данных (Supabase / Firestore / LocalDB)
// ==========================================

async function loadDatabaseItems() {
  elements.dbLoading.classList.remove('hidden');
  elements.dbItemsList.innerHTML = '';

  let items = [];

  try {
    // Вариант 1: Supabase PostgreSQL (Таблица 'items')
    if (currentBackend === 'supabase' && supabaseClient) {
      elements.dbSourceDesc.textContent = 'Подключено к Supabase: таблица `items` (PostgreSQL)';
      const { data, error } = await supabaseClient
        .from('items')
        .select('*')
        .order('id', { ascending: false });

      if (error) throw error;
      items = data || [];
    }
    // Вариант 2: Firebase Cloud Firestore (Коллекция 'items')
    else if (currentBackend === 'firebase' && firestoreDb) {
      elements.dbSourceDesc.textContent = 'Подключено к Firebase: коллекция `items` (Firestore)';
      const { collection, getDocs, query, orderBy } = 
        await import('https://www.gstatic.com/firebasejs/10.12.0/firebase-firestore.js');

      const q = query(collection(firestoreDb, 'items'), orderBy('createdAt', 'desc'));
      const snap = await getDocs(q);
      items = snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    }
    // Вариант 3: Demo Local Database
    else {
      elements.dbSourceDesc.textContent = 'Режим демонстрации БД (локальное реактивное хранилище данных)';
      items = getDemoDatabaseItems();
    }
  } catch (err) {
    console.warn('Ошибка загрузки из удаленной БД, переключение на локальный кэш:', err);
    elements.dbSourceDesc.textContent = 'Резервное хранилище (ошибка удаленной БД: ' + err.message + ')';
    items = getDemoDatabaseItems();
  } finally {
    elements.dbLoading.classList.add('hidden');
    renderDatabaseItems(items);
  }
}

async function handleAddItem(e) {
  e.preventDefault();
  const title = elements.newItemTitle.value.trim();
  if (!title) return;

  const newItem = {
    title: title,
    created_at: new Date().toISOString(),
    user_name: currentUser ? currentUser.name : 'Аноним'
  };

  elements.newItemTitle.value = '';

  try {
    // Запись в Supabase
    if (currentBackend === 'supabase' && supabaseClient) {
      const { error } = await supabaseClient.from('items').insert([newItem]);
      if (error) throw error;
    }
    // Запись в Firestore
    else if (currentBackend === 'firebase' && firestoreDb) {
      const { collection, addDoc, serverTimestamp } = 
        await import('https://www.gstatic.com/firebasejs/10.12.0/firebase-firestore.js');
      await addDoc(collection(firestoreDb, 'items'), {
        ...newItem,
        createdAt: serverTimestamp()
      });
    }
    // Запись в Demo DB
    else {
      addDemoDatabaseItem(newItem);
    }

    loadDatabaseItems();
  } catch (err) {
    alert('Ошибка добавления записи: ' + err.message);
  }
}

function renderDatabaseItems(items) {
  elements.dbItemsList.innerHTML = '';

  if (!items || items.length === 0) {
    elements.dbItemsList.innerHTML = `
      <li class="empty-state">
        <p>В базе данных пока нет записей.</p>
        <span style="font-size: 11px;">Используйте поле выше, чтобы создать первую запись.</span>
      </li>
    `;
    return;
  }

  items.forEach(item => {
    const li = document.createElement('li');
    li.className = 'item-card';

    const dateStr = item.created_at || item.createdAt 
      ? new Date(item.created_at || item.createdAt).toLocaleDateString('ru-RU', { hour: '2-digit', minute: '2-digit' })
      : 'Недавно';

    li.innerHTML = `
      <div class="item-info">
        <span class="item-title">${escapeHtml(item.title || item.name || 'Элемент')}</span>
        <span class="item-date">Создано: ${dateStr} &bull; Автор: ${escapeHtml(item.user_name || 'Пользователь')}</span>
      </div>
      <span class="item-tag">ID: ${escapeHtml(String(item.id).substring(0, 8))}</span>
    `;
    elements.dbItemsList.appendChild(li);
  });
}

// Полноценный мок локальной БД для демонстрации структуры
function getDemoDatabaseItems() {
  const stored = localStorage.getItem(STORAGE_KEYS.DEMO_DB_ITEMS);
  if (stored) {
    try { return JSON.parse(stored); } catch (e) {}
  }

  const initialItems = [
    { id: 'sb-101', title: 'Проект Flutter RuStore запущен', created_at: new Date(Date.now() - 3600000).toISOString(), user_name: 'Система' },
    { id: 'sb-102', title: 'Интеграция Supabase Auth выполнена', created_at: new Date(Date.now() - 1800000).toISOString(), user_name: 'Klixim' },
    { id: 'sb-103', title: 'Подключены провайдеры GitHub, Google, Apple', created_at: new Date(Date.now() - 600000).toISOString(), user_name: 'Dev' },
    { id: 'sb-104', title: 'Добавлены российские сервисы Yandex ID и VK ID', created_at: new Date().toISOString(), user_name: 'OAuth Service' }
  ];

  localStorage.setItem(STORAGE_KEYS.DEMO_DB_ITEMS, JSON.stringify(initialItems));
  return initialItems;
}

function addDemoDatabaseItem(item) {
  const items = getDemoDatabaseItems();
  const entry = {
    id: 'rec-' + Math.random().toString(36).substring(2, 8),
    ...item
  };
  items.unshift(entry);
  localStorage.setItem(STORAGE_KEYS.DEMO_DB_ITEMS, JSON.stringify(items));
}

// ==========================================
// 6. Вспомогательные функции и события
// ==========================================

function showMessage(msg, type = 'info') {
  elements.statusMsg.textContent = msg;
  elements.statusMsg.className = `status-message ${type}`;
  elements.statusMsg.classList.remove('hidden');
}

function clearMessage() {
  elements.statusMsg.classList.add('hidden');
}

function escapeHtml(str) {
  const div = document.createElement('div');
  div.textContent = str;
  return div.innerHTML;
}

// Привязка событий
function setupEventListeners() {
  // Выбор бэкенда
  elements.btnSelectSupabase.addEventListener('click', () => setBackend('supabase'));
  elements.btnSelectFirebase.addEventListener('click', () => setBackend('firebase'));

  // Открытие/закрытие модального окна конфигурации
  elements.configToggleBtn.addEventListener('click', () => {
    initConfigFields();
    elements.configModal.classList.remove('hidden');
  });
  elements.closeConfigBtn.addEventListener('click', () => elements.configModal.classList.add('hidden'));
  elements.saveConfigBtn.addEventListener('click', saveConfig);

  // Кнопки авторизации
  elements.btnGithub.addEventListener('click', () => handleLogin('github'));
  elements.btnGoogle.addEventListener('click', () => handleLogin('google'));
  elements.btnApple.addEventListener('click', () => handleLogin('apple'));
  elements.btnYandex.addEventListener('click', () => handleLogin('yandex'));
  elements.btnVk.addEventListener('click', () => handleLogin('vk'));

  // Выход
  elements.btnLogout.addEventListener('click', handleLogout);

  // База данных
  elements.addItemForm.addEventListener('submit', handleAddItem);
  elements.btnRefreshDb.addEventListener('click', loadDatabaseItems);
}

// Запуск при загрузке страницы
document.addEventListener('DOMContentLoaded', () => {
  setupEventListeners();
  initConfigFields();
  setBackend(currentBackend);
  initClients();
  checkOAuthCallbacks();
});
