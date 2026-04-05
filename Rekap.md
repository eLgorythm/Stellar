# Rekapitulasi Implementasi ADB Wireless Pairing (X25519/SPAKE2)

Dokumen ini merangkum alur kerja dan detail implementasi kode pada `pair.rs` yang telah berhasil melakukan pairing dengan Android Wireless Debugging.

## 1. Arsitektur Keamanan Utama
Proses pairing menggunakan empat lapis keamanan:
1.  **TLS 1.3 (BoringSSL):** Enkripsi transport dasar dengan sertifikat *self-signed*.
2.  **SPAKE2 (Password-Authenticated Key Exchange):** Pertukaran kunci aman menggunakan PIN pairing dan EKM.
3.  **HKDF (HMAC-based Key Derivation Function):** Menurunkan kunci AES dari hasil SPAKE2.
4.  **AES-128-GCM:** Enkripsi payload data identitas perangkat (`PeerInfo`).

## 2. Analisis Fungsi-Demi-Fungsi

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
1.  **EKM Size 64 Byte:** Menggunakan 64 byte, bukan 32 byte.
2.  **Null Terminator pada Label/Nama:** Menyertakan `\0` pada `EXPORTED_KEY_LABEL` dan `CLIENT_NAME` agar panjang string sinkron dengan logika `sizeof` di C++.
3.  **Fixed Struct Padding:** Mengirimkan payload `PeerInfo` tepat 8192 byte (bukan ukuran dinamis) sehingga `adbd` dapat melakukan `memcpy` langsung ke struct internalnya.
4.  **IV Counter Reset:** Menggunakan IV nol untuk pesan masuk pertama dari Android, meskipun kita baru saja mengirim pesan keluar.
5.  **Persistensi Sertifikat:** Menyimpan dan memuat sertifikat RSA yang sama untuk proses pairing dan koneksi, memastikan `adbd` mengenali client.
6.  **Negosiasi STLS yang Benar:** Mengikuti alur `CNXN` (cleartext) -> `STLS` (respons) -> `STLS` (konfirmasi) sebelum melakukan upgrade ke TLS.
7.  **Verifikasi CNXN Server:** Membaca dan memverifikasi paket `CNXN` yang dikirim server setelah TLS terjalin.

## 4. Status Log
Berdasarkan `Success.md`:
- `TLS X25519 OK` -> Handshake berhasil.
- `SPAKE2 Exchange Berhasil!` -> PIN dan EKM cocok.
- `PEERINFO DECRYPT SUKSES` -> Kunci AES valid dan data identitas Android (GUID) berhasil terbaca.
- `PAIRING COMPLETE X25519!` -> Proses selesai sepenuhnya.
