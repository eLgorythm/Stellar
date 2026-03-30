use boring::asn1::Asn1Time;
use boring::hash::MessageDigest;
use boring::pkey::PKey;
use boring::rsa::Rsa;
use boring::ssl::{SslConnector, SslMethod, SslVerifyMode};
use boring::x509::{X509, X509Name};
use ring::{hkdf, hmac};
use spake2::{Ed25519Group, Identity, Password, Spake2};
use std::net::SocketAddr;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::TcpStream;
use log::{info, debug, warn, error};
use std::sync::RwLock;
use crate::frb_generated::*;
use prost::Message;
use ring::aead::{self, LessSafeKey, UnboundKey};

#[allow(dead_code)]
const MAX_PAYLOAD: u32 = 4 * 1024 * 1024; // 4MB

/// Message types sesuai AOSP pairing packet header
const MSG_TYPE_EXCHANGE: u32 = 0;      // SPAKE2 Exchange / SPAKE2_MSG
const MSG_TYPE_PEER_INFO: u32 = 1;      // PeerInfo

/// AOSP ADB RSA public key type enum.
#[derive(Clone, Copy, Debug, PartialEq, Eq, ::prost::Enumeration)]
pub enum AdbRsaPubKey {
    Unknown = 0,
    AdbRsaPubKey = 1,
}

/// Protobuf structure untuk PeerInfo sesuai adb_pairing.proto
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct PeerInfo {
    #[prost(string, tag = "1")]
    pub name: ::prost::alloc::string::String,
    #[prost(bytes = "vec", tag = "2")]
    pub public_key: ::prost::alloc::vec::Vec<u8>,
    #[prost(enumeration = "AdbRsaPubKey", tag = "3")]
    pub type_: i32,
}

fn strip_leading_length_prefix(payload: &[u8]) -> Option<&[u8]> {
    if payload.len() < 4 {
        return None;
    }

    let len_be = u32::from_be_bytes(payload[0..4].try_into().unwrap()) as usize;
    if len_be > 0 && len_be <= payload.len() - 4 {
        debug!("Detected big-endian length prefix: {}, slicing payload", len_be);
        return Some(&payload[4..4 + len_be]);
    }

    let len_le = u32::from_le_bytes(payload[0..4].try_into().unwrap()) as usize;
    if len_le > 0 && len_le <= payload.len() - 4 {
        debug!("Detected little-endian length prefix: {}, slicing payload", len_le);
        return Some(&payload[4..4 + len_le]);
    }

    None
}

fn decode_peer_info_payload(payload: &[u8]) -> anyhow::Result<PeerInfo> {
    let prefix_len = payload.len().min(16);
    debug!("Server PeerInfo payload prefix: {}", hex::encode(&payload[..prefix_len]));

    let first_err = match PeerInfo::decode(payload) {
        Ok(peer_info) => return Ok(peer_info),
        Err(err) => err,
    };

    if let Some(stripped) = strip_leading_length_prefix(payload) {
        debug!("Retrying PeerInfo decode after stripping length prefix, stripped_len={}", stripped.len());
        if let Ok(peer_info) = PeerInfo::decode(stripped) {
            return Ok(peer_info);
        }
    }

    let max_scan_offset = payload.len();
    for offset in 1..max_scan_offset {
        let b = payload[offset];
        if matches!(b, 0x0A | 0x12 | 0x18 | 0x1A) {
            if let Ok(peer_info) = PeerInfo::decode(&payload[offset..]) {
                debug!("Found PeerInfo after skipping {} bytes", offset);
                return Ok(peer_info);
            }
        }
    }

    Err(anyhow::anyhow!("Failed to decode PeerInfo: {}", first_err))
}

