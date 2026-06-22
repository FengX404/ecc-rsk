import { describe, test, expect } from 'vitest'
import { cn, formatDate, formatRelativeTime } from '@/lib/utils'

describe('cn (className merge)', () => {
  test('merges class names', () => {
    expect(cn('foo', 'bar')).toBe('foo bar')
  })

  test('handles conditional classes', () => {
    expect(cn('foo', false && 'bar', 'baz')).toBe('foo baz')
  })

  test('handles undefined', () => {
    expect(cn('foo', undefined, 'bar')).toBe('foo bar')
  })

  test('merges tailwind classes correctly', () => {
    expect(cn('px-2', 'px-4')).toBe('px-4')
  })
})

describe('formatDate', () => {
  test('formats date correctly', () => {
    const date = new Date('2024-01-15T10:30:00Z')
    expect(formatDate(date)).toMatch(/2024/)
  })

  test('handles string input', () => {
    expect(formatDate('2024-01-15')).toMatch(/2024/)
  })
})

describe('formatRelativeTime', () => {
  test('returns "just now" for recent dates', () => {
    const now = new Date()
    expect(formatRelativeTime(now)).toBe('just now')
  })

  test('returns minutes ago', () => {
    const fiveMinAgo = new Date(Date.now() - 5 * 60 * 1000)
    expect(formatRelativeTime(fiveMinAgo)).toBe('5 minutes ago')
  })

  test('returns hours ago', () => {
    const twoHoursAgo = new Date(Date.now() - 2 * 60 * 60 * 1000)
    expect(formatRelativeTime(twoHoursAgo)).toBe('2 hours ago')
  })
})