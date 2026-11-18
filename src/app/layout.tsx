import type { Metadata } from "next";
import "./globals.css";
export const metadata: Metadata = {title:"Trade Journal | 交易覆盤日誌",description:"以交易計畫、成交紀錄和覆盤建立自己的交易日誌。"};
export default function RootLayout({children}:{children:React.ReactNode}) {return <html lang="zh-Hant"><body>{children}</body></html>;}
