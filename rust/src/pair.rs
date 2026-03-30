use boring::asn1::Asn1Time;
use boring::hash::MessageDigest;
use boring::pkey::PKey;
use boring::rsa::Rsa;
use boring::ssl::{SslConnector, SslMethod, SslVerifyMode};
use boring::x509::{X509, X509Name};
use ring::{hkdf, hmac};
use spake2::{Ed25519Group, Identity, Password, Spake2};
use std::net::SocketAddr;
use tokio::io::{AsyncReadExt, AsyncBufRead, AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::net::TcpStream;
use log::{info, debug, error};
use std::sync::RwLock;
use crate::frb_generated::*;
use prost::Message;

#[allow(dead_code)]
const MAX_PAYLOAD: u32 = 4 * 1024 * 1024; // 4MB

/// Message types sesuai PairingConnection.h AOSP
const MSG_TYPE_EXCHANGE: u32 = 1;      // SPAKE2 Exchange
const MSG_TYPE_CONFIRMATION: u32 = 2;   // SPAKE2 Confirmation (HMAC)
const MSG_TYPE_PEER_INFO: u32 = 3;      // Protobuf PeerInfo

/// Protobuf structure untuk PeerInfo sesuai adb_pairing.proto
#[derive(Clone, PartialEq, ::prost::Message)]
pub struct PeerInfo {
    #[prost(string, tag = "1")]
    pub name: ::prost::alloc::string::String,
    #[prost(bytes = "vec", tag = "2")]
    pub public_key: ::prost::alloc::vec::Vec<u8>,
    #[prost(int32, tag = "3")]
    pub type_: i32,
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

fn derive_keys(shared_secret: &[u8]) -> anyhow::Result<([u8; 32], [u8; 32])> {
    use ring::hkdf;

    debug!("Deriving keys: shared_secret_len={} bytes", shared_secret.len());

    // Helper struct agar ring mengizinkan ekstraksi lebih dari 32 byte.
    // Secara default, hkdf::Algorithm sebagai KeyType membatasi output hanya 32 byte.
    struct HkdfOutput(usize);
    impl hkdf::KeyType for HkdfOutput {
        fn len(&self) -> usize { self.0 }
    }

    let salt = hkdf::Salt::new(hkdf::HKDF_SHA256, &[]);
    let prk = salt.extract(shared_secret);
    
    // Menggunakan null terminator
    let info: &[&[u8]] = &[b"adb pairing auth"];
    
    // Minta 64 byte: 32 byte pertama untuk Kc (Client), 32 byte kedua untuk Ks (Server)
    let okm_generator = prk.expand(info, HkdfOutput(64))
        .map_err(|_| anyhow::anyhow!("HKDF expand failed: invalid info or secret"))?;
    
    let mut okm = [0u8; 64];
    okm_generator.fill(&mut okm)
        .map_err(|_| anyhow::anyhow!("HKDF fill failed: could not generate 64 bytes"))?;

    let mut kc = [0u8; 32]; // Client Key
    let mut ks = [0u8; 32]; // Server Key
    kc.copy_from_slice(&okm[0..32]);
    ks.copy_from_slice(&okm[32..64]);
    
    debug!("Keys derived: Kc={}..., Ks={}...", hex::encode(&kc[..4]), hex::encode(&ks[..4]));
    
    Ok((kc, ks))
}

/// Hitung HMAC-SHA256 untuk konfirmasi pertukaran kunci
fn compute_conf_hmac(key: &[u8], payload: &[u8]) -> anyhow::Result<Vec<u8>> {
    let s_key = hmac::Key::new(hmac::HMAC_SHA256, key);
    let tag = hmac::sign(&s_key, payload);
    Ok(tag.as_ref().to_vec())
}

async fn write_spake2_exchange_message<W: AsyncWriteExt + Unpin>(writer: &mut W, msg_type: u32, payload: &[u8]) -> anyhow::Result<()> {
    debug!("Sending SPAKE2 Exchange: Type={}, Len={}", msg_type, payload.len());
    write_message(writer, msg_type, payload).await?;
    Ok(())
}

async fn write_confirmation_message<W: AsyncWriteExt + Unpin>(writer: &mut W, payload: &[u8]) -> anyhow::Result<()> {
    debug!("Sending SPAKE2 Confirmation message: Type={}, Len={}", MSG_TYPE_CONFIRMATION, payload.len());
    write_message(writer, MSG_TYPE_CONFIRMATION, payload).await?;
    Ok(())
}

/// Format TLP Standar ADB: [type: u32 LE][len: u32 LE][payload]
async fn write_message<W: AsyncWriteExt + Unpin>(writer: &mut W, msg_type: u32, payload: &[u8]) -> anyhow::Result<()> {
    // Kirim 4 byte prefix (Type di byte pertama sesuai TODO.md)
    let mut prefix = [0u8; 4];
    let type_bytes = msg_type.to_le_bytes();
    prefix.copy_from_slice(&type_bytes);
    writer.write_all(&prefix).await?;

    // Kirim 2 byte Length (Big Endian)
    writer.write_u16(payload.len() as u16).await?;

    // Kirim Payload
    writer.write_all(payload).await?;
    writer.flush().await?;
    
    debug!("Sent ADP Packet: Type={}, Len={}", msg_type, payload.len());
    Ok(())
}

/// Membaca paket TLP ADB (ADP): [type: u32 LE][len: u16 BE][payload]
/// Digunakan untuk membersihkan buffer secara total setiap pembacaan.
async fn read_tlp_packet<R: AsyncReadExt + Unpin>(reader: &mut R) -> anyhow::Result<(u32, Vec<u8>)> {
    let mut header = [0u8; 6]; // 4 byte Type + 2 byte Length
    reader.read_exact(&mut header).await?;

    let msg_type = u32::from_le_bytes([header[0], header[1], header[2], header[3]]);
    let len = u16::from_be_bytes([header[4], header[5]]) as usize;

    debug!("Received ADP Packet: Type={}, Len={}", msg_type, len);

    let mut payload = vec![0u8; len];
    reader.read_exact(&mut payload).await?;
    
    Ok((msg_type, payload))
}

/// Membaca pesan konfirmasi atau error dengan penanganan TLP standar.
async fn read_confirmation_message<R: AsyncReadExt + Unpin>(reader: &mut R) -> anyhow::Result<Vec<u8>> {
    let (msg_type, payload) = read_tlp_packet(reader).await?;
    debug!("Step 4: Received message type {}", msg_type);

    if msg_type == 257 {
        error!("Server returned protocol error (257). Raw Payload: {}", hex::encode(&payload));
        return Err(anyhow::anyhow!("Server rejected pairing (Error 257). Biasanya disebabkan Pairing Code salah atau mismatch identitas."));
    }

    if msg_type != MSG_TYPE_CONFIRMATION {
        return Err(anyhow::anyhow!("Unexpected message type: {}. Expected 2.", msg_type));
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
        Ok(ssl_stream) => {
            let (ssl_read, mut ssl_write) = tokio::io::split(ssl_stream);
            let mut ssl_reader = BufReader::new(ssl_read);

            // --- TAHAP SPAKE2 ---
            // Identitas HARUS sesuai standar AOSP pairing_connection.cpp
            // Menghapus \0 karena BoringSSL biasanya menggunakan panjang string tanpa null
            let (state, msg1_data) = Spake2::<Ed25519Group>::start_a(
                &Password::new(pairing_code.as_bytes()),
                &Identity::new(b"adb pair client"),
                &Identity::new(b"adb pair server"),
            );

            // The spake2 crate's Ed25519Group produces 33 bytes: [prefix, point_bytes...]
            // However, the ADB protocol expects exactly 32 bytes (the raw point).
            // We must strip the prefix (usually 0x00 for Side A) before sending.
            let (my_prefix, msg1_payload_to_send) = if msg1_data.len() == 33 {
                (msg1_data[0], &msg1_data[1..])
            } else {
                return Err(anyhow::anyhow!("Unexpected MSG1 size from spake2: {}", msg1_data.len()));
            };
            debug!("MSG1 prefix = {}, payload size = {}", my_prefix, msg1_payload_to_send.len());
            debug!("MSG1 payload to send: {}", hex::encode(msg1_payload_to_send));

            // MSG1: Client Hello (Exchange)
            info!("Step 1/5: Sending SPAKE2 Exchange (Client)");
            write_spake2_exchange_message(&mut ssl_write, MSG_TYPE_EXCHANGE, msg1_payload_to_send).await?;

            // MSG2: Menerima Server Public Value
            info!("Step 2/5: Waiting for SPAKE2 Exchange (Server)");
            let (m_type, msg2_payload) = tokio::time::timeout(
                tokio::time::Duration::from_secs(5), 
                read_spake2_exchange_message(&mut ssl_reader) // Menggunakan fungsi khusus
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

            let msg2_spake_for_finish = if msg2_payload.len() == 33 && (msg2_payload[0] == b'A' || msg2_payload[0] == b'B' || msg2_payload[0] == b'S') {
                debug!("Received MSG2 with explicit SPAKE2 prefix: {}", msg2_payload[0]);
                msg2_payload.clone()
            } else if msg2_payload.len() == 32 {
                let mut buf = Vec::with_capacity(33);
                buf.push(peer_prefix);
                buf.extend_from_slice(&msg2_payload);
                debug!("Processing MSG2 by prepending peer prefix: {}", peer_prefix);
                buf
            } else {
                return Err(anyhow::anyhow!("Unexpected SPAKE2 MSG2 payload length: {}", msg2_payload.len()));
            };

            let shared_secret = state.finish(&msg2_spake_for_finish)
                .map_err(|e| anyhow::anyhow!("SPAKE2 finish error: {:?}", e))?;
            
            debug!("SPAKE2 shared secret generated, length: {}", shared_secret.len());
            
            let (kc, ks) = derive_keys(&shared_secret)?;

            // Konstruksi Payload HMAC (MSG1 || MSG2)
            // Android menggabungkan (concatenate) pertukaran pesan sebelumnya untuk validasi
            let mut hmac_input = Vec::with_capacity(64);
            hmac_input.extend_from_slice(msg1_payload_to_send); // MSG1 data (32 bytes)
            hmac_input.extend_from_slice(&msg2_payload);       // MSG2 data (32 bytes)
            
            // MSG3: Kirim HMAC konfirmasi client
            let msg3_data = compute_conf_hmac(&kc, &hmac_input)?;
            info!("Step 3/5: Sending HMAC Confirmation (Client)");
            debug!("Computed MSG3 confirmation HMAC: {}", hex::encode(&msg3_data));
            write_confirmation_message(&mut ssl_write, &msg3_data).await?;
            debug!("MSG3 sent successfully");

            // MSG4: Menerima Konfirmasi Server
            info!("Step 4/5: Waiting for HMAC Confirmation (Server)");
            let msg4_payload = tokio::time::timeout(
                tokio::time::Duration::from_secs(5), 
                read_confirmation_message(&mut ssl_reader)
            ).await.map_err(|_| anyhow::anyhow!("Timeout waiting for MSG4"))??;
            debug!("Received MSG4 confirmation payload: {}", hex::encode(&msg4_payload));
            
            // Verifikasi HMAC server menggunakan kunci Ks dan payload (MSG1 || MSG2)
            let expected_server_conf = compute_conf_hmac(&ks, &hmac_input)?;
            if expected_server_conf != msg4_payload {
                return Err(anyhow::anyhow!("SPAKE2 Confirmation mismatch! Possible wrong pairing code."));
            }

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

            write_message(&mut ssl_write, MSG_TYPE_PEER_INFO, &peer_info_bin).await?;

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