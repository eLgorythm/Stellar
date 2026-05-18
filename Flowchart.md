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

    subgraph Stellar_Logic [Stellar Application - Rust]
        subgraph Logic_Pairing [Fase Pairing: Detail]
            Rust_Pair[Rust: init_pairing]
            Cert[Load/Gen adb_cert.pem]
            
            subgraph SPAKE2_Process [Proses SPAKE2]
                EKM[Export EKM 64-byte]
                Pass[Pass = PIN + EKM]
                MSG1[Send MSG1: Masked Point]
                MSG2[Receive MSG2: Server Point]
                SK[Compute Shared Key 64-byte]
            end
            
            subgraph PeerInfo_Process [Proses PeerInfo]
                HKDF[HKDF Expansion: AES-128 Key]
                EncOut[Send Encrypted RSA PubKey]
                EncIn[Receive Encrypted Device Info]
            end
            
            Flag[Simpan pairing_success.flag]
        end

        subgraph Logic_Connection [Fase Koneksi]
            Rust_Conn[Rust: connect_to_device]
            CNXN_C[Send ADB CNXN - Cleartext]
            STLS_R[Receive STLS Response]
            STLS_C[Send STLS Confirm]
            TLS_C[Secure TLS Handshake]
            ADB_S[Active ADB Session Saved]
        end

        subgraph Logic_Scanning [Fase Scanning]
            Rust_Scan[Rust: scan_gacha_link]
            Shell[Open ADB Shell: logcat]
            Filter{Cari URL + authkey}
        end
    end

    subgraph Android_ADBD [Android System - adbd]
        A_Pair[adbd: Pairing Service]
        A_Conn[adbd: Connection Service]
        A_Log[(System Logcat)]
    end

    %% UI to Logic Connections
    PairBtn --> MDNS_P[mDNS Discovery: _adb-tls-pairing._tcp]
    MDNS_P --> Rust_Pair
    InputCode --> Rust_Pair
    Rust_Pair --> Cert --> EKM
    EKM --> Pass --> MSG1
    MSG2 --> SK --> HKDF --> EncOut
    EncIn --> Flag --> Paired{Is Paired?}

    ConnBtn --> MDNS_C[mDNS Discovery: _adb-tls-connect._tcp]
    MDNS_C --> Rust_Conn
    Rust_Conn --> CNXN_C
    STLS_C --> TLS_C --> ADB_S
    
    ScanBtn --> Rust_Scan
    Rust_Scan --> Shell

    %% Logic to ADBD Connections (The "Participant" Interactions)
    MSG1 -- TCP/TLS --> A_Pair
    A_Pair -- Return MSG2 --> MSG2
    EncOut -- Encrypted --> A_Pair
    A_Pair -- Return PeerInfo --> EncIn

    CNXN_C -- Cleartext --> A_Conn
    A_Conn -- STLS Packet --> STLS_R
    STLS_C -- Confirm --> A_Conn
    TLS_C -- Secure Handshake --> A_Conn
    
    Shell -- stream logcat --> A_Log
    A_Log -- Output --> Filter
    OpenGame -. User Action .-> A_Log

    Paired -- True --> ConnBtn
    Paired -- False --> PairBtn
    ADB_S --> ScanBtn
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
