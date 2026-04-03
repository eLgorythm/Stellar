use crate::frb_generated::*;
use anyhow::{anyhow, Context, Result};
use log::{info, LevelFilter, Log, Metadata, Record};
use std::sync::Mutex;
use tokio::net::TcpStream;
use boring::ssl::{SslConnector, SslMethod, SslVerifyMode};
use boring::pkey::{PKey, Private};
use boring::rsa::Rsa;
use boring::asn1::Asn1Time;
use boring::hash::MessageDigest;
use boring::x509::{X509, X509Name};
use boring::x509::extension::BasicConstraints;
use boring::bn::BigNum;
use once_cell::sync::Lazy;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use boring::symm::{Cipher, Crypter, Mode};
use curve25519_dalek::{
    scalar::Scalar,
    edwards::{EdwardsPoint, CompressedEdwardsY}
};
use sha2::{Digest, Sha256};

static GLOBAL_SINK: Lazy<Mutex<Option<StreamSink<String>>>> = Lazy::new(|| Mutex::new(None));

// Konstanta sesuai referensi BoringSSL/AOSP (Tanpa Null Terminator)
const EXPORTED_KEY_LABEL: &str = "adb-label";
pub const CLIENT_NAME: &str = "adb pair client\0";
pub const SERVER_NAME: &str = "adb pair server\0";

// Konstanta M dan N dari BoringSSL (Format Little-Endian murni)
const M_POINT_LE: [u8; 32] = [
    0x2e, 0xd1, 0xee, 0x88, 0x1b, 0x44, 0xcf, 0xcf, 0x53, 0x8f, 0x47, 0xa3, 0x47, 0xe3, 0xa1, 0x51,
    0x5c, 0x6b, 0x1c, 0x13, 0x32, 0x6d, 0x62, 0xb6, 0xad, 0xdd, 0xd9, 0xf6, 0x4b, 0x7e, 0xda, 0x5a,
];

const N_POINT_LE: [u8; 32] = [
    0x78, 0xc7, 0x3b, 0x69, 0x11, 0x9a, 0x32, 0x71, 0x0d, 0x68, 0xaf, 0x06, 0xbd, 0xdc, 0xbd, 0x3d,
    0x10, 0x72, 0x46, 0xb4, 0x74, 0xfe, 0xb5, 0x99, 0x7a, 0x8e, 0x7d, 0xe3, 0x0a, 0xdf, 0xe3, 0x10,
];

const MSG_TYPE_SPAKE2: u8 = 0;
const MSG_TYPE_PEER_INFO: u8 = 1;

struct BridgeLogger;

impl Log for BridgeLogger {
    fn enabled(&self, _metadata: &Metadata) -> bool { true }
    fn log(&self, record: &Record) {
        if let Some(sink) = GLOBAL_SINK.lock().unwrap().as_ref() {
            let _ = sink.add(format!("[STELLAR_RUST_X25519] {}", record.args()));
        }
    }
    fn flush(&self) {}
}

pub fn init_logger(sink: StreamSink<String>) {
    *GLOBAL_SINK.lock().unwrap() = Some(sink);
    let _ = log::set_boxed_logger(Box::new(BridgeLogger))
        .map(|()| log::set_max_level(LevelFilter::Info));
}

