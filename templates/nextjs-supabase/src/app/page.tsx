import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'

export default async function HomePage() {
  const supabase = createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (user) {
    redirect('/dashboard')
  }

  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-24">
      <h1 className="text-4xl font-bold mb-8">Next.js + Supabase App</h1>
      <div className="flex gap-4">
        <a href="/login" className="px-4 py-2 bg-blue-500 text-white rounded">
          Login
        </a>
        <a href="/signup" className="px-4 py-2 bg-green-500 text-white rounded">
          Sign Up
        </a>
      </div>
    </main>
  )
}