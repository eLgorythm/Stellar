use crate::frb_generated::*;
use anyhow::{anyhow, Context, Result};
use log::{info, debug, error};
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
use std::fs;
use boring::symm::{Cipher, Crypter, Mode};
use sha2::Sha256;

// Konstanta sesuai referensi AOSP pairing_auth.cpp. 
// AOSP menggunakan sizeof() yang menyertakan null terminator untuk identitas SPAKE2.
// Dan ExportKeyingMaterial label juga menyertakan null terminator.
const EXPORTED_KEY_LABEL: &str = "adb-label\0";
pub const CLIENT_NAME: &[u8] = b"adb pair client\0";
pub const SERVER_NAME: &[u8] = b"adb pair server\0";

const MSG_TYPE_SPAKE2: u8 = 0;
const MSG_TYPE_PEER_INFO: u8 = 1;

// --- BoringSSL SPAKE2 FFI Bindings ---
#[repr(C)]
struct SPAKE2_CTX { _private: [u8; 0] }

extern "C" {
    fn SPAKE2_CTX_new(
        role: i32,
        my_name: *const u8, my_name_len: usize,
        peer_name: *const u8, peer_name_len: usize,
    ) -> *mut SPAKE2_CTX;
    fn SPAKE2_CTX_free(ctx: *mut SPAKE2_CTX);
    fn SPAKE2_generate_msg(
        ctx: *mut SPAKE2_CTX, out: *mut u8, out_len: *mut usize, max_out: usize,
        password: *const u8, password_len: usize,
    ) -> i32;
    fn SPAKE2_process_msg(
        ctx: *mut SPAKE2_CTX, out: *mut u8, out_len: *mut usize, max_out: usize,
        inbound: *const u8, inbound_len: usize,
    ) -> i32;
}

struct SpakeGuard(*mut SPAKE2_CTX);
unsafe impl Send for SpakeGuard {}
impl Drop for SpakeGuard {
    fn drop(&mut self) {
        unsafe { SPAKE2_CTX_free(self.0) }
    }
}

#[no_mangle]
pub async fn init_pairing(port: u16, pairing_code: String, storage_dir: String) -> Result<String> {
    info!("[PAIR] Memulai proses pairing X25519 pada 127.0.0.1:{}", port);

    // 1. TLS Handshake
    let mut tls_stream = setup_tls(port, &storage_dir).await?;
    info!("[PAIR] TLS X25519 OK");

    // 2. Export Keying Material (EKM) - AOSP menggunakan 64 bytes
    let mut exported_key_material = [0u8; 64];
    tls_stream.ssl().export_keying_material(&mut exported_key_material, EXPORTED_KEY_LABEL, None)
        .context("Gagal mengekspor material kunci TLS")?;

    // 3. Gabungkan PIN dengan EKM (Exported Key Material)
    // ADB Pairing Spesifikasi: Password = PIN + EKM
    let mut password = Vec::new();
    password.extend_from_slice(pairing_code.trim().as_bytes()); // Pastikan PIN bersih dari whitespace
    password.extend_from_slice(&exported_key_material);

    debug!("Panjang PIN: {} bytes", pairing_code.len());
    debug!("Panjang EKM: {} bytes", exported_key_material.len());
    debug!("Total Password Byte (Hex): {}", hex::encode(&password));

    // 4. SPAKE2 Exchange (MSG1 & MSG2)
    info!("[PAIR] [STEP 2/3] SPAKE2 Exchange...");
    let (shared_key, _msg1_bytes, _msg2_bytes) = spake2_exchange(&mut tls_stream, &password).await?;
    
    // 5. Konfirmasi Kunci (MSG3) DIHAPUS - Tidak ada dalam pairing_connection.cpp AOSP
    // send_auth_confirmation(...) -> Server akan reset koneksi jika menerima data tak terduga di sini.
    info!("[PAIR] SPAKE2 Exchange OK");

    // 6. PeerInfo Exchange (AES-128-GCM)
    info!("[PAIR] [STEP 3/3] PeerInfo Exchange...");
    peer_info_exchange(&mut tls_stream, &shared_key, &storage_dir).await?;
    info!("[PAIR] PAIRING COMPLETE X25519!");

    Ok("Pairing X25519 berhasil!".to_string())
}