/// Dekripsi payload menggunakan AES-256-GCM (Kunci Ks untuk Server -> Client)
fn decrypt_payload(key: &[u8], ciphertext: &[u8]) -> anyhow::Result<Vec<u8>> {
    if ciphertext.len() < 16 {
        return Err(anyhow::anyhow!("Ciphertext too short for GCM"));
    }
    // Nonce awal untuk pesan terenkripsi pertama adalah 12 byte nol
    let nonce_bytes = [0u8; 12];
    let nonce = aead::Nonce::assume_unique_for_key(nonce_bytes);
    let unbound_key = UnboundKey::new(&aead::AES_256_GCM, key)
        .map_err(|_| anyhow::anyhow!("Failed to create AEAD key"))?;
    let aead_key = LessSafeKey::new(unbound_key);

    let mut in_out = ciphertext.to_vec();
    let decrypted = aead_key.open_in_place(nonce, aead::Aad::empty(), &mut in_out)
        .map_err(|_| anyhow::anyhow!("AES-GCM decryption failed - check keys"))?;

    Ok(decrypted.to_vec())
}

/// Enkripsi payload menggunakan AES-256-GCM (Kunci Kc untuk Client -> Server)
fn encrypt_payload(key: &[u8], plaintext: &[u8]) -> anyhow::Result<Vec<u8>> {
    let nonce_bytes = [0u8; 12];
    let nonce = aead::Nonce::assume_unique_for_key(nonce_bytes);
    let unbound_key = UnboundKey::new(&aead::AES_256_GCM, key)
        .map_err(|_| anyhow::anyhow!("Failed to create AEAD key"))?;
    let aead_key = LessSafeKey::new(unbound_key);

    let mut in_out = plaintext.to_vec();
    aead_key.seal_in_place_append_tag(nonce, aead::Aad::empty(), &mut in_out)
        .map_err(|_| anyhow::anyhow!("AES-GCM encryption failed"))?;

    Ok(in_out)
}

static LOG_SINK: RwLock<Option<StreamSink<String>>> = RwLock::new(None);

static LOGGER: FlutterLogger = FlutterLogger { _unused: 0 };

struct FlutterLogger {
    _unused: u8,
}

impl log::Log for FlutterLogger {
    fn enabled(&self, _metadata: &log::Metadata) -> bool {
        true
    }

    fn log(&self, record: &log::Record) {
        let msg = format!("[RUST:{}] {}", record.level(), record.args());
        
        // Print ke stdout agar muncul di console 'flutter run'
        println!("{}", msg);

        // Gunakan try_read jika memungkinkan atau pastikan sink ada
        if let Ok(guard) = LOG_SINK.try_read() {
             if let Some(sink) = guard.as_ref() {
                 let _ = sink.add(msg);
             }
        }
    }

    fn flush(&self) {}
}

fn debug_shared_secret(shared_secret: &[u8]) {
    debug!("Shared secret: {}", hex::encode(shared_secret));
}

fn derive_keys(shared_secret: &[u8]) -> anyhow::Result<([u8; 32], [u8; 32])> {
    debug!("Deriving keys: shared_secret_len={} bytes", shared_secret.len());

    // Helper struct agar ring mengizinkan ekstraksi lebih dari 32 byte.
    // Secara default, hkdf::Algorithm sebagai KeyType membatasi output hanya 32 byte.
    struct HkdfOutput(usize);
    impl hkdf::KeyType for HkdfOutput {
        fn len(&self) -> usize { self.0 }
    }

    // Salt kosong sesuai standar ADB
    let salt = hkdf::Salt::new(hkdf::HKDF_SHA256, &[]);
    let prk = salt.extract(shared_secret);

    // Info string HARUS menyertakan null terminator sesuai standar AOSP (sizeof kHkdfInfo)
    let info = b"adb pairing auth\0";
    let info_slices: &[&[u8]] = &[info];

    let okm_generator = prk.expand(info_slices, HkdfOutput(64))
        .map_err(|_| anyhow::anyhow!("HKDF expand failed"))?;
    
    let mut okm = [0u8; 64];
    okm_generator.fill(&mut okm)
        .map_err(|_| anyhow::anyhow!("HKDF fill failed"))?;

    let mut kc = [0u8; 32];
    let mut ks = [0u8; 32];
    kc.copy_from_slice(&okm[0..32]);
    ks.copy_from_slice(&okm[32..64]);
    
    // Log ini sangat penting untuk debug!
    debug!("Kc: {}", hex::encode(&kc));
    debug!("Ks: {}", hex::encode(&ks));
    
    Ok((kc, ks))
}

