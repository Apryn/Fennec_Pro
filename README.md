# ⚡ SECMON - Premium Trading Bot Assistant

**SECMON** adalah aplikasi asisten otomatisasi trading premium (*lead-magnet app*) yang dirancang khusus untuk para trader finansial dan live streamer. Aplikasi ini dilengkapi dengan visualisasi **Cyber Dark Mode** berkinerja tinggi, logika manajemen risiko otomatis, dan sistem pengaman **Anti-Ban (Anti-Deteksi)** saat terhubung dengan platform market Olymp Trade.

---

## 📁 Struktur Repositori

Repositori ini terdiri dari dua komponen utama:

1. **`fennec_pro_mobile/` (Flutter Mobile App)**:
   Projek cross-platform Flutter yang siap dikompilasi untuk Android (`.apk`) dan iOS. Berisi integrasi WebView platform trading, bi-directional JS bridge, dan manajemen risiko Martingale.
2. **`web_preview/` (Web Preview Simulator)**:
   Simulator interaktif berbasis HTML/CSS/JS yang meniru visual dan logika bisnis aplikasi mobile Secmon Pro secara presisi untuk diuji langsung di browser tanpa perlu compiler SDK.

---

## ⚡ Fitur Utama

- **Sistem Otomatisasi (Auto-Trade)**: Eksekusi transaksi otomatis (UP/DOWN) langsung pada platform trading berdasarkan sinyal masuk.
- **Sistem Keamanan Anti-Ban (Anti-Detection)**:
  - *Jeda Reaksi Acak (Randomized Delay)*: Memberikan jeda antara 1.5s s.d 3.5s sebelum klik otomatis dilakukan untuk mensimulasikan reaksi motorik manusia.
  - *Simulasi Rangkaian Event Mouse*: Memicu urutan hover dan klik yang valid (`mouseenter` -> `mouseover` -> `mousedown` -> `focus` -> `mouseup` -> `click`).
  - *Koordinat Klik Acak*: Mengklik koordinat X/Y acak di area tombol, bukan di titik tengah statis (pola robot).
- **Proteksi Saldo Minimum (Balance Guard)**: Secara otomatis memantau saldo akun riil Anda lewat WebView, dan langsung melakukan *Force Stop* jika saldo turun di bawah batas pengaman Anda.
- **Beralih Otomatis ke Demo (Auto-Demo Switch)**: Beralih otomatis ke akun Demo jika menyentuh batas *Stop Loss* tertentu untuk menguji keandalan strategi sebelum kembali ke akun Riil saat mendeteksi profit kembali.
- **Kalkulator & Manajemen Risiko Martingale**: Mendukung pengaturan Base Trade, Soft Martingale, Martingale Multiplier, reset level, dan pembatasan level maksimum.
- **Visual Personalisasi**: Pilihan warna aksen neon (Cyber Green, Electric Blue, Hot Pink, Toxic Purple), kontrol intensitas cahaya (*glow*), dan *High Contrast Stream Mode* untuk streamer TikTok.

---

## 🛠️ Panduan Memulai & Pengujian

### 1. Menjalankan Web Preview Simulator (Browser)
Simulator web telah berjalan di server lokal Anda pada port `8080`.
- **Alamat URL**: 👉 [http://localhost:8080/index.html](http://localhost:8080/index.html)
- **Petunjuk Autentikasi**:
  - Masukkan **Trader ID Anda (5-15 digit angka)** atau `88888` untuk langsung masuk ke Dashboard.
  - Masukkan `77777` untuk melihat simulasi penolakan aktivasi karena salah tautan affiliate (*Wrong Affiliate Error*).
  - Gunakan tombol **Simulate WIN** dan **Simulate LOSS** untuk memicu logika simulasi.

### 2. Kompilasi Aplikasi Android (APK)
Projek Android telah dikonfigurasi dengan **Gradle 8.7** dan kompatibilitas **Java 21**. Jalankan perintah ini di dalam folder `fennec_pro_mobile`:
```bash
# 1. Unduh library dependensi
C:\flutter\bin\flutter.bat pub get

# 2. Inisialisasi platform native Android
C:\flutter\bin\flutter.bat create . --platforms=android

# 3. Build APK rilis
C:\flutter\bin\flutter.bat build apk --release
```
*Hasil APK rilis akan tersimpan di: `build/app/outputs/flutter-apk/app-release.apk`.*

### 3. Kompilasi Aplikasi iOS (macOS & Xcode)
Wrapper native iOS telah disiapkan. Salin berkas projek ke Mac Anda dan jalankan:
```bash
# 1. Unduh library Flutter & Pods
flutter pub get
cd ios
pod install

# 2. Build iOS (No Codesign) untuk pengujian
flutter build ios --release --no-codesign
```
*Gunakan Xcode untuk membuka `ios/Runner.xcworkspace` jika ingin melakukan debugging langsung pada perangkat iPhone.*

---

## 🚀 Alur Kerja CI/CD (GitHub Actions)

Berkas workflow otomatisasi build telah disiapkan di `.github/workflows/build.yml`. Setiap kali Anda melakukan `git push` ke branch `main` atau `master`, GitHub Actions akan otomatis:
1. Mengompilasi aplikasi Android menjadi **APK Rilis**.
2. Mengompilasi aplikasi iOS (No-Sign) pada runner macOS.
3. Melampirkan kedua aplikasi hasil kompilasi tersebut sebagai file unduhan (*Artifacts*) di halaman log build GitHub Anda.
# Fennec_Pro
