const { Telegraf } = require("telegraf");
const dotenv = require("dotenv");
const { createClient } = require("@supabase/supabase-js");

dotenv.config();

const botToken = process.env.TELEGRAM_ADMIN_BOT_TOKEN || "";
const adminId = parseInt(process.env.ADMIN_TELEGRAM_ID || "0");
const supabaseUrl = process.env.SUPABASE_URL || "";
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY || "";

if (!botToken) {
  console.error("❌ TELEGRAM_ADMIN_BOT_TOKEN belum diisi di berkas .env!");
  process.exit(1);
}

const bot = new Telegraf(botToken);
let supabase = null;

if (supabaseUrl && supabaseKey) {
  supabase = createClient(supabaseUrl, supabaseKey);
  console.log("✅ Admin Bot: Supabase Client terinisialisasi.");
} else {
  console.warn("⚠️ Admin Bot: Supabase URL/Key tidak ditemukan. Beberapa fitur database akan dinonaktifkan.");
}

// Middleware Keamanan: Hanya izinkan ID Telegram Admin yang terdaftar di .env
bot.use(async (ctx, next) => {
  const userId = ctx.from ? ctx.from.id : null;
  
  if (adminId !== 0 && userId !== adminId) {
    console.log(`[AdminBot] Akses diblokir untuk pengguna ilegal: ${userId} (${ctx.from ? ctx.from.username : "unknown"})`);
    return ctx.reply("⛔ Akses Ditolak: Anda bukan Administrator resmi Secmon.");
  }
  return next();
});

// Perintah /start
bot.start((ctx) => {
  ctx.reply(
    "🤖 *Selamat datang di Bot Panel Admin Secmon!*\n\n" +
    "Gunakan perintah berikut untuk mengelola trader Anda:\n" +
    "📊 `/stats <trader_id>` - Lihat statistik detail trader\n" +
    "🔑 `/whitelist <trader_id>` - Masukkan ID ke database secara manual\n" +
    "🚫 `/blacklist <trader_id>` - Hapus ID dari database\n" +
    "🔍 `/check <trader_id>` - Trigger cek referral manual via forwarder\n" +
    "ℹ️ `/help` - Tampilkan bantuan ini lagi",
    { parse_mode: "Markdown" }
  );
});

bot.help((ctx) => {
  ctx.reply(
    "📋 *Daftar Perintah Admin Secmon:*\n\n" +
    "📊 `/stats <trader_id>` : Menampilkan persentase win rate, total trade, total profit, dan saldo terakhir trader.\n" +
    "🔑 `/whitelist <trader_id>` : Membuka akses bot Secmon untuk ID tersebut secara manual.\n" +
    "🚫 `/blacklist <trader_id>` : Menutup akses/menghapus ID dari daftar aktif.\n" +
    "🔍 `/check <trader_id>` : Mengirim permintaan cek rujukan ke Bot Kingfin secara manual.",
    { parse_mode: "Markdown" }
  );
});

