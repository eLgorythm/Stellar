# Persistensi Sertifikat dan Keamanan Client

Bagian ini menjelaskan bagaimana Stellar mengelola kredensial kriptografis secara aman dan memastikan identitas client tetap konsisten di mata sistem Android.

## 1. Persistensi Sertifikat (adb_cert.pem)

Dalam protokol ADB Wireless, identitas client (Stellar) ditentukan oleh pasangan kunci RSA. Jika client menggunakan kunci yang berbeda saat mencoba melakukan koneksi (`connect`) dibandingkan dengan yang digunakan saat `pairing`, daemon `adbd` pada Android akan menolak koneksi tersebut. 

### Mekanisme Penyimpanan
Stellar menyimpan sertifikat X.509 dan Private Key dalam satu file gabungan bernama `adb_cert.pem` di dalam direktori internal aplikasi.

### Implementasi `get_persistent_cert`
Fungsi ini bertanggung jawab untuk memuat kunci yang ada atau membuat yang baru jika belum tersedia:

```rust
pub(crate) fn get_persistent_cert(storage_dir: &str) -> Result<(X509, PKey<Private>)> {
    let path = std::path::Path::new(storage_dir).join("adb_cert.pem");
    
    // 1. Cek apakah sertifikat sudah ada di penyimpanan
    if path.exists() {
        let data = fs::read(&path)?;
        let cert = X509::from_pem(&data)?;
        let pkey = PKey::private_key_from_pem(&data)?;
        return Ok((cert, pkey));
    }

    // 2. Jika tidak ada (pairing pertama), buat baru
    let (cert, pkey) = generate_self_signed_cert()?;
    let mut pem = cert.to_pem()?;
    pem.extend_from_slice(&pkey.private_key_to_pem_pkcs8()?);
    
    // 3. Simpan secara permanen untuk koneksi di masa depan
    if !std::path::Path::new(storage_dir).exists() {
        fs::create_dir_all(storage_dir)?;
    }
    fs::write(&path, pem)?;

    Ok((cert, pkey))
}
```

## 2. Keamanan & Spesifikasi Sertifikat Client

Stellar menggunakan sertifikat *self-signed* yang dikonfigurasi khusus untuk memenuhi persyaratan keamanan BoringSSL dan kompatibilitas Android modern.

### Parameter Teknis:
- **Algoritma:** RSA 2048-bit.
- **Masa Berlaku:** 3650 hari (10 tahun) untuk menghindari kegagalan koneksi akibat sertifikat kedaluwarsa.
- **Signature:** SHA-256.

### Kompatibilitas Android 13+ (SKID & AKID)
Android versi terbaru mewajibkan sertifikat menyertakan ekstensi **Subject Key Identifier (SKID)** dan **Authority Key Identifier (AKID)** untuk jabat tangan TLS yang valid.

```rust
fn generate_self_signed_cert() -> Result<(X509, PKey<Private>)> {
    let rsa = Rsa::generate(2048)?;
    let pkey = PKey::from_rsa(rsa)?;
    let mut builder = X509::builder()?;
    
    // Konfigurasi Nama & Serial
    let mut name_builder = X509Name::builder()?;
    name_builder.append_entry_by_text("CN", "Stellar")?;
    let name = name_builder.build();
    builder.set_subject_name(&name)?;
    builder.set_issuer_name(&name)?;

    // Ekstensi Kritis untuk Android Modern
    let ctx = builder.x509v3_context(None, None);
    
    // 1. Subject Key Identifier
    let skid = boring::x509::extension::SubjectKeyIdentifier::new()
        .build(&ctx)?;
    builder.append_extension(&skid)?;

    // 2. Authority Key Identifier
    let akid = boring::x509::extension::AuthorityKeyIdentifier::new()
        .keyid(true)
        .build(&ctx)?;
    builder.append_extension(&akid)?;

    builder.sign(&pkey, MessageDigest::sha256())?;
    Ok((builder.build(), pkey))
}
```

## 3. Analisis Keamanan Client
1. **Isolasi Private Key:** Kunci privat tidak pernah meninggalkan perangkat dan hanya dapat diakses oleh aplikasi Stellar (direktori `/data/user/0/...`).
2. **TLS 1.3:** Seluruh proses komunikasi menggunakan TLS 1.3 melalui BoringSSL, mencegah serangan *man-in-the-middle* pada lapisan transport.
3. **Otentikasi Berlapis:** Keamanan client tidak hanya bergantung pada TLS, tetapi juga pada verifikasi PIN melalui protokol SPAKE2 yang menjamin bahwa hanya client yang memegang PIN yang dapat menyelesaikan jabat tangan kriptografis.

---
*Dokumen ini merupakan bagian dari spesifikasi teknis project Stellar.*