'use client'

import { createClient } from '@/lib/supabase/client'
import type { RealtimePostgresChangesPayload } from '@supabase/supabase-js'
import { useEffect, useState } from 'react'

interface UseRealtimeOptions<T> {
  table: string
  filter?: string
  initialData?: T[]
}

/**
 * 订阅 Postgres Changes 的 hook。
 * CRITICAL: 必须在 useEffect cleanup 中清理订阅。
 */
export function useRealtime<T extends { id: string }>({
  table,
  filter,
  initialData = []
}: UseRealtimeOptions<T>) {
  const supabase = createClient()
  const [data, setData] = useState<T[]>(initialData)

  useEffect(() => {
    let channel = supabase
      .channel(`${table}-changes`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table,
          ...(filter ? { filter } : {})
        },
        (payload: RealtimePostgresChangesPayload<T>) => {
          if (payload.eventType === 'INSERT') {
            setData((prev) => [...prev, payload.new as T])
          } else if (payload.eventType === 'UPDATE') {
            setData((prev) =>
              prev.map((item) =>
                item.id === (payload.new as T).id ? (payload.new as T) : item
              )
            )
          } else if (payload.eventType === 'DELETE') {
            setData((prev) =>
              prev.filter((item) => item.id !== (payload.old as T).id)
            )
          }
        }
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [supabase, table, filter])

  return data
}