#[no_mangle]
pub async fn init_pairing(port: u16, pairing_code: String) -> Result<String> {
    info!("Memulai proses pairing X25519 pada 127.0.0.1:{}", port);

    // 1. TLS Handshake
    let mut tls_stream = setup_tls(port).await?;
    info!("TLS X25519 OK");

    // 2. Export Keying Material (EKM) - Penting untuk keamanan SPAKE2 di ADB
    let mut exported_key_material = [0u8; 64];
    tls_stream.ssl().export_keying_material(&mut exported_key_material, EXPORTED_KEY_LABEL, None)
        .context("Gagal mengekspor material kunci TLS")?;

    // 3. Gabungkan PIN dengan EKM (Exported Key Material)
    // ADB Pairing Spesifikasi: Password = PIN + EKM
    let mut password = Vec::new();
    password.extend_from_slice(pairing_code.trim().as_bytes()); // Pastikan PIN bersih dari whitespace
    password.extend_from_slice(&exported_key_material);

    // JANGAN gunakan std::str::from_utf8 karena ada EKM (binary) di dalamnya.
    // Gunakan hex::encode atau debug format byte-nya saja.
    info!("DEBUG: Panjang PIN: {} bytes", pairing_code.len());
    info!("DEBUG: Panjang EKM: {} bytes", exported_key_material.len());
    info!("DEBUG: Total Password Byte (Hex): {}", hex::encode(&password));

    // 4. SPAKE2 Exchange
    info!("[STEP 2/3] SPAKE2 Exchange...");
    let shared_key = spake2_exchange(&mut tls_stream, &password).await?;
    info!("SPAKE2 X25519 OK");

    // 5. PeerInfo Exchange (AES-128-GCM)
    info!("[STEP 3/3] PeerInfo Exchange...");
    peer_info_exchange(&mut tls_stream, &shared_key).await?;
    info!("PAIRING COMPLETE X25519!");

    Ok("Pairing X25519 berhasil!".to_string())
}

async fn setup_tls(port: u16) -> Result<tokio_boring::SslStream<TcpStream>> {
    let (cert, pkey) = generate_self_signed_cert()?;
    let mut connector = SslConnector::builder(SslMethod::tls())?;
    connector.set_verify(SslVerifyMode::NONE);
    connector.set_certificate(&cert)?;
    connector.set_private_key(&pkey)?;

    let stream = TcpStream::connect(format!("127.0.0.1:{}", port)).await?;
    let mut config = connector.build().configure()?;
    config.set_verify_hostname(false);
    
    tokio_boring::connect(config, "localhost", stream).await
        .context("TLS connection failed")
}

async fn write_adb_msg<S>(stream: &mut S, msg_type: u8, payload: &[u8]) -> Result<()>
where S: AsyncReadExt + AsyncWriteExt + Unpin {
    let mut header = [0u8; 6];
    header[0] = 1; // version
    header[1] = msg_type;
    header[2..6].copy_from_slice(&(payload.len() as i32).to_be_bytes());
    
    stream.write_all(&header).await?;
    stream.write_all(payload).await?;
    stream.flush().await?;
    Ok(())
}

async fn read_adb_msg<S>(stream: &mut S) -> Result<(u8, Vec<u8>)>
where S: AsyncReadExt + AsyncWriteExt + Unpin {
    let mut header = [0u8; 6];
    stream.read_exact(&mut header).await?;
    
    let msg_type = header[1];
    let len = i32::from_be_bytes([header[2], header[3], header[4], header[5]]) as usize;
    
    let mut payload = vec![0u8; len];
    stream.read_exact(&mut payload).await?;
    Ok((msg_type, payload))
}

async fn read_adb_msg_debug<S>(stream: &mut S) -> Result<(u8, Vec<u8>)>
where S: AsyncReadExt + AsyncWriteExt + Unpin {
    let mut header = [0u8; 6];
    stream.read_exact(&mut header).await?;
    
    let msg_type = header[1];
    let len = i32::from_be_bytes([header[2], header[3], header[4], header[5]]) as usize;
    info!("DEBUG ADB MSG: Terma Header [type: {}, len: {}], hex: {}", msg_type, len, hex::encode(&header));
    
    let mut payload = vec![0u8; len];
    stream.read_exact(&mut payload).await?;
    Ok((msg_type, payload))
}

