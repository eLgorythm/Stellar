--------- beginning of main
03-31 01:22:28.111 28515  2270 I flutter : [IMPORTANT:flutter/shell/platform/android/android_context_vk_impeller.cc(62)] Using the Impeller rendering backend (Vulkan).
03-31 01:22:28.176 28515  2299 I flutter : The Dart VM service is listening on http://127.0.0.1:38569/sn638iHjBJY=/
03-31 01:22:30.013 28515 28515 I flutter : [01:22:30] [RUST:INFO] Rust logger initialized via StreamSink
03-31 01:22:30.017 28515 28515 I flutter : [01:22:30] [RUST:INFO] Bridge: Aliran log telah tersambung ke Dart.
03-31 01:22:32.471 28515 28515 I flutter : [01:22:32] DART: Memulai mDNS discovery untuk _adb-tls-pairing._tcp
03-31 01:22:37.080 28515 28515 I flutter : [01:22:37] DART: Layanan ditemukan: adb-7pgqlndalbscukg6-617mqw pada port 35005
03-31 01:22:37.172 28515 28515 I flutter : [01:22:37] DART: Discovery selesai. Port 35005 siap. Menunggu input user...
03-31 01:22:43.554 28515  2852 I flutter : [IMPORTANT:flutter/shell/platform/android/android_context_vk_impeller.cc(62)] Using the Impeller rendering backend (Vulkan).
03-31 01:22:44.511 28515 28515 I flutter : DART BG: lookup isolate...
03-31 01:22:44.515 28515 28515 I flutter : DART BG: payload = 35005
03-31 01:22:44.517 28515 28515 I flutter : DART BG: input = 185448
03-31 01:22:44.518 28515 28515 I flutter : DART BG: sendPort = SendPort
03-31 01:22:44.519 28515 28515 I flutter : DART: Background Isolate mengirim data ke Main Isolate...
03-31 01:22:44.541 28515 28515 I flutter : [01:22:44] DART: Memanggil Rust init_pairing(port: 35005, code: 185448)
03-31 01:22:44.553 28515 28515 I flutter : [01:22:44] [RUST:INFO] init_pairing dimulai: port=35005, code=185448
03-31 01:22:44.556 28515 28515 I flutter : [01:22:44] [RUST:DEBUG] Generating RSA 2048 keys and X509 certificate...
03-31 01:22:45.216 28515 28515 I flutter : [01:22:45] [RUST:INFO] Generated self-signed certificate and private key
03-31 01:22:45.217 28515 28515 I flutter : [01:22:45] [RUST:INFO] Connecting to 127.0.0.1:35005
03-31 01:22:45.224 28515 28515 I flutter : [01:22:45] [RUST:INFO] Starting TLS Handshake...
03-31 01:22:45.244 28515 28515 I flutter : [01:22:45] [RUST:DEBUG] MSG1 prefix = 65, payload size = 32
03-31 01:22:45.245 28515 28515 I flutter : [01:22:45] [RUST:DEBUG] MSG1 payload to send: 6697d2cd4a33e2ca7779b1d9471daefbd63b2ea4273639a43f96a17a7ad00838
03-31 01:22:45.247 28515 28515 I flutter : [01:22:45] [RUST:INFO] Step 1/5: Sending SPAKE2 Exchange (Client)
03-31 01:22:45.248 28515 28515 I flutter : [01:22:45] [RUST:DEBUG] Sending SPAKE2 Exchange: Type=0, Len=32
03-31 01:22:45.250 28515 28515 I flutter : [01:22:45] [RUST:DEBUG] Sent AOSP PairingPacket: Type=0, Len=32
03-31 01:22:45.251 28515 28515 I flutter : [01:22:45] [RUST:INFO] Step 2/5: Waiting for SPAKE2 Exchange (Server)
03-31 01:22:45.252 28515 28515 I flutter : [01:22:45] [RUST:DEBUG] TLP header byte[0] = 0x01
03-31 01:22:45.253 28515 28515 I flutter : [01:22:45] [RUST:DEBUG] TLP header byte[1] = 0x00
03-31 01:22:45.254 28515 28515 I flutter : [01:22:45] [RUST:DEBUG] TLP header byte[2] = 0x00
03-31 01:22:45.256 28515 28515 I flutter : [01:22:45] [RUST:DEBUG] TLP header byte[3] = 0x00
03-31 01:22:45.257 28515 28515 I flutter : [01:22:45] [RUST:DEBUG] TLP header byte[4] = 0x00
03-31 01:22:45.258 28515 28515 I flutter : [01:22:45] [RUST:DEBUG] TLP header byte[5] = 0x20
03-31 01:22:45.259 28515 28515 I flutter : [01:22:45] [RUST:DEBUG] Full TLP header: 010000000020
03-31 01:22:45.261 28515 28515 I flutter : [01:22:45] [RUST:DEBUG] Received AOSP PairingPacket: Type=0, Len=32
03-31 01:22:45.262 28515 28515 I flutter : [01:22:45] [RUST:DEBUG] Received MSG2 payload length: 32
03-31 01:22:45.263 28515 28515 I flutter : [01:22:45] [RUST:DEBUG] MSG2 payload raw: b37b521d24b6a4be5075835d84b453faeb46438fe482eab3e592f4b3651195ad
03-31 01:22:45.264 28515 28515 I flutter : [01:22:45] [RUST:DEBUG] Prepend peer prefix 66 to MSG2 payload
03-31 01:22:45.265 28515 28515 I flutter : [01:22:45] [RUST:DEBUG] SPAKE2 shared secret generated, length: 32
03-31 01:22:45.267 28515 28515 I flutter : [01:22:45] [RUST:DEBUG] Shared secret: 708963140fc2a8a615744cbb5f801258cdc0741b9c4c626f47ba09af2bc81887
03-31 01:22:45.268 28515 28515 I flutter : [01:22:45] [RUST:DEBUG] Deriving keys: shared_secret_len=32 bytes
03-31 01:22:45.269 28515 28515 I flutter : [01:22:45] [RUST:DEBUG] Kc: 13da46dfcd79ab441150e3b0c1daa3d7f7cbea3671ff984fd172cec87d8a25b8
03-31 01:22:45.271 28515 28515 I flutter : [01:22:45] [RUST:DEBUG] Ks: c61eecdd10f67979af46fb53b58a1da924dee07a6a52ba5c7dc5b95254504922
03-31 01:22:45.272 28515 28515 I flutter : [01:22:45] [RUST:INFO] Step 3/6: Sending HMAC Confirmation (Client)
03-31 01:22:45.273 28515 28515 I flutter : [01:22:45] [RUST:DEBUG] Computed MSG3 confirmation HMAC: eadf49c660ec68bd2722886fb74317873906737f73249222f7671519fff8949e
03-31 01:22:45.274 28515 28515 I flutter : [01:22:45] [RUST:DEBUG] Sending SPAKE2 Confirmation message: Type=0, Len=32
03-31 01:22:45.274 28515 28515 I flutter : [01:22:45] [RUST:DEBUG] Sent AOSP PairingPacket: Type=0, Len=32
03-31 01:22:45.276 28515 28515 I flutter : [01:22:45] [RUST:DEBUG] MSG3 sent successfully
03-31 01:22:45.277 28515 28515 I flutter : [01:22:45] [RUST:INFO] Step 4/6: Waiting for server response
03-31 01:22:45.278 28515 28515 I flutter : [01:22:45] [RUST:DEBUG] TLP header byte[0] = 0x01
03-31 01:22:45.279 28515 28515 I flutter : [01:22:45] [RUST:DEBUG] TLP header byte[1] = 0x01
03-31 01:22:45.281 28515 28515 I flutter : [01:22:45] [RUST:DEBUG] TLP header byte[2] = 0x00
03-31 01:22:45.282 28515 28515 I flutter : [01:22:45] [RUST:DEBUG] TLP header byte[3] = 0x00
03-31 01:22:45.283 28515 28515 I flutter : [01:22:45] [RUST:DEBUG] TLP header byte[4] = 0x20
03-31 01:22:45.284 28515 28515 I flutter : [01:22:45] [RUST:DEBUG] TLP header byte[5] = 0x10
03-31 01:22:45.285 28515 28515 I flutter : [01:22:45] [RUST:DEBUG] Full TLP header: 010100002010
03-31 01:22:45.286 28515 28515 I flutter : [01:22:45] [RUST:DEBUG] Received AOSP PairingPacket: Type=1, Len=8208
03-31 01:22:45.287 28515 28515 I flutter : [01:22:45] [RUST:DEBUG] Received PeerInfo directly after client confirmation
03-31 01:22:45.289 28515 28515 I flutter : [01:22:45] [RUST:DEBUG] Decryption with Ks failed (AES-GCM decryption failed - check keys), trying Kc as fallback...

Error: AnyhowException(AES-GCM decryption failed with both keys. Shared secret or HKDF info mismatch.)