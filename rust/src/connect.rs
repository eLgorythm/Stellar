use anyhow::{anyhow, Context, Result, Ok as AnyOk};
use log::{info, debug};
use tokio::net::TcpStream;
use boring::ssl::{SslConnector, SslMethod, SslVerifyMode};
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use crate::pair::get_persistent_cert;
use once_cell::sync::Lazy;
use tokio::sync::Mutex;
use std::time::Duration;
use tokio_boring::SslStream;

const A_CNXN: u32 = 0x4e584e43;
const A_STLS: u32 = 0x534c5453;
const A_OPEN: u32 = 0x4e45504f;
const A_OKAY: u32 = 0x59414b4f;
const A_WRTE: u32 = 0x45545257;
const A_CLSE: u32 = 0x45534c43;
const A_VERSION: u32 = 0x01000001;
const A_STLS_VERSION: u32 = 0x01000000;
const MAX_PAYLOAD: u32 = 1024 * 1024;

static ACTIVE_SESSION: Lazy<Mutex<Option<SslStream<TcpStream>>>> = Lazy::new(|| Mutex::new(None));

#[derive(Debug)]
struct AdbMessage {
    command: u32,
    arg0: u32,
    arg1: u32,
    data: Vec<u8>,
}

impl AdbMessage {
    fn new(cmd: u32, arg0: u32, arg1: u32, data: Vec<u8>) -> Self {
        Self { command: cmd, arg0, arg1, data }
    }

    fn serialize(&self) -> Vec<u8> {
        let mut buf = Vec::with_capacity(24 + self.data.len());
        buf.extend_from_slice(&self.command.to_le_bytes());
        buf.extend_from_slice(&self.arg0.to_le_bytes());
        buf.extend_from_slice(&self.arg1.to_le_bytes());
        buf.extend_from_slice(&(self.data.len() as u32).to_le_bytes());
        let check = self.data.iter().fold(0u32, |acc, &x| acc.wrapping_add(x as u32));
        buf.extend_from_slice(&check.to_le_bytes());
        buf.extend_from_slice(&(self.command ^ 0xffffffff).to_le_bytes());
        buf.extend_from_slice(&self.data);
        buf
    }
}

async fn read_packet<S: AsyncReadExt + Unpin>(stream: &mut S) -> Result<AdbMessage> {
    let mut header = [0u8; 24];
    stream.read_exact(&mut header).await?;
    let command = u32::from_le_bytes([header[0], header[1], header[2], header[3]]);
    let arg0 = u32::from_le_bytes([header[4], header[5], header[6], header[7]]);
    let arg1 = u32::from_le_bytes([header[8], header[9], header[10], header[11]]);
    let len = u32::from_le_bytes([header[12], header[13], header[14], header[15]]) as usize;
    
    let mut data = vec![0u8; len];
    if len > 0 {
        stream.read_exact(&mut data).await?;
    }
    AnyOk(AdbMessage::new(command, arg0, arg1, data))
}

