# Alur Kerja Stellar (Pairing -> Connect -> Scan)

Diagram ini menjelaskan bagaimana Stellar berkomunikasi dengan sistem Android menggunakan protokol ADB Wireless Debugging melalui jembatan Flutter & Rust.

```mermaid
graph TD
    subgraph UI_Flutter [UI Flutter]
        Start([Mulai]) --> WD[User Aktifkan Wireless Debugging]
        WD --> PairBtn[Tekan Tombol PAIR]
        InputCode[Input Pairing Code dari Notifikasi]
        ConnBtn[Tekan Tombol CONNECT]
        ScanBtn[Tekan Tombol SCAN NOW]
        OpenGame[Buka Game & Halaman Riwayat]
    end

    subgraph Logic_Pairing [Fase Pairing]
        PairBtn --> MDNS_P[mDNS Discovery: _adb-tls-pairing]
        MDNS_P --> Rust_Pair[Rust: init_pairing]
        InputCode --> Rust_Pair
        Rust_Pair --> TLS_P[TLS Handshake]
        TLS_P --> EKM[Export Keying Material]
        EKM --> SPAKE2[SPAKE2 Exchange: Shared Key]
        SPAKE2 --> PeerInfo[PeerInfo Exchange: RSA PubKey]
        PeerInfo --> Flag[Simpan pairing_success.flag]
        Flag --> Paired{Is Paired?}
    end

    subgraph Logic_Connection [Fase Koneksi]
        Paired -- True --> ConnBtn
        ConnBtn --> MDNS_C[mDNS Discovery: _adb-tls-connect]
        MDNS_C --> Rust_Conn[Rust: connect_to_device]
        Rust_Conn --> CNXN_C[Send ADB CNXN - Cleartext]
        CNXN_C --> STLS[Upgrade to STLS]
        STLS --> TLS_C[Secure TLS Handshake]
        TLS_C --> ADB_S[Active ADB Session Saved]
    end

    subgraph Logic_Scanning [Fase Scanning]
        ADB_S --> ScanBtn
        ScanBtn --> Rust_Scan[Rust: scan_gacha_link]
        Rust_Scan --> Shell[Open ADB Shell: logcat]
        OpenGame -. Memunculkan Log .-> Log[(System Logcat)]
        Log --> Shell
        Shell --> Filter{Cari URL + authkey}
        Filter -- Found --> Notify[Notifikasi: Link Retrieved!]
        Notify --> Copy[Copy & Import Data]
    end

    Paired -- False --> PairBtn
```

## Detail Teknis

### 1. Pairing (Self-Pairing)
Stellar menggunakan teknik *self-pairing* di mana aplikasi bertindak sebagai klien ADB untuk dirinya sendiri.
- **mDNS:** Digunakan untuk menemukan port acak yang dibuka oleh sistem Android untuk layanan pairing.
- **SPAKE2:** Protokol pertukaran kunci yang aman berdasarkan password (pairing code).
- **Certificates:** Stellar men-generate sertifikat RSA self-signed yang disimpan secara lokal untuk otentikasi di masa mendatang.

### 2. Connection
Setelah pairing sukses, Stellar tidak perlu lagi meminta kode pairing.
- **STLS:** Upgrade koneksi TCP biasa ke TLS (Secure) sesuai spesifikasi ADB modern (Android 11+).
- **Session Persistence:** Sesi TLS disimpan dalam `ACTIVE_SESSION` di memori Rust untuk digunakan kembali saat scanning.

### 3. Scanning
Proses scanning dilakukan dengan membaca output dari perintah `logcat`.
- **Grep Filter:** Rust melakukan filtering secara real-time terhadap stream logcat untuk mencari pola URL gacha yang valid.
- **Authkey:** Link hanya dianggap valid jika mengandung parameter `authkey`, yang diperlukan untuk mengakses API riwayat gacha HoYoverse.
