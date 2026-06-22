import { describe, test, expect } from 'vitest'
import { authSchema, loginSchema, registerSchema } from '@/schemas/auth'

describe('authSchema', () => {
  test('validates valid email', () => {
    const result = authSchema.safeParse({ email: 'test@example.com' })
    expect(result.success).toBe(true)
  })

  test('rejects invalid email', () => {
    const result = authSchema.safeParse({ email: 'invalid-email' })
    expect(result.success).toBe(false)
  })
})

describe('loginSchema', () => {
  test('validates valid login data', () => {
    const result = loginSchema.safeParse({
      email: 'test@example.com',
      password: 'password123',
    })
    expect(result.success).toBe(true)
  })

  test('rejects empty password', () => {
    const result = loginSchema.safeParse({
      email: 'test@example.com',
      password: '',
    })
    expect(result.success).toBe(false)
  })

  test('rejects short password', () => {
    const result = loginSchema.safeParse({
      email: 'test@example.com',
      password: 'short',
    })
    expect(result.success).toBe(false)
  })
})

describe('registerSchema', () => {
  test('validates valid registration data', () => {
    const result = registerSchema.safeParse({
      email: 'test@example.com',
      password: 'SecurePassword123!',
    })
    expect(result.success).toBe(true)
  })

  test('rejects password without minimum length', () => {
    const result = registerSchema.safeParse({
      email: 'test@example.com',
      password: 'short',
    })
    expect(result.success).toBe(false)
  })

  test('requires email', () => {
    const result = registerSchema.safeParse({
      password: 'SecurePassword123!',
    })
    expect(result.success).toBe(false)
  })
})