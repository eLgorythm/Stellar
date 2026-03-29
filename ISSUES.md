--------- beginning of main
03-29 20:57:35.946 31817  9483 I flutter : [IMPORTANT:flutter/shell/platform/android/android_context_vk_impeller.cc(62)] Using the Impeller rendering backend (Vulkan).
03-29 20:57:36.034 31817  9499 I flutter : The Dart VM service is listening on http://127.0.0.1:35399/FVZaTts7Bvg=/
03-29 20:57:38.019 31817 31817 I flutter : [20:57:38] [RUST:INFO] Rust logger initialized via StreamSink
03-29 20:57:38.022 31817 31817 I flutter : [20:57:38] [RUST:INFO] Bridge: Aliran log telah tersambung ke Dart.
03-29 20:57:40.685 31817 31817 I flutter : [20:57:40] DART: Memulai mDNS discovery untuk _adb-tls-pairing._tcp
03-29 20:57:46.015 31817 31817 I flutter : [20:57:46] DART: Layanan ditemukan: adb-7pgqlndalbscukg6-617mqw pada port 38493
03-29 20:57:46.111 31817 31817 I flutter : [20:57:46] DART: Discovery selesai. Port 38493 siap. Menunggu input user...
03-29 20:57:54.206 31817  9728 I flutter : [IMPORTANT:flutter/shell/platform/android/android_context_vk_impeller.cc(62)] Using the Impeller rendering backend (Vulkan).
03-29 20:57:55.382 31817 31817 I flutter : DART BG: lookup isolate...
03-29 20:57:55.386 31817 31817 I flutter : DART BG: payload = 38493
03-29 20:57:55.387 31817 31817 I flutter : DART BG: input = 459643
03-29 20:57:55.388 31817 31817 I flutter : DART BG: sendPort = SendPort
03-29 20:57:55.389 31817 31817 I flutter : DART: Background Isolate mengirim data ke Main Isolate...
03-29 20:57:55.413 31817 31817 I flutter : [20:57:55] DART: Memanggil Rust init_pairing(port: 38493, code: 459643)
03-29 20:57:55.422 31817 31817 I flutter : [20:57:55] [RUST:INFO] init_pairing dimulai: port=38493, code=459643
03-29 20:57:55.424 31817 31817 I flutter : [20:57:55] [RUST:DEBUG] Generating RSA 2048 keys and X509 certificate...
03-29 20:57:55.798 31817 31817 I flutter : [20:57:55] [RUST:INFO] Generated self-signed certificate and private key
03-29 20:57:55.800 31817 31817 I flutter : [20:57:55] [RUST:INFO] Connecting to 127.0.0.1:38493
03-29 20:57:55.808 31817 31817 I flutter : [20:57:55] [RUST:INFO] Starting TLS Handshake...
03-29 20:57:55.831 31817 31817 I flutter : [20:57:55] [RUST:DEBUG] MSG1 prefix = 65, payload size = 32
03-29 20:57:55.833 31817 31817 I flutter : [20:57:55] [RUST:INFO] Step 1/5: Sending SPAKE2 Exchange (Client)
03-29 20:57:55.835 31817 31817 I flutter : [20:57:55] [RUST:DEBUG] Sent SPAKE2 Exchange message: Type=1, Len=32
03-29 20:57:55.836 31817 31817 I flutter : [20:57:55] [RUST:INFO] Step 2/5: Waiting for SPAKE2 Exchange (Server)
03-29 20:57:55.838 31817 31817 I flutter : [20:57:55] [RUST:DEBUG] Read message header for SPAKE2 Exchange: Type=1
03-29 20:57:55.839 31817 31817 I flutter : [20:57:55] [RUST:DEBUG] Read SPAKE2 Exchange payload by exact read: 32 bytes
03-29 20:57:55.840 31817 31817 I flutter : [20:57:55] [RUST:DEBUG] Processing MSG2 with peer prefix: 66
03-29 20:57:55.842 31817 31817 I flutter : [20:57:55] [RUST:INFO] Step 3/5: Sending HMAC Confirmation (Client)

Error: AnyhowException(Broken pipe (os error 32))