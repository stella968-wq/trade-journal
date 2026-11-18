# Trade Journal MVP 資料字典

本版欄位依 MVP 範圍設計，尚待產品逐欄驗收。所有使用者資料表含 UUID 主鍵、user_id（profiles 使用 id）、created_at、updated_at。金額與數量 NUMERIC；時間 TIMESTAMPTZ。

| 表 | 欄位 | 說明 |
|---|---|---|
| profiles | id, display_name, timezone, currency | id 關聯 auth.users.id |
| instruments | user_id, symbol, name, asset_class, exchange, quote_currency, notes | 個人標的 |
| trade_plans | instrument_id, side, status, planned_entry_price, planned_quantity, planned_at, thesis, risk_notes | 計畫 |
| import_batches | source_name, file_path, status, row_count, imported_at, notes | 匯入批次與私有檔案路徑 |
| executions | instrument_id, trade_plan_id, import_batch_id, side, executed_at, quantity, price, fees, currency, external_ref, notes | 原始成交；使用者只可讀取/新增 |
| reviews | trade_plan_id, instrument_id, reviewed_at, summary, process_rating, emotion, what_went_well, what_to_improve, next_time | 覆盤 |
| review_insights | review_id, category, content, source | 覆盤心得 |

私人 bucket trade-journal-private 使用 <auth.uid()>/... 作為物件路徑前綴；SQL policies 限制物件讀取、上傳與刪除到該使用者路徑，且不允許覆寫更新。
