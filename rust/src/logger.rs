use android_logger::Config;
use log::LevelFilter;
use std::sync::Once;

pub fn init_logger() {
    android_logger::init_once(
        Config::default()
            .with_tag("STELLAR_RUST")
            .with_max_level(LevelFilter::Trace)
    );
    
    log::info!("[STELLAR_RUST] Logger initialized - all Rust logs now tagged STELLAR_RUST");
}

static INIT: Once = Once::new();

/// Fungsi ini bisa dipanggil dari API untuk menjamin logger menyala
pub fn init_app() {
    INIT.call_once(|| {
        init_logger();
    });
}
