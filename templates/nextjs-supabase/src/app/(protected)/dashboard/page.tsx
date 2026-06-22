import { createClient } from '@/lib/supabase/server'

export const dynamic = 'force-dynamic'

export default async function DashboardPage() {
  const supabase = createClient()
  const { data: { user } } = await supabase.auth.getUser()

  return (
    <div className="space-y-4">
      <h2 className="text-2xl font-bold">Welcome</h2>
      <p className="text-muted-foreground">
        Signed in as {user?.email}
      </p>
      {/* TODO: Add dashboard content */}
    </div>
  )
}
