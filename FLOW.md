Client (Stellar)                          Server (Android adbd)
------------------                        ------------------------

[1] Generate Ed25519 + X509
        |
        |  TLS Connect (BoringSSL)
        |-------------------------------------->
        |<--------------------------------------  TLS Handshake OK
        |
        |  --- SPAKE2 START ---
        |
[2] MSG1: SPAKE2 (32 byte)
        |-------------------------------------->
        |
        |<--------------------------------------  MSG2: SPAKE2 (32 byte)
        |
[3] Compute Shared Secret
        |
[4] HKDF → Kc, Ks
        |
[5] MSG3 = HMAC(Kc, MSG1 || MSG2)
        |-------------------------------------->
        |
        |<--------------------------------------  MSG4 = HMAC(Ks, MSG1 || MSG2 || MSG3)
        |
[6] Verify MSG4 ✅
        |
        |<--------------------------------------  PeerInfo (AES-GCM encrypted)
        |
[7] Decrypt PeerInfo (Ks)
        |
[8] Decode protobuf PeerInfo
        |
        |-------------------------------------->  Send Client PeerInfo (encrypted)
        |
        |  --- TLS READY ---
        |
[9] Pairing SUCCESS → device trusted

=============================================================
TLS → SPAKE2 → HKDF → MSG3 → MSG4 → VERIFY → AES → PeerInfo
=============================================================

Participant Client (Stellar)
Participant Server (adbd)

Client->Server: TLS Handshake (BoringSSL)
Server-->Client: TLS Established

Note over Client,Server: === SPAKE2 PHASE ===

Client->Server: MSG1 (SPAKE2, 32B)
Server-->Client: MSG2 (SPAKE2, 32B)

Note over Client: Compute shared_secret
Note over Client: HKDF → Kc, Ks

Client->Server: MSG3 = HMAC(Kc, MSG1 || MSG2)

Server-->Client: MSG4 = HMAC(Ks, MSG1 || MSG2 || MSG3)

Note over Client: Verify MSG4 ✅

Note over Client,Server: === ENCRYPTED CHANNEL ===

Server-->Client: PeerInfo (AES-GCM, key=Ks)

Note over Client: Decrypt PeerInfo (Ks)
Note over Client: Decode protobuf

Client->Server: PeerInfo (AES-GCM, key=Kc)

Note over Client,Server: === PAIRING COMPLETE ===

Server-->Client: Pairing Success (implicit)
Note over Client: Device trusted & appears in adb devices

┌─────────────────┬─────────────────────┐
│    TLS Layer    │   SPAKE2 Layer      │
├─────────────────┼─────────────────────┤
│   Ed25519       │     P-256 SPAKE2    │
│   Client Cert   │   x/y scalars       │
│   (Auth)        │   (Key Exchange)    │
└─────────────────┴─────────────────────┘