const express = require("express");
const cors = require("cors");
const dotenv = require("dotenv");
const { createClient } = require("@supabase/supabase-js");
const { initClient, verifyTraderIdViaBot } = require("./auto_forwarder");

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Inisialisasi Klien Supabase
const supabaseUrl = process.env.SUPABASE_URL || "";
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY || "";
let supabase = null;

if (supabaseUrl && supabaseKey) {
  supabase = createClient(supabaseUrl, supabaseKey);
  console.log("✅ Supabase Client terinisialisasi.");
} else {
  console.warn("⚠️ SUPABASE_URL atau SUPABASE_KEY tidak ditemukan di berkas .env!");
  console.warn("Penyimpanan riwayat transaksi dan whitelist lokal dinonaktifkan.");
}

// Endpoint 1: Verifikasi Trader ID (Aktivasi Bot Secmon Pro)
app.get("/verify-trader", async (req, res) => {
  const traderId = req.query.traderId;

  if (!traderId) {
    return res.status(400).json({ error: "Parameter traderId wajib diisi." });
  }

  const cleanId = traderId.trim();

  // 1. Cek di Database Supabase terlebih dahulu
  if (supabase) {
    try {
      const { data, error } = await supabase
        .from("affiliate_traders")
        .select("trader_id, status")
        .eq("trader_id", cleanId)
        .single();

      if (data && data.status === "active") {
        console.log(`[Server] ID ${cleanId} ditemukan di database (Status: Active)`);
        return res.json({ active: true, status: "success", source: "database" });
      }
    } catch (dbErr) {
      console.log(`[Server] ID ${cleanId} belum ada di database atau database error: ${dbErr.message}`);
    }
  }

  // 2. Jika tidak ada di DB, gunakan Telegram Auto-Forwarder untuk tanya ke Bot Kingfin
  const isValid = await verifyTraderIdViaBot(cleanId);

  if (isValid) {
    console.log(`[Server] ID ${cleanId} terverifikasi valid via Kingfin Bot Telegram!`);
    
    // Simpan ke database Supabase agar verifikasi berikutnya instan
    if (supabase) {
      try {
        const { error } = await supabase
          .from("affiliate_traders")
          .insert({
            trader_id: cleanId,
            status: "active",
            activated_at: new Date().toISOString()
          });
        
        if (error) {
          console.error(`[Server] Gagal menyimpan ID ${cleanId} ke database:`, error.message);
        } else {
          console.log(`[Server] ID ${cleanId} sukses disimpan ke database.`);
        }
      } catch (insertErr) {
        console.error(`[Server] Gagal memasukkan ID ke database: ${insertErr.message}`);
      }
    }
    
    return res.json({ active: true, status: "success", source: "telegram_bot" });
  } else {
    console.log(`[Server] ID ${cleanId} ditolak oleh Kingfin Bot (bukan referral atau bot tidak merespons).`);
    return res.json({ active: false, status: "failed", error: "not_referral_or_timeout" });
  }
});

// Endpoint 2: Catat Transaksi (Trade Logging dari Aplikasi HP)
app.post("/log-trade", async (req, res) => {
  const { traderId, asset, direction, nominal, result, profit, balance, timestamp } = req.body;

  if (!traderId) {
    return res.status(400).json({ error: "Parameter traderId wajib diisi." });
  }

  console.log(`[Server] Mencatat trade untuk ID ${traderId}: ${asset} | ${direction} | Rp${nominal} | ${result}`);

  if (supabase) {
    try {
      const { error } = await supabase
        .from("trade_logs")
        .insert({
          trader_id: traderId,
          asset: asset,
          direction: direction,
          nominal: parseInt(nominal) || 0,
          result: result,
          profit: parseInt(profit) || 0,
          balance: parseInt(balance) || 0,
          timestamp: timestamp || new Date().toISOString()
        });

      if (error) {
        console.error("[Server] ❌ Gagal menyimpan log transaksi ke database:", error.message);
        return res.status(500).json({ error: error.message });
      }
    } catch (e) {
      console.error("[Server] ❌ Eror database log-trade:", e.message);
      return res.status(500).json({ error: e.message });
    }
  }

  return res.json({ status: "logged" });
});

// Jalankan Server & Telegram Client
async function start() {
  // Jalankan inisialisasi sesi telegram
  await initClient();

  // Jalankan Bot Telegram Admin di proses yang sama agar berbagi koneksi client yang aktif
  require("./admin_bot");

  app.listen(PORT, () => {
    console.log(`🚀 Server Secmon Pro berjalan di port ${PORT}`);
  });
}

start();
