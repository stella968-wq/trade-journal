# Trade Journal

手機優先的交易覆盤日誌 MVP，使用 Next.js App Router、React、TypeScript、Tailwind CSS 與 Supabase。

## 版本與啟動

建立環境：Node.js 24.22.1、pnpm 11.25.0。實際解析套件版本如下（另由 pnpm-lock.yaml 固定）：

| 套件 | 版本 |
|---|---:|
| Next.js | 16.4.6 |
| React / React DOM | 19.3.0 |
| TypeScript | 5.9.3 |
| Tailwind CSS | 4.3.3 |
| Supabase SSR | 0.12.7 |
| Supabase JS | 2.119.0 |
| ESLint | 10.15.0 |

1. 安裝 Node.js 與 pnpm。
2. 複製 .env.example 為 .env.local，填入 Supabase URL 與公開 anon/publishable key。
3. 執行 pnpm install。
4. 執行 pnpm dev，開啟 http://localhost:3000。

不需在前端設定 service_role 或其他 Secret Key。Supabase browser/server client 分別位於 src/lib/supabase/client.ts 與 src/lib/supabase/server.ts。

## 頁面

- / Dashboard 空狀態
- /login 電子郵件 magic-link 介面
- /plans/new 交易計畫表單預覽
- /trades 交易紀錄空狀態
- /reviews 覆盤日誌空狀態

目前表單尚未寫入資料庫；CSV 配對、損益計算與 AI 覆盤不在本階段。登入需在 Supabase Auth 設定允許的 redirect URL。

## Database

Migration 放在 supabase/migrations/。先在本機或測試 Supabase 專案審閱與套用，本專案未連線或修改正式資料庫。欄位假設見 supabase/DATA_DICTIONARY.md。


