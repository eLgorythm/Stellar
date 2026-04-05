use anyhow::{anyhow, Context, Result};
use log::info;
use tokio::net::TcpStream;
use boring::ssl::{SslConnector, SslMethod, SslVerifyMode};
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use crate::pair::get_persistent_cert;

const A_CNXN: u32 = 0x4e584e43;
const A_STLS: u32 = 0x534c5453;
const A_VERSION: u32 = 0x01000001;
const A_STLS_VERSION: u32 = 0x01000000;
const MAX_PAYLOAD: u32 = 1024 * 1024;

/// Melakukan koneksi ADB Secure (TLS) ke perangkat yang sudah di-pairing.
/// Alur: TLS Handshake -> ADB CNXN Packet Exchange.
pub async fn connect_to_device(addr: String, storage_dir: String) -> Result<String> {
    info!("[CONNECTION] Memulai negosiasi dengan {}...", addr);

    // 1. Persiapkan sertifikat permanen
    let (cert, pkey) = get_persistent_cert(&storage_dir).context("Certificate not found. Please pair first.")?;
    
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
        Ok("Connection successful!".to_string())
    } else {
        Err(anyhow!("ADB Server refused the secure connection (Received Command: 0x{:08x})", resp_cmd))
    }
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