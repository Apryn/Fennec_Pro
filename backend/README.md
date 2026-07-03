# Backend Fennec Pro - Server & Telegram Bots

Repositori ini berisi kode backend Node.js untuk menangani:
1. **Server API Verifikasi & Log**: Menerima request aktivasi dari aplikasi HP Fennec Pro dan mencatat riwayat transaksi.
2. **Auto-Forwarder Telegram (GramJS)**: Melakukan pengecekan otomatis ke Bot Kingfin melalui akun Telegram Anda secara 24/7 jika Trader ID belum terdaftar di database.
3. **Bot Telegram Panel Admin**: Bot khusus untuk memantau data statistik trader, melakukan whitelist manual, dan memantau win rate trader.

---

## 🗄️ 1. Persiapan Database (Supabase)

Silakan buat dua tabel berikut di database Supabase Anda:

### Tabel A: `affiliate_traders` (Whitelist Trader)
Tabel ini digunakan untuk mencatat Trader ID yang sudah aktif terdaftar di bawah rujukan Anda.
* **SQL Schema**:
  ```sql
  create table affiliate_traders (
    trader_id text primary key,
    status text default 'active',
    activated_at timestamp with time zone default timezone('utc'::text, now())
  );
  ```

### Tabel B: `trade_logs` (Riwayat Transaksi)
Tabel ini digunakan untuk mencatat riwayat transaksi yang dikirim oleh aplikasi HP untuk dihitung statistiknya.
* **SQL Schema**:
  ```sql
  create table trade_logs (
    id bigint generated always as identity primary key,
    trader_id text not null,
    asset text not null,
    direction text not null,
    nominal bigint not null,
    result text not null,
    profit bigint not null,
    balance bigint not null,
    timestamp timestamp with time zone default timezone('utc'::text, now())
  );
  ```

---

## 🔑 2. Konfigurasi Lingkungan (`.env`)

Buat berkas bernama `.env` di dalam folder `backend/` ini, lalu isi konfigurasinya:

```env
PORT=3000

# 1. Supabase credentials
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-supabase-service-role-key

# 2. Akun Telegram User (Untuk Auto-Forwarder)
# Dapatkan api_id dan api_hash di https://my.telegram.org/
TELEGRAM_API_ID=123456
TELEGRAM_API_HASH=your_api_hash_here
# Biarkan kosong pada jalankan pertama. Setelah login sukses, salin string sesi yang dicetak di terminal ke sini:
TELEGRAM_SESSION_STRING=

# Username Bot Kingfin di Telegram (default: KingfinReferralBot)
KINGFIN_BOT_USERNAME=KingfinReferralBot

# 3. Bot Telegram Admin (Untuk cek statistik / whitelist)
# Buat bot baru di BotFather untuk mendapatkan token
TELEGRAM_ADMIN_BOT_TOKEN=your_telegram_bot_token
# Masukkan ID Telegram pribadi Anda (angka) agar akses bot admin terkunci hanya untuk Anda.
# Cara tahu ID Anda: Chat ke telegram bot @userinfobot
ADMIN_TELEGRAM_ID=your_telegram_user_id
```

---

## 🚀 3. Langkah Menjalankan

1. Masuk ke folder backend dan unduh dependensi:
   ```bash
   cd backend
   npm install
   ```

2. Jalankan server pertama kali untuk melakukan registrasi login Telegram:
   ```bash
   npm start
   ```
   * Terminal akan meminta Anda memasukkan nomor telepon Telegram dan kode verifikasi yang dikirim ke Telegram Anda.
   * Setelah sukses login, **salin string sesi panjang yang dicetak di terminal** dan simpan di file `.env` sebagai `TELEGRAM_SESSION_STRING`.
   * Hentikan server (`Ctrl + C`), lalu jalankan kembali `npm start`. Sekarang server akan masuk otomatis tanpa perlu memasukkan kode lagi!

3. Di terminal terpisah, jalankan Bot Telegram Panel Admin:
   ```bash
   npm run admin-bot
   ```
   * Selamat! Bot Admin Anda sudah berjalan. Silakan chat `/start` ke bot Telegram Anda untuk melihat daftar perintah.
