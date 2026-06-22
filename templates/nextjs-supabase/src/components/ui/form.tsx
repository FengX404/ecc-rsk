import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import type { z } from 'zod'

import { cn } from '@/lib/utils'
import { Button } from '@/components/ui/button'

interface FormProps<T extends z.ZodType<any, any>> {
  schema: T
  defaultValues?: Partial<z.infer<T>>
  onSubmit: (data: z.infer<T>) => Promise<void> | void
  children: (form: ReturnType<typeof useForm<z.infer<T>>) => React.ReactNode
  className?: string
}

export function Form<T extends z.ZodType<any, any>>({
  schema,
  defaultValues,
  onSubmit,
  children,
  className,
}: FormProps<T>) {
  const form = useForm<z.infer<T>>({
    resolver: zodResolver(schema),
    defaultValues: defaultValues as any,
  })

  return (
    <form
      onSubmit={form.handleSubmit(async (data) => {
        await onSubmit(data)
      })}
      className={cn('space-y-4', className)}
    >
      {children(form)}
    </form>
  )
}

interface FormFieldProps {
  name: string
  label?: string
  type?: 'text' | 'email' | 'password' | 'number'
  placeholder?: string
  required?: boolean
  className?: string
}

export function FormField({
  name,
  label,
  type = 'text',
  placeholder,
  required,
  className,
}: FormFieldProps) {
  // This is a simplified version. In production, use Form context.
  return (
    <div className={cn('space-y-2', className)}>
      {label && (
        <label htmlFor={name} className="text-sm font-medium">
          {label}
          {required && <span className="text-destructive ml-1">*</span>}
        </label>
      )}
      <input
        id={name}
        name={name}
        type={type}
        placeholder={placeholder}
        required={required}
        className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
      />
    </div>
  )
}

interface FormErrorProps {
  message?: string
}

export function FormError({ message }: FormErrorProps) {
  if (!message) return null
  return (
    <p className="text-sm text-destructive">{message}</p>
  )
}

interface FormSubmitProps {
  children: React.ReactNode
  loading?: boolean
  className?: string
}

export function FormSubmit({ children, loading, className }: FormSubmitProps) {
  return (
    <Button
      type="submit"
      disabled={loading}
      className={cn('w-full', className)}
    >
      {loading ? 'Loading...' : children}
    </Button>
  )
}