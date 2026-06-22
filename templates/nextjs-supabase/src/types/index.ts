/**
 * Server Action 返回类型。
 * - success: 操作成功
 * - error: 通用错误消息
 * - fieldErrors: 字段级错误（Zod flatten）
 */
export interface ActionState {
  success?: boolean
  error?: string
  fieldErrors?: Record<string, string[]>
}
