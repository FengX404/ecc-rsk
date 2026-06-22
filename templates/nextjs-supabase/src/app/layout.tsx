import type { Metadata } from 'next'
import { QueryProvider } from '@/lib/query-provider'
import './globals.css'

export const metadata: Metadata = {
  title: 'Next.js + Supabase App',
  description: 'A full-stack application built with Next.js and Supabase',
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL ?? 'http://localhost:3000'),
  openGraph: {
    title: 'Next.js + Supabase App',
    description: 'A full-stack application built with Next.js and Supabase',
    type: 'website'
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Next.js + Supabase App',
    description: 'A full-stack application built with Next.js and Supabase'
  }
}

export default function RootLayout({
  children
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>
        <QueryProvider>{children}</QueryProvider>
      </body>
    </html>
  )
}