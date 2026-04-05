mod frb_generated; /* AUTO INJECTED BY flutter_rust_bridge. This line may not be accurate, and you can change it according to your needs. */
pub mod api;
pub mod pair;
pub mod connect;
pub mod boring_helper;
pub mod logger;

/// Mengekspos fungsi inisialisasi ke tingkat crate agar bisa dipanggil oleh api.rs
pub fn init_app() {
    logger::init_app();
}