/// Melakukan koneksi ADB Secure (TLS) ke perangkat yang sudah di-pairing.
/// Alur: TLS Handshake -> ADB CNXN Packet Exchange.
pub async fn connect_to_device(addr: String, storage_dir: String) -> Result<String> {
    info!("[CONNECTION] Memulai negosiasi dengan {}...", addr);

    // 1. Persiapkan sertifikat permanen
    let (cert, pkey) = get_persistent_cert(&storage_dir).await.context("Certificate not found. Please pair first.")?;
    
    // 2. Sambungkan ke TCP port Wireless Debugging
    let mut stream = TcpStream::connect(&addr).await
        .context(format!("Failed to open TCP connection to {}", addr))?;

    // --- FASE NEGOSIASI STLS (Cleartext) ---
    
    let banner = b"host::\0";

    // A. Kirim CNXN awal (Cleartext)
    write_adb_packet(&mut stream, A_CNXN, A_VERSION, MAX_PAYLOAD, banner).await?;

    // B. Baca respons (Harus STLS: 0x534c5453)
    let mut header = [0u8; 24];
    stream.read_exact(&mut header).await?;
    let cmd = u32::from_le_bytes(header[0..4].try_into()?);
    
    if cmd != A_STLS {
        return Err(anyhow!("Perangkat tidak merespons dengan STLS (Command: 0x{:08x}). Pastikan Wireless Debugging aktif.", cmd));
    }
    info!("[CONNECTION] Server mendukung TLS. Mengonfirmasi upgrade...");

    // C. Kirim STLS konfirmasi
    write_adb_packet(&mut stream, A_STLS, A_STLS_VERSION, 0, &[]).await?;

    // --- FASE TLS UPGRADE ---

    let tls_stream = upgrade_to_tls(stream, cert, pkey).await?;
    info!("[CONNECTION] TLS Handshake Berhasil. Menginisialisasi sesi ADB...");

    // --- FASE SECURE ADB (Encrypted) ---

    let mut secure_stream = tls_stream;

    // Setelah TLS upgrade, server (adbd) akan mengirimkan paket CNXN terenkripsi.
    let mut resp_header = [0u8; 24];
    secure_stream.read_exact(&mut resp_header).await.context("Gagal membaca CNXN header dari server")?;
    let resp_cmd = u32::from_le_bytes(resp_header[0..4].try_into()?);

    if resp_cmd == A_CNXN {
        let data_len = u32::from_le_bytes(resp_header[12..16].try_into()?) as usize;
        if data_len > 0 {
            let mut data_raw = vec![0u8; data_len];
            secure_stream.read_exact(&mut data_raw).await?;
            let device_identity = String::from_utf8_lossy(&data_raw);
            info!("[CONNECTION] ADB Secure Connected! Device: {}", device_identity);
        }
        
        // Simpan sesi ke global state agar bisa dipakai scan gacha
        let mut session = ACTIVE_SESSION.lock().await;
        *session = Some(secure_stream);
        
        Ok("Connection successful!".to_string())
    } else {
        Err(anyhow!("ADB Server refused the secure connection (Received Command: 0x{:08x})", resp_cmd))
    }
}

pub async fn scan_gacha_link() -> Result<String> {
    let mut session_guard = ACTIVE_SESSION.lock().await;
    let stream = session_guard.as_mut().ok_or_else(|| anyhow!("Device not connected. Please tap CONNECT first."))?;

    info!("[SCAN] Membuka shell stream untuk mencari gacha link...");
    
    let shell_cmd = "shell:logcat -b all -c && logcat | grep --line-buffered -E 'https://(webstatic|hk4e-api|webstatic-sea|hk4e-api-os|api-takumi|api-os-takumi|gs|public-operation-hk4e|aki-gm-resources-oversea).(mihoyo\\.com|hoyoverse\\.com|aki-game\\.net|aki-game\\.com)' | grep --line-buffered -i 'gacha' | grep --line-buffered -v 'DART:'\u{0}";
    let open_msg = AdbMessage::new(A_OPEN, 7, 0, shell_cmd.as_bytes().to_vec());
    stream.write_all(&open_msg.serialize()).await?;

    let okay = read_packet(stream).await?;
    if okay.command != A_OKAY {
        return Err(anyhow!("Gagal membuka shell stream. Pastikan perangkat merespon."));
    }

    let mut log_buffer = String::new();
    // Tunggu output logcat (timeout 30s)
    let result = tokio::time::timeout(Duration::from_secs(30), async {
        let mut link_found: Option<String> = None;

        while let Ok(msg) = read_packet(stream).await {
            if msg.command == A_WRTE {
                let chunk = String::from_utf8_lossy(&msg.data);
                // Filter manual untuk memastikan DART log tidak masuk ke buffer pencarian
                if !chunk.contains("DART:") {
                    log_buffer.push_str(&chunk);
                }
                
                // Kita cek buffer yang terakumulasi
                if let Some(link) = extract_url(&log_buffer, false) {
                    // Tutup shell stream setelah ketemu
                    let close_msg = AdbMessage::new(A_CLSE, 7, okay.arg0, vec![]);
                    let _ = stream.write_all(&close_msg.serialize()).await;
                    link_found = Some(link);
                    break;
                }
                // Acknowledge WRTE
                let ack = AdbMessage::new(A_OKAY, okay.arg0, 7, vec![]);
                stream.write_all(&ack.serialize()).await?;
            } else if msg.command == A_CLSE {
                break;
            }
        }

        if let Some(l) = link_found {
            return AnyOk(l);
        }

        // Pengecekan terakhir jika stream ditutup tapi data masih ada di buffer
        if let Some(link) = extract_url(&log_buffer, true) {
            return AnyOk(link);
        }

        Err(anyhow!("Stream ditutup sebelum link ditemukan"))
    }).await;

    match result {
        core::result::Result::Ok(res) => res,
        Err(_) => {
            // Kirim CLSE jika timeout agar stream di sisi adbd tidak nyangkut
            let _ = stream.write_all(&AdbMessage::new(A_CLSE, 7, okay.arg0, vec![]).serialize()).await;
            Err(anyhow!("Waktu habis. Silakan buka halaman riwayat permohonan di dalam game."))
        }
    }
}

