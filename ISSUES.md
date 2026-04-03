--------- beginning of main
04-03 02:49:06.868  9502 13359 I flutter : [IMPORTANT:flutter/shell/platform/android/android_context_vk_impeller.cc(62)] Using the Impeller rendering backend (Vulkan).
04-03 02:49:07.023  9502 13388 I flutter : The Dart VM service is listening on http://127.0.0.1:34893/nyQ8LPFN6Rk=/
04-03 02:49:08.994  9502  9502 I flutter : [02:49:08] [STELLAR_RUST_X25519] Bridge: Aliran log telah tersambung ke Dart.
04-03 02:49:11.711  9502  9502 I flutter : [02:49:11] DART: Memulai mDNS discovery untuk _adb-tls-pairing._tcp
04-03 02:49:17.771  9502  9502 I flutter : [02:49:17] DART: Layanan ditemukan: adb-7pgqlndalbscukg6-617mqw pada port 39449
04-03 02:49:17.873  9502  9502 I flutter : [02:49:17] DART: Discovery selesai. Port 39449 siap. Menunggu input user...
04-03 02:49:28.493  9502 13587 I flutter : [IMPORTANT:flutter/shell/platform/android/android_context_vk_impeller.cc(62)] Using the Impeller rendering backend (Vulkan).
04-03 02:49:29.565  9502  9502 I flutter : DART BG: lookup isolate...
04-03 02:49:29.571  9502  9502 I flutter : DART BG: payload = 39449
04-03 02:49:29.572  9502  9502 I flutter : DART BG: input = 659894
04-03 02:49:29.574  9502  9502 I flutter : DART BG: sendPort = SendPort
04-03 02:49:29.576  9502  9502 I flutter : DART: Background Isolate mengirim data ke Main Isolate...
04-03 02:49:29.588  9502  9502 I flutter : [02:49:29] DART: Memanggil Rust init_pairing(port: 39449, code: 659894)
04-03 02:49:29.596  9502  9502 I flutter : [02:49:29] [STELLAR_RUST_X25519] Memulai proses pairing X25519 pada 127.0.0.1:39449
04-03 02:49:29.867  9502  9502 I flutter : [02:49:29] [STELLAR_RUST_X25519] TLS X25519 OK
04-03 02:49:29.869  9502  9502 I flutter : [02:49:29] [STELLAR_RUST_X25519] DEBUG: Panjang PIN: 6 bytes
04-03 02:49:29.871  9502  9502 I flutter : [02:49:29] [STELLAR_RUST_X25519] DEBUG: Panjang EKM: 64 bytes
04-03 02:49:29.872  9502  9502 I flutter : [02:49:29] [STELLAR_RUST_X25519] DEBUG: Total Password Byte (Hex): 3635393839349ad1107b44fac44cbf49f46f249cced40f5778c53832bb7a79e4fe037fb2b6051d02f0fb37f8146e4903472f65ebf3f67d92b6be833fe4adcf34aed06f78793b
04-03 02:49:29.874  9502  9502 I flutter : [02:49:29] [STELLAR_RUST_X25519] [STEP 2/3] SPAKE2 Exchange...
04-03 02:49:29.876  9502  9502 I flutter : [02:49:29] [STELLAR_RUST_X25519] DEBUG SPAKE2: Memulai dekompresi titik M dan N
04-03 02:49:29.877  9502  9502 I flutter : [02:49:29] [STELLAR_RUST_X25519] DEBUG SPAKE2: Titik M dan N berhasil didekompresi
04-03 02:49:29.879  9502  9502 I flutter : [02:49:29] [STELLAR_RUST_X25519] DEBUG SPAKE2: MSG1 (outbound) hex: e30793c5961fc1719cfe88c0cdae1a199c53e2d998a9e30fbcf715d7ec3e0d58
04-03 02:49:29.880  9502  9502 I flutter : [02:49:29] [STELLAR_RUST_X25519] [STEP 2/3] MSG1 Terkirim. Menunggu MSG2 (Y*) dari Android...
04-03 02:49:29.882  9502  9502 I flutter : [02:49:29] [STELLAR_RUST_X25519] DEBUG ADB MSG: Terma Header [type: 0, len: 32], hex: 010000000020
04-03 02:49:29.883  9502  9502 I flutter : [02:49:29] [STELLAR_RUST_X25519] DEBUG SPAKE2: MSG2 (inbound/Y*) hex: d9f8df69374d9b12f349d5836ac797fac958765eca54b66889d79e52aebbb23f
04-03 02:49:29.885  9502  9502 I flutter : [02:49:29] [STELLAR_RUST_X25519] DEBUG SPAKE2: Z Point (compressed) hex: a70de763f0220a973f036ae8a6081399e13bf9511b7a036b6f08d3f1163faafc
04-03 02:49:29.887  9502  9502 I flutter : [02:49:29] [STELLAR_RUST_X25519] DEBUG SPAKE2: Transcript Hash (Salt) hex: a6ddc54d06172565c75aebb5dec7f4ecf5f6da33c128342183a6b1296b477dee
04-03 02:49:29.888  9502  9502 I flutter : [02:49:29] [STELLAR_RUST_X25519] DEBUG SPAKE2: Shared Secret (first 16 bytes) hex: 02e2f33b4e01e97d33d0aebcf7a7d335
04-03 02:49:29.889  9502  9502 I flutter : [02:49:29] [STELLAR_RUST_X25519] [STEP 3/3] SPAKE2 Exchange Berhasil!
04-03 02:49:29.891  9502  9502 I flutter : [02:49:29] [STELLAR_RUST_X25519] SPAKE2 X25519 OK
04-03 02:49:29.892  9502  9502 I flutter : [02:49:29] [STELLAR_RUST_X25519] [STEP 3/3] PeerInfo Exchange...

Error AnyhowException(Unknown BoringSSL Error)