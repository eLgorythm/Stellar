--------- beginning of main
03-30 22:29:44.500 32703 32703 I flutter : [22:29:44] [RUST:INFO] Connecting to 127.0.0.1:35289
03-30 22:29:44.503 32703 32703 I flutter : [22:29:44] [RUST:INFO] Starting TLS Handshake...
03-30 22:29:44.523 32703 32703 I flutter : [22:29:44] [RUST:DEBUG] MSG1 prefix = 65, payload size = 32
03-30 22:29:44.524 32703 32703 I flutter : [22:29:44] [RUST:DEBUG] MSG1 payload to send: e58c8352f0949d57d4c8c2be4498a8950964918d85224eb48436a1e45f227856
03-30 22:29:44.527 32703 32703 I flutter : [22:29:44] [RUST:INFO] Step 1/5: Sending SPAKE2 Exchange (Client)
03-30 22:29:44.530 32703 32703 I flutter : [22:29:44] [RUST:DEBUG] Sending SPAKE2 Exchange: Type=0, Len=32
03-30 22:29:44.533 32703 32703 I flutter : [22:29:44] [RUST:DEBUG] Sent AOSP PairingPacket: Type=0, Len=32
03-30 22:29:44.536 32703 32703 I flutter : [22:29:44] [RUST:INFO] Step 2/5: Waiting for SPAKE2 Exchange (Server)
03-30 22:29:44.538 32703 32703 I flutter : [22:29:44] [RUST:DEBUG] TLP header byte[0] = 0x01
03-30 22:29:44.542 32703 32703 I flutter : [22:29:44] [RUST:DEBUG] TLP header byte[1] = 0x00
03-30 22:29:44.543 32703 32703 I flutter : [22:29:44] [RUST:DEBUG] TLP header byte[2] = 0x00
03-30 22:29:44.544 32703 32703 I flutter : [22:29:44] [RUST:DEBUG] TLP header byte[3] = 0x00
03-30 22:29:44.553 32703 32703 I flutter : [22:29:44] [RUST:DEBUG] TLP header byte[4] = 0x00
03-30 22:29:44.554 32703 32703 I flutter : [22:29:44] [RUST:DEBUG] TLP header byte[5] = 0x20
03-30 22:29:44.556 32703 32703 I flutter : [22:29:44] [RUST:DEBUG] Full TLP header: 010000000020
03-30 22:29:44.557 32703 32703 I flutter : [22:29:44] [RUST:DEBUG] Received AOSP PairingPacket: Type=0, Len=32
03-30 22:29:44.563 32703 32703 I flutter : [22:29:44] [RUST:DEBUG] Received MSG2 payload length: 32
03-30 22:29:44.564 32703 32703 I flutter : [22:29:44] [RUST:DEBUG] MSG2 payload raw: 2cd36018c3baadcbe68ed2b432216c7489d98931c6befe5bad35a7646b0c2c3d
03-30 22:29:44.566 32703 32703 I flutter : [22:29:44] [RUST:DEBUG] Processing MSG2 by prepending peer prefix: 66
03-30 22:29:44.567 32703 32703 I flutter : [22:29:44] [RUST:DEBUG] SPAKE2 shared secret generated, length: 32
03-30 22:29:44.571 32703 32703 I flutter : [22:29:44] [RUST:DEBUG] Shared secret: 0b6ff750ef7c12003a5f21fea87b55375192495fa38669ec31b2e17a859d85ef
03-30 22:29:44.572 32703 32703 I flutter : [22:29:44] [RUST:DEBUG] Deriving keys: shared_secret_len=32 bytes
03-30 22:29:44.573 32703 32703 I flutter : [22:29:44] [RUST:DEBUG] Kc: 48be046f0ae0c9a2bb3ee67f8ed9b7c504bbb505deb072583fdb850f94d8fce9
03-30 22:29:44.575 32703 32703 I flutter : [22:29:44] [RUST:DEBUG] Ks: 9f75709324ccdc4491d8b7ce3b5ea2cd742f86e9d103067239b5f176e26099cf
03-30 22:29:44.603 32703 32703 I flutter : [22:29:44] [RUST:INFO] Step 3/6: Sending HMAC Confirmation (Client)
03-30 22:29:44.606 32703 32703 I flutter : [22:29:44] [RUST:DEBUG] Computed MSG3 confirmation HMAC: d4223631a2495379523032a446bd13b0aabe96f7f21f9cf5d1473d6275a62be3
03-30 22:29:44.608 32703 32703 I flutter : [22:29:44] [RUST:DEBUG] Sending SPAKE2 Confirmation message: Type=0, Len=32
03-30 22:29:44.610 32703 32703 I flutter : [22:29:44] [RUST:DEBUG] Sent AOSP PairingPacket: Type=0, Len=32
03-30 22:29:44.612 32703 32703 I flutter : [22:29:44] [RUST:DEBUG] MSG3 sent successfully
03-30 22:29:44.614 32703 32703 I flutter : [22:29:44] [RUST:INFO] Step 4/6: Waiting for server response
03-30 22:29:44.617 32703 32703 I flutter : [22:29:44] [RUST:DEBUG] TLP header byte[0] = 0x01
03-30 22:29:44.619 32703 32703 I flutter : [22:29:44] [RUST:DEBUG] TLP header byte[1] = 0x01
03-30 22:29:44.621 32703 32703 I flutter : [22:29:44] [RUST:DEBUG] TLP header byte[2] = 0x00
03-30 22:29:44.625 32703 32703 I flutter : [22:29:44] [RUST:DEBUG] TLP header byte[3] = 0x00
03-30 22:29:44.629 32703 32703 I flutter : [22:29:44] [RUST:DEBUG] TLP header byte[4] = 0x20
03-30 22:29:44.631 32703 32703 I flutter : [22:29:44] [RUST:DEBUG] TLP header byte[5] = 0x10
03-30 22:29:44.633 32703 32703 I flutter : [22:29:44] [RUST:DEBUG] Full TLP header: 010100002010
03-30 22:29:44.635 32703 32703 I flutter : [22:29:44] [RUST:DEBUG] Received AOSP PairingPacket: Type=1, Len=8208
03-30 22:29:44.638 32703 32703 I flutter : [22:29:44] [RUST:DEBUG] Received PeerInfo directly after client confirmation
03-30 22:29:44.639 32703 32703 I flutter : [22:29:44] [RUST:DEBUG] Received server PeerInfo payload: 8208 bytes
03-30 22:29:44.641 32703 32703 I flutter : [22:29:44] [RUST:DEBUG] Server PeerInfo payload prefix: eaf97f4e9a462ac22cf0619bed840c8c
03-30 22:29:44.643 32703 32703 I flutter : [22:29:44] [RUST:WARN] Failed to decode server PeerInfo, continuing anyway: Failed to decode PeerInfo: failed to decode Protobuf message: invalid key value: 2193171814012

Error: AnyhowException(Server confirmation HMAC mismatch)