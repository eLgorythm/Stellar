TLS connect
↓
SPAKE2 start_a → kirim Msg1
↓
terima Msg2
↓
finish() → dapat shared_secret
↓
derive key (HKDF)
↓
Msg3: kirim client confirmation (HMAC)
↓
Msg4: terima server confirmation
↓
verifikasi
↓
kirim PeerInfo (RSA public key)