# Stellar - ADB Gacha Link Scanner

Stellar adalah aplikasi Android berbasis Flutter dan Rust yang dirancang untuk mengambil tautan riwayat permohonan (*Gacha Link*) dari game besutan HoYoverse (Genshin Impact, Honkai: Star Rail, Honkai Impact 3rd, dan Zenless Zone Zero) secara otomatis menggunakan protokol **ADB Wireless Debugging**.

Aplikasi ini menggunakan teknik **Self-Pairing**, di mana aplikasi bertindak sebagai client ADB yang berkomunikasi dengan sistem Android pada perangkat yang sama melalui antarmuka `localhost`.

## 📖 Cara Penggunaan

1. **Aktifkan Developer Options:** Masuk ke pengaturan Android dan aktifkan "Wireless Debugging".
2. **Pairing:**
    - Tekan tombol **PAIR** di aplikasi Stellar.
    - Buka pengaturan Wireless Debugging dan pilih "Pair device with pairing code".
    - Masukkan kode 6-digit yang muncul ke dalam notifikasi input Stellar.
3. **Connect:** Setelah status *Is Paired* menjadi `True`, tekan tombol **CONNECT**.
4. **Scan Gacha:**
    - Tekan **SCAN NOW** pada dialog yang muncul.
    - Buka game (misal: Genshin Impact) dan buka halaman **History/Riwayat Permohonan**.
    - Tunggu hingga notifikasi "Link Retrieved!" muncul.
5. **Copy Link:** Salin tautan yang didapat dan gunakan di platform analisis gacha pilihan Anda (seperti Paimon.moe).

## 🛡 Keamanan & Privasi

- **No Root Required:** Aplikasi ini bekerja sepenuhnya pada level user menggunakan fitur standar Android Developer.
- **Local Processing:** Seluruh proses dekripsi dan ekstraksi link dilakukan secara lokal di perangkat Anda. Tidak ada data sensitif (seperti `authkey`) yang dikirim ke server pihak ketiga oleh aplikasi ini.
- **Ephemeral Keys:** Sertifikat TLS dibuat secara unik per perangkat dan disimpan di direktori internal aplikasi yang aman.

## ⚖️ Lisensi

Proyek ini dikembangkan untuk tujuan edukasi dan alat bantu personal. Stellar tidak berafiliasi dengan HoYoverse. Penggunaan aplikasi ini tunduk pada kebijakan privasi dan ketentuan layanan masing-masing game.

---
*Developed with ❤️ by elfnd using Flutter & Rust.*
