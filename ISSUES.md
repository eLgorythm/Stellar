03-29 23:29:25.836  5355  5355 I flutter : [23:29:25] DART: Discovery selesai. Port 45787 siap. Menunggu input user...
03-29 23:29:32.980  5355  5355 I flutter : DART BG: lookup isolate...
03-29 23:29:32.988  5355  5355 I flutter : DART BG: payload = 45787
03-29 23:29:33.000  5355  5355 I flutter : DART BG: input = 999835
03-29 23:29:33.001  5355  5355 I flutter : DART BG: sendPort = SendPort
03-29 23:29:33.004  5355  5355 I flutter : DART: Background Isolate mengirim data ke Main Isolate...
03-29 23:29:33.022  5355  5355 I flutter : [23:29:33] DART: Memanggil Rust init_pairing(port: 45787, code: 999835)
03-29 23:29:33.030  5355  5355 I flutter : [23:29:33] [RUST:INFO] init_pairing dimulai: port=45787, code=999835
03-29 23:29:33.042  5355  5355 I flutter : [23:29:33] [RUST:DEBUG] Generating RSA 2048 keys and X509 certificate...
03-29 23:29:33.750  5355  5355 I flutter : [23:29:33] [RUST:INFO] Generated self-signed certificate and private key
03-29 23:29:33.753  5355  5355 I flutter : [23:29:33] [RUST:INFO] Connecting to 127.0.0.1:45787
03-29 23:29:33.755  5355  5355 I flutter : [23:29:33] [RUST:INFO] Starting TLS Handshake...
03-29 23:29:33.781  5355  5355 I flutter : [23:29:33] [RUST:DEBUG] MSG1 prefix = 65, payload size = 32
03-29 23:29:33.783  5355  5355 I flutter : [23:29:33] [RUST:DEBUG] MSG1 payload to send: 183fd7a4d121c57dfa655b5d6e23cda48cdc7782e1321f6dd22bd01c4daec742
03-29 23:29:33.787  5355  5355 I flutter : [23:29:33] [RUST:INFO] Step 1/5: Sending SPAKE2 Exchange (Client)
03-29 23:29:33.788  5355  5355 I flutter : [23:29:33] [RUST:DEBUG] Sent SPAKE2 Exchange message: Type=1, Len=32, Payload=183fd7a4d121c57dfa655b5d6e23cda48cdc7782e1321f6dd22bd01c4daec742
03-29 23:29:33.790  5355  5355 I flutter : [23:29:33] [RUST:INFO] Step 2/5: Waiting for SPAKE2 Exchange (Server)
03-29 23:29:33.793  5355  5355 I flutter : [23:29:33] [RUST:DEBUG] Read message header for SPAKE2 Exchange: Type=1
03-29 23:29:33.794  5355  5355 I flutter : [23:29:33] [RUST:DEBUG] Read raw SPAKE2 Exchange payload by exact read: 32 bytes, Payload=0020025a36bff97c2972d92c7258244d2bb3652fb1e7cbf67d90f099c04f95de
03-29 23:29:33.795  5355  5355 I flutter : [23:29:33] [RUST:DEBUG] Received MSG2 payload length: 32
03-29 23:29:33.796  5355  5355 I flutter : [23:29:33] [RUST:DEBUG] MSG2 payload raw: 0020025a36bff97c2972d92c7258244d2bb3652fb1e7cbf67d90f099c04f95de
03-29 23:29:33.798  5355  5355 I flutter : [23:29:33] [RUST:DEBUG] Processing MSG2 by prepending peer prefix: 66
03-29 23:29:33.800  5355  5355 I flutter : [23:29:33] [RUST:INFO] Step 3/5: Sending HMAC Confirmation (Client)
03-29 23:29:33.801  5355  5355 I flutter : [23:29:33] [RUST:DEBUG] Computed MSG3 confirmation HMAC: 11d490f07f24a1da221495a8d673ef40316178de1ee8cb93764456c61a5fafa7
03-29 23:29:33.803  5355  5355 I flutter : [23:29:33] [RUST:DEBUG] Preparing to send SPAKE2 Confirmation message: Type=2, Len=32, Payload=11d490f07f24a1da221495a8d673ef40316178de1ee8cb93764456c61a5fafa7
03-29 23:29:33.804  5355  5355 I flutter : [23:29:33] [RUST:DEBUG] write_confirmation_message: wrote MSG_TYPE_CONFIRMATION
03-29 23:29:33.805  5355  5355 I flutter : [23:29:33] [RUST:DEBUG] write_confirmation_message: wrote payload length 32
03-29 23:29:33.807  5355  5355 I flutter : [23:29:33] [RUST:DEBUG] write_confirmation_message: wrote payload bytes
03-29 23:29:33.810  5355  5355 I flutter : [23:29:33] [RUST:DEBUG] Sent SPAKE2 Confirmation message: Type=2, Len=32, Payload=11d490f07f24a1da221495a8d673ef40316178de1ee8cb93764456c61a5fafa7
03-29 23:29:33.811  5355  5355 I flutter : [23:29:33] [RUST:DEBUG] MSG3 sent successfully
03-29 23:29:33.812  5355  5355 I flutter : [23:29:33] [RUST:INFO] Step 4/5: Waiting for HMAC Confirmation (Server)

Error: AnyhowException(Timeout waiting for MSG4).