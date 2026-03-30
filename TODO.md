let mut hmac_input = Vec::with_capacity(64);
hmac_input.extend_from_slice(&msg1_sent);     // 32 byte
hmac_input.extend_from_slice(&msg2_received); // 32 byte

// Hitung HMAC menggunakan Kc (32 byte pertama dari HKDF)
let msg3_hmac = compute_hmac(&kc, &hmac_input);