fn extract_url(text: &str, is_final: bool) -> Option<String> {
    for line in text.lines() {
        // Pastikan baris mengandung authkey sebelum mencoba ekstraksi
        if line.contains("authkey=") {
            if let Some(start) = line.find("https://") {
                let sub = &line[start..];
                if let Some(end) = sub.find([' ', '"', '\'', '\n', '\r', '<', '>', ')', ']']) {
                    let candidate = &sub[..end];
                    debug!("[SCAN] Extracted complete link with authkey: {}", candidate);
                    return Some(candidate.to_string());
                } else if is_final && sub.contains("authkey=") {
                    // Jika stream berakhir, ambil seluruh sisa string sebagai URL
                    debug!("[SCAN] Stream ended, taking remaining buffer as link");
                    return Some(sub.to_string());
                }
            }
        }
    }
    None
}

async fn upgrade_to_tls(stream: TcpStream, cert: boring::x509::X509, pkey: boring::pkey::PKey<boring::pkey::Private>) -> Result<tokio_boring::SslStream<TcpStream>> {
    let mut connector = SslConnector::builder(SslMethod::tls())?;
    connector.set_certificate(&cert)?;
    connector.set_private_key(&pkey)?;
    let mut config = connector.build().configure()?;
    config.set_verify_hostname(false);
    config.set_verify_callback(SslVerifyMode::PEER, |_, _| true);
    
    tokio_boring::connect(config, "localhost", stream).await
        .context("TLS handshake failed during upgrade")
}

async fn write_adb_packet<S>(stream: &mut S, cmd: u32, arg0: u32, arg1: u32, data: &[u8]) -> Result<()>
where S: AsyncWriteExt + Unpin {
    let len = data.len() as u32;
    let checksum = data.iter().fold(0u32, |acc, &x| acc + x as u32);
    let magic = cmd ^ 0xFFFFFFFF;

    let mut header = Vec::with_capacity(24);
    header.extend_from_slice(&cmd.to_le_bytes());
    header.extend_from_slice(&arg0.to_le_bytes());
    header.extend_from_slice(&arg1.to_le_bytes());
    header.extend_from_slice(&len.to_le_bytes());
    header.extend_from_slice(&checksum.to_le_bytes());
    header.extend_from_slice(&magic.to_le_bytes());

    stream.write_all(&header).await?;
    if !data.is_empty() {
        stream.write_all(data).await?;
    }
    stream.flush().await?;
    Ok(())
}