async fn setup_tls(port: u16, _storage_dir: &str) -> Result<tokio_boring::SslStream<TcpStream>> {
    let (cert, pkey) = generate_self_signed_cert()?;
    let mut connector = SslConnector::builder(SslMethod::tls())?;
    connector.set_verify(SslVerifyMode::PEER);
    connector.set_certificate(&cert)?;
    connector.set_private_key(&pkey)?;

    let stream = TcpStream::connect(format!("127.0.0.1:{}", port)).await?;
    let mut config = connector.build().configure()?;
    config.set_verify_hostname(false);
    config.set_verify_callback(SslVerifyMode::PEER, |_, _| true);
    
    tokio_boring::connect(config, "localhost", stream).await
        .context("[PAIR] TLS connection failed")
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


async fn read_adb_msg_debug<S>(stream: &mut S) -> Result<(u8, Vec<u8>)>
where S: AsyncReadExt + AsyncWriteExt + Unpin {
    let mut header = [0u8; 6];
    stream.read_exact(&mut header).await?;
    
    let msg_type = header[1];
    let len = i32::from_be_bytes([header[2], header[3], header[4], header[5]]) as usize;
    info!("[PAIR] DEBUG ADB MSG: Terma Header [type: {}, len: {}], hex: {}", msg_type, len, hex::encode(&header));
    
    let mut payload = vec![0u8; len];
    stream.read_exact(&mut payload).await?;
    Ok((msg_type, payload))
}

async fn spake2_exchange<S>(stream: &mut S, password: &[u8]) -> Result<(Vec<u8>, Vec<u8>, Vec<u8>)> 
where S: tokio::io::AsyncReadExt + tokio::io::AsyncWriteExt + Unpin {
    // 1. Inisialisasi Context via FFI (Role Alice = 0) di dalam wrapper Send
    let guard = unsafe {
        let p = SPAKE2_CTX_new(
            0, 
            CLIENT_NAME.as_ptr(), CLIENT_NAME.len(),
            SERVER_NAME.as_ptr(), SERVER_NAME.len()
        );
        if p.is_null() { return Err(anyhow!("Gagal membuat SPAKE2_CTX via FFI")); }
        SpakeGuard(p)
    };

    // 2. Generate MSG1 (Outbound)
    let mut msg1_bytes = vec![0u8; 32];
    let mut out_len = 0;
    let res = unsafe {
        SPAKE2_generate_msg(guard.0, msg1_bytes.as_mut_ptr(), &mut out_len, 32, password.as_ptr(), password.len())
    };
    if res != 1 { return Err(anyhow!("FFI: SPAKE2_generate_msg gagal")); }

    info!("[PAIR] DEBUG SPAKE2: MSG1 (outbound) hex: {}", hex::encode(&msg1_bytes));
    write_adb_msg(stream, MSG_TYPE_SPAKE2, &msg1_bytes).await?;

    // 3. Baca MSG2 (Inbound)
    let (msg_type, inbound) = read_adb_msg_debug(stream).await?;
    if msg_type != MSG_TYPE_SPAKE2 {
        return Err(anyhow!("Tipe pesan salah: {}, harap SPAKE2", msg_type));
    }
    
    // 4. Proses MSG2 untuk mendapatkan Shared Key (64 bytes)
    let mut shared_key = vec![0u8; 64];
    let mut key_len = 0;
    let res = unsafe {
        SPAKE2_process_msg(guard.0, shared_key.as_mut_ptr(), &mut key_len, 64, inbound.as_ptr(), inbound.len())
    };

    if res != 1 {
        let err = crate::boring_helper::detailed_boring_error("FFI: SPAKE2_process_msg gagal (PIN salah atau Transcript mismatch)");
        error!("{}", err);
        return Err(err);
    }

    let y_star_bytes = inbound.to_vec();
    info!("[PAIR] DEBUG SPAKE2: Shared Key (Final Hash) hex: {}", hex::encode(&shared_key));
    info!("[PAIR] [STEP 3/3] SPAKE2 Exchange Berhasil!");
    Ok((shared_key, msg1_bytes, y_star_bytes))
}


async fn peer_info_exchange<S>(stream: &mut S, shared_key: &[u8], storage_dir: &str) -> Result<()>
where S: AsyncReadExt + AsyncWriteExt + Unpin {
    // 1. Derivasi Kunci menggunakan Shared Key dari SPAKE2
    // HKDF-SHA256(salt=None, ikm=64_byte_spake2_output)
    let hk = hkdf::Hkdf::<Sha256>::new(None, shared_key);

    let mut aes_key = [0u8; 16];
    hk.expand(b"adb pairing_auth aes-128-gcm key", &mut aes_key)
        .map_err(|_| anyhow!("Gagal ekspansi AES Key"))?;

    // Referensi AOSP (aes-gcm-128.cpp) memulai IV dengan 12-byte nol
    let base_iv = [0u8; 12]; 

    info!("[PAIR] DEBUG PeerInfo: AES Key: {}", hex::encode(&aes_key));

    // 2. Siapkan PeerInfo (Sesuai rsa_2048_key.cpp dan adb_wifi.cpp)
    // Berdasarkan log, PeerInfo berukuran tepat 8192 byte (ciphertext 8192 + tag 16 = 8208)
    let peer_info = {
        let (cert, _) = get_persistent_cert(storage_dir)?;
        let rsa = cert.public_key()?.rsa()?;
        let adb_pub_key = encode_rsa_adb_format(&rsa)?; 
        
        let pub_key_base64 = boring::base64::encode_block(&adb_pub_key)
            .replace(['\n', '\r'], "");

        // PeerInfo Struct di AOSP: 8192 byte total (1 byte type + 8191 byte data)
        let mut info = vec![0u8; 8192];
        
        // Type 0 = ADB_RSA_PUB_KEY (berdasarkan log outbound plaintext 00 40...)
        info[0] = 0u8; 
        
        let mut data_payload = Vec::new();
        data_payload.extend_from_slice(pub_key_base64.as_bytes());
        data_payload.extend_from_slice(b" NoeLynx@Stellar\0");
        
        let copy_len = std::cmp::min(data_payload.len(), 8191);
        info[1..1+copy_len].copy_from_slice(&data_payload[..copy_len]);

        info
    };

    // 3. Enkripsi & Kirim profil Client (Counter 0)
    // Sekarang Stellar mengirim profilnya terlebih dahulu sebelum menerima respon.
    let cipher = Cipher::aes_128_gcm();
    info!("[PAIR] DEBUG PeerInfo: Plaintext Outbound hex: {}", hex::encode(&peer_info));

    let encrypted_client = {
        // Gunakan base_iv murni (Counter 0) untuk paket pertama yang dikirim
        let mut crypter = Crypter::new(cipher, Mode::Encrypt, &aes_key, Some(&base_iv))?;
        let mut out = vec![0u8; peer_info.len() + 32];
        let len = crypter.update(&peer_info, &mut out)?;
        let final_len = crypter.finalize(&mut out[len..])
            .map_err(|_| crate::boring_helper::detailed_boring_error("Gagal enkripsi PeerInfo Outbound"))?;
        let mut tag = vec![0u8; 16];
        crypter.get_tag(&mut tag)?;
        out.truncate(len + final_len);
        out.extend_from_slice(&tag);
        out
    };

    info!("[PAIR] DEBUG PeerInfo: Ciphertext Outbound hex: {}", hex::encode(&encrypted_client));
    info!("[PAIR] DEBUG: Sending Encrypted Client PeerInfo (Counter 0)...");
    write_adb_msg(stream, MSG_TYPE_PEER_INFO, &encrypted_client).await?;

    // 4. Terima & Dekripsi Respon PeerInfo dari Android (Counter 0 Inbound)
    let (msg_type, response) = read_adb_msg_debug(stream).await?;
    if msg_type != MSG_TYPE_PEER_INFO {
        return Err(anyhow!("Expected PEER_INFO (1), got {}", msg_type));
    }

    if response.len() < 16 { return Err(anyhow!("Payload response terlalu pendek")); }
    let (ciphertext, tag) = response.split_at(response.len() - 16);

    // FIX: Untuk pesan PeerInfo pertama dari Android, counter IV harus 0.
    // Jangan meng-XOR dengan 1 kecuali ini adalah pesan kedua dalam sesi yang sama.
    let iv_android = base_iv;

    info!("[PAIR] DEBUG ADB RX: first 32 hex: {}", hex::encode(&ciphertext[..std::cmp::min(ciphertext.len(), 32)]));
    info!("[PAIR] DEBUG AES: CT len={}, Tag: {}", ciphertext.len(), hex::encode(tag));

    let decrypted = {
        // Gunakan IV Counter 1 untuk dekripsi balasan dari Android
        let mut decryptor = Crypter::new(cipher, Mode::Decrypt, &aes_key, Some(&iv_android))?;
        decryptor.set_tag(&tag)?;
        let mut out = vec![0u8; ciphertext.len() + 32];
        let len = decryptor.update(ciphertext, &mut out)?;
        let final_len = decryptor.finalize(&mut out[len..])
            .map_err(|_| crate::boring_helper::detailed_boring_error("AES-GCM Tag verification failed (Incorrect SPAKE2 key or IV)"))?;
        out.truncate(len + final_len);
        out
    };

    let peer_info_str = String::from_utf8_lossy(&decrypted)
        .trim_matches(char::from(0))
        .to_string();
    info!("[PAIR] PEERINFO DECRYPT SUCCESS: {}", peer_info_str);
    
    Ok(())
}

/// Mengonversi RSA Public Key ke format mincrypt yang digunakan Android ADB
fn encode_rsa_adb_format(rsa: &Rsa<boring::pkey::Public>) -> Result<Vec<u8>> {
    let n = rsa.n();
    let n_bytes = n.to_vec();
    
    // ADB mengharapkan modulus 2048-bit (256 bytes)
    if n_bytes.len() > 256 {
        return Err(anyhow!("Modulus too large for ADB"));
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
    let n0inv_vec = n0_inv_neg.to_vec();
    let mut n0inv_bytes = [0u8; 4];
    let n0_len = n0inv_vec.len();
    let copy_len = std::cmp::min(n0_len, 4);
    n0inv_bytes[4 - copy_len..].copy_from_slice(&n0inv_vec[n0_len - copy_len..]);
    let n0inv_val = u32::from_be_bytes(n0inv_bytes);
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

/// Mengambil sertifikat dari penyimpanan internal atau membuatnya jika belum ada.
/// Ini memastikan kunci yang digunakan saat pairing sama dengan saat koneksi.
pub(crate) fn get_persistent_cert(storage_dir: &str) -> Result<(X509, PKey<Private>)> {
    let path = std::path::Path::new(storage_dir).join("adb_cert.pem");
    
    if path.exists() {
        let data = fs::read(&path)?;
        let cert = X509::from_pem(&data)?;
        let pkey = PKey::private_key_from_pem(&data)?;
        return Ok((cert, pkey));
    }

    // Jika belum ada, buat baru (terjadi saat pairing pertama kali)
    let (cert, pkey) = generate_self_signed_cert()?;
    let mut pem = cert.to_pem()?;
    pem.extend_from_slice(&pkey.private_key_to_pem_pkcs8()?);
    
    if !std::path::Path::new(storage_dir).exists() {
        fs::create_dir_all(storage_dir).context("Failed to create storage directory")?;
    }
    fs::write(&path, pem).context("Failed to write permanent certificate file")?;

    Ok((cert, pkey))
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

    // Tambahkan ekstensi SKID dan AKID (Wajib untuk kompatibilitas TLS Android 13+)
    let skid = {
        let ctx = builder.x509v3_context(None, None);
        boring::x509::extension::SubjectKeyIdentifier::new()
            .build(&ctx)
            .context("Failed to build SKID extension")?
    };
    builder.append_extension(&skid)?;

    let akid = {
        let ctx = builder.x509v3_context(None, None);
        boring::x509::extension::AuthorityKeyIdentifier::new()
            .keyid(true)
            .build(&ctx)
            .context("Failed to build AKID extension")?
    };
    builder.append_extension(&akid)?;

    builder.sign(&pkey, MessageDigest::sha256())?;

    Ok((builder.build(), pkey))
}
