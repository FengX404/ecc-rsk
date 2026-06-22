'use server'

import { revalidatePath } from 'next/cache'
import { createClient } from '@/lib/supabase/server'
import { profileSchema } from '@/schemas/profile'
import type { ActionState } from '@/types'

export async function updateProfile(
  prevState: ActionState | null,
  formData: FormData
): Promise<ActionState> {
  // 1. 校验认证
  const supabase = createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return { error: 'Unauthorized' }
  }

  // 2. 校验输入
  const parsed = profileSchema.safeParse({
    username: formData.get('username'),
    full_name: formData.get('full_name'),
  })

  if (!parsed.success) {
    return {
      error: 'Invalid input',
      fieldErrors: parsed.error.flatten().fieldErrors
    }
  }

  // 3. 执行操作
  const { error } = await supabase
    .from('profiles')
    .update(parsed.data)
    .eq('id', user.id)

  if (error) {
    return { error: error.message }
  }

  // 4. 重新验证缓存
  revalidatePath('/dashboard')

  return { success: true }
}