// Perintah 1: /stats <traderId>
bot.command("stats", async (ctx) => {
  const args = ctx.message.text.split(" ");
  if (args.length < 2) {
    return ctx.reply("⚠️ Format salah. Contoh penggunaan: /stats 88888");
  }

  const traderId = args[1].trim();
  if (!supabase) {
    return ctx.reply("❌ Database Supabase tidak terhubung.");
  }

  await ctx.reply(`📊 Mengambil statistik untuk Trader ID: ${traderId}...`);

  try {
    // 1. Ambil status aktivasi
    const { data: traderData } = await supabase
      .from("affiliate_traders")
      .select("status, activated_at")
      .eq("trader_id", traderId)
      .single();

    // 2. Ambil statistik log trading
    const { data: logs, error } = await supabase
      .from("trade_logs")
      .select("*")
      .eq("trader_id", traderId)
      .order("timestamp", { ascending: false });

    if (error) throw error;

    const status = traderData ? traderData.status.toUpperCase() : "BELUM TERDAFTAR (INACTIVE)";
    const activatedAt = traderData && traderData.activated_at 
      ? new Date(traderData.activated_at).toLocaleString("id-ID")
      : "-";

    if (!logs || logs.length === 0) {
      return ctx.reply(
        `📈 *STATISTIK TRADER ID: ${traderId}*\n` +
        `────────────────────────\n` +
        `🔑 Status: *${status}*\n` +
        `📅 Tanggal Aktivasi: \`${activatedAt}\`\n\n` +
        `⚠️ *Belum ada riwayat transaksi tercatat.*`,
        { parse_mode: "Markdown" }
      );
    }

    const totalTrades = logs.where ? logs.length : logs.filter(log => ["WIN", "LOSS", "DRAW"].includes(log.result)).length;
    const totalWins = logs.filter(log => log.result === "WIN").length;
    const totalLosses = logs.filter(log => log.result === "LOSS").length;
    const totalDraws = logs.filter(log => log.result === "DRAW").length;

    let netProfit = 0;
    logs.forEach(log => {
      netProfit += (log.profit || 0);
    });

    const winRate = totalTrades === 0 ? 0 : ((totalWins / totalTrades) * 100).toFixed(1);
    const lastBalance = logs[0].balance || 0;
    const lastAsset = logs[0].asset || "N/A";
    const lastUpdate = new Date(logs[0].timestamp).toLocaleString("id-ID");

    ctx.reply(
      `📊 *STATISTIK TRADER ID: ${traderId}*\n` +
      `────────────────────────\n` +
      `🔑 Status: *${status}*\n` +
      `📅 Tgl Aktivasi: \`${activatedAt}\`\n\n` +
      `🔄 Total Trades: *${totalTrades}*\n` +
      `🟢 Menang (WIN): *${totalWins}*\n` +
      `🔴 Kalah (LOSS): *${totalLosses}*\n` +
      `🟡 Seri (DRAW): *${totalDraws}*\n` +
      `📈 Win Rate: *${winRate}%*\n\n` +
      `💰 Total Profit/Loss: *Rp ${netProfit.toLocaleString("id-ID")}*\n` +
      `💳 Saldo Terakhir: *Rp ${lastBalance.toLocaleString("id-ID")}*\n` +
      `🏷️ Aset Terakhir: *${lastAsset}*\n` +
      `⏰ Aktivitas Terakhir: \`${lastUpdate}\``,
      { parse_mode: "Markdown" }
    );

  } catch (err) {
    ctx.reply(`❌ Gagal mengambil data: ${err.message}`);
  }
});

// Perintah 2: /whitelist <traderId>
bot.command("whitelist", async (ctx) => {
  const args = ctx.message.text.split(" ");
  if (args.length < 2) {
    return ctx.reply("⚠️ Format salah. Contoh penggunaan: /whitelist 12345");
  }

  const traderId = args[1].trim();
  if (!supabase) {
    return ctx.reply("❌ Database Supabase tidak terhubung.");
  }

  try {
    const { error } = await supabase
      .from("affiliate_traders")
      .upsert({
        trader_id: traderId,
        status: "active",
        activated_at: new Date().toISOString()
      });

    if (error) throw error;
    ctx.reply(`✅ Sukses mem-whitelist *ID ${traderId}*. Bot Secmon sekarang dapat langsung digunakan oleh ID tersebut.`, { parse_mode: "Markdown" });
  } catch (err) {
    ctx.reply(`❌ Gagal mem-whitelist ID: ${err.message}`);
  }
});

// Perintah 3: /blacklist <traderId>
bot.command("blacklist", async (ctx) => {
  const args = ctx.message.text.split(" ");
  if (args.length < 2) {
    return ctx.reply("⚠️ Format salah. Contoh penggunaan: /blacklist 12345");
  }

  const traderId = args[1].trim();
  if (!supabase) {
    return ctx.reply("❌ Database Supabase tidak terhubung.");
  }

  try {
    const { error } = await supabase
      .from("affiliate_traders")
      .delete()
      .eq("trader_id", traderId);

    if (error) throw error;
    ctx.reply(`✅ Sukses menghapus *ID ${traderId}* dari database. Akses bot Secmon untuk ID tersebut telah ditutup.`, { parse_mode: "Markdown" });
  } catch (err) {
    ctx.reply(`❌ Gagal mem-blacklist ID: ${err.message}`);
  }
});