async fn spake2_exchange<S>(stream: &mut S, password: &[u8]) -> Result<Vec<u8>> 
where S: tokio::io::AsyncReadExt + tokio::io::AsyncWriteExt + Unpin {
    // 1. Persiapan Titik M dan N
    info!("DEBUG SPAKE2: Memulai dekompresi titik M dan N");
    let m_point = CompressedEdwardsY(M_POINT_LE)
        .decompress()
        .ok_or_else(|| anyhow!("M_POINT tidak valid"))?;
    let n_point = CompressedEdwardsY(N_POINT_LE)
        .decompress()
        .ok_or_else(|| anyhow!("N_POINT tidak valid"))?;
    info!("DEBUG SPAKE2: Titik M dan N berhasil didekompresi");

    // 2. Generate Ephemeral Key (x) dan Scalar Password (w)
    let x_scalar = Scalar::random(&mut rand::thread_rng());
    let w_hash = Sha256::digest(password);
    let w_scalar = Scalar::from_bytes_mod_order(w_hash.into());

    // 3. STEP 1: Kirim MSG1 = xG + wM
    let msg1_point = EdwardsPoint::mul_base(&x_scalar) + (m_point * w_scalar);
    let msg1_bytes = msg1_point.compress().0; // ADB SPAKE2 menggunakan Compressed Edwards Y
    info!("DEBUG SPAKE2: MSG1 (outbound) hex: {}", hex::encode(&msg1_bytes));

    write_adb_msg(stream, MSG_TYPE_SPAKE2, &msg1_bytes).await?;
    info!("[STEP 2/3] MSG1 Terkirim. Menunggu MSG2 (Y*) dari Android...");

    // 4. STEP 2: Terima Respon MSG2 (Y*)
    let (msg_type, inbound) = read_adb_msg_debug(stream).await?;
    if msg_type != MSG_TYPE_SPAKE2 {
        return Err(anyhow!("Tipe pesan salah: {}, harap SPAKE2", msg_type));
    }
    let y_star_bytes: [u8; 32] = inbound.try_into().map_err(|_| anyhow!("Invalid Y* length"))?;

    // 5. STEP 3: Hitung Shared Secret Z = x(Y* - wN)
    // Android mengirim Compressed Edwards Y
    let y_star_edwards = CompressedEdwardsY(y_star_bytes)
        .decompress()
        .ok_or_else(|| anyhow!("Y* dari Android tidak valid sebagai titik Edwards"))?;
    info!("DEBUG SPAKE2: MSG2 (inbound/Y*) hex: {}", hex::encode(&y_star_bytes));

    let z_point = (y_star_edwards - (n_point * w_scalar)) * x_scalar;
    let z_compressed_bytes = z_point.compress().0; // Ini adalah IKM untuk HKDF
    info!("DEBUG SPAKE2: Z Point (compressed) hex: {}", hex::encode(&z_compressed_bytes));

    // Hitung Transcript Hash (Sesuai Spesifikasi BoringSSL Ed25519)
    let mut transcript_hasher = Sha256::new();
    
    // Preamble di-hash langsung tanpa panjang (Sesuai BoringSSL spake25519.cc)
    transcript_hasher.update(b"SPAKE2-Ed25519-Sha256-Transcript");
    
    // IdA, IdB, X, dan Y masing-masing diawali panjangnya (u64 Little Endian)
    for item in &[CLIENT_NAME.as_bytes(), SERVER_NAME.as_bytes(), &msg1_bytes, &y_star_bytes] {
        transcript_hasher.update(&(item.len() as u64).to_le_bytes());
        transcript_hasher.update(item);
    }
    
    let transcript_hash = transcript_hasher.finalize(); // Ini adalah salt
    info!("DEBUG SPAKE2: Transcript Hash (Salt) hex: {}", hex::encode(&transcript_hash));

    // Derivasi Shared Secret menggunakan HKDF-SHA256 (Label Ed25519)
    let mut shared_secret = vec![0u8; 32];
    hkdf::Hkdf::<Sha256>::new(Some(transcript_hash.as_ref()), z_compressed_bytes.as_ref())
        .expand(b"SPAKE2-Ed25519-Sha256-HKDF", &mut shared_secret)
        .map_err(|e| anyhow!("HKDF untuk shared secret gagal: {:?}", e))?;
    info!("DEBUG SPAKE2: Shared Secret (first 16 bytes) hex: {}", hex::encode(&shared_secret[..16]));

    info!("[STEP 3/3] SPAKE2 Exchange Berhasil!");
    Ok(shared_secret)
}

