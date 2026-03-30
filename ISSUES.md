--------- beginning of main
03-30 19:25:16.648  8604 13362 I flutter : [IMPORTANT:flutter/shell/platform/android/android_context_vk_impeller.cc(62)] Using the Impeller rendering backend (Vulkan).
03-30 19:25:16.761  8604 13390 I flutter : The Dart VM service is listening on http://127.0.0.1:43067/cn7ZEbfLWtk=/
03-30 19:25:18.651  8604  8604 I flutter : [19:25:18] [RUST:INFO] Rust logger initialized via StreamSink
03-30 19:25:18.654  8604  8604 I flutter : [19:25:18] [RUST:INFO] Bridge: Aliran log telah tersambung ke Dart.
03-30 19:25:20.682  8604  8604 I flutter : [19:25:20] DART: Memulai mDNS discovery untuk _adb-tls-pairing._tcp
03-30 19:25:24.530  8604  8604 I flutter : [19:25:24] DART: Layanan ditemukan: adb-7pgqlndalbscukg6-617mqw pada port 43965
03-30 19:25:24.618  8604  8604 I flutter : [19:25:24] DART: Discovery selesai. Port 43965 siap. Menunggu input user...
03-30 19:25:32.561  8604 13532 I flutter : [IMPORTANT:flutter/shell/platform/android/android_context_vk_impeller.cc(62)] Using the Impeller rendering backend (Vulkan).
03-30 19:25:33.661  8604  8604 I flutter : DART BG: lookup isolate...
03-30 19:25:33.665  8604  8604 I flutter : DART BG: payload = 43965
03-30 19:25:33.666  8604  8604 I flutter : DART BG: input = 673276
03-30 19:25:33.667  8604  8604 I flutter : DART BG: sendPort = SendPort
03-30 19:25:33.668  8604  8604 I flutter : DART: Background Isolate mengirim data ke Main Isolate...
03-30 19:25:33.682  8604  8604 I flutter : [19:25:33] DART: Memanggil Rust init_pairing(port: 43965, code: 673276)
03-30 19:25:33.695  8604  8604 I flutter : [19:25:33] [RUST:INFO] init_pairing dimulai: port=43965, code=673276
03-30 19:25:33.698  8604  8604 I flutter : [19:25:33] [RUST:DEBUG] Generating RSA 2048 keys and X509 certificate...
03-30 19:25:34.349  8604  8604 I flutter : [19:25:34] [RUST:INFO] Generated self-signed certificate and private key
03-30 19:25:34.351  8604  8604 I flutter : [19:25:34] [RUST:INFO] Connecting to 127.0.0.1:43965
03-30 19:25:34.354  8604  8604 I flutter : [19:25:34] [RUST:INFO] Starting TLS Handshake...
03-30 19:25:34.387  8604  8604 I flutter : [19:25:34] [RUST:DEBUG] MSG1 prefix = 65, payload size = 32
03-30 19:25:34.388  8604  8604 I flutter : [19:25:34] [RUST:DEBUG] MSG1 payload to send: 3a838d9d07316ba301aeebccf0b68f2149579903ff51a60ba709b11473114f25
03-30 19:25:34.390  8604  8604 I flutter : [19:25:34] [RUST:INFO] Step 1/5: Sending SPAKE2 Exchange (Client)
03-30 19:25:34.391  8604  8604 I flutter : [19:25:34] [RUST:DEBUG] Sending SPAKE2 Exchange: Type=1, Len=32
03-30 19:25:34.393  8604  8604 I flutter : [19:25:34] [RUST:DEBUG] Sent ADP Packet: Type=1, Len=32
03-30 19:25:34.394  8604  8604 I flutter : [19:25:34] [RUST:INFO] Step 2/5: Waiting for SPAKE2 Exchange (Server)
03-30 19:25:34.396  8604  8604 I flutter : [19:25:34] [RUST:DEBUG] Received ADP Packet: Type=1, Len=32
03-30 19:25:34.397  8604  8604 I flutter : [19:25:34] [RUST:DEBUG] Received MSG2 payload length: 32
03-30 19:25:34.398  8604  8604 I flutter : [19:25:34] [RUST:DEBUG] MSG2 payload raw: a9ca7f6d52929102bb01a8d58b9991b6e034194c45ace218d1218756628817d3
03-30 19:25:34.400  8604  8604 I flutter : [19:25:34] [RUST:DEBUG] Processing MSG2 by prepending peer prefix: 66
03-30 19:25:34.401  8604  8604 I flutter : [19:25:34] [RUST:DEBUG] SPAKE2 shared secret generated, length: 32
03-30 19:25:34.402  8604  8604 I flutter : [19:25:34] [RUST:DEBUG] Deriving keys: shared_secret_len=32 bytes
03-30 19:25:34.403  8604  8604 I flutter : [19:25:34] [RUST:DEBUG] Keys derived: Kc=fbc80b2e..., Ks=54229a19...
03-30 19:25:34.404  8604  8604 I flutter : [19:25:34] [RUST:INFO] Step 3/5: Sending HMAC Confirmation (Client)
03-30 19:25:34.406  8604  8604 I flutter : [19:25:34] [RUST:DEBUG] Computed MSG3 confirmation HMAC: b0a9ca095686b4833d3dd3b8d9068311d5cb26eebd8b037f1da685d7d031a4de
03-30 19:25:34.407  8604  8604 I flutter : [19:25:34] [RUST:DEBUG] Sending SPAKE2 Confirmation message: Type=2, Len=32
03-30 19:25:34.409  8604  8604 I flutter : [19:25:34] [RUST:DEBUG] Sent ADP Packet: Type=2, Len=32
03-30 19:25:34.410  8604  8604 I flutter : [19:25:34] [RUST:DEBUG] MSG3 sent successfully
03-30 19:25:34.412  8604  8604 I flutter : [19:25:34] [RUST:INFO] Step 4/5: Waiting for HMAC Confirmation (Server)
03-30 19:25:34.413  8604  8604 I flutter : [19:25:34] [RUST:DEBUG] Received ADP Packet: Type=257, Len=8208
03-30 19:25:34.415  8604  8604 I flutter : [19:25:34] [RUST:DEBUG] Step 4: Received message type 257
03-30 19:25:34.416  8604  8604 I flutter : [19:25:34] [RUST:ERROR] Server returned protocol error (257). Raw Payload: 7adda966faaebe4d1e2beb8c87c4b682d2b7dbde2789351c03d9cf1712400f377f83ba6b62b65e0d9c14825201ca7bfb00e230210be0d37f5d8bcd2631acde2efca91678bef8c6c1acf3fb2148c11fbda483050b664fb5e0ef0a288872988a684e54e9772142b1785d45507ee4bfe820f4a881f1b595114f00029cd194427b26a4dc1c51ccb99d022370593864b8c001451d569e7edd2dee404760189fb5121a39d62e8a36a592051afc43d92bf14e6136cf729f6662084b7bb48147bdaa1a26375b0c1c8acbc44b4f3f70c7b729cd1dc10dbbf2f7e49864ddee32e37e98832415b285d0eb878a491ec76819fb127c3d736a38706804f53f6e6ad9167367eec759d167c196b960b87a7281f62836fd52231f82a82a0a894c788b2c82aa59191fa1f8ef6f74a14cd072236b13d702863b32da7d06712fafc981d4204d2b427d1f885ff6bb7ec38102c70f1371a50c07ed1dc870a3c2d65f3544b880c8f5b3ef8cfc7a884d6c5c95bfee482bddf0bdb75a4159f2dd8b2fab12f025d6b8ab4866c548a9385a01f7f3845d91a5f435caee89eb7f47ecc31921a2004272c10e109c7440350162eaff740562f2b8627c4b6ecec482f1dcac8f7ec3f3dfb57008530ca243242f5b208a932b03155e54c6a3cf715b7b38e78459617e5658

Error: AnyhowException(Server rejected pairing (Error 257). Pairing code salah atau mismatch Identity.)
