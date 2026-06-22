import { test, expect } from '@playwright/test'

test.describe('Dashboard', () => {
  test.beforeEach(async ({ page }) => {
    // 登录
    await page.goto('/login')
    await page.fill('input[type="email"]', 'test@example.com')
    await page.fill('input[type="password"]', 'password123')
    await page.click('button[type="submit"]')
    await expect(page).toHaveURL('/dashboard')
  })

  test('should display dashboard page', async ({ page }) => {
    await expect(page.locator('h1')).toContainText('Dashboard')
    await expect(page.locator('text=Welcome')).toBeVisible()
  })

  test('should display user profile', async ({ page }) => {
    await expect(page.locator('text=testuser')).toBeVisible()
  })

  test('should allow profile update', async ({ page }) => {
    await page.click('text=Profile')
    await page.fill('input[name="username"]', 'newusername')
    await page.click('button[type="submit"]')
    await expect(page.locator('text=Profile updated')).toBeVisible()
  })

  test('should logout', async ({ page }) => {
    await page.click('text=Logout')
    await expect(page).toHaveURL('/login')
  })
})