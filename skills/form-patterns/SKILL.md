---
name: form-patterns
description: 表单模式（React Hook Form + Zod、Server Actions 表单、复杂表单、表单 UX、可访问性、文件上传）。
metadata:
  origin: ECC-RSK
---

# Form Patterns

React Hook Form + Zod + Server Actions 表单模式，覆盖基础表单、Server Actions 表单、复杂表单、表单 UX、可访问性、文件上传。

## When to Activate

- 设计表单（登录、注册、编辑、向导）
- 编写 Server Actions 表单
- 实现复杂表单（多步、动态字段）
- 优化表单 UX
- 确保表单可访问性
- 实现文件上传

---

## 1. React Hook Form + Zod

### 1.1 基础表单

```typescript
// app/login/page.tsx
'use client'

import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { createClient } from '@/lib/supabase/client'
import { useRouter } from 'next/navigation'

const LoginSchema = z.object({
  email: z.string().email('Invalid email'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
})

type LoginInput = z.infer<typeof LoginSchema>

export default function LoginPage() {
  const router = useRouter()
  const supabase = createClient()

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<LoginInput>({
    resolver: zodResolver(LoginSchema),
  })

  const onSubmit = async (data: LoginInput) => {
    const { error } = await supabase.auth.signInWithPassword({
      email: data.email,
      password: data.password,
    })

    if (error) {
      // 设置错误
      return
    }

    router.push('/dashboard')
    router.refresh()
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <div>
        <label htmlFor="email">Email</label>
        <input
          id="email"
          type="email"
          {...register('email')}
          aria-invalid={errors.email ? 'true' : 'false'}
        />
        {errors.email && (
          <p role="alert">{errors.email.message}</p>
        )}
      </div>

      <div>
        <label htmlFor="password">Password</label>
        <input
          id="password"
          type="password"
          {...register('password')}
          aria-invalid={errors.password ? 'true' : 'false'}
        />
        {errors.password && (
          <p role="alert">{errors.password.message}</p>
        )}
      </div>

      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Logging in...' : 'Login'}
      </button>
    </form>
  )
}
```

---

## 2. Server Actions 表单

### 2.1 `useActionState` 集成

```typescript
// app/posts/create-form.tsx
'use client'

import { useActionState } from 'react'
import { createPost } from '@/lib/actions/post'

export function CreatePostForm() {
  const [state, formAction, isPending] = useActionState(createPost, null)

  return (
    <form action={formAction}>
      <div>
        <label htmlFor="title">Title</label>
        <input
          id="title"
          name="title"
          type="text"
          required
          aria-invalid={state?.error ? 'true' : 'false'}
        />
        {state?.error && (
          <p role="alert">{state.error}</p>
        )}
      </div>

      <div>
        <label htmlFor="content">Content</label>
        <textarea id="content" name="content" />
      </div>

      <button type="submit" disabled={isPending}>
        {isPending ? 'Creating...' : 'Create Post'}
      </button>
    </form>
  )
}
```

### 2.2 Server Action 实现

```typescript
// lib/actions/post.ts
'use server'

import { z } from 'zod'
import { createClient } from '@/lib/supabase/server'
import { revalidatePath } from 'next/cache'

const CreatePostSchema = z.object({
  title: z.string().min(1).max(200),
  content: z.string().optional(),
})

export async function createPost(prevState: any, formData: FormData) {
  // 1. 解析 formData
  const input = {
    title: formData.get('title'),
    content: formData.get('content'),
  }

  // 2. 校验输入
  const parsed = CreatePostSchema.safeParse(input)
  if (!parsed.success) {
    return {
      error: 'Invalid input',
      details: parsed.error.flatten(),
    }
  }

  // 3. 校验授权
  const supabase = createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    return { error: 'Unauthorized' }
  }

  // 4. 执行操作
  const { data, error } = await supabase
    .from('posts')
    .insert({
      user_id: user.id,
      title: parsed.data.title,
      content: parsed.data.content,
    })
    .select()
    .single()

  if (error) {
    return { error: error.message }
  }

  // 5. 刷新缓存
  revalidatePath('/posts')

  return { data, success: true }
}
```

---

## 3. 复杂表单

### 3.1 多步向导

```typescript
// app/register/page.tsx
'use client'

import { useState } from 'react'
import { useForm, FormProvider } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'

const RegisterSchema = z.object({
  // Step 1
  email: z.string().email(),
  password: z.string().min(6),
  // Step 2
  name: z.string().min(1),
  bio: z.string().optional(),
  // Step 3
  avatar: z.any().optional(),
})

type RegisterInput = z.infer<typeof RegisterSchema>

export default function RegisterPage() {
  const [step, setStep] = useState(1)

  const methods = useForm<RegisterInput>({
    resolver: zodResolver(RegisterSchema),
    mode: 'onChange',
  })

  const { handleSubmit, trigger } = methods

  const nextStep = async () => {
    // 校验当前步骤字段
    const fields = step === 1 ? ['email', 'password'] : ['name', 'bio']
    const isValid = await trigger(fields)
    if (isValid) {
      setStep((prev) => prev + 1)
    }
  }

  const prevStep = () => {
    setStep((prev) => prev - 1)
  }

  const onSubmit = async (data: RegisterInput) => {
    // 提交所有数据
    console.log(data)
  }

  return (
    <FormProvider {...methods}>
      <form onSubmit={handleSubmit(onSubmit)}>
        {step === 1 && <Step1 />}
        {step === 2 && <Step2 />}
        {step === 3 && <Step3 />}

        <div className="flex justify-between">
          {step > 1 && (
            <button type="button" onClick={prevStep}>
              Previous
            </button>
          )}
          {step < 3 ? (
            <button type="button" onClick={nextStep}>
              Next
            </button>
          ) : (
            <button type="submit">Register</button>
          )}
        </div>
      </form>
    </FormProvider>
  )
}
```