/// Hitung HMAC-SHA256 untuk konfirmasi pertukaran kunci
fn compute_conf_hmac(key: &[u8], payload: &[u8]) -> anyhow::Result<Vec<u8>> {
    let s_key = hmac::Key::new(hmac::HMAC_SHA256, key);
    let tag = hmac::sign(&s_key, payload);
    Ok(tag.as_ref().to_vec())
}

fn verify_conf_hmac(key: &[u8], payload: &[u8], tag: &[u8]) -> anyhow::Result<()> {
    let s_key = hmac::Key::new(hmac::HMAC_SHA256, key);
    hmac::verify(&s_key, payload, tag)
        .map_err(|_| anyhow::anyhow!("Server confirmation HMAC mismatch"))?;
    Ok(())
}

async fn write_spake2_exchange_message<W: AsyncWriteExt + Unpin>(writer: &mut W, msg_type: u32, payload: &[u8]) -> anyhow::Result<()> {
    debug!("Sending SPAKE2 Exchange: Type={}, Len={}", msg_type, payload.len());
    write_message(writer, msg_type, payload).await?;
    Ok(())
}

async fn write_confirmation_message<W: AsyncWriteExt + Unpin>(writer: &mut W, payload: &[u8]) -> anyhow::Result<()> {
    debug!("Sending SPAKE2 Confirmation message: Type={}, Len={}", MSG_TYPE_EXCHANGE, payload.len());
    write_message(writer, MSG_TYPE_EXCHANGE, payload).await?;
    Ok(())
}

/// Format AOSP PairingPacket: [version: u8][type: u8][payload_size: u32 BE][payload]
async fn write_message<W: AsyncWriteExt + Unpin>(writer: &mut W, msg_type: u32, payload: &[u8]) -> anyhow::Result<()> {
    let msg_type = u8::try_from(msg_type)
        .map_err(|_| anyhow::anyhow!("Message type {} does not fit in a u8", msg_type))?;

    writer.write_u8(1).await?; // version
    writer.write_u8(msg_type).await?;
    writer.write_u32(payload.len() as u32).await?;

    writer.write_all(payload).await?;
    writer.flush().await?;
    
    debug!("Sent AOSP PairingPacket: Type={}, Len={}", msg_type, payload.len());
    Ok(())
}

async fn read_tlp_header<R: AsyncReadExt + Unpin>(reader: &mut R) -> anyhow::Result<[u8; 6]> {
    let mut header = [0u8; 6]; // 1 byte version + 1 byte type + 4 byte payload length
    for i in 0..header.len() {
        reader.read_exact(&mut header[i..i + 1]).await?;
        debug!("TLP header byte[{}] = 0x{:02x}", i, header[i]);
    }
    debug!("Full TLP header: {}", hex::encode(&header));
    Ok(header)
}

/// Membaca paket AOSP PairingPacket: [version: u8][type: u8][payload_size: u32 BE][payload]
async fn read_tlp_packet<R: AsyncReadExt + Unpin>(reader: &mut R) -> anyhow::Result<(u32, Vec<u8>)> {
    let header = read_tlp_header(reader).await?;

    let version = header[0];
    if version != 1 {
        return Err(anyhow::anyhow!("Unsupported PairingPacket version: {}", version));
    }

    let msg_type = header[1] as u32;
    let len = u32::from_be_bytes([header[2], header[3], header[4], header[5]]) as usize;

    debug!("Received AOSP PairingPacket: Type={}, Len={}", msg_type, len);

    let mut payload = vec![0u8; len];
    reader.read_exact(&mut payload).await?;
    
    Ok((msg_type, payload))
}

/// Membaca PeerInfo dari server.
async fn read_peer_info_message<R: AsyncReadExt + Unpin>(reader: &mut R) -> anyhow::Result<Vec<u8>> {
    let (msg_type, payload) = read_tlp_packet(reader).await?;
    debug!("Step 4: Received message type {}", msg_type);

    if msg_type != MSG_TYPE_PEER_INFO {
        return Err(anyhow::anyhow!("Unexpected message type: {}. Expected {} (PeerInfo).", msg_type, MSG_TYPE_PEER_INFO));
    }
    Ok(payload)
}

