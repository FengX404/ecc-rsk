-- 插入测试用户（仅在开发环境）
INSERT INTO public.profiles (id, username, full_name)
VALUES
  ('00000000-0000-0000-0000-000000000001', 'testuser1', 'Test User 1'),
  ('00000000-0000-0000-0000-000000000002', 'testuser2', 'Test User 2')
ON CONFLICT (id) DO NOTHING;