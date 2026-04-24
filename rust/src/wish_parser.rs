use serde::{Deserialize, Serialize};
use anyhow::Result;

use flutter_rust_bridge::frb;
use crate::frb_generated::StreamSink;
use crate::wish::{core_parser, get_metadata};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct GachaLogEntry {
    pub gacha_type: String,
    #[serde(default, skip_serializing_if = "String::is_empty")]
    pub gacha_id: String,
    #[serde(default)]
    pub item_id: String,
    #[serde(default)]
    pub count: String,
    pub time: String,
    pub name: String,
    pub item_type: String,
    pub rank_type: String, // "3", "4", "5"
    pub id: String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub uid: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub lang: Option<String>,
    #[serde(default)]
    pub uigf_gacha_type: String,
}

#[derive(Debug, Deserialize)]
pub struct GachaResponse {
    pub retcode: i32,
    pub message: String,
    pub data: Option<GachaData>,
}

#[derive(Debug, Deserialize)]
pub struct GachaData {
    pub list: Vec<GachaLogEntry>,
}

/// Stellar format
#[derive(Debug, Serialize, Deserialize, Default)]
pub struct WishHistoryStore {
    pub entries: Vec<GachaLogEntry>,
    #[serde(default)]
    pub uid: Option<String>,
    #[serde(default)]
    pub lang: Option<String>,
}

#[frb]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CompletedBannerInfo {
    pub gacha_type: String,
    pub entries_count: usize,
}

#[frb]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProgressUpdate {
    pub gacha_type: String,
    pub current_page: u32,
    pub total_entries_fetched: usize,
    // Changed from Vec<String> to Vec<CompletedBannerInfo>
    pub completed_banner_details: Vec<CompletedBannerInfo>,
}

#[frb]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExportResult {
    pub content: String,
    pub file_name: String,
}

/// Fungsi untuk mengimpor file JSON eksternal (UIGF/Stellar Format)
pub fn import_local_json(json_content: String, storage_dir: String, game: String, uid: Option<String>) -> Result<usize> {
    let meta = get_metadata(&game);
    core_parser::import_local_json(json_content, storage_dir, meta, uid)
}

/// Fungsi untuk mengekspor data ke format JSON standar (UIGF/SRGF)
pub fn export_local_json(storage_dir: String, game: String, version: String, uid: Option<String>, app_version: String) -> Result<ExportResult> {
    let meta = get_metadata(&game);
    core_parser::export_local_json(storage_dir, meta, version, uid, app_version)
}

/// Fungsi utama untuk mengambil data dari URL dan menyimpannya ke JSON
pub async fn fetch_and_save_history(sink: StreamSink<ProgressUpdate>, url: String, storage_dir: String, game: String) -> Result<()> {
    let meta = get_metadata(&game);
    core_parser::fetch_and_save_history(sink, url, storage_dir, meta).await
}

#[frb]
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct FiveStarHistory {
    pub name: String,
    pub pity: i32,
    pub time: String,
    pub is_standard: bool,
    pub item_type: String,
}

#[frb]
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct MonthlyStat {
    pub year: i32,
    pub month: i32,
    pub total_pulls: i32,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct BannerSummary {
    pub title: String,
    pub pity: i32,
    pub last_5_star: String,
    pub last_5_star_pity: i32,
    pub is_guaranteed: bool,
    pub total_wishes: i32,
    pub history_5_star: Vec<FiveStarHistory>,
    pub history_4_star: Vec<FiveStarHistory>,
    pub avg_pity: f64,
    pub total_4_star: i32,
    pub pity_4_star: i32,
    pub monthly_stats: Vec<MonthlyStat>,
}

/// Memuat dari JSON dan menghitung Pity
pub fn calculate_pity(storage_dir: String, game: String) -> Result<Vec<BannerSummary>> {
    let meta = get_metadata(&game);
    core_parser::calculate_pity(storage_dir, meta)
}