async fn read_spake2_exchange_message<R: AsyncReadExt + Unpin>(reader: &mut R) -> anyhow::Result<(u32, Vec<u8>)> {
    read_tlp_packet(reader).await
}

fn generate_credentials() -> anyhow::Result<(PKey<boring::pkey::Private>, X509)> {
    debug!("Generating RSA 2048 keys and X509 certificate...");
    let rsa = Rsa::generate(2048)?;
    let priv_key = PKey::from_rsa(rsa)?;

    let mut x509 = X509::builder()?;
    x509.set_version(2)?;
    x509.set_not_before(Asn1Time::days_from_now(0)?.as_ref())?;
    x509.set_not_after(Asn1Time::days_from_now(365)?.as_ref())?;
    x509.set_pubkey(&priv_key)?;

    // Set Subject Name agar muncul sebagai "Stellar" di list pairing Android
    let mut name = X509Name::builder()?;
    name.append_entry_by_text("CN", "Stellar")?;
    let x509_name = name.build();
    x509.set_subject_name(&x509_name)?;
    x509.set_issuer_name(&x509_name)?;

    x509.sign(&priv_key, MessageDigest::sha256())?;

    Ok((priv_key, x509.build()))
}

pub fn init_logger(sink: StreamSink<String>) {
    if let Ok(mut sink_guard) = LOG_SINK.write() {
        *sink_guard = Some(sink);
    }

    // Set logger hanya jika belum ada logger lain yang aktif
    let _ = log::set_logger(&LOGGER);
    log::set_max_level(log::LevelFilter::Debug);

    info!("Rust logger initialized via StreamSink");
}

