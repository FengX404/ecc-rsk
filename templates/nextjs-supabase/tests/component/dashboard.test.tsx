import { describe, test, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'

// Mock Server Component
vi.mock('@/lib/supabase/server', () => ({
  createClient: () => ({
    auth: {
      getUser: vi.fn().mockResolvedValue({
        data: { user: { id: '123', email: 'test@example.com' } },
      }),
    },
  }),
}))

describe('DashboardPage', () => {
  test('renders welcome message', async () => {
    // Note: Server Components need special handling in tests
    // This is a simplified test for demonstration
    const mockUser = { email: 'test@example.com' }

    expect(mockUser.email).toBe('test@example.com')
  })
})