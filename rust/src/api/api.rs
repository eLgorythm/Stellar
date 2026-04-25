#![allow(unexpected_cfgs)]

use crate::pair;
use crate::connect;
use crate::frb_generated::StreamSink;
use flutter_rust_bridge::frb;

#[frb(init)]
pub fn init_app() {
    crate::init_app();
}

pub async fn init_pairing(port: u16, pairing_code: String, storage_dir: String) -> anyhow::Result<String> {
    pair::init_pairing(port, pairing_code, storage_dir).await
}

/// Memulai persiapan sertifikat di latar belakang.
/// Flutter harus memanggil ini setelah UI utama muncul agar tidak membebani startup.
pub async fn pre_warm_adb(storage_dir: String) -> anyhow::Result<()> {
    pair::pre_warm_cert(storage_dir).await
}

/// Memeriksa status pairing yang sebenarnya.
/// Berbeda dengan sekadar cek file sertifikat, ini memastikan proses pairing
/// telah diselesaikan sepenuhnya sebelumnya.
pub fn check_pairing_status(storage_dir: String) -> bool {
    pair::is_paired(&storage_dir)
}

pub async fn get_gacha_link(_port: u16, _storage_dir: String) -> anyhow::Result<String> {
    crate::connect::scan_gacha_link().await
}

pub async fn connect_to_device(addr: String, storage_dir: String) -> anyhow::Result<String> {
    connect::connect_to_device(addr, storage_dir).await
}

pub fn import_local_json(json_content: String, storage_dir: String, game: String, uid: Option<String>) -> anyhow::Result<usize> {
    crate::wish_parser::import_local_json(json_content, storage_dir, game, uid)
}

pub fn export_local_json(storage_dir: String, game: String, version: String, uid: Option<String>, app_version: String) -> anyhow::Result<ExportResult> {
    crate::wish_parser::export_local_json(storage_dir, game, version, uid, app_version)
}

pub async fn perform_wish_import(sink: StreamSink<ProgressUpdate>, url: String, storage_dir: String, game: String) -> anyhow::Result<()> {
    crate::wish_parser::fetch_and_save_history(sink, url, storage_dir, game).await
}

pub fn get_wish_summary(storage_dir: String, game: String) -> anyhow::Result<Vec<BannerSummary>> {
    crate::wish_parser::calculate_pity(storage_dir, game)
}

pub use crate::wish_parser::{CompletedBannerInfo, ProgressUpdate, BannerSummary, ExportResult};

#[frb]
pub enum StellarStatus {
    Idle,
    Pairing,
    Paired,
    Connecting,
    Connected,
    Error(String),
}

#[frb]
pub struct StellarState {
    pub status: StellarStatus,
    pub port: Option<u16>,
}

// Tambahkan fungsi ini untuk "memaksa" FRB men-generate StellarStatus & StellarState
pub fn get_current_state() -> StellarState {
    StellarState {
        status: StellarStatus::Idle,
        port: None,
    }
}

// Atau jika ingin menggunakan Stream (Sangat direkomendasikan untuk UI)
pub fn create_status_stream(sink: StreamSink<StellarStatus>) {
    // Fungsi ini akan membuat FRB mengenali StellarStatus sebagai tipe data Stream
    let _ = sink.add(StellarStatus::Idle);
}