// Perintah 4: /check <traderId> (Menjalankan auto-forwarder manual)
bot.command("check", async (ctx) => {
  const args = ctx.message.text.split(" ");
  if (args.length < 2) {
    return ctx.reply("⚠️ Format salah. Contoh penggunaan: /check 12345");
  }

  const traderId = args[1].trim();
  
  // Impor dinamis modul forwarder untuk mengecek
  try {
    const { verifyTraderIdViaBot, client } = require("./auto_forwarder");
    if (!client || !client.connected) {
      return ctx.reply("❌ Sistem auto-forwarder Telegram client sedang tidak aktif/koneksi putus.");
    }

    ctx.reply(`🔍 Mengirim cek rujukan untuk ID ${traderId} ke Bot Kingfin via Telegram...`);
    const isValid = await verifyTraderIdViaBot(traderId);

    if (isValid) {
      ctx.reply(`🟢 *VERIFIKASI BERHASIL*: ID ${traderId} aktif terverifikasi.`);
    } else {
      ctx.reply(`🔴 *TIDAK TERVERIFIKASI*: ID ${traderId} belum ditemukan atau terjadi timeout.`);
    }
  } catch (err) {
    ctx.reply(`❌ Eror saat menjalankan verifikasi proxy: ${err.message}`);
  }
});

// Listener untuk teks biasa (jika user langsung kirim angka/ID tanpa perintah)
bot.on("text", async (ctx) => {
  const text = ctx.message.text.trim();
  
  // Jika dimulai dengan slash (/), abaikan karena itu adalah command
  if (text.startsWith("/")) return;

  // Jika isi pesan adalah 5-15 digit angka, anggap sebagai Trader ID
  if (/^\d{5,15}$/.test(text)) {
    const traderId = text;
    
    if (!supabase) {
      return ctx.reply("❌ Database Supabase tidak terhubung.");
    }

    try {
      // 1. Ambil status aktivasi
      const { data: traderData } = await supabase
        .from("affiliate_traders")
        .select("status, activated_at")
        .eq("trader_id", traderId)
        .single();

      // 2. Ambil statistik log trading
      const { data: logs } = await supabase
        .from("trade_logs")
        .select("*")
        .eq("trader_id", traderId)
        .order("timestamp", { ascending: false });

      const status = traderData ? traderData.status.toUpperCase() : "BELUM AKTIF";
      const activatedAt = traderData && traderData.activated_at 
        ? new Date(traderData.activated_at).toLocaleString("id-ID")
        : "-";

      let statsText = "";
      if (logs && logs.length > 0) {
        const totalTrades = logs.length;
        const totalWins = logs.filter(log => log.result === "WIN").length;
        const totalLosses = logs.filter(log => log.result === "LOSS").length;
        const totalDraws = logs.filter(log => log.result === "DRAW").length;
        
        let netProfit = 0;
        logs.forEach(log => { netProfit += (log.profit || 0); });
        
        const winRate = totalTrades === 0 ? 0 : ((totalWins / totalTrades) * 100).toFixed(1);
        const lastBalance = logs[0].balance || 0;

        statsText = 
          `🔄 Total Trades: *${totalTrades}*\n` +
          `🟢 Win / 🔴 Loss / 🟡 Draw: *${totalWins}* / *${totalLosses}* / *${totalDraws}*\n` +
          `📈 Win Rate: *${winRate}%*\n` +
          `💰 Net Profit: *Rp ${netProfit.toLocaleString("id-ID")}*\n` +
          `💳 Saldo Terakhir: *Rp ${lastBalance.toLocaleString("id-ID")}*`;
      } else {
        statsText = `⚠️ *Belum ada riwayat transaksi tercatat.*`;
      }

      const responseText = 
        `🔎 *HASIL DETEKSI TRADER ID: ${traderId}*\n` +
        `────────────────────────\n` +
        `🔑 Status: *${status}*\n` +
        `📅 Tgl Aktivasi: \`${activatedAt}\`\n\n` +
        statsText;

      // Sediakan tombol inline
      const inlineKeyboard = {
        reply_markup: {
          inline_keyboard: [
            [
              { text: "🔑 Whitelist (Aktifkan)", callback_data: `whitelist_${traderId}` },
              { text: "🚫 Blacklist (Hapus)", callback_data: `blacklist_${traderId}` }
            ],
            [
              { text: "🔍 Cek Rujukan Kingfin", callback_data: `check_${traderId}` }
            ]
          ]
        },
        parse_mode: "Markdown"
      };

      await ctx.reply(responseText, inlineKeyboard);

    } catch (err) {
      ctx.reply(`❌ Gagal memeriksa Trader ID: ${err.message}`);
    }
  } else {
    ctx.reply("⚠️ Kirimkan 5 s.d 15 digit Trader ID langsung untuk melakukan pengecekan cepat.");
  }
});

