"use client";
import {FormEvent,useState} from "react";
import {createClient} from "@/lib/supabase/client";
export function LoginForm(){
 const [message,setMessage]=useState(""); const [busy,setBusy]=useState(false);
 async function submit(e:FormEvent<HTMLFormElement>){e.preventDefault();setBusy(true);setMessage("");const email=String(new FormData(e.currentTarget).get("email")||"");
 if(!process.env.NEXT_PUBLIC_SUPABASE_URL||!process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY){setMessage("請先設定 Supabase 環境變數，再啟用登入。");setBusy(false);return;}
 const result=await createClient().auth.signInWithOtp({email,options:{emailRedirectTo:window.location.origin+"/auth/callback"}});
 setMessage(result.error?"登入連結寄送失敗："+result.error.message:"登入連結已寄出，請查看電子郵件。");setBusy(false);
 }
 return <form onSubmit={submit} className="mt-6 space-y-4"><label className="block"><span className="mb-2 block text-sm font-medium">電子郵件</span><input required type="email" name="email" autoComplete="email" placeholder="you@example.com" className="min-h-12 w-full rounded-xl border px-3 text-sm"/></label><button disabled={busy} className="min-h-12 w-full rounded-xl bg-[#167c68] px-4 text-sm font-semibold text-white disabled:opacity-60">{busy?"寄送中…":"寄送登入連結"}</button>{message&&<p role="status" className="text-sm text-[#167c68]">{message}</p>}</form>;
}
