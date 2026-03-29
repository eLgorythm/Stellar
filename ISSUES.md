--------- beginning of main
03-29 21:53:30.586 32668  7041 I flutter : [IMPORTANT:flutter/shell/platform/android/android_context_vk_impeller.cc(62)] Using the Impeller rendering backend (Vulkan).
03-29 21:53:30.820 32668  7126 I flutter : The Dart VM service is listening on http://127.0.0.1:40381/MX09DHmmzNM=/
03-29 21:53:33.607 32668 32668 I flutter : [21:53:33] [RUST:INFO] Rust logger initialized via StreamSink
03-29 21:53:33.611 32668 32668 I flutter : [21:53:33] [RUST:INFO] Bridge: Aliran log telah tersambung ke Dart.
03-29 21:53:36.421 32668 32668 I flutter : [21:53:36] DART: Memulai mDNS discovery untuk _adb-tls-pairing._tcp
03-29 21:53:45.102 32668 32668 I flutter : [21:53:45] DART: Layanan ditemukan: adb-7pgqlndalbscukg6-617mqw pada port 36491
03-29 21:53:45.191 32668 32668 I flutter : [21:53:45] DART: Discovery selesai. Port 36491 siap. Menunggu input user...
03-29 21:53:53.699 32668  7825 I flutter : [IMPORTANT:flutter/shell/platform/android/android_context_vk_impeller.cc(62)] Using the Impeller rendering backend (Vulkan).
03-29 21:53:54.884 32668 32668 I flutter : DART BG: lookup isolate...
03-29 21:53:54.889 32668 32668 I flutter : DART BG: payload = 36491
03-29 21:53:54.890 32668 32668 I flutter : DART BG: input = 873285
03-29 21:53:54.892 32668 32668 I flutter : DART BG: sendPort = SendPort
03-29 21:53:54.893 32668 32668 I flutter : DART: Background Isolate mengirim data ke Main Isolate...
03-29 21:53:54.911 32668 32668 I flutter : [21:53:54] DART: Memanggil Rust init_pairing(port: 36491, code: 873285)
03-29 21:53:54.926 32668 32668 I flutter : [21:53:54] [RUST:INFO] init_pairing dimulai: port=36491, code=873285
03-29 21:53:54.930 32668 32668 I flutter : [21:53:54] [RUST:DEBUG] Generating RSA 2048 keys and X509 certificate...
03-29 21:53:55.353 32668 32668 I flutter : [21:53:55] [RUST:INFO] Generated self-signed certificate and private key
03-29 21:53:55.355 32668 32668 I flutter : [21:53:55] [RUST:INFO] Connecting to 127.0.0.1:36491
03-29 21:53:55.358 32668 32668 I flutter : [21:53:55] [RUST:INFO] Starting TLS Handshake...
03-29 21:53:55.393 32668 32668 I flutter : [21:53:55] [RUST:DEBUG] MSG1 prefix = 65, payload size = 32
03-29 21:53:55.395 32668 32668 I flutter : [21:53:55] [RUST:INFO] Step 1/5: Sending SPAKE2 Exchange (Client)
03-29 21:53:55.396 32668 32668 I flutter : [21:53:55] [RUST:DEBUG] Sent SPAKE2 Exchange message: Type=1, Len=32
03-29 21:53:55.398 32668 32668 I flutter : [21:53:55] [RUST:INFO] Step 2/5: Waiting for SPAKE2 Exchange (Server)
03-29 21:53:55.400 32668 32668 I flutter : [21:53:55] [RUST:DEBUG] Read message header for SPAKE2 Exchange: Type=1
03-29 21:53:55.402 32668 32668 I flutter : [21:53:55] [RUST:DEBUG] Read SPAKE2 Exchange payload by exact read: 32 bytes
03-29 21:53:55.403 32668 32668 I flutter : [21:53:55] [RUST:DEBUG] Processing MSG2 with peer prefix: 66

Error: AnyhowException(CorruptMessage) (Percobaan 1)

03-29 21:54:04.439 32668 32668 I flutter : [21:54:04] DART: Memulai mDNS discovery untuk _adb-tls-pairing._tcp
03-29 21:54:08.196 32668 32668 I flutter : [21:54:08] DART: Layanan ditemukan: adb-7pgqlndalbscukg6-617mqw pada port 35285
03-29 21:54:08.266 32668 32668 I flutter : [21:54:08] DART: Discovery selesai. Port 35285 siap. Menunggu input user...
03-29 21:54:14.375 32668 32668 I flutter : DART BG: lookup isolate...
03-29 21:54:14.377 32668 32668 I flutter : DART BG: payload = 35285
03-29 21:54:14.378 32668 32668 I flutter : DART BG: input = 407718
03-29 21:54:14.379 32668 32668 I flutter : DART BG: sendPort = SendPort
03-29 21:54:14.379 32668 32668 I flutter : DART: Background Isolate mengirim data ke Main Isolate...
03-29 21:54:14.382 32668 32668 I flutter : [21:54:14] DART: Memanggil Rust init_pairing(port: 35285, code: 407718)
03-29 21:54:14.387 32668 32668 I flutter : [21:54:14] [RUST:INFO] init_pairing dimulai: port=35285, code=407718
03-29 21:54:14.412 32668 32668 I flutter : [21:54:14] [RUST:DEBUG] Generating RSA 2048 keys and X509 certificate...
03-29 21:54:15.274 32668 32668 I flutter : [21:54:15] [RUST:INFO] Generated self-signed certificate and private key
03-29 21:54:15.275 32668 32668 I flutter : [21:54:15] [RUST:INFO] Connecting to 127.0.0.1:35285
03-29 21:54:15.277 32668 32668 I flutter : [21:54:15] [RUST:INFO] Starting TLS Handshake...
03-29 21:54:15.305 32668 32668 I flutter : [21:54:15] [RUST:DEBUG] MSG1 prefix = 65, payload size = 32
03-29 21:54:15.307 32668 32668 I flutter : [21:54:15] [RUST:INFO] Step 1/5: Sending SPAKE2 Exchange (Client)
03-29 21:54:15.308 32668 32668 I flutter : [21:54:15] [RUST:DEBUG] Sent SPAKE2 Exchange message: Type=1, Len=32
03-29 21:54:15.309 32668 32668 I flutter : [21:54:15] [RUST:INFO] Step 2/5: Waiting for SPAKE2 Exchange (Server)
03-29 21:54:15.310 32668 32668 I flutter : [21:54:15] [RUST:DEBUG] Read message header for SPAKE2 Exchange: Type=1
03-29 21:54:15.311 32668 32668 I flutter : [21:54:15] [RUST:DEBUG] Read SPAKE2 Exchange payload by exact read: 32 bytes
03-29 21:54:15.313 32668 32668 I flutter : [21:54:15] [RUST:DEBUG] Processing MSG2 with peer prefix: 66
03-29 21:54:15.314 32668 32668 I flutter : [21:54:15] [RUST:INFO] Step 3/5: Sending HMAC Confirmation (Client)
03-29 21:54:15.315 32668 32668 I flutter : [21:54:15] [RUST:DEBUG] Sent variable-length message: Type=2, Len=32
03-29 21:54:15.317 32668 32668 I flutter : [21:54:15] [RUST:INFO] Step 4/5: Waiting for HMAC Confirmation (Server)

Error: AnyhowException(Timeout waiting for MSG4) (Percobaan 2)