# Alur Kerja Stellar (Pairing -> Connect -> Scan)

Diagram ini menjelaskan bagaimana Stellar berkomunikasi dengan sistem Android menggunakan protokol ADB Wireless Debugging melalui jembatan Flutter & Rust.

```mermaid
graph TD
    %% Definisi Style agar lebih enak dilihat
    classDef ui fill:#e1f5fe,stroke:#01579b
    classDef rust fill:#f3e5f5,stroke:#4a148c
    classDef adb fill:#fff3e0,stroke:#e65100

    subgraph User_Interface [User Interface - Flutter]
        Start([Mulai])
        PairBtn[Klik PAIR & Input PIN]
        ConnBtn[Klik CONNECT]
        ScanBtn[Klik SCAN NOW]
    end

    subgraph Stellar_Logic [Stellar Engine - Rust]
        P_Init[Init Pairing & Gen Cert]
        P_SPAKE2[Proses SPAKE2 + PIN]
        P_Peer[Exchange RSA Public Key]
        
        C_Init[Init Connection & STLS]
        C_TLS[TLS Handshake Secure]
        
        S_Log[Run Logcat Shell]
        S_Filt{Cari Gacha Link}
    end

    subgraph Android_System [Android - adbd]
        A_Pair[adbd Pairing Service]
        A_Conn[adbd Connection Service]
        A_Log[(System Logcat)]
        
        %% Invisible links to force vertical elongation
        A_Pair ~~~ A_Conn ~~~ A_Log
    end

    %% --- ALUR PAIRING ---
    Start --> PairBtn
    PairBtn --> P_Init
    P_Init <--> A_Pair
    P_Init --> P_SPAKE2
    P_SPAKE2 <--> A_Pair
    P_SPAKE2 --> P_Peer
    P_Peer <--> A_Pair
    P_Peer --> Paired{Is Paired?}

    %% --- ALUR KONEKSI ---
    Paired -- Ya --> ConnBtn
    ConnBtn --> C_Init
    C_Init <--> A_Conn
    C_Init --> C_TLS
    C_TLS <--> A_Conn
    C_TLS --> Connected([Connected])

    %% --- ALUR SCANNING ---
    Connected --> ScanBtn
    ScanBtn --> S_Log
    S_Log <--> A_Log
    S_Log --> S_Filt
    S_Filt -- Ketemu --> Success([Link Retrieved!])

    %% Penerapan Style
    class Start,PairBtn,ConnBtn,ScanBtn ui
    class P_Init,P_SPAKE2,P_Peer,C_Init,C_TLS,S_Log,S_Filt rust
    class A_Pair,A_Conn,A_Log adb
```

## Detail Teknis

### 1. Pairing (Self-Pairing)
Stellar menggunakan teknik *self-pairing* di mana aplikasi bertindak sebagai klien ADB untuk dirinya sendiri.
- **mDNS:** Menemukan port pairing (`_adb-tls-pairing._tcp`).
- **SPAKE2:** Protokol pertukaran kunci aman yang menggabungkan PIN dan **EKM (Exported Keying Material)**.
- **Certificates:** Stellar men-generate sertifikat RSA self-signed (`adb_cert.pem`) yang akan didaftarkan ke sistem Android.

### 2. Connection
Setelah pairing sukses, Stellar membangun koneksi aman setiap kali diperlukan.
- **STLS Negotiation:** Upgrade koneksi TCP standar ke TLS secara aman sesuai protokol ADB modern.
- **Session Persistence:** Sesi TLS disimpan dalam `ACTIVE_SESSION` di memori Rust untuk menjalankan perintah shell.

### 3. Scanning
Proses pengambilan link dilakukan dengan memantau log sistem.
- **Logcat Stream:** Membaca log sistem Android secara real-time melalui enkripsi TLS.
- **Grep Filter:** Rust melakukan filtering otomatis untuk mencari pola URL gacha HoYoverse yang mengandung `authkey`.
