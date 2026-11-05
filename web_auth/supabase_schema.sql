-- ============================================================
-- SQL-скрипт инициализации таблицы items для Supabase (PostgreSQL)
-- Вставьте этот код в SQL Editor в панели Supabase
-- ============================================================

-- 1. Создаем таблицу items для хранения списка
CREATE TABLE IF NOT EXISTS public.items (
    id BIGSERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    user_name TEXT DEFAULT 'Аноним',
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Включаем Row Level Security (RLS) для защиты данных
ALTER TABLE public.items ENABLE ROW LEVEL SECURITY;

-- 3. Политика для чтения: разрешить всем авторизованным пользователям читать записи
CREATE POLICY "Разрешить чтение авторизованным пользователям"
ON public.items
FOR SELECT
TO authenticated
USING (true);

-- Также разрешаем чтение анонимным пользователям (anon), если нужно показывать список до входа:
CREATE POLICY "Разрешить публичное чтение"
ON public.items
FOR SELECT
TO anon
USING (true);

-- 4. Политика для добавления: разрешить авторизованным пользователям создавать записи
CREATE POLICY "Разрешить добавление авторизованным пользователям"
ON public.items
FOR INSERT
TO authenticated
WITH CHECK (true);

-- 5. Начальные тестовые данные для проверки отображения списка
INSERT INTO public.items (title, user_name) VALUES
    ('Добро пожаловать в проект Flutter + RuStore!', 'Администратор'),
    ('Авторизация через Supabase настроена', 'Система'),
    ('Проверка загрузки списка из базы данных PostgreSQL', 'Klixim');
