# Panduan Integrasi Server Verifikasi Trader ID (Secmon)

Dokumen ini menjelaskan cara membuat server verifikasi untuk memvalidasi apakah suatu **Trader ID** terdaftar di bawah link afiliasi Anda sebelum pengguna dapat mengakses fitur premium bot Secmon.

---

## 🛠️ 1. Cara Kerja Verifikasi di Secmon

Saat pengguna memasukkan Trader ID dan mengeklik tombol **Aktivasi**, aplikasi Secmon akan mengirimkan permintaan HTTP GET ke server Anda:

```http
GET https://api-anda.com/verify-trader?traderId=12345
```

Aplikasi Secmon akan menganggap ID tersebut **VALID** jika server Anda merespons dengan status code `200` dan mengembalikan JSON dengan format salah satu di bawah ini:
* `{"active": true}`
* `{"status": "success"}`
* `{"valid": true}`

Jika mengembalikan JSON selain di atas (misal `{"active": false}`) atau mengembalikan HTTP status selain 200, maka aktivasi akan ditolak dengan pesan kesalahan.

---

## 💻 2. Templat Kode Server (Pilihan)

Anda bisa memilih salah satu metode di bawah ini untuk diterapkan:

### Pilihan A: Supabase Edge Function (Direkomendasikan - Gratis & Mudah)

1. Buat akun di [Supabase](https://supabase.com/).
2. Buat tabel database bernama `affiliate_traders` dengan kolom:
   * `trader_id` (Text / Varchar, Primary Key)
   * `created_at` (Timestamp)
3. Buat Edge Function baru dan isi dengan kode berikut:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Tangani preflight request CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const url = new URL(req.url)
    const traderId = url.searchParams.get('traderId')

    if (!traderId) {
      return new Response(
        JSON.stringify({ error: 'Missing traderId parameter' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Inisialisasi klien Supabase menggunakan Environment Variables internal
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    )

    // Cari Trader ID di tabel database
    const { data, error } = await supabaseClient
      .from('affiliate_traders')
      .select('trader_id')
      .eq('trader_id', traderId.trim())
      .single()

    const isValid = data !== null && !error;

    return new Response(
      JSON.stringify({ active: isValid }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (err) {
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
```

---

### Pilihan B: Node.js + Express (Deploy di Vercel/Render/Heroku)

Jika Anda ingin menggunakan server Node.js sendiri:

```javascript
const express = require('express');
const cors = require('cors');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Contoh database lokal sederhana (Untuk produksi, sambungkan ke database seperti MongoDB/PostgreSQL)
// Anda bisa mengimpor daftar ID dari file CSV/Excel hasil ekspor dashboard broker.
const VALID_TRADER_IDS = new Set([
  "88888",  // ID simulasi sukses
  "123456",
  "987654"
]);

app.get('/verify-trader', (req, res) => {
  const traderId = req.query.traderId;

  if (!traderId) {
    return res.status(400).json({ error: 'Parameter traderId wajib diisi.' });
  }

  const cleanId = traderId.trim();
  const isValid = VALID_TRADER_IDS.has(cleanId);

  res.json({
    active: isValid,
    status: isValid ? "success" : "failed"
  });
});

app.listen(PORT, () => {
  console.log(`Server verifikasi berjalan di port ${PORT}`);
});
```

---

## 📈 3. Cara Memperbarui Daftar Trader ID Afiliasi

Karena broker biasanya tidak memberikan akses API langsung ke database afiliasi untuk alasan keamanan, cara paling praktis untuk memperbarui daftar Trader ID adalah:

1. **Ekspor Manual**:
   * Masuk ke portal Afiliasi Olymp Trade Anda.
   * Masuk ke menu Laporan/Statistik pendaftaran.
   * Ekspor daftar Trader ID yang terdaftar di bawah Anda sebagai berkas **CSV** atau **Excel**.
2. **Impor Ke Database**:
   * Gunakan fitur import CSV bawaan Supabase / phpMyAdmin untuk memasukkan data baru ke tabel `affiliate_traders`.
   * Jika menggunakan server Node.js lokal, Anda dapat menyalin daftar ID tersebut dan mem-paste ke dalam array/Set server Anda lalu melakukan deploy ulang.