async fn peer_info_exchange<S>(stream: &mut S, shared_key: &[u8]) -> Result<()> 
where S: AsyncReadExt + AsyncWriteExt + Unpin {
    // 1. Derivasi kunci AES-128-GCM dari shared key SPAKE2
    let mut aes_key = [0u8; 16];
    hkdf::Hkdf::<Sha256>::new(None, shared_key)
        .expand(b"adb pairing_auth aes-128-gcm key", &mut aes_key)
        .map_err(|e| anyhow!("HKDF failed: {:?}", e))?;

    // 2. Siapkan PeerInfo (Berisi Public Key RSA Klien)
    let (cert, _) = generate_self_signed_cert()?;
    let rsa = cert.public_key()?.rsa()?;
    let adb_pub_key = encode_rsa_adb_format(&rsa)?;
    
    let mut peer_info = vec![0u8]; // ADB PeerInfo starts with version 0
    peer_info.extend_from_slice(&adb_pub_key);
    // Metadata: " Ascent@Antagonism\0" atau format "c:name\0"
    peer_info.extend_from_slice(b"c:stellar\0");

    // 3. Enkripsi PeerInfo
    let iv = [0u8; 12]; // Nonce/IV adalah 0 (i64 little endian) sesuai referensi
    let mut crypter = Crypter::new(Cipher::aes_128_gcm(), Mode::Encrypt, &aes_key, Some(&iv))?;
    
    let mut encrypted = vec![0u8; peer_info.len() + Cipher::aes_128_gcm().block_size()];
    let count = crypter.update(&peer_info, &mut encrypted)?;
    let final_count = crypter.finalize(&mut encrypted[count..])?;
    encrypted.truncate(count + final_count);
    
    let mut tag = [0u8; 16];
    crypter.get_tag(&mut tag)?;
    encrypted.extend_from_slice(&tag);

    // 4. Kirim & Terima PeerInfo
    write_adb_msg(stream, MSG_TYPE_PEER_INFO, &encrypted).await?;
    
    let (msg_type, response) = read_adb_msg(stream).await?;
    if msg_type != MSG_TYPE_PEER_INFO {
        return Err(anyhow!("Gagal menerima respon PeerInfo dari Android"));
    }

    // 5. Dekripsi Respon PeerInfo
    if response.len() < 16 { return Err(anyhow!("Payload response terlalu pendek")); }
    let (ciphertext, tag) = response.split_at(response.len() - 16);
    
    let mut decryptor = Crypter::new(Cipher::aes_128_gcm(), Mode::Decrypt, &aes_key, Some(&iv))?;
    decryptor.set_tag(tag)?;
    
    let mut decrypted = vec![0u8; ciphertext.len() + Cipher::aes_128_gcm().block_size()];
    let count = decryptor.update(ciphertext, &mut decrypted)?;
    let final_count = decryptor.finalize(&mut decrypted[count..])?;
    decrypted.truncate(count + final_count);

    info!("ADB PeerInfo exchange success: {:?}", 
        String::from_utf8_lossy(&decrypted).trim_matches(char::from(0))
    );
    
    Ok(())
}

