Saat menginisialisasi SPAKE2, ADB menggunakan identitas statis. Jika library SPAKE2 di Rust kamu (misalnya menggunakan spake2 crate) tidak menggunakan Personalization String atau Context yang sama persis dengan string di atas, maka key_material yang dihasilkan akan berbeda, meskipun PIN-nya benar.

    Client Role: Menggunakan my_name = "adb pair client" dan their_name = "adb pair server".

    Penting: Pastikan panjang string ini dihitung dengan benar (biasanya tanpa null terminator \0 jika menggunakan sizeof - 1, tapi di sini kodenya menggunakan sizeof langsung, yang berarti menyertakan \0). Periksa apakah library Rust kamu menyertakan null terminator dalam context string-nya.

2. Alur Enkripsi vs Dekripsi (State Management)

Di dalam PairingAuthCtx, objek cipher_ hanya dibuat satu kali setelah SPAKE2_process_msg berhasil.
C++

cipher_.reset(new Aes128Gcm(key_material, key_material_len));

Ini mengonfirmasi bahwa:

    Satu Kunci untuk Dua Arah: Kunci AES yang sama digunakan untuk Encrypt (TX) dan Decrypt (RX).

    Urutan Nonce: Karena objek Aes128Gcm yang sama digunakan, kamu harus sangat hati-hati dengan urutan panggilannya.

        Setiap kali Encrypt() dipanggil, enc_sequence_ bertambah.

        Setiap kali Decrypt() dipanggil, dec_sequence_ bertambah.

3. Sinkronisasi Urutan (Urutan Kirim/Terima)

Sesuai kode ini, urutan operasi yang diharapkan ADB adalah:

    Handshake: Bertukar pesan SPAKE2.

    Init Cipher: Buat objek AES dengan kunci hasil SPAKE2.

    Kirim PeerInfo: Panggil Encrypt(). (Ini akan menggunakan enc_sequence = 0).

    Terima PeerInfo: Panggil Decrypt(). (Ini akan menggunakan dec_sequence = 0).

Kenapa kamu gagal verifikasi Tag?
Jika kamu tidak sengaja memanggil Encrypt() dua kali sebelum Decrypt(), atau jika logika dec_sequence kamu di Rust dimulai dari 1, maka verifikasi Tag dari server akan gagal karena server mengirimkan balasan pertamanya menggunakan nonce 0.
4. Ukuran Buffer (Safe Sizes)
C++

size_t PairingAuthCtx::SafeEncryptedSize(size_t len) {
    return cipher_->EncryptedSize(len); // len + 16 byte tag
}

Pastikan di Rust, saat kamu menerima paket dari ADB:

    Ambil total panjang data dari header.

    Pisahkan 16 byte terakhir sebagai Tag.

    Sisa datanya adalah Ciphertext.

    Kirim Ciphertext + Tag tersebut ke fungsi dekripsi BoringSSL/RustCrypto kamu.