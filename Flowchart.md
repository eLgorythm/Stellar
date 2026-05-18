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

    subgraph Logic_Pairing [Fase Pairing: Detail]
        PairBtn --> MDNS_P[mDNS Discovery: _adb-tls-pairing._tcp]
        MDNS_P --> Rust_Pair[Rust: init_pairing]
        InputCode --> Rust_Pair
        Rust_Pair --> Cert[Load/Gen adb_cert.pem]
        Cert --> TLS_P[TLS 1.3 Handshake]
        
        subgraph SPAKE2_Process [Proses SPAKE2]
            TLS_P --> EKM[Export EKM 64-byte]
            EKM --> Pass[Pass = PIN + EKM]
            Pass --> MSG1[Send MSG1: Masked Point]
            MSG1 --> MSG2[Receive MSG2: Server Point]
            MSG2 --> SK[Compute Shared Key 64-byte]
        end
        
        subgraph PeerInfo_Process [Proses PeerInfo]
            SK --> HKDF[HKDF Expansion: AES-128 Key]
            HKDF --> EncOut[Send Encrypted RSA PubKey]
            EncOut --> EncIn[Receive Encrypted Device Info]
        end
        
        EncIn --> Flag[Simpan pairing_success.flag]
        Flag --> Paired{Is Paired?}
    end

    subgraph Logic_Connection [Fase Koneksi]
        Paired -- True --> ConnBtn
        ConnBtn --> MDNS_C[mDNS Discovery: _adb-tls-connect._tcp]
        MDNS_C --> Rust_Conn[Rust: connect_to_device]
        Rust_Conn --> CNXN_C[Send ADB CNXN - Cleartext]
        CNXN_C --> STLS_R[Receive STLS Response]
        STLS_R --> STLS_C[Send STLS Confirm]
        STLS_C --> TLS_C[Secure TLS Handshake]
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
- **mDNS:** Menemukan port pairing (`_adb-tls-pairing._tcp`).
- **TLS 1.3:** Enkripsi dasar untuk pertukaran kunci.
- **SPAKE2:** Protokol PAKE (Password-Authenticated Key Exchange) yang menggabungkan PIN dan **EKM (Exported Keying Material)** untuk menghasilkan *Shared Key* tanpa mengirim password asli.
- **PeerInfo:** Pertukaran identitas (RSA Public Key) yang dienkripsi menggunakan **AES-128-GCM** hasil derivasi SPAKE2.

### 2. Connection
- **STLS Negotiation:** Protokol ADB untuk upgrade koneksi dari plaintext ke TLS secara aman.
- **Certificate Auth:** Menggunakan `adb_cert.pem` yang sudah didaftarkan saat pairing untuk melewati verifikasi keamanan Android.
- **Session Persistence:** Sesi disimpan dalam `ACTIVE_SESSION` agar perintah shell (logcat) bisa langsung dijalankan.

### 3. Scanning
- **Logcat Stream:** Membaca log sistem Android secara real-time.
- **Grep Filter:** Mencari pola URL gacha HoYoverse yang mengandung parameter `authkey`.