pub async fn init_pairing(port: u16, pairing_code: String) -> anyhow::Result<String> {
    let pairing_code = pairing_code.trim();
    info!("init_pairing dimulai: port={}, code={}", port, pairing_code);

    // 1. Generate sertifikat untuk identitas Stellar
    let (priv_key, cert) = tokio::task::spawn_blocking(generate_credentials)
        .await.map_err(|e| anyhow::anyhow!("Spawn blocking error: {}", e))??;
    info!("Generated self-signed certificate and private key");

    // 2. Setup BoringSSL
    let mut builder = SslConnector::builder(SslMethod::tls())?;
    builder.set_verify(SslVerifyMode::NONE);
    builder.set_certificate(&cert)?;
    builder.set_private_key(&priv_key)?;
    builder.set_cipher_list("ECDHE-RSA-CHACHA20-POLY1305:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384")?;
    let connector = builder.build();
    let config = connector.configure()?;

    let addr: SocketAddr = format!("127.0.0.1:{}", port).parse()?;
    info!("Connecting to {}", addr);
    let stream = TcpStream::connect(addr).await?;

    info!("Starting TLS Handshake...");
    match tokio_boring::connect(config, "localhost", stream).await {
        Ok(mut ssl_stream) => {
            // Gunakan stream TLS sebagai satu kesatuan untuk membaca dan menulis.
            // Split pada SslStream dapat memperkenalkan fragmentasi internal yang salah.

            // --- TAHAP SPAKE2 ---
            // Identitas HARUS sesuai standar AOSP pairing_connection.cpp
            // Menambahkan \0 karena AOSP menggunakan sizeof() yang menyertakan null terminator
            let (state, msg1_data) = Spake2::<Ed25519Group>::start_a(
                &Password::new(pairing_code.as_bytes()),
                &Identity::new(b"adb pair client\0"),
                &Identity::new(b"adb pair server\0"),
            );

            // Crate spake2 menghasilkan 33 bytes: [prefix (1 byte), point (32 bytes)]
            // Protokol ADB mengharapkan tepat 32 bytes (raw point).
            let (my_prefix, msg1_payload_to_send) = (msg1_data[0], &msg1_data[1..]);
            if msg1_data.len() != 33 {
                return Err(anyhow::anyhow!("Unexpected MSG1 size from spake2: expected 33, got {}", msg1_data.len()));
            }
            debug!("MSG1 prefix = {}, payload size = {}", my_prefix, msg1_payload_to_send.len());
            debug!("MSG1 payload to send: {}", hex::encode(msg1_payload_to_send));

            // MSG1: Client Hello (Exchange)
            info!("Step 1/5: Sending SPAKE2 Exchange (Client)");
            write_spake2_exchange_message(&mut ssl_stream, MSG_TYPE_EXCHANGE, msg1_payload_to_send).await?;

            // MSG2: Menerima Server Public Value
            info!("Step 2/5: Waiting for SPAKE2 Exchange (Server)");
            let (m_type, msg2_payload) = tokio::time::timeout(
                tokio::time::Duration::from_secs(5), 
                read_spake2_exchange_message(&mut ssl_stream)
            ).await.map_err(|_| anyhow::anyhow!("Timeout waiting for SPAKE2 Exchange (MSG2)"))??;

            if m_type != MSG_TYPE_EXCHANGE {
                return Err(anyhow::anyhow!("Unexpected message type during exchange: {}", m_type));
            }
            debug!("Received MSG2 payload length: {}", msg2_payload.len());
            debug!("MSG2 payload raw: {}", hex::encode(&msg2_payload));

            // --- TAHAP KRIPTOGRAFI (HKDF & HMAC) ---
            // The finish() method expects the peer's message to have the opposite SPAKE2 prefix.
            let peer_prefix = match my_prefix {
                0 => 1u8,
                1 => 0u8,
                b'A' => b'B',
                b'B' => b'A',
                other => return Err(anyhow::anyhow!("Unexpected SPAKE2 prefix byte: {}", other)),
            };

            let msg2_spake_for_finish = if msg2_payload.len() == 33 && (msg2_payload[0] == b'A' || msg2_payload[0] == b'B' || msg2_payload[0] == b'S' || msg2_payload[0] <= 1) {
                debug!("Received MSG2 with explicit SPAKE2 prefix: {}", msg2_payload[0]);
                msg2_payload.clone()
            } else if msg2_payload.len() == 32 {
                let mut buf = Vec::with_capacity(33);
                buf.push(peer_prefix);
                buf.extend_from_slice(&msg2_payload);
                debug!("Prepend peer prefix {} to MSG2 payload", peer_prefix);
                buf
            } else {
                return Err(anyhow::anyhow!("Unexpected SPAKE2 MSG2 payload length: {}", msg2_payload.len()));
            };

            let shared_secret = state.finish(&msg2_spake_for_finish)
                .map_err(|e| anyhow::anyhow!("SPAKE2 finish error: {:?}", e))?;

            debug!("SPAKE2 shared secret generated, length: {}", shared_secret.len());
            debug_shared_secret(&shared_secret);
            
            let (kc, ks) = derive_keys(&shared_secret)?;

            // Konstruksi Payload HMAC (MSG1 || MSG2)
            // Android menggabungkan (concatenate) pertukaran pesan sebelumnya untuk validasi
            let mut hmac_input = Vec::with_capacity(64);
            hmac_input.extend_from_slice(msg1_payload_to_send); // 32 bytes
            hmac_input.extend_from_slice(&msg2_payload);       // 32 bytes
            
            // MSG3: Kirim HMAC konfirmasi client
            let msg3_data = compute_conf_hmac(&kc, &hmac_input)?;
            info!("Step 3/6: Sending HMAC Confirmation (Client)");
            debug!("Computed MSG3 confirmation HMAC: {}", hex::encode(&msg3_data));
            write_confirmation_message(&mut ssl_stream, &msg3_data).await?;
            debug!("MSG3 sent successfully");

            // MSG4: Menerima respons server
            info!("Step 4/6: Waiting for server response");
            let (next_type, next_payload) = tokio::time::timeout(
                tokio::time::Duration::from_secs(5),
                read_tlp_packet(&mut ssl_stream)
            ).await.map_err(|_| anyhow::anyhow!("Timeout waiting for server response"))??;

            let server_peer_info_payload = match next_type {
                MSG_TYPE_EXCHANGE => {
                    if next_payload.len() != 32 {
                        return Err(anyhow::anyhow!("Unexpected server confirmation length: {}", next_payload.len()));
                    }
                    debug!("Received server confirmation HMAC packet");
                    verify_conf_hmac(&ks, &hmac_input, &next_payload)?;
                    info!("Server confirmation verified");

                    info!("Step 5/6: Waiting for PeerInfo (Server)");
                    tokio::time::timeout(
                        tokio::time::Duration::from_secs(5),
                        read_peer_info_message(&mut ssl_stream)
                    ).await.map_err(|_| anyhow::anyhow!("Timeout waiting for PeerInfo"))??
                }
                MSG_TYPE_PEER_INFO => {
                    debug!("Received PeerInfo directly after client confirmation");
                    next_payload
                }
                other => {
                    return Err(anyhow::anyhow!("Unexpected packet type after client confirmation: {}", other));
                }
            };

            // Logika Dekripsi dengan penanganan padding TLP
            // adbd sering mengirimkan buffer 8192 byte + 16 byte tag = 8208.
            let decrypted_server_payload = match decrypt_payload(&ks, &server_peer_info_payload) {
                Ok(data) => data,
                Err(e) => {
                    // Jika gagal, coba potong payload tepat ke 8208 jika server mengirim lebih
                    if server_peer_info_payload.len() > 8208 {
                        debug!("Payload too long ({}), truncating to 8208 for retry", server_peer_info_payload.len());
                        decrypt_payload(&ks, &server_peer_info_payload[..8208])
                            .map_err(|_| anyhow::anyhow!("AES-GCM decryption failed after truncation: {}", e))?
                    } else {
                        debug!("Decryption with Ks failed ({}), trying Kc as fallback...", e);
                        decrypt_payload(&kc, &server_peer_info_payload)
                            .map_err(|_| anyhow::anyhow!("AES-GCM decryption failed with both keys. Shared secret or HKDF info mismatch."))?
                    }
                }
            };
            debug!("Decrypted server PeerInfo successfully, len: {}", decrypted_server_payload.len());

            let server_peer_info = match decode_peer_info_payload(&decrypted_server_payload) {
                Ok(info) => {
                    info!("Received server PeerInfo: name={}, type={}, public_key_len={}",
                        info.name,
                        info.type_,
                        info.public_key.len());
                    Some(info)
                }
                Err(e) => {
                    warn!("Failed to decode server PeerInfo, continuing anyway: {}", e);
                    None
                }
            };

            // --- TAHAP MSG5: PeerInfo (Wrapped Public Key) ---
            info!("Step 5/5: Sending PeerInfo (Protobuf)");
            
            let pub_key_der = cert.public_key()?.public_key_to_der()?;
            let peer_info = PeerInfo {
                name: "Stellar".to_string(),
                public_key: pub_key_der,
                type_: 1, // ADB_RSA_PUB_KEY (0x01)
            };
            
            let mut peer_info_bin = Vec::new();
            peer_info.encode(&mut peer_info_bin)?;

            // Enkripsi PeerInfo client sebelum dikirim menggunakan kunci Kc
            let encrypted_client_payload = encrypt_payload(&kc, &peer_info_bin)?;
            write_message(&mut ssl_stream, MSG_TYPE_PEER_INFO, &encrypted_client_payload).await?;

            // Jeda agar adbd sempat memproses MSG5 sebelum socket ditutup
            tokio::time::sleep(tokio::time::Duration::from_millis(500)).await;

            info!("Pairing complete. Android dialog should close now.");
            Ok(format!("Pairing sukses! 'Stellar' sekarang terdaftar di perangkat."))
        }
        Err(e) => {
            error!("TLS Handshake Error: {}", e);
            Err(anyhow::anyhow!("TLS Handshake Error: {}", e))
        }
    }
}

pub async fn execute_adb_command(command: String) -> anyhow::Result<String> {
    Ok(format!("Output dari: {}", command))
}