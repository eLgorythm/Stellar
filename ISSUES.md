--------- beginning of main
03-29 23:59:34.184 12460 20887 I flutter : [IMPORTANT:flutter/shell/platform/android/android_context_vk_impeller.cc(62)] Using the Impeller rendering backend (Vulkan).
03-29 23:59:34.339 12460 20933 I flutter : The Dart VM service is listening on http://127.0.0.1:33961/8_gbI22CG98=/
03-29 23:59:36.458 12460 12460 I flutter : [23:59:36] [RUST:INFO] Rust logger initialized via StreamSink
03-29 23:59:36.463 12460 12460 I flutter : [23:59:36] [RUST:INFO] Bridge: Aliran log telah tersambung ke Dart.
03-29 23:59:39.152 12460 12460 I flutter : [23:59:39] DART: Memulai mDNS discovery untuk _adb-tls-pairing._tcp
03-29 23:59:48.011 12460 12460 I flutter : [23:59:48] DART: Layanan ditemukan: adb-7pgqlndalbscukg6-617mqw pada port 46633
03-29 23:59:48.125 12460 12460 I flutter : [23:59:48] DART: Discovery selesai. Port 46633 siap. Menunggu input user...
03-29 23:59:54.394 12460 21329 I flutter : [IMPORTANT:flutter/shell/platform/android/android_context_vk_impeller.cc(62)] Using the Impeller rendering backend (Vulkan).
03-29 23:59:55.566 12460 12460 I flutter : DART BG: lookup isolate...
03-29 23:59:55.571 12460 12460 I flutter : DART BG: payload = 46633
03-29 23:59:55.572 12460 12460 I flutter : DART BG: input = 337412
03-29 23:59:55.573 12460 12460 I flutter : DART BG: sendPort = SendPort
03-29 23:59:55.573 12460 12460 I flutter : DART: Background Isolate mengirim data ke Main Isolate...
03-29 23:59:55.587 12460 12460 I flutter : [23:59:55] DART: Memanggil Rust init_pairing(port: 46633, code: 337412)
03-29 23:59:55.597 12460 12460 I flutter : [23:59:55] [RUST:INFO] init_pairing dimulai: port=46633, code=337412
03-29 23:59:55.598 12460 12460 I flutter : [23:59:55] [RUST:DEBUG] Generating RSA 2048 keys and X509 certificate...
03-29 23:59:55.886 12460 12460 I flutter : [23:59:55] [RUST:INFO] Generated self-signed certificate and private key
03-29 23:59:55.887 12460 12460 I flutter : [23:59:55] [RUST:INFO] Connecting to 127.0.0.1:46633
03-29 23:59:55.891 12460 12460 I flutter : [23:59:55] [RUST:INFO] Starting TLS Handshake...
03-29 23:59:55.918 12460 12460 I flutter : [23:59:55] [RUST:DEBUG] MSG1 prefix = 65, payload size = 32
03-29 23:59:55.920 12460 12460 I flutter : [23:59:55] [RUST:DEBUG] MSG1 payload to send: 038ef43de85717c407f1b613c506096b77d6fea54e1df8ba46c627be2c165d3d
03-29 23:59:55.921 12460 12460 I flutter : [23:59:55] [RUST:INFO] Step 1/5: Sending SPAKE2 Exchange (Client)
03-29 23:59:55.923 12460 12460 I flutter : [23:59:55] [RUST:DEBUG] Sending SPAKE2 Exchange message: Type=1, Len=32
03-29 23:59:55.925 12460 12460 I flutter : [23:59:55] [RUST:DEBUG] Sent variable-length message: Type=1, Len=32, Payload=038ef43de85717c407f1b613c506096b77d6fea54e1df8ba46c627be2c165d3d
03-29 23:59:55.927 12460 12460 I flutter : [23:59:55] [RUST:INFO] Step 2/5: Waiting for SPAKE2 Exchange (Server)
03-29 23:59:55.928 12460 12460 I flutter : [23:59:55] [RUST:DEBUG] Read message header for SPAKE2 Exchange: Type=1
03-29 23:59:55.930 12460 12460 I flutter : [23:59:55] [RUST:DEBUG] Read raw SPAKE2 Exchange payload by exact read: 32 bytes, Payload=0020e4d46c9a7cf110bca19138e41c8f3a02a905128d890cc6e2e46d430b14b0
03-29 23:59:55.931 12460 12460 I flutter : [23:59:55] [RUST:DEBUG] Received MSG2 payload length: 32
03-29 23:59:55.933 12460 12460 I flutter : [23:59:55] [RUST:DEBUG] MSG2 payload raw: 0020e4d46c9a7cf110bca19138e41c8f3a02a905128d890cc6e2e46d430b14b0
03-29 23:59:55.934 12460 12460 I flutter : [23:59:55] [RUST:DEBUG] Processing MSG2 by prepending peer prefix: 66
03-29 23:59:55.935 12460 12460 I flutter : [23:59:55] [RUST:INFO] Step 3/5: Sending HMAC Confirmation (Client)
03-29 23:59:55.936 12460 12460 I flutter : [23:59:55] [RUST:DEBUG] Computed MSG3 confirmation HMAC: 012b762ce119236a7f9123eeae3f5cf50b11ba28d96536289e4a8d2491effb98
03-29 23:59:55.937 12460 12460 I flutter : [23:59:55] [RUST:DEBUG] Preparing to send SPAKE2 Confirmation message: Type=2, Len=32, Payload=012b762ce119236a7f9123eeae3f5cf50b11ba28d96536289e4a8d2491effb98
03-29 23:59:55.942 12460 12460 I flutter : [23:59:55] [RUST:DEBUG] write_confirmation_message: wrote MSG_TYPE_CONFIRMATION
03-29 23:59:55.944 12460 12460 I flutter : [23:59:55] [RUST:DEBUG] write_confirmation_message: wrote payload length 32
03-29 23:59:55.945 12460 12460 I flutter : [23:59:55] [RUST:DEBUG] write_confirmation_message: wrote payload bytes
03-29 23:59:55.947 12460 12460 I flutter : [23:59:55] [RUST:DEBUG] Sent SPAKE2 Confirmation message: Type=2, Len=32, Payload=012b762ce119236a7f9123eeae3f5cf50b11ba28d96536289e4a8d2491effb98
03-29 23:59:55.948 12460 12460 I flutter : [23:59:55] [RUST:DEBUG] MSG3 sent successfully
03-29 23:59:55.949 12460 12460 I flutter : [23:59:55] [RUST:INFO] Step 4/5: Waiting for HMAC Confirmation (Server)

Error: AnyhowException(Timeout waiting for MSG4).