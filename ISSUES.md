03-29 22:39:25.924 12877 12877 I flutter : [22:39:25] DART: Memulai mDNS discovery untuk _adb-tls-pairing._tcp
03-29 22:39:29.910 12877 12877 I flutter : [22:39:29] DART: Layanan ditemukan: adb-7pgqlndalbscukg6-617mqw pada port 34757
03-29 22:39:29.989 12877 12877 I flutter : [22:39:29] DART: Discovery selesai. Port 34757 siap. Menunggu input user...
03-29 22:39:37.785 12877 12877 I flutter : DART BG: lookup isolate...
03-29 22:39:37.794 12877 12877 I flutter : DART BG: payload = 34757
03-29 22:39:37.799 12877 12877 I flutter : DART BG: input = 483684
03-29 22:39:37.800 12877 12877 I flutter : DART BG: sendPort = SendPort
03-29 22:39:37.801 12877 12877 I flutter : DART: Background Isolate mengirim data ke Main Isolate...
03-29 22:39:37.815 12877 12877 I flutter : [22:39:37] DART: Memanggil Rust init_pairing(port: 34757, code: 483684)
03-29 22:39:37.827 12877 12877 I flutter : [22:39:37] [RUST:INFO] init_pairing dimulai: port=34757, code=483684
03-29 22:39:37.898 12877 12877 I flutter : [22:39:37] [RUST:DEBUG] Generating RSA 2048 keys and X509 certificate...
03-29 22:39:38.513 12877 12877 I flutter : [22:39:38] [RUST:INFO] Generated self-signed certificate and private key
03-29 22:39:38.515 12877 12877 I flutter : [22:39:38] [RUST:INFO] Connecting to 127.0.0.1:34757
03-29 22:39:38.522 12877 12877 I flutter : [22:39:38] [RUST:INFO] Starting TLS Handshake...
03-29 22:39:38.545 12877 12877 I flutter : [22:39:38] [RUST:DEBUG] MSG1 prefix = 65, payload size = 32
03-29 22:39:38.547 12877 12877 I flutter : [22:39:38] [RUST:INFO] Step 1/5: Sending SPAKE2 Exchange (Client)
03-29 22:39:38.550 12877 12877 I flutter : [22:39:38] [RUST:DEBUG] Sent SPAKE2 Exchange message: Type=1, Len=32, Payload=f3dcccfb9074efb9c223b64f590903a5ec7b6f771b5a51d329ab72fdca8aedd0
03-29 22:39:38.552 12877 12877 I flutter : [22:39:38] [RUST:INFO] Step 2/5: Waiting for SPAKE2 Exchange (Server)
03-29 22:39:38.553 12877 12877 I flutter : [22:39:38] [RUST:DEBUG] Read message header for SPAKE2 Exchange: Type=1
03-29 22:39:38.557 12877 12877 I flutter : [22:39:38] [RUST:DEBUG] Read raw SPAKE2 Exchange payload by exact read: 32 bytes, Payload=002072123065961226ec2f82b0e0179e54f0bc1a26c0a05a0c7e3f5342fff7f8
03-29 22:39:38.558 12877 12877 I flutter : [22:39:38] [RUST:DEBUG] Processing MSG2 by prepending peer prefix: 66
03-29 22:39:38.559 12877 12877 I flutter : [22:39:38] [RUST:INFO] Step 3/5: Sending HMAC Confirmation (Client)


Error: AnyhowException(Broken pipe(os error 32))