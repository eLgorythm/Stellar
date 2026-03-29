--------- beginning of main
03-30 00:14:34.840 14666 25226 I flutter : [IMPORTANT:flutter/shell/platform/android/android_context_vk_impeller.cc(62)] Using the Impeller rendering backend (Vulkan).
03-30 00:14:35.006 14666 25245 I flutter : The Dart VM service is listening on http://127.0.0.1:40147/f9d_S4aHvxk=/
03-30 00:14:37.258 14666 14666 I flutter : [00:14:37] [RUST:INFO] Rust logger initialized via StreamSink
03-30 00:14:37.262 14666 14666 I flutter : [00:14:37] [RUST:INFO] Bridge: Aliran log telah tersambung ke Dart.
03-30 00:14:40.095 14666 14666 I flutter : [00:14:40] DART: Memulai mDNS discovery untuk _adb-tls-pairing._tcp
03-30 00:14:49.898 14666 14666 I flutter : [00:14:49] DART: Layanan ditemukan: adb-7pgqlndalbscukg6-617mqw pada port 36723
03-30 00:14:49.995 14666 14666 I flutter : [00:14:49] DART: Discovery selesai. Port 36723 siap. Menunggu input user...
03-30 00:15:00.735 14666 25508 I flutter : [IMPORTANT:flutter/shell/platform/android/android_context_vk_impeller.cc(62)] Using the Impeller rendering backend (Vulkan).
03-30 00:15:01.842 14666 14666 I flutter : DART BG: lookup isolate...
03-30 00:15:01.847 14666 14666 I flutter : DART BG: payload = 36723
03-30 00:15:01.847 14666 14666 I flutter : DART BG: input = 635928
03-30 00:15:01.848 14666 14666 I flutter : DART BG: sendPort = SendPort
03-30 00:15:01.849 14666 14666 I flutter : DART: Background Isolate mengirim data ke Main Isolate...
03-30 00:15:01.862 14666 14666 I flutter : [00:15:01] DART: Memanggil Rust init_pairing(port: 36723, code: 635928)
03-30 00:15:01.872 14666 14666 I flutter : [00:15:01] [RUST:INFO] init_pairing dimulai: port=36723, code=635928
03-30 00:15:01.873 14666 14666 I flutter : [00:15:01] [RUST:DEBUG] Generating RSA 2048 keys and X509 certificate...
03-30 00:15:02.862 14666 14666 I flutter : [00:15:02] [RUST:INFO] Generated self-signed certificate and private key
03-30 00:15:02.864 14666 14666 I flutter : [00:15:02] [RUST:INFO] Connecting to 127.0.0.1:36723
03-30 00:15:02.865 14666 14666 I flutter : [00:15:02] [RUST:INFO] Starting TLS Handshake...
03-30 00:15:02.888 14666 14666 I flutter : [00:15:02] [RUST:DEBUG] MSG1 prefix = 65, payload size = 32
03-30 00:15:02.889 14666 14666 I flutter : [00:15:02] [RUST:DEBUG] MSG1 payload to send: b8c10e2ac23531b6694479f9bc3f9946b26af869761c452fafc4964633f1660a
03-30 00:15:02.891 14666 14666 I flutter : [00:15:02] [RUST:INFO] Step 1/5: Sending SPAKE2 Exchange (Client)
03-30 00:15:02.892 14666 14666 I flutter : [00:15:02] [RUST:DEBUG] Sending SPAKE2 Exchange message: Type=1, Len=32
03-30 00:15:02.894 14666 14666 I flutter : [00:15:02] [RUST:DEBUG] Sent variable-length message: Type=1, Len=32, Payload=b8c10e2ac23531b6694479f9bc3f9946b26af869761c452fafc4964633f1660a
03-30 00:15:02.895 14666 14666 I flutter : [00:15:02] [RUST:INFO] Step 2/5: Waiting for SPAKE2 Exchange (Server)
03-30 00:15:02.896 14666 14666 I flutter : [00:15:02] [RUST:DEBUG] Read message header for SPAKE2 Exchange: Type=1
03-30 00:15:02.897 14666 14666 I flutter : [00:15:02] [RUST:DEBUG] Detected 2-byte BE length prefix: 32, read payload
03-30 00:15:02.899 14666 14666 I flutter : [00:15:02] [RUST:DEBUG] Received MSG2 payload length: 32
03-30 00:15:02.900 14666 14666 I flutter : [00:15:02] [RUST:DEBUG] MSG2 payload raw: 4c28284a1c03c56c85e37eba324691bb08d952cafd90cd7b8c359073751d78e0
03-30 00:15:02.901 14666 14666 I flutter : [00:15:02] [RUST:DEBUG] Processing MSG2 by prepending peer prefix: 66
03-30 00:15:02.902 14666 14666 I flutter : [00:15:02] [RUST:INFO] Step 3/5: Sending HMAC Confirmation (Client)
03-30 00:15:02.903 14666 14666 I flutter : [00:15:02] [RUST:DEBUG] Computed MSG3 confirmation HMAC: ddfd91e3b6c802dff2b313c2bdfc41b602cf3439ca3eff56e5c441d463b080b8
03-30 00:15:02.904 14666 14666 I flutter : [00:15:02] [RUST:DEBUG] Preparing to send SPAKE2 Confirmation message: Type=2, Len=32, Payload=ddfd91e3b6c802dff2b313c2bdfc41b602cf3439ca3eff56e5c441d463b080b8
03-30 00:15:02.905 14666 14666 I flutter : [00:15:02] [RUST:DEBUG] write_confirmation_message: wrote MSG_TYPE_CONFIRMATION
03-30 00:15:02.907 14666 14666 I flutter : [00:15:02] [RUST:DEBUG] write_confirmation_message: wrote payload length 32
03-30 00:15:02.908 14666 14666 I flutter : [00:15:02] [RUST:DEBUG] write_confirmation_message: wrote payload bytes
03-30 00:15:02.909 14666 14666 I flutter : [00:15:02] [RUST:DEBUG] Sent SPAKE2 Confirmation message: Type=2, Len=32, Payload=ddfd91e3b6c802dff2b313c2bdfc41b602cf3439ca3eff56e5c441d463b080b8
03-30 00:15:02.910 14666 14666 I flutter : [00:15:02] [RUST:DEBUG] MSG3 sent successfully
03-30 00:15:02.912 14666 14666 I flutter : [00:15:02] [RUST:INFO] Step 4/5: Waiting for HMAC Confirmation (Server)

Error: AnyhowException(Timeout waiting for MSG4).