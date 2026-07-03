const { TelegramClient } = require("telegram");
const { StringSession } = require("telegram/sessions");
const readline = require("readline");
const dotenv = require("dotenv");

dotenv.config();

const apiId = parseInt(process.env.TELEGRAM_API_ID || "0");
const apiHash = process.env.TELEGRAM_API_HASH || "";
const stringSession = new StringSession(process.env.TELEGRAM_SESSION_STRING || "");

const client = new TelegramClient(stringSession, apiId, apiHash, {
  connectionRetries: 5,
});

async function initClient() {
  if (apiId === 0 || !apiHash) {
    console.warn("⚠️ TELEGRAM_API_ID atau TELEGRAM_API_HASH belum diisi di berkas .env!");
    console.warn("Sistem auto-forwarder Telegram akan dinonaktifkan sementara.");
    return;
  }
  
  await client.start({
    phoneNumber: async () => {
      const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
      return new Promise((resolve) => rl.question("Masukkan nomor telepon Telegram Anda (e.g. +62812...): ", (ans) => { rl.close(); resolve(ans); }));
    },
    password: async () => {
      const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
      return new Promise((resolve) => rl.question("Masukkan password 2FA Anda (jika ada): ", (ans) => { rl.close(); resolve(ans); }));
    },
    phoneCode: async () => {
      const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
      return new Promise((resolve) => rl.question("Masukkan kode verifikasi Telegram yang dikirim: ", (ans) => { rl.close(); resolve(ans); }));
    },
    onError: (err) => console.error(err),
  });

  console.log("✅ Berhasil login ke Telegram!");
  console.log("--------------------------------------------------------------------------------");
  console.log("SANGAT PENTING: Salin string sesi di bawah ini dan simpan di file .env Anda");
  console.log("sebagai TELEGRAM_SESSION_STRING agar server tidak meminta kode login lagi saat restart:");
  console.log("--------------------------------------------------------------------------------");
  console.log(client.session.save());
  console.log("--------------------------------------------------------------------------------");
}

// Fungsi untuk verifikasi Trader ID dengan mengirimkan pesan ke Bot Kingfin
async function verifyTraderIdViaBot(traderId) {
  const kingfinBot = process.env.KINGFIN_BOT_USERNAME || "KingfinReferralBot";
  
  try {
    console.log(`[Forwarder] Mengirim ID ${traderId} ke Bot @${kingfinBot}...`);
    // Kirim pesan teks berupa Trader ID ke Bot Kingfin
    await client.sendMessage(kingfinBot, { message: traderId });
    
    // Tunggu balasan dari Bot Kingfin (timeout 8 detik)
    return new Promise((resolve) => {
      const timeout = setTimeout(() => {
        console.log("[Forwarder] ⚠️ Verifikasi timeout (8 detik tidak ada respons dari Kingfin Bot).");
        client.removeEventHandler(handler);
        resolve(false);
      }, 8000);
      
      const handler = async (event) => {
        const message = event.message;
        const sender = await message.getSender();
        
        // Pastikan pengirim adalah Bot Kingfin
        if (sender && sender.username && sender.username.toLowerCase() === kingfinBot.toLowerCase()) {
          clearTimeout(timeout);
          client.removeEventHandler(handler);
          
          const text = (message.message || "").toLowerCase();
          console.log(`[Forwarder] Respon dari Kingfin Bot: "${message.message.trim()}"`);
          
          // Heuristik pencocokan teks respon sukses dari bot Kingfin:
          // Biasanya berisi kata "terdaftar", "di bawah", "under", "aktif", "success", dll.
          const isValidReferral = 
            text.includes("terdaftar") || 
            text.includes("dibawah") || 
            text.includes("di bawah") || 
            text.includes("aktif") || 
            text.includes("active") || 
            text.includes("referral") ||
            text.includes("partner") ||
            text.includes("sukses") ||
            text.includes("yes") ||
            (text.includes("ya") && !text.includes("tidak"));

          resolve(isValidReferral);
        }
      };
      
      client.addEventHandler(handler);
    });
  } catch (e) {
    console.error(`[Forwarder] ❌ Eror saat berkomunikasi dengan Bot Telegram: ${e}`);
    return false;
  }
}

module.exports = {
  initClient,
  verifyTraderIdViaBot,
  client
};
