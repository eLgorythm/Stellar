--------- beginning of main
03-30 03:00:25.477 13126 18179 I flutter : [IMPORTANT:flutter/shell/platform/android/android_context_vk_impeller.cc(62)] Using the Impeller rendering backend (Vulkan).
03-30 03:00:25.570 13126 18212 I flutter : The Dart VM service is listening on http://127.0.0.1:32921/uUTte8LpaZU=/
03-30 03:00:27.652 13126 13126 I flutter : [03:00:27] [RUST:INFO] Rust logger initialized via StreamSink
03-30 03:00:27.657 13126 13126 I flutter : [03:00:27] [RUST:INFO] Bridge: Aliran log telah tersambung ke Dart.
03-30 03:00:30.564 13126 13126 I flutter : [03:00:30] DART: Memulai mDNS discovery untuk _adb-tls-pairing._tcp
03-30 03:00:36.523 13126 13126 I flutter : [03:00:36] DART: Layanan ditemukan: adb-7pgqlndalbscukg6-617mqw pada port 38621
03-30 03:00:36.625 13126 13126 I flutter : [03:00:36] DART: Discovery selesai. Port 38621 siap. Menunggu input user...
03-30 03:00:43.233 13126 18364 I flutter : [IMPORTANT:flutter/shell/platform/android/android_context_vk_impeller.cc(62)] Using the Impeller rendering backend (Vulkan).
03-30 03:00:44.619 13126 13126 I flutter : DART BG: lookup isolate...
03-30 03:00:44.625 13126 13126 I flutter : DART BG: payload = 38621
03-30 03:00:44.625 13126 13126 I flutter : DART BG: input = 713215
03-30 03:00:44.627 13126 13126 I flutter : DART BG: sendPort = SendPort
03-30 03:00:44.628 13126 13126 I flutter : DART: Background Isolate mengirim data ke Main Isolate...
03-30 03:00:44.656 13126 13126 I flutter : [03:00:44] DART: Memanggil Rust init_pairing(port: 38621, code: 713215)
03-30 03:00:44.677 13126 13126 I flutter : [03:00:44] [RUST:INFO] init_pairing dimulai: port=38621, code=713215
03-30 03:00:44.679 13126 13126 I flutter : [03:00:44] [RUST:DEBUG] Generating RSA 2048 keys and X509 certificate...
03-30 03:00:44.962 13126 13126 I flutter : [03:00:44] [RUST:INFO] Generated self-signed certificate and private key
03-30 03:00:44.964 13126 13126 I flutter : [03:00:44] [RUST:INFO] Connecting to 127.0.0.1:38621
03-30 03:00:44.967 13126 13126 I flutter : [03:00:44] [RUST:INFO] Starting TLS Handshake...
03-30 03:00:44.994 13126 13126 I flutter : [03:00:44] [RUST:DEBUG] MSG1 prefix = 65, payload size = 32
03-30 03:00:44.995 13126 13126 I flutter : [03:00:44] [RUST:DEBUG] MSG1 payload to send: efa4161b5637c0a9ebcc9c62beb6f80a3c6443937d80ef27d3c7a9bd98120173
03-30 03:00:44.998 13126 13126 I flutter : [03:00:44] [RUST:INFO] Step 1/5: Sending SPAKE2 Exchange (Client)
03-30 03:00:44.999 13126 13126 I flutter : [03:00:44] [RUST:DEBUG] Sending SPAKE2 Exchange: Type=1, Len=32
03-30 03:00:45.001 13126 13126 I flutter : [03:00:45] [RUST:DEBUG] Sent ADP Packet: Type=1, Len=32
03-30 03:00:45.002 13126 13126 I flutter : [03:00:45] [RUST:INFO] Step 2/5: Waiting for SPAKE2 Exchange (Server)
03-30 03:00:45.003 13126 13126 I flutter : [03:00:45] [RUST:DEBUG] Received ADP Packet: Type=1, Len=32
03-30 03:00:45.005 13126 13126 I flutter : [03:00:45] [RUST:DEBUG] Received MSG2 payload length: 32
03-30 03:00:45.006 13126 13126 I flutter : [03:00:45] [RUST:DEBUG] MSG2 payload raw: 98a66e62d71be4362b4cb18fbb06f6c41797591a8dfeda744b5a90c0a1eafc1e
03-30 03:00:45.008 13126 13126 I flutter : [03:00:45] [RUST:DEBUG] Processing MSG2 by prepending peer prefix: 66
03-30 03:00:45.009 13126 13126 I flutter : [03:00:45] [RUST:INFO] Step 3/5: Sending HMAC Confirmation (Client)
03-30 03:00:45.011 13126 13126 I flutter : [03:00:45] [RUST:DEBUG] Computed MSG3 confirmation HMAC: 5d62e7af8fd0f53b861af84303da7aaa9e1e244f464299800c6f643af35b4a87
03-30 03:00:45.012 13126 13126 I flutter : [03:00:45] [RUST:DEBUG] Sending SPAKE2 Confirmation message: Type=2, Len=32
03-30 03:00:45.014 13126 13126 I flutter : [03:00:45] [RUST:DEBUG] Sent ADP Packet: Type=2, Len=32
03-30 03:00:45.015 13126 13126 I flutter : [03:00:45] [RUST:DEBUG] MSG3 sent successfully
03-30 03:00:45.017 13126 13126 I flutter : [03:00:45] [RUST:INFO] Step 4/5: Waiting for HMAC Confirmation (Server)
03-30 03:00:45.019 13126 13126 I flutter : [03:00:45] [RUST:DEBUG] Received ADP Packet: Type=257, Len=8208
03-30 03:00:45.020 13126 13126 I flutter : [03:00:45] [RUST:DEBUG] Step 4: Received message type 257
03-30 03:00:45.023 13126 13126 I flutter : [03:00:45] [RUST:ERROR] Server returned protocol error (257). Raw Payload: 3b35d75fc8f79dc7510e704ec454f4215a49302b166805eea86e7475652ede1802bfeee2c51a7dcb74e90a5a831c6ac5a2470149494d4f40c7c80cfe4abf2bd602166e8c594ebf0bd2e6689624a4915c8bba211dffed73a4b8dcd9308c06e01d8dec5594f7778242e1c57522d1dfaedcb83f14317ecbeacf758bd9d7fa44ab01b776c38ba0fa78940113bde44ba5c2cc93d534f3be6a5be13f1ce5dc22e0842a93e85bd57ee31a4f1b34960ffa0bc57dc5af2ad3a4fa568a1a1eb875c7cb8e1d8d9ef1ef32c722fd1e03fd0f5ef2863ef73b253a4835e22dde01aeeb1d3c906d4bd52d11f87986b6f70579adb58f79f79473fbe521c745f025239c34e8bf1311b3daf89d71aea9804cc4c9374e679e74310fe425b4f23bd35c374eca88b3df9354010da7c34c209e5a0b38d7e10b89c543c31beb74b0c8bac2f55064e69ca26e48de037c08ba614d75bb7aa1d68311fd48981080fbdef24179e172271c99576a91a155706d32733cecf6b323ef700d1dd43701f3046db4d850a802889d539cad6a57628d6c7056be05d1d03a6b70121a820c7fc2f942babc51c28395defa94fd192197a6f743661f9f0f953f3f3c56b3ca9b6948d988c014387351662bcd0b97bc5ab032f4ed912f234c1f36463b1246d3b67ba1724f75ebe897

Error: AnyhowException(Server rejected pairing (Error 257). pairing code salah atau mismatch identity.)