// Callback handler untuk tombol inline
bot.action(/^whitelist_(.+)$/, async (ctx) => {
  const traderId = ctx.match[1];
  if (!supabase) return ctx.answerCbQuery("Database error");

  try {
    const { error } = await supabase
      .from("affiliate_traders")
      .upsert({
        trader_id: traderId,
        status: "active",
        activated_at: new Date().toISOString()
      });

    if (error) throw error;
    await ctx.answerCbQuery(`ID ${traderId} berhasil di-whitelist!`);
    await ctx.reply(`✅ *ID ${traderId}* sukses di-whitelist dan sekarang aktif!`, { parse_mode: "Markdown" });
  } catch (err) {
    await ctx.reply(`❌ Gagal mem-whitelist ID: ${err.message}`);
  }
});

bot.action(/^blacklist_(.+)$/, async (ctx) => {
  const traderId = ctx.match[1];
  if (!supabase) return ctx.answerCbQuery("Database error");

  try {
    const { error } = await supabase
      .from("affiliate_traders")
      .delete()
      .eq("trader_id", traderId);

    if (error) throw error;
    await ctx.answerCbQuery(`ID ${traderId} dihapus!`);
    await ctx.reply(`🚫 *ID ${traderId}* sukses dihapus dari database.`, { parse_mode: "Markdown" });
  } catch (err) {
    await ctx.reply(`❌ Gagal menghapus ID: ${err.message}`);
  }
});

bot.action(/^check_(.+)$/, async (ctx) => {
  const traderId = ctx.match[1];
  await ctx.answerCbQuery("Memulai cek Kingfin...");
  await ctx.reply(`🔍 Mengecek rujukan ID ${traderId} ke Bot Kingfin...`);

  try {
    const { verifyTraderIdViaBot, client } = require("./auto_forwarder");
    if (!client || !client.connected) {
      return ctx.reply("❌ Sistem Telegram client tidak aktif/putus.");
    }

    const isValid = await verifyTraderIdViaBot(traderId);
    if (isValid) {
      await ctx.reply(`🟢 *RESPON VALID*: ID ${traderId} terdaftar di bawah rujukan Anda!`, {
        reply_markup: {
          inline_keyboard: [[{ text: "🔑 Whitelist Sekarang", callback_data: `whitelist_${traderId}` }]]
        },
        parse_mode: "Markdown"
      });
    } else {
      await ctx.reply(`🔴 *RESPON DITOLAK*: ID ${traderId} tidak terdaftar di bawah rujukan Anda.`);
    }
  } catch (err) {
    await ctx.reply(`❌ Eror verifikasi: ${err.message}`);
  }
});

bot.launch().then(() => {
  console.log("🤖 Admin Telegram Bot berjalan...");
});

// Enable graceful stop
process.once("SIGINT", () => bot.stop("SIGINT"));
process.once("SIGTERM", () => bot.stop("SIGTERM"));
