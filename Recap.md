# Rekapitulasi Implementasi ADB Wireless Pairing (X25519/SPAKE2)

Dokumen ini merangkum alur kerja dan detail implementasi kode pada `pair.rs` yang telah berhasil melakukan pairing dengan Android Wireless Debugging.

## 1. Arsitektur Keamanan & Protokol
Proses pairing menggunakan empat lapis keamanan:
1.  **TLS 1.3 (BoringSSL):** Enkripsi transport dasar dengan sertifikat *self-signed*.
2.  **SPAKE2 (Password-Authenticated Key Exchange):** Pertukaran kunci aman menggunakan PIN pairing dan EKM.
3.  **HKDF (HMAC-based Key Derivation Function):** Menurunkan kunci AES dari hasil SPAKE2.
4.  **AES-128-GCM:** Enkripsi payload data identitas perangkat (`PeerInfo`).

## 2. Analisis Fungsi-Demi-Fungsi

### `mDNS Discovery` (Discovery Phase)
**Tujuan:** Menemukan port layanan ADB yang berubah secara dinamis setiap kali Wireless Debugging diaktifkan.
- **Service Types:** 
    - `_adb-tls-pairing._tcp`: Digunakan untuk proses pairing awal.
    - `_adb-tls-connect._tcp`: Digunakan untuk koneksi ADB Secure setelah perangkat ter-pairing.
- **Logic:** Aplikasi melakukan *scanning* pada interface `localhost` untuk mendapatkan port yang tepat sebelum memulai socket TCP.

### `init_pairing`
**Tujuan:** Orkes-trator utama seluruh proses pairing.
- **Alur:**
    1.  Memanggil `setup_tls` untuk jabat tangan awal.
    2.  Melakukan **Export Keying Material (EKM)** sebesar 64 byte dengan label `"adb-label\0"`. EKM ini menjamin bahwa sesi SPAKE2 terikat secara kriptografis ke sesi TLS yang sedang berjalan.
    3.  Menggabungkan PIN (6 digit) dengan EKM menjadi satu buffer password.
    4.  Menjalankan `spake2_exchange`.
    5.  Menjalankan `peer_info_exchange` untuk pertukaran identitas terakhir.

### `setup_tls`
**Tujuan:** Membangun koneksi terenkripsi asinkron menggunakan `tokio_boring`.
- Menggunakan sertifikat X509 ephemeral yang dibuat saat runtime.
- Menonaktifkan verifikasi hostname karena kita terhubung ke `127.0.0.1` (localhost).

### `spake2_exchange` (FFI BoringSSL)
**Tujuan:** Implementasi protokol PAKE yang kompatibel 100% dengan Android.
- **FFI Call:** Memanggil langsung fungsi C `SPAKE2_CTX_new`, `SPAKE2_generate_msg`, dan `SPAKE2_process_msg`.
- **Identitas Penting:** Menggunakan `adb pair client\0` dan `adb pair server\0`. Karakter null (`\0`) wajib disertakan agar perhitungan *transcript hash* sama dengan sisi Android (C++ `sizeof`).
- **SpakeGuard:** Wrapper RAII untuk memastikan konteks memory di sisi C dibebaskan (`SPAKE2_CTX_free`) secara otomatis jika fungsi error atau selesai.
- **Send Trait:** Implementasi `unsafe impl Send for SpakeGuard` memungkinkan pointer mentah dikelola dengan aman di dalam runtime asinkron Tokio.

### `peer_info_exchange`
**Tujuan:** Pertukaran informasi identitas perangkat (RSA Public Key) secara terenkripsi.
- **Derivasi Kunci:** Menggunakan HKDF-SHA256 untuk mengubah *shared secret* SPAKE2 menjadi kunci AES 16-byte dengan info string `"adb pairing_auth aes-128-gcm key"`.
- **IV / Nonce:** Sesuai `aes-gcm-128.cpp` AOSP, IV dimulai sebagai 12-byte nol. Counter enkripsi dan dekripsi bersifat independen dan keduanya dimulai dari 0 untuk paket pertama.
- **Struktur Data:** Mengikuti struct `PeerInfo` AOSP dengan ukuran tetap **8192 byte**. 
    - Byte 0: Tipe pesan (`0` untuk RSA Public Key).
    - Byte 1-dst: String Base64 dari kunci RSA + Identifier (`Stellar@Stellar`).

### `encode_rsa_adb_format`
**Tujuan:** Mengonversi kunci RSA standar ke format **mincrypt** yang diharapkan oleh daemon `adbd`.
- Format ini terdiri dari:
    1.  Ukuran modulus dalam word (64 untuk RSA 2048).
    2.  Nilai `n0inv` (inverse modulus).
    3.  Modulus `N` dalam format Little-Endian.
    4.  Nilai `RR` ($2^{4096} \pmod N$) untuk mempercepat perhitungan modular di perangkat Android yang memiliki resource terbatas.
    5.  Eksponen publik (biasanya 65537).