/// Mengonversi RSA Public Key ke format mincrypt yang digunakan Android ADB
fn encode_rsa_adb_format(rsa: &Rsa<boring::pkey::Public>) -> Result<Vec<u8>> {
    let n = rsa.n();
    let n_bytes = n.to_vec();
    
    // ADB mengharapkan modulus 2048-bit (256 bytes)
    if n_bytes.len() > 256 {
        return Err(anyhow!("Modulus terlalu besar untuk ADB"));
    }

    let mut result = Vec::with_capacity(524);
    
    // 1. Modulus Size in Words (2048 bit / 32 bit = 64)
    result.extend_from_slice(&64u32.to_le_bytes());

    // 2. n0inv = -1 / n[0] mod 2^32
    let mut ctx = boring::bn::BigNumContext::new()?;
    let mut r32 = BigNum::new()?;
    r32.set_bit(32)?;
    
    let mut n0 = BigNum::new()?;
    n0.checked_rem(n, &r32, &mut ctx)?;
    let mut n0_inv = BigNum::new()?;
    n0_inv.mod_inverse(&n0, &r32, &mut ctx)?;

    let mut n0_inv_neg = BigNum::new()?;
    n0_inv_neg.checked_sub(&r32, &n0_inv.as_ref())?;
    
    // Ambil 4 byte terendah untuk n0inv
    let n0inv_bytes = n0_inv_neg.to_vec();
    let mut n0inv_val_bytes = [0u8; 4];
    let copy_len = std::cmp::min(n0inv_bytes.len(), 4);
    let start = n0inv_bytes.len() - copy_len;
    n0inv_val_bytes[4-copy_len..].copy_from_slice(&n0inv_bytes[start..]);
    let n0inv_val = u32::from_be_bytes(n0inv_val_bytes);
    result.extend_from_slice(&n0inv_val.to_le_bytes());

    // 3. Modulus N (Little Endian)
    let mut n_le = n_bytes.clone();
    n_le.reverse();
    n_le.resize(256, 0);
    result.extend_from_slice(&n_le);

    // 4. RR = (2^2048)^2 mod N (Little Endian)
    let mut rr = BigNum::new()?;
    rr.set_bit(4096)?; // (2^2048)^2 = 2^4096
    let mut rr_mod = BigNum::new()?;
    rr_mod.checked_rem(&rr, &n, &mut ctx)?;
    let mut rr_bytes = rr_mod.to_vec();
    rr_bytes.reverse();
    rr_bytes.resize(256, 0);
    result.extend_from_slice(&rr_bytes);

    // 5. Exponent (Default 65537)
    let e: u32 = rsa.e().to_dec_str()?.parse()?;
    result.extend_from_slice(&e.to_le_bytes());

    Ok(result)
}

fn generate_self_signed_cert() -> Result<(X509, PKey<Private>)> {
    let rsa = Rsa::generate(2048).context("Failed to generate RSA key")?;
    let pkey = PKey::from_rsa(rsa).context("Failed to create PKey")?;

    let mut builder = X509::builder()?;
    builder.set_version(2)?;

    let serial_bn = BigNum::from_u32(rand::random())?;
    let serial_asn1 = serial_bn.to_asn1_integer()?; 
    builder.set_serial_number(&serial_asn1)?;

    let not_before = Asn1Time::days_from_now(0)?;
    let not_after = Asn1Time::days_from_now(3650)?;
    builder.set_not_before(&not_before)?;
    builder.set_not_after(&not_after)?;

    let mut name_builder = X509Name::builder()?;
    name_builder.append_entry_by_text("CN", "Stellar")?;
    let name = name_builder.build();
    builder.set_subject_name(&name)?;
    builder.set_issuer_name(&name)?;

    builder.set_pubkey(&pkey)?;

    let bc = BasicConstraints::new().ca().build()?;
    builder.append_extension(&bc)?;

    builder.sign(&pkey, MessageDigest::sha256())?;

    Ok((builder.build(), pkey))
}

// Dummy async function buat testing
pub async fn execute_adb_command(command: String) -> Result<String> {
    Ok(format!("ADB X25519 ready: {}", command))
}