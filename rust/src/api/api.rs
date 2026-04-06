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

pub async fn get_gacha_link(_port: u16, _storage_dir: String) -> anyhow::Result<String> {
    crate::connect::scan_gacha_link().await
}

pub async fn connect_to_device(addr: String, storage_dir: String) -> anyhow::Result<String> {
    connect::connect_to_device(addr, storage_dir).await
}

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