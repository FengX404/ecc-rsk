import { describe, test, expect } from 'vitest'
import { profileSchema } from '@/schemas/profile'

describe('profileSchema', () => {
  test('validates valid profile data', () => {
    const result = profileSchema.safeParse({
      username: 'testuser',
      fullName: 'Test User',
      website: 'https://example.com',
    })
    expect(result.success).toBe(true)
  })

  test('accepts partial data', () => {
    const result = profileSchema.safeParse({
      username: 'testuser',
    })
    expect(result.success).toBe(true)
  })

  test('rejects invalid username (too short)', () => {
    const result = profileSchema.safeParse({
      username: 'ab',
    })
    expect(result.success).toBe(false)
  })

  test('rejects invalid website URL', () => {
    const result = profileSchema.safeParse({
      website: 'invalid-url',
    })
    expect(result.success).toBe(false)
  })

  test('accepts empty optional fields', () => {
    const result = profileSchema.safeParse({})
    expect(result.success).toBe(true)
  })
})