### `write_adb_msg` & `read_adb_msg_debug`
**Tujuan:** Framing protokol ADB Wireless.
- Paket terdiri dari 6 byte header:
    - `[0]`: Versi (1)
    - `[1]`: Tipe Pesan (0=SPAKE2, 1=PeerInfo)
    - `[2-5]`: Panjang Payload (Big Endian i32)

### `connect_to_device`
**Tujuan:** Membangun koneksi ADB Secure (TLS) ke perangkat yang sudah di-pairing.
- **Alur:**
    1.  **Persiapan Sertifikat:** Memuat sertifikat dan kunci privat yang persisten dari penyimpanan internal aplikasi (`/data/user/0/labs.oxfnd.stellar/files/adb_cert.pem`). Ini memastikan kunci yang digunakan untuk koneksi sama dengan yang didaftarkan saat pairing.
    2.  **Negosiasi STLS (Cleartext):**
        *   Client mengirim paket `CNXN` (Connect) awal dalam bentuk teks biasa (`host::\0`).
        *   Membaca respons dari server. Jika server mendukung TLS, ia akan membalas dengan paket `STLS` (Switch to TLS).
        *   Client mengirim paket `STLS` konfirmasi untuk memulai proses upgrade ke TLS.
    3.  **TLS Upgrade:** Setelah negosiasi STLS, koneksi TCP mentah di-upgrade menjadi koneksi TLS menggunakan `tokio_boring`. Sertifikat client yang dimuat sebelumnya digunakan untuk autentikasi.
    4.  **Fase ADB Aman (Terenkripsi):**
        *   Setelah jabat tangan TLS berhasil, server (`adbd`) akan mengirimkan paket `CNXN` terenkripsi yang berisi identitas perangkat (misalnya `device::ro.product.name=...`).
        *   Client membaca dan memverifikasi paket `CNXN` ini. Jika berhasil, koneksi dianggap sukses dan kanal aman siap untuk perintah ADB.
- **Detail Penting:**
    *   Menggunakan konstanta `A_CNXN`, `A_STLS`, `A_VERSION`, `A_STLS_VERSION` yang sesuai dengan protokol ADB.
    *   Verifikasi `A_STLS` yang tepat (`0x534c5453`) untuk memastikan respons server benar.

### `upgrade_to_tls`
**Tujuan:** Fungsi pembantu untuk melakukan jabat tangan TLS di atas `TcpStream` yang sudah ada.
- Menggunakan sertifikat dan kunci privat yang dimuat dari `get_persistent_cert()`.
- Menonaktifkan verifikasi hostname dan menggunakan `SslVerifyMode::PEER` dengan callback `true` untuk mengabaikan verifikasi sertifikat server (karena kita hanya peduli server menerima sertifikat client).

### `write_adb_packet`
**Tujuan:** Fungsi pembantu untuk mengonstruksi dan mengirim paket ADB 24-byte standar.
- Menghitung `checksum` dan `magic` yang diperlukan untuk setiap paket ADB.
- Memastikan data dikirim dalam format *Little Endian* sesuai spesifikasi ADB.

## 3. Detail Penting Keberhasilan
Kunci utama yang membuat kode ini akhirnya berhasil adalah:
1.  **Dynamic Port Resolution:** Penggunaan mDNS discovery untuk menangani port Android yang bersifat ephemeral.
2.  **EKM Size 64 Byte:** Menggunakan 64 byte sesuai standar ADB terbaru, bukan 32 byte.
3.  **Null Terminator pada Label/Nama:** Menyertakan `\0` pada `EXPORTED_KEY_LABEL` dan `CLIENT_NAME` agar panjang string sinkron dengan logika `sizeof` di C++ pada sisi `adbd`.
4.  **Fixed Struct Padding:** Mengirimkan payload `PeerInfo` tepat 8192 byte sehingga `adbd` dapat melakukan mapping memori langsung.
5.  **IV Counter Reset:** Menggunakan IV nol untuk pesan masuk pertama dari Android untuk sinkronisasi state AES-GCM.
6.  **Persistensi Sertifikat:** Menyimpan RSA Keypair secara persisten di internal storage agar kredensial tetap valid setelah aplikasi di-restart.
7.  **Negosiasi STLS yang Benar:** Implementasi transisi protokol dari TCP plaintext ke TLS 1.3 melalui handshake `A_STLS`.
8.  **Verifikasi CNXN Server:** Validasi paket `CNXN` terenkripsi pasca-TLS untuk memastikan integritas sesi ADB.

## 4. Status Log
Berdasarkan `Success.md`:
- `TLS X25519 OK` -> Handshake berhasil.
- `SPAKE2 Exchange Berhasil!` -> PIN dan EKM cocok.
- `PEERINFO DECRYPT SUKSES` -> Kunci AES valid dan data identitas Android (GUID) berhasil terbaca.
- `PAIRING COMPLETE X25519!` -> Proses selesai sepenuhnya.

- **Heads-up Display**: Mengatur `Importance.max` dan `Priority.max` agar notifikasi hasil scan muncul sebagai banner popup di atas game.

- **State Management**: Menggunakan `StellarStatus` (FRB generated enum) untuk mengelola transisi antarmuka secara reaktif antara status Idle, Pairing, Paired, dan Connected.

