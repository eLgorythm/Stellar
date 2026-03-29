use boring::asn1::Asn1Time;
use boring::hash::MessageDigest;
use boring::pkey::PKey;
use boring::rsa::Rsa;
use boring::ssl::{SslConnector, SslMethod, SslVerifyMode};
use boring::x509::{X509, X509Name};
use bytes::{Buf, BufMut, BytesMut};
use spake2::{Ed25519Group, Identity, Password, Spake2};
use std::net::SocketAddr;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::TcpStream;
use log::{info, debug, error};
use std::sync::RwLock;
use crate::frb_generated::{SseEncode as _, *};

const ADB_VERSION: u32 = 0x01000000;
const MAX_PAYLOAD: u32 = 1024 * 1024;
const A_PARE: u32 = 0x45524150; // "PARE"

const PARE_MSG_TYPE_1: u32 = 1; // Client Hello
const PARE_MSG_TYPE_2: u32 = 2; // Server Hello
const PARE_MSG_TYPE_3: u32 = 3; // Client Response
const PARE_MSG_TYPE_4: u32 = 4; // Server Response
const PARE_MSG_TYPE_5: u32 = 5; // Client Final (Public Key)

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

#[derive(Debug)]
struct AdbPacket {
    command: u32,
    arg0: u32,
    arg1: u32,
    payload: Vec<u8>,
}

impl AdbPacket {
    fn serialize(&self) -> Vec<u8> {
        let mut buf = BytesMut::with_capacity(24 + self.payload.len());
        buf.put_u32_le(self.command);
        buf.put_u32_le(self.arg0);
        buf.put_u32_le(self.arg1);
        buf.put_u32_le(self.payload.len() as u32);
        let checksum = self.calculate_checksum();
        buf.put_u32_le(checksum);
        buf.put_u32_le(self.command ^ 0xFFFFFFFF);
        buf.put_slice(&self.payload);

        let result = buf.to_vec();
        debug!("Outgoing Packet: Cmd=0x{:08X}, Arg0={}, Arg1={}, Len={}, Checksum=0x{:08X}", self.command, self.arg0, self.arg1, self.payload.len(), checksum);
        result
    }

    fn calculate_checksum(&self) -> u32 {
        self.payload.iter().map(|&b| b as u32).fold(0u32, |acc, x| acc.wrapping_add(x))
    }

    async fn read_from<R: AsyncReadExt + Unpin>(reader: &mut R) -> anyhow::Result<Self> {
        let mut header = [0u8; 24];
        reader.read_exact(&mut header).await?;
        
        let mut buf = &header[..];
        let command = buf.get_u32_le();
        let arg0 = buf.get_u32_le();
        let _arg1 = buf.get_u32_le();
        let payload_len = buf.get_u32_le();
        let checksum = buf.get_u32_le();
        let command_magic = buf.get_u32_le();

        // Verifikasi Magic: command ^ 0xFFFFFFFF
        if command ^ 0xFFFFFFFF != command_magic {
            return Err(anyhow::anyhow!("Invalid ADB Packet Magic"));
        }

        debug!("Incoming Header: Cmd=0x{:08X}, Arg0={}, Len={}, Checksum=0x{:08X}", command, arg0, payload_len, checksum);

        let mut payload = vec![0u8; payload_len as usize];
        if payload_len > 0 {
            reader.read_exact(&mut payload).await?;
            debug!("Incoming Payload ({} bytes): {:02X?}", payload_len, payload);
        }

        Ok(AdbPacket { command, arg0, arg1: _arg1, payload })
    }
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
    // Logger sekarang diinisialisasi melalui stream di awal aplikasi

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
            // --- TAHAP SPAKE2 ---
            
            // MSG1: Client mengirim SPAKE2 Public Value
            let (state, msg1_data) = Spake2::<Ed25519Group>::start_a(
                &Password::new(pairing_code.as_bytes()),
                &Identity::new(b"client"),
                &Identity::new(b"server"),
            );

            info!("Sending MSG1 (Client Hello)");
            let p1 = AdbPacket {
                command: A_PARE,
                arg0: PARE_MSG_TYPE_1,
                arg1: 0,
                payload: msg1_data,
            };
            ssl_stream.write_all(&p1.serialize()).await?;

            // MSG2: Menerima Server Public Value
            let p2 = AdbPacket::read_from(&mut ssl_stream).await?;
            if p2.command != A_PARE || p2.arg0 != PARE_MSG_TYPE_2 {
                return Err(anyhow::anyhow!("Expected MSG2 (PARE, type 2), but got Cmd:0x{:X}, Type:{}", p2.command, p2.arg0));
            }
            info!("Received MSG2 (Server Hello)");

            // MSG3: Hitung shared secret dan kirim verifikasi (Confirmation)
            let shared_secret = state.finish(&p2.payload)
                .map_err(|e| anyhow::anyhow!("SPAKE2 Error: {:?}", e))?;
            let msg3_data = shared_secret.clone();
            
            info!("Sending MSG3 (Client Response)");
            let p3 = AdbPacket {
                command: A_PARE,
                arg0: PARE_MSG_TYPE_3,
                arg1: 0,
                payload: msg3_data,
            };
            ssl_stream.write_all(&p3.serialize()).await?;

            // MSG4: Menerima Konfirmasi Server
            let p4 = AdbPacket::read_from(&mut ssl_stream).await?;
            if p4.command != A_PARE || p4.arg0 != PARE_MSG_TYPE_4 {
                return Err(anyhow::anyhow!("Verification failed at MSG4. Expected type 4, got {}", p4.arg0));
            }
            
            // Verifikasi konfirmasi server secara kriptografis
            if shared_secret != p4.payload {
                return Err(anyhow::anyhow!("SPAKE2 Confirmation mismatch! Check pairing code."));
            }
            info!("MSG4 Verified. SPAKE2 exchange successful.");

            // MSG5: Kirim "Certificate" (Public Key RSA Stellar) untuk dipercaya permanen
            let pub_key_bytes = cert.public_key()?.public_key_to_pem()?;
            info!("Sending MSG5 (Final Public Key). Length: {} bytes", pub_key_bytes.len());
            
            let p5 = AdbPacket {
                command: A_PARE,
                arg0: PARE_MSG_TYPE_5,
                arg1: 0,
                payload: pub_key_bytes,
            };
            ssl_stream.write_all(&p5.serialize()).await?;

            // Berikan jeda sangat singkat agar adbd selesai memproses MSG5 sebelum socket ditutup
            tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;

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
    // Setelah pairing sukses, koneksi berikutnya dilakukan ke port 'Wireless Debugging' 
    // yang berbeda menggunakan sertifikat yang sudah di-exchange.
    Ok(format!("Output dari: {}", command))
}