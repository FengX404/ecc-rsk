import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

export async function updateSession(request: NextRequest) {
  let supabaseResponse = NextResponse.next({
    request
  })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value)
          )
          supabaseResponse = NextResponse.next({
            request
          })
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          )
        }
      }
    }
  )

  // 重要：不要在 getUser() 和返回 supabaseResponse 之间写任何逻辑
  // 一个简单的错误可能导致用户被随机注销

  const {
    data: { user }
  } = await supabase.auth.getUser()

  const publicPaths = ['/login', '/register', '/callback', '/']
  const isPublicPath = publicPaths.some(
    (path) =>
      request.nextUrl.pathname === path ||
      (path === '/callback' && request.nextUrl.pathname.startsWith('/callback'))
  )

  if (!user && !isPublicPath) {
    // 未登录用户重定向到登录页
    const url = request.nextUrl.clone()
    url.pathname = '/login'
    return NextResponse.redirect(url)
  }

  // 重要：返回 supabaseResponse，而不是新的 NextResponse
  return supabaseResponse
}