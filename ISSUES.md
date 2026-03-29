--------- beginning of main
03-29 23:02:52.438 26320  6922 I flutter : [IMPORTANT:flutter/shell/platform/android/android_context_vk_impeller.cc(62)] Using the Impeller rendering backend (Vulkan).
03-29 23:02:52.910 26320  6968 I flutter : The Dart VM service is listening on http://127.0.0.1:35109/b1ex5tdF0C0=/
03-29 23:02:55.289 26320 26320 I flutter : [23:02:55] [RUST:INFO] Rust logger initialized via StreamSink
03-29 23:02:55.293 26320 26320 I flutter : [23:02:55] [RUST:INFO] Bridge: Aliran log telah tersambung ke Dart.
03-29 23:02:58.186 26320 26320 I flutter : [23:02:58] DART: Memulai mDNS discovery untuk _adb-tls-pairing._tcp
03-29 23:03:16.345 26320 26320 I flutter : [23:03:16] DART: Layanan ditemukan: adb-7pgqlndalbscukg6-617mqw pada port 35523
03-29 23:03:16.454 26320 26320 I flutter : [23:03:16] DART: Discovery selesai. Port 35523 siap. Menunggu input user...
03-29 23:03:25.330 26320  8032 I flutter : [IMPORTANT:flutter/shell/platform/android/android_context_vk_impeller.cc(62)] Using the Impeller rendering backend (Vulkan).
03-29 23:03:26.656 26320 26320 I flutter : DART BG: lookup isolate...
03-29 23:03:26.663 26320 26320 I flutter : DART BG: payload = 35523
03-29 23:03:26.664 26320 26320 I flutter : DART BG: input = 719457
03-29 23:03:26.665 26320 26320 I flutter : DART BG: sendPort = SendPort
03-29 23:03:26.666 26320 26320 I flutter : DART: Background Isolate mengirim data ke Main Isolate...
03-29 23:03:26.685 26320 26320 I flutter : [23:03:26] DART: Memanggil Rust init_pairing(port: 35523, code: 719457)
03-29 23:03:26.696 26320 26320 I flutter : [23:03:26] [RUST:INFO] init_pairing dimulai: port=35523, code=719457
03-29 23:03:26.698 26320 26320 I flutter : [23:03:26] [RUST:DEBUG] Generating RSA 2048 keys and X509 certificate...
03-29 23:03:27.103 26320 26320 I flutter : [23:03:27] [RUST:INFO] Generated self-signed certificate and private key
03-29 23:03:27.104 26320 26320 I flutter : [23:03:27] [RUST:INFO] Connecting to 127.0.0.1:35523
03-29 23:03:27.108 26320 26320 I flutter : [23:03:27] [RUST:INFO] Starting TLS Handshake...
03-29 23:03:27.142 26320 26320 I flutter : [23:03:27] [RUST:DEBUG] MSG1 prefix = 65, payload size = 32
03-29 23:03:27.143 26320 26320 I flutter : [23:03:27] [RUST:DEBUG] MSG1 payload to send: 9429fa0932de35fed101943e745aa87c42898e290cccccb0064f42465fc3bab5
03-29 23:03:27.144 26320 26320 I flutter : [23:03:27] [RUST:INFO] Step 1/5: Sending SPAKE2 Exchange (Client)
03-29 23:03:27.146 26320 26320 I flutter : [23:03:27] [RUST:DEBUG] Sent SPAKE2 Exchange message: Type=1, Len=32, Payload=9429fa0932de35fed101943e745aa87c42898e290cccccb0064f42465fc3bab5
03-29 23:03:27.149 26320 26320 I flutter : [23:03:27] [RUST:INFO] Step 2/5: Waiting for SPAKE2 Exchange (Server)
03-29 23:03:27.153 26320 26320 I flutter : [23:03:27] [RUST:DEBUG] Read message header for SPAKE2 Exchange: Type=1
03-29 23:03:27.155 26320 26320 I flutter : [23:03:27] [RUST:DEBUG] Read raw SPAKE2 Exchange payload by exact read: 32 bytes, Payload=002019f03846cc6cfa32499680d8627ada9ac1b3de9cbaa1cd9d48ed1805fa03
03-29 23:03:27.156 26320 26320 I flutter : [23:03:27] [RUST:DEBUG] Received MSG2 payload length: 32
03-29 23:03:27.157 26320 26320 I flutter : [23:03:27] [RUST:DEBUG] MSG2 payload raw: 002019f03846cc6cfa32499680d8627ada9ac1b3de9cbaa1cd9d48ed1805fa03
03-29 23:03:27.158 26320 26320 I flutter : [23:03:27] [RUST:DEBUG] Processing MSG2 by prepending peer prefix: 66
03-29 23:03:27.159 26320 26320 I flutter : [23:03:27] [RUST:INFO] Step 3/5: Sending HMAC Confirmation (Client)
03-29 23:03:27.160 26320 26320 I flutter : [23:03:27] [RUST:DEBUG] Computed MSG3 confirmation HMAC: 177d7632fdb2304cfc909f716af251d9efcaf89eb39294e1908d65af50f95162
03-29 23:03:27.161 26320 26320 I flutter : [23:03:27] [RUST:DEBUG] Preparing to send SPAKE2 Confirmation message: Type=2, Len=32, Payload=177d7632fdb2304cfc909f716af251d9efcaf89eb39294e1908d65af50f95162

Error: AnyhowException(Broken pipe(os error 32)).