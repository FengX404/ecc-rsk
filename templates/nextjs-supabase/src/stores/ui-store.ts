import { create } from 'zustand'

interface UIState {
  sidebarOpen: boolean
  toggleSidebar: () => void
  setSidebar: (open: boolean) => void
}

/**
 * UI 状态 store（高频更新的客户端状态）。
 * 服务器状态（数据）应使用 TanStack Query，而非 Zustand。
 */
export const useUIStore = create<UIState>((set) => ({
  sidebarOpen: false,
  toggleSidebar: () => set((state) => ({ sidebarOpen: !state.sidebarOpen })),
  setSidebar: (open) => set({ sidebarOpen: open })
}))
