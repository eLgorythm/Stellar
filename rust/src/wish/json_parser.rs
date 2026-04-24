use serde::{Deserialize, Serialize};
use crate::wish_parser::{GachaLogEntry, WishHistoryStore};
use anyhow::{Result, anyhow};

/// Metadata untuk format UIGF/SRGF
#[derive(Debug, Serialize, Deserialize)]
pub struct GachaArchiveInfo {
    pub export_app: String,
    pub export_app_version: String,
    #[serde(rename = "version", alias = "uigf_version", alias = "srgf_version")]
    pub version: String,
    pub lang: String,
    pub export_timestamp: i64,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub region_time_zone: Option<i32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub uid: Option<String>,
}

/// Format UIGF v3.x (Legacy - Single Game)
#[derive(Debug, Serialize, Deserialize)]
pub struct UigfV3Store {
    pub info: Option<serde_json::Value>,
    pub list: Vec<GachaLogEntry>,
}

/// Format UIGF v4.x (Multi-game/Multi-account)
/// Mendukung v4.0, v4.1 (ZZZ support), dan v4.2
#[derive(Debug, Serialize, Deserialize)]
pub struct UigfV4Store {
    pub info: Option<serde_json::Value>,
    pub hk4e: Option<Vec<UigfV4Account>>,  // Genshin Impact
    pub hkrpg: Option<Vec<UigfV4Account>>, // Honkai: Star Rail
    pub nap: Option<Vec<UigfV4Account>>,   // Zenless Zone Zero (v4.1+)
}

#[derive(Debug, Serialize, Deserialize)]
pub struct UigfV4Account {
    pub uid: String,
    pub timezone: i32,
    pub list: Vec<GachaLogEntry>,
}

pub struct UniversalImportResult {
    pub entries: Vec<GachaLogEntry>,
    pub uid: Option<String>,
    pub lang: Option<String>,
}

/// Fungsi sentral untuk memproses berbagai jenis JSON ekspor
pub fn parse_universal_json(content: &str, game: &str, manual_uid: Option<String>) -> Result<UniversalImportResult> {
    // 1. Coba format Stellar (Internal)
    if let Ok(store) = serde_json::from_str::<WishHistoryStore>(content) {
        if !store.entries.is_empty() { 
            return Ok(UniversalImportResult {
                entries: store.entries,
                uid: store.uid,
                lang: store.lang,
            });
        }
    }

    // 2. Coba format UIGF v4.x (Mendukung 4.0, 4.1, 4.2)
    // Format ini menggunakan struktur array per game (hk4e, hkrpg, nap)
    if let Ok(v4) = serde_json::from_str::<UigfV4Store>(content) {
        let (meta_uid, meta_lang) = v4.info.as_ref()
            .and_then(|v| serde_json::from_value::<GachaArchiveInfo>(v.clone()).ok())
            .map(|i| (i.uid, Some(i.lang)))
            .unwrap_or((None, None));

        let accounts = match game {
            "gi" => v4.hk4e,
            "hsr" => v4.hkrpg,
            "zzz" => v4.nap,
            _ => None,
        };
        if let Some(accs) = accounts {
            // Ambil UID dari entri jika di info v4 tidak ada
            let first_entry_uid = accs.first().map(|a| a.uid.clone());
            let first_entry_lang = accs.first().and_then(|a| a.list.first()).and_then(|e| e.lang.clone());

            let entries: Vec<GachaLogEntry> = accs.into_iter()
                .filter(|a| {
                    // Jika user input UID, filter hanya akun yang cocok. 
                    // Jika tidak, ambil semua.
                    match (&manual_uid, &a.uid) {
                        (Some(m), u) => m == u,
                        _ => true,
                    }
                })
                .flat_map(|a| a.list).collect();
            if !entries.is_empty() { 
                return Ok(UniversalImportResult {
                    uid: meta_uid.or(first_entry_uid),
                    lang: meta_lang.or(first_entry_lang),
                    entries,
                });
            }
        }
    }

    // 3. Coba format UIGF v3.x (Genshin)
    if let Ok(v3) = serde_json::from_str::<UigfV3Store>(content) {
        let (meta_uid, meta_lang) = v3.info.as_ref()
            .and_then(|v| serde_json::from_value::<GachaArchiveInfo>(v.clone()).ok())
            .map(|i| (i.uid, Some(i.lang)))
            .unwrap_or((None, None));

        if !v3.list.is_empty() { 
            return Ok(UniversalImportResult {
                entries: v3.list,
                uid: meta_uid,
                lang: meta_lang,
            });
        }
    }

    Err(anyhow!("Format JSON tidak dikenal atau data kosong untuk game ini. Stellar mendukung UIGF v3.0, SRGF v1.0, dan v4.0-4.2."))
}
