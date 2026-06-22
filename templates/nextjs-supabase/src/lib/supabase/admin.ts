import 'server-only'
import { createClient } from '@supabase/supabase-js'
import type { Database } from '@/types/supabase'

/**
 * Service Role client — 绕过 RLS，仅用于服务端管理任务。
 * CRITICAL: 永不暴露给 Client Component。
 */
export function createAdminClient() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY

  if (!url || !key) {
    throw new Error('Missing Supabase admin credentials')
  }

  return createClient<Database>(url, key, {
    auth: {
      autoRefreshToken: false,
      persistSession: false
    }
  })
}
