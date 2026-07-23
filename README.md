# JPC Inspect

Website mockup siap deploy untuk inspeksi terencana, tindak lanjut, verifikasi, dan closing keselamatan pertambangan.

## Yang sudah tersedia

- Dashboard jadwal pelaksanaan dan jadwal closing.
- Workflow inspeksi: planned → execution → report review → follow-up → verification → final closing/reopen.
- Kanban temuan dan tindakan perbaikan.
- Bukti closing, verifikasi independen, penolakan, dan reopen.
- Simulasi kewenangan: Admin, KTT/PTL, Inspector, PIC, Verifier HSE, dan Viewer/Auditor.
- Checklist digital, register objek dan risiko, SLA, laporan, serta audit trail.
- Tampilan responsif desktop dan mobile.
- API konfigurasi Vercel serta rancangan schema Supabase dengan RLS.

## Matriks closing yang direkomendasikan

- **PIC Area:** melaksanakan tindak lanjut dan mengajukan closing; tidak menutup temuan sendiri.
- **Inspector/Pengawas:** membuat temuan, memantau, dapat mengajukan closing, dan menutup laporan setelah persyaratan lengkap.
- **Verifier HSE:** memeriksa bukti dan efektivitas; dapat menerima/menolak serta menutup temuan.
- **KTT/PTL:** final closing inspeksi dan reopen; juga dapat melakukan verifikasi sesuai matriks perusahaan.
- **Administrator:** administrasi sistem; kewenangan operasional sebaiknya dibatasi melalui kebijakan perusahaan.
- **Viewer/Auditor:** hanya membaca dan mengekspor.

Matriks ini adalah rancangan kontrol internal. Tetapkan secara formal dalam prosedur perusahaan dan sesuaikan dengan struktur KTT/PTL serta kompetensi personel.

## Jalankan lokal

Gunakan Vercel CLI:

```bash
npm i -g vercel
vercel dev
```

Atau untuk melihat frontend demo saja:

```bash
python3 -m http.server 8080
```

Buka `http://localhost:8080`.

## Deploy ke Vercel

1. Push folder ini ke repository GitHub/GitLab/Bitbucket.
2. Import repository pada Vercel.
3. Framework preset: **Other**; root directory: folder proyek ini.
4. Tidak perlu build command untuk versi statis ini.
5. Tambahkan environment variables bila Supabase sudah tersedia:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
6. Deploy dan cek `/api/health`.

## Menyiapkan Supabase

1. Buat project Supabase.
2. Jalankan `supabase/schema.sql` melalui SQL Editor.
3. Buat private storage bucket `inspection-evidence`.
4. Aktifkan Auth dan buat profile setiap pengguna.
5. Tinjau RLS; uji setiap peran sebelum produksi.
6. Gunakan `data/supabase-adapter.js` sebagai titik awal integrasi frontend.

> Jangan pernah mengekspos `SUPABASE_SERVICE_ROLE_KEY` ke browser atau endpoint `/api/config`.

## Struktur

- `index.html` — seluruh layar aplikasi.
- `styles.css` — desain responsif.
- `app.js` — demo interaktif dan role simulation.
- `api/config.js` — konfigurasi publik Supabase.
- `api/health.js` — health check Vercel Function.
- `data/supabase-adapter.js` — adapter REST awal.
- `supabase/schema.sql` — schema, indeks, trigger, dan RLS awal.

## Catatan produksi

Sebelum go-live, tambahkan autentikasi Supabase, upload file ke private storage, penomoran transaksi server-side, notifikasi, tanda tangan elektronik, transaksi atomik untuk final closing/reopen, backup, retensi data, dan pengujian keamanan.
