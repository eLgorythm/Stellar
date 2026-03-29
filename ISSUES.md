--------- beginning of main
03-30 00:26:23.921 20982 28812 I flutter : [IMPORTANT:flutter/shell/platform/android/android_context_vk_impeller.cc(62)] Using the Impeller rendering backend (Vulkan).
03-30 00:26:24.230 20982 28846 I flutter : The Dart VM service is listening on http://127.0.0.1:45259/zXSYkdwnTLw=/
03-30 00:26:26.226 20982 20982 I flutter : [00:26:26] [RUST:INFO] Rust logger initialized via StreamSink
03-30 00:26:26.230 20982 20982 I flutter : [00:26:26] [RUST:INFO] Bridge: Aliran log telah tersambung ke Dart.
03-30 00:26:29.150 20982 20982 I flutter : [00:26:29] DART: Memulai mDNS discovery untuk _adb-tls-pairing._tcp
03-30 00:26:37.870 20982 20982 I flutter : [00:26:37] DART: Layanan ditemukan: adb-7pgqlndalbscukg6-617mqw pada port 36653
03-30 00:26:37.973 20982 20982 I flutter : [00:26:37] DART: Discovery selesai. Port 36653 siap. Menunggu input user...
03-30 00:26:43.789 20982 29177 I flutter : [IMPORTANT:flutter/shell/platform/android/android_context_vk_impeller.cc(62)] Using the Impeller rendering backend (Vulkan).
03-30 00:26:45.140 20982 20982 I flutter : DART BG: lookup isolate...
03-30 00:26:45.145 20982 20982 I flutter : DART BG: payload = 36653
03-30 00:26:45.145 20982 20982 I flutter : DART BG: input = 122526
03-30 00:26:45.146 20982 20982 I flutter : DART BG: sendPort = SendPort
03-30 00:26:45.147 20982 20982 I flutter : DART: Background Isolate mengirim data ke Main Isolate...
03-30 00:26:45.161 20982 20982 I flutter : [00:26:45] DART: Memanggil Rust init_pairing(port: 36653, code: 122526)
03-30 00:26:45.171 20982 20982 I flutter : [00:26:45] [RUST:INFO] init_pairing dimulai: port=36653, code=122526
03-30 00:26:45.173 20982 20982 I flutter : [00:26:45] [RUST:DEBUG] Generating RSA 2048 keys and X509 certificate...
03-30 00:26:45.470 20982 20982 I flutter : [00:26:45] [RUST:INFO] Generated self-signed certificate and private key
03-30 00:26:45.472 20982 20982 I flutter : [00:26:45] [RUST:INFO] Connecting to 127.0.0.1:36653
03-30 00:26:45.478 20982 20982 I flutter : [00:26:45] [RUST:INFO] Starting TLS Handshake...
03-30 00:26:45.509 20982 20982 I flutter : [00:26:45] [RUST:DEBUG] MSG1 prefix = 65, payload size = 32
03-30 00:26:45.510 20982 20982 I flutter : [00:26:45] [RUST:DEBUG] MSG1 payload to send: 2343a00761d572f31acf2920f72a5d49864292e42e059e94e8177346880a06d0
03-30 00:26:45.512 20982 20982 I flutter : [00:26:45] [RUST:INFO] Step 1/5: Sending SPAKE2 Exchange (Client)
03-30 00:26:45.513 20982 20982 I flutter : [00:26:45] [RUST:DEBUG] Sending SPAKE2 Exchange message: Type=1, Len=32
03-30 00:26:45.514 20982 20982 I flutter : [00:26:45] [RUST:DEBUG] Sent variable-length message: Type=1, Len=32, Payload=2343a00761d572f31acf2920f72a5d49864292e42e059e94e8177346880a06d0
03-30 00:26:45.515 20982 20982 I flutter : [00:26:45] [RUST:INFO] Step 2/5: Waiting for SPAKE2 Exchange (Server)
03-30 00:26:45.517 20982 20982 I flutter : [00:26:45] [RUST:DEBUG] Read message header for SPAKE2 Exchange: Type=1
03-30 00:26:45.518 20982 20982 I flutter : [00:26:45] [RUST:DEBUG] Detected 2-byte BE length prefix: 32, read payload
03-30 00:26:45.520 20982 20982 I flutter : [00:26:45] [RUST:DEBUG] Received MSG2 payload length: 32
03-30 00:26:45.522 20982 20982 I flutter : [00:26:45] [RUST:DEBUG] MSG2 payload raw: 1cd523c1f80447d3fee67d9ca455f31e1b4057f125cce012a8f15ff424197ad0
03-30 00:26:45.523 20982 20982 I flutter : [00:26:45] [RUST:DEBUG] Processing MSG2 by prepending peer prefix: 66
03-30 00:26:45.525 20982 20982 I flutter : [00:26:45] [RUST:INFO] Step 3/5: Sending HMAC Confirmation (Client)
03-30 00:26:45.526 20982 20982 I flutter : [00:26:45] [RUST:DEBUG] Computed MSG3 confirmation HMAC: 253caa683c8b97bc4de2488dc0af3d8a6667041453b68744e70ef06f73fa30ed
03-30 00:26:45.528 20982 20982 I flutter : [00:26:45] [RUST:DEBUG] Sending SPAKE2 Confirmation message: Type=2, Len=32
03-30 00:26:45.529 20982 20982 I flutter : [00:26:45] [RUST:DEBUG] Sent variable-length message: Type=2, Len=32, Payload=253caa683c8b97bc4de2488dc0af3d8a6667041453b68744e70ef06f73fa30ed
03-30 00:26:45.530 20982 20982 I flutter : [00:26:45] [RUST:DEBUG] MSG3 sent successfully
03-30 00:26:45.532 20982 20982 I flutter : [00:26:45] [RUST:INFO] Step 4/5: Waiting for HMAC Confirmation (Server)
03-30 00:26:45.533 20982 20982 I flutter : [00:26:45] [RUST:DEBUG] Read message header for SPAKE2 Confirmation: Type=257

Error: AnyhowException(Unexpected message type for SPAKE2 Confirmation: 257. Expected MSG_TYPE_CONFIRMATION(2).)