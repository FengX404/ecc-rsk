import { z } from 'zod'

export const profileSchema = z.object({
  username: z
    .string()
    .min(3, 'Username must be at least 3 characters')
    .max(50, 'Username must be less than 50 characters')
    .regex(/^[a-zA-Z0-9_]+$/, 'Username can only contain letters, numbers, and underscores'),
  full_name: z.string().max(100, 'Full name must be less than 100 characters').optional().nullable(),
  avatar_url: z.string().url('Invalid URL').optional().nullable()
})

export const profileUpdateSchema = profileSchema.partial()

export type ProfileInput = z.infer<typeof profileSchema>
export type ProfileUpdateInput = z.infer<typeof profileUpdateSchema>