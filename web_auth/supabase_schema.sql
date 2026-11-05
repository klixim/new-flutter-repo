-- ============================================================
-- SQL-скрипт инициализации таблицы items для Supabase (PostgreSQL)
-- Выполните этот код в SQL Editor в консоли https://supabase.com
-- ============================================================

-- 1. Создаем таблицу items для хранения записей
CREATE TABLE IF NOT EXISTS public.items (
    id BIGSERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    user_name TEXT DEFAULT 'Аноним',
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Включаем Row Level Security (RLS) для защиты данных
ALTER TABLE public.items ENABLE ROW LEVEL SECURITY;

-- 3. Политики RLS (чтение, добавление, удаление)
-- Разрешить чтение всем (анонимным и авторизованным)
DROP POLICY IF EXISTS "Разрешить публичное чтение" ON public.items;
CREATE POLICY "Разрешить публичное чтение"
ON public.items
FOR SELECT
TO anon, authenticated
USING (true);

-- Разрешить добавление авторизованным и анонимным (в демо-целях)
DROP POLICY IF EXISTS "Разрешить добавление записей" ON public.items;
CREATE POLICY "Разрешить добавление записей"
ON public.items
FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- Разрешить удаление записей
DROP POLICY IF EXISTS "Разрешить удаление записей" ON public.items;
CREATE POLICY "Разрешить удаление записей"
ON public.items
FOR DELETE
TO anon, authenticated
USING (true);

-- 4. Включаем публикацию в Supabase Realtime (для синхронизации между Web и Мобильным приложением)
ALTER PUBLICATION supabase_realtime ADD TABLE public.items;

-- 5. Начальные тестовые данные
INSERT INTO public.items (title, user_name) VALUES
    ('База данных Supabase PostgreSQL успешно подключена', 'Supabase Admin'),
    ('Авторизация через OAuth: GitHub, Gmail, Apple, Yandex, VK', 'Dev Team'),
    ('Синхронизация между Web (JS) и Flutter (Mobile)', 'Klixim');
