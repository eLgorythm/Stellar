# Stellar Flow Diagrams

Dokumen ini menjelaskan alur teknis proses **Pairing** dan **Connection** antara aplikasi Stellar dan layanan Android Wireless Debugging.

## 1. Alur Proses Pairing (SPAKE2)

Proses ini dilakukan sekali untuk mendaftarkan sertifikat Stellar ke sistem Android.

```mermaid
sequenceDiagram
    participant U as User
    participant F as Flutter UI
    participant R as Rust (pair.rs)
    participant A as Android adbd

    U->>F: Tap PAIR
    F->>F: Start mDNS Discovery (_adb-tls-pairing)
    F->>U: Show "Ready to Pair" Notification
    U->>F: Input 6-digit PIN
    F->>R: init_pairing(port, PIN, storage_dir)
    
    R->>A: 1. TLS 1.3 Handshake (Self-signed Cert)
    A-->>R: TLS Established
    
    Note over R: Export Keying Material (EKM) 64-bit
    Note over R: Password = PIN + EKM
    
    R->>A: 2. SPAKE2 MSG1 (Outbound)
    A-->>R: SPAKE2 MSG2 (Inbound)
    
    Note over R: Derive Shared Key & AES-128-GCM Key (HKDF)
    
    R->>A: 3. PeerInfo Exchange (Encrypted RSA PubKey)
    A-->>R: PeerInfo Response (Encrypted)
    
    Note over R: Save Cert to adb_cert.pem
    R-->>F: Return Success
    F->>U: Show "Pairing Success"
```

## 2. Alur Proses Connection (ADB Secure)

Proses ini dilakukan setiap kali aplikasi ingin memulai sesi perintah ADB (seperti logcat).

```mermaid
sequenceDiagram
    participant F as Flutter UI
    participant R as Rust (connect.rs)
    participant A as Android adbd

    F->>F: Start mDNS Discovery (_adb-tls-connect)
    F->>R: connect_to_device(addr, storage_dir)
    
    R->>R: Load adb_cert.pem from storage
    R->>A: TCP Connect (Wireless Debug Port)
    
    Note over R,A: PHASE 1: STLS Negotiation (Cleartext)
    R->>A: Send CNXN (host::)
    A-->>R: Send STLS Response
    R->>A: Send STLS Confirm
    
    Note over R,A: PHASE 2: TLS Upgrade
    R->>A: TLS Handshake (Using Persistent Cert)
    A-->>R: TLS Established
    
    Note over R,A: PHASE 3: Secure ADB Session
    A-->>R: Send Encrypted CNXN (Device Info)
    
    Note over R: Store SslStream in ACTIVE_SESSION
    R-->>F: Return Success
    F->>F: Show Gacha Scanner Dialog
```

## Keterangan Teknis

- **SPAKE2:** Digunakan untuk otentikasi berbasis password tanpa mengirimkan password asli melalui jaringan.
- **EKM:** Menjamin bahwa sesi SPAKE2 terikat secara kriptografis ke sesi TLS yang aktif.
- **STLS:** Protokol transisi milik ADB untuk meningkatkan koneksi dari TCP biasa ke TLS (Secure ADB).