### 3.2 动态字段数组

```typescript
// app/survey/page.tsx
'use client'

import { useForm, useFieldArray } from 'react-hook-form'

export default function SurveyPage() {
  const { control, register, handleSubmit } = useForm({
    defaultValues: {
      questions: [{ question: '', answer: '' }],
    },
  })

  const { fields, append, remove } = useFieldArray({
    control,
    name: 'questions',
  })

  const onSubmit = (data: any) => {
    console.log(data)
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      {fields.map((field, index) => (
        <div key={field.id}>
          <input
            {...register(`questions.${index}.question`)}
            placeholder="Question"
          />
          <input
            {...register(`questions.${index}.answer`)}
            placeholder="Answer"
          />
          <button type="button" onClick={() => remove(index)}>
            Remove
          </button>
        </div>
      ))}

      <button type="button" onClick={() => append({ question: '', answer: '' })}>
        Add Question
      </button>

      <button type="submit">Submit</button>
    </form>
  )
}
```

---

## 4. 表单 UX

### 4.1 实时校验 vs 提交时校验

```typescript
// 实时校验（onChange）
const { register } = useForm({
  mode: 'onChange', // 或 'onBlur'
})

// 提交时校验
const { register } = useForm({
  mode: 'onSubmit',
})
```

### 4.2 加载状态

```typescript
const { formState: { isSubmitting } } = useForm()

<button type="submit" disabled={isSubmitting}>
  {isSubmitting ? 'Submitting...' : 'Submit'}
</button>
```

### 4.3 成功/失败反馈

```typescript
const [state, formAction] = useActionState(createPost, null)

{state?.success && (
  <p className="success">Post created successfully!</p>
)}

{state?.error && (
  <p className="error">{state.error}</p>
)}
```

---

## 5. 可访问性

### 5.1 `<label>` 关联

```typescript
<label htmlFor="email">Email</label>
<input id="email" {...register('email')} />
```

### 5.2 `aria-invalid` / `aria-describedby`

```typescript
<input
  id="email"
  {...register('email')}
  aria-invalid={errors.email ? 'true' : 'false'}
  aria-describedby={errors.email ? 'email-error' : undefined}
/>
{errors.email && (
  <p id="email-error" role="alert">{errors.email.message}</p>
)}
```

### 5.3 错误公告（`aria-live`）

```typescript
{errors.email && (
  <p role="alert" aria-live="polite">{errors.email.message}</p>
)}
```

---

## 6. 文件上传

### 6.1 单文件上传

```typescript
// app/upload/page.tsx
'use client'

import { useForm } from 'react-hook-form'
import { uploadFile } from '@/lib/actions/upload'

export default function UploadPage() {
  const { register, handleSubmit, watch } = useForm()

  const file = watch('file')

  const onSubmit = async (data: any) => {
    const formData = new FormData()
    formData.append('file', data.file[0])

    const result = await uploadFile(formData)
    console.log(result)
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input type="file" {...register('file')} />
      {file && file[0] && (
        <p>Selected: {file[0].name}</p>
      )}
      <button type="submit">Upload</button>
    </form>
  )
}
```

### 6.2 多文件上传

```typescript
<input type="file" multiple {...register('files')} />
```

### 6.3 拖拽上传

```typescript
// components/dropzone.tsx
'use client'

import { useState } from 'react'

export function Dropzone({ onDrop }: { onDrop: (files: File[]) => void }) {
  const [isDragging, setIsDragging] = useState(false)

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault()
    setIsDragging(true)
  }

  const handleDragLeave = (e: React.DragEvent) => {
    e.preventDefault()
    setIsDragging(false)
  }

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault()
    setIsDragging(false)
    const files = Array.from(e.dataTransfer.files)
    onDrop(files)
  }

  return (
    <div
      onDragOver={handleDragOver}
      onDragLeave={handleDragLeave}
      onDrop={handleDrop}
      className={isDragging ? 'dragging' : ''}
    >
      Drop files here
    </div>
  )
}
```

---

## Best Practices

1. **Zod schema 校验** — 类型推导 + 运行时校验
2. **Server Actions 表单** — 渐进式增强
3. **`useActionState` 集成** — 状态管理
4. **多步向导** — 分步校验
5. **动态字段数组** — `useFieldArray`
6. **实时校验 vs 提交时校验** — 根据场景选择
7. **加载状态** — `isSubmitting`
8. **成功/失败反馈** — 用户反馈
9. **可访问性** — `<label>`、`aria-invalid`、`aria-live`
10. **文件上传** — FormData + Server Action