## 5. Pemindaian Gacha Link (Logcat Streaming)
- **Fungsi `scan_gacha_link`**: Menggunakan shell ADB untuk menjalankan `logcat` dengan filter regex yang dioptimalkan.
- **Buffering Strategis**: Mengakumulasi data dalam `log_buffer` di sisi Rust untuk menangani link panjang (authkey) yang sering terfragmentasi dalam beberapa paket data ADB (`A_WRTE`).
- **Line Buffering**: Menggunakan flag `--line-buffered` pada shell Android untuk memastikan data dialirkan segera setelah baris ditemukan, mengurangi latensi deteksi.
- **Filtering**: Menggunakan `grep -v 'DART:'` untuk mencegah aplikasi menangkap log-nya sendiri yang berisi URL yang sedang diproses.

## 6. Persistensi & Riwayat
- **Penyimpanan Lokal**: Link gacha terakhir disimpan secara otomatis ke `${storageDir}/gacha_link.txt`.
- **Manajemen File**: Menggunakan mode penulisan yang menimpa isi lama (overwrite) karena link biasanya hanya berlaku selama 24 jam.
- **UI History**: Penambahan dialog riwayat yang dapat diakses melalui ikon jam di AppBar untuk memudahkan penyalinan ulang link tanpa harus memicu sesi ADB baru.

## 7. Optimasi Notifikasi & UI
- **Penyelesaian Crash**: Mengatasi error `Missing type parameter` pada `flutter_local_notifications` dengan mengganti `cancelAll()` menjadi loop manual pembatalan ID spesifik (0-4).
- **Heads-up Display**: Mengatur `Importance.max` dan `Priority.max` agar notifikasi hasil scan muncul sebagai banner popup di atas game.
- **State Management**: Menggunakan `StellarStatus` (FRB generated enum) untuk mengelola transisi antarmuka secara reaktif antara status Idle, Pairing, Paired, dan Connected.
- **Estetika Retro**: Penerapan font `VT323` secara konsisten pada komponen status dan output link untuk memperkuat identitas visual aplikasi.

## 8. Pengambilan Riwayat & Kalkulasi Pity (Wish Parser)
Fitur ini memungkinkan pengguna mengunduh riwayat gacha secara permanen dan menghitung statistik *pity* secara lokal.

### `fetch_and_save_history`
**Tujuan:** Mengambil data dari API resmi HoYoverse menggunakan URL yang didapat dari scan.
- **Multi-Game & Region Support:** Otomatis mendeteksi host API (Asia, Global, CN) berdasarkan parameter `region` dan jenis game (`gi`, `hsr`, `zzz`).
- **Pagination Logic:** Menggunakan parameter `end_id` untuk melakukan *crawling* riwayat dari yang terbaru hingga data terakhir yang tersimpan di lokal (menghindari redundansi).
- **Incremental Sync:** Hanya menyimpan entri baru ke dalam `wish_{game}.json` menggunakan `HashMap` untuk de-duplikasi ID unik.
- **Stream Progress:** Mengirimkan update real-time ke Flutter UI menggunakan `StreamSink<ProgressUpdate>` untuk menampilkan progres per banner.

### `calculate_pity`
**Tujuan:** Menganalisis file JSON untuk menghasilkan ringkasan statistik banner.
- **Sorting Kronologis:** Mengurutkan entri berdasarkan ID secara numerik (u64) untuk memastikan perhitungan *pity* akurat meskipun data diterima secara acak.
- **Pity Sharing (Genshin):** Menggabungkan counter antara banner Karakter 1 (301) dan Karakter 2 (400) sesuai mekanisme asli game.
- **Algoritma Guaranteed:** 
    - Mendeteksi apakah item bintang 5 terakhir adalah item "Standard" menggunakan daftar konstanta internal.
    - Jika ya, maka status `is_guaranteed` disetel ke `true` untuk banner event berikutnya.
- **Statistik Lanjutan:** Menghitung rata-rata *pity* (`avg_pity`) dari seluruh riwayat bintang 5 yang ditemukan.

### Detail Teknis Keberhasilan Parser:
1.  **ID-Based Integrity:** Menggunakan ID unik dari server sebagai kunci utama, bukan index array, sehingga data tetap valid jika ada penggabungan riwayat lama dan baru.
2.  **Rate Limit Awareness:** Implementasi delay kecil (200ms) antar request halaman API untuk mencegah blokir IP sementara dari server HoYoverse.
3.  **UI Consistency:** Pengurutan manual pada hasil akhir `BannerSummary` agar posisi kartu di UI tetap konsisten (Event -> Weapon -> Standard).
4.  **Base64/URL Sanitization:** Pembersihan otomatis karakter kutipan atau spasi pada URL gacha yang seringkali terbawa dari hasil *copy-paste* atau logcat.

## 9. Keamanan Data Riwayat
- **Local Storage Only:** Seluruh file `.json` disimpan di direktori internal aplikasi.
- **Authkey Filtering:** Parameter sensitif dibersihkan dari log sebelum ditampilkan atau disimpan, hanya menyisakan data riwayat publik.
