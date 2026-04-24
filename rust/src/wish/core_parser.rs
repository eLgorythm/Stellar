use serde::{Deserialize, Serialize};
use std::fs;
use std::path::Path;
use anyhow::{Result, anyhow, Ok as AnyOk};
use log::{info, error, debug, warn};
use std::collections::HashMap;

use flutter_rust_bridge::frb;
use crate::frb_generated::StreamSink;
use crate::wish::{get_metadata, json_parser, GachaMetadata};

// These structs are defined in wish_parser.rs and used here.
use crate::wish_parser::{GachaLogEntry, GachaResponse, GachaData, WishHistoryStore, CompletedBannerInfo, ProgressUpdate, FiveStarHistory, BannerSummary, ExportResult};

/// Fungsi untuk mengimpor file JSON eksternal (UIGF/Stellar Format)
pub fn import_local_json(json_content: String, storage_dir: String, meta: Box<dyn GachaMetadata>, manual_uid: Option<String>) -> Result<usize> {
    let game_id = meta.get_game_id();
    let save_path = Path::new(&storage_dir).join(format!("wish_{}.json", game_id));
    
    // 1. Gunakan parser universal untuk mendapatkan list entri
    let import_result = json_parser::parse_universal_json(&json_content, game_id, manual_uid.clone())?;

    // 2. Muat data lama
    let mut entries_map: HashMap<String, GachaLogEntry> = HashMap::new();
    let mut store_meta = (None, None);
    if save_path.exists() {
        if let Ok(data) = fs::read_to_string(&save_path) {
            if let Ok(store) = serde_json::from_str::<WishHistoryStore>(&data) {
                for entry in store.entries {
                    entries_map.insert(entry.id.clone(), entry);
                }
                store_meta = (store.uid, store.lang);
            }
        }
    }

    // 3. Merge data baru (hindari duplikat berdasarkan ID)
    let initial_count = entries_map.len();
    for entry in import_result.entries {
        entries_map.insert(entry.id.clone(), entry);
    }
    let added_count = entries_map.len() - initial_count;

    // 4. Simpan kembali
    let final_store = WishHistoryStore { 
        entries: entries_map.values().cloned().collect(),
        uid: manual_uid.or(import_result.uid).or(store_meta.0),
        lang: import_result.lang.or(store_meta.1),
    };
    
    let json_data = serde_json::to_string_pretty(&final_store)?;
    fs::write(&save_path, json_data)?;

    info!(
        "[IMPORTER] Berhasil mengimpor {} data baru ke {}. Total: {}", 
        added_count, game_id, entries_map.len()
    );

    Ok(added_count)
}

/// Fungsi untuk mengekspor data ke format JSON standar UIGF
pub fn export_local_json(storage_dir: String, meta: Box<dyn GachaMetadata>, version: String, manual_uid: Option<String>, app_version: String) -> Result<ExportResult> {
    let game_id = meta.get_game_id();
    let path = Path::new(&storage_dir).join(format!("wish_{}.json", game_id));
    if !path.exists() {
        return Err(anyhow!("Tidak ada data riwayat untuk game ini."));
    }

    let data = fs::read_to_string(path)?;
    let store: WishHistoryStore = serde_json::from_str(&data)?;

    // Mapping uigf_gacha_type berdasarkan standar UIGF
    let mut export_list = store.entries;
    for entry in export_list.iter_mut() {
        entry.uigf_gacha_type = meta.map_gacha_type(&entry.gacha_type);
    }

    // Prioritas UID: Manual > Stored > Fallback dari ID
    let mut final_uid = manual_uid.filter(|u| !u.trim().is_empty()).unwrap_or_else(|| {
        store.uid.clone().unwrap_or_else(|| {
            export_list.first().map(|e| e.id.chars().take(9).collect::<String>()).unwrap_or_else(|| "000000000".into())
        })
    });
    let final_lang = store.lang.unwrap_or_else(|| "en-us".to_string());
    
    // Logika Timezone berdasarkan prefix UID (Referensi dari biuu/genshin-wish-export)
    // 6(America): TZ=-5, 7(Europe): TZ=1, Lainnya (Asia/CN): TZ=8
    let timezone = if final_uid.starts_with('6') {
        -5 // America
    } else if final_uid.starts_with('7') {
        1  // Europe
    } else {
        8  // Asia / PRC
    };

    let now = chrono::Local::now();
    let export_timestamp = now.timestamp();
    let export_time = now.format("%Y-%m-%d %H:%M:%S").to_string();

    // Pastikan format version selalu diawali dengan 'v' (misal: "4.0" -> "v4.0")
    let uigf_version = if version.starts_with('v') {
        version.clone()
    } else {
        format!("v{}", version)
    };

    // Metadata standar UIGF
    let mut info = json_parser::GachaArchiveInfo {
        export_app: "Stellar".to_string(),
        export_app_version: app_version,
        version: uigf_version.clone(),
        lang: final_lang.clone(),
        export_timestamp,
        region_time_zone: None,
        uid: None,
    };

    // Untuk v3.0 / SRGF, UID dan Timezone masuk ke metadata 'info' sesuai TODO.md
    if !uigf_version.starts_with("v4") {
        info.uid = Some(final_uid.clone());
        info.region_time_zone = Some(timezone);
    }

    let mut info_value = serde_json::to_value(info)?;

    // Backward Compatibility: UIGF v3.0 menggunakan key 'uigf_version' atau 'srgf_version'
    if !uigf_version.starts_with("v4") {
        if let Some(obj) = info_value.as_object_mut() {
            if let Some(v) = obj.remove("version") {
                let key = if game_id == "hsr" { "srgf_version" } else { "uigf_version" };
                obj.insert(key.to_string(), v);
            }
        }
    }

    // Bersihkan data dari tiap entry agar sesuai output TODO.md yang ramping (tanpa redundansi UID/Lang)
    for entry in export_list.iter_mut() {
        entry.uid = None;
        entry.lang = None;
    }

    // Cek apakah versi yang diminta adalah keluarga v4.x
    let export_data = if uigf_version.starts_with("v4") {
        let pool_name = meta.get_uigf_pool_name();
        let account = json_parser::UigfV4Account { 
            uid: final_uid.clone(), 
            timezone,
            list: export_list 
        };

        let mut v4_store = json_parser::UigfV4Store {
            info: Some(info_value),
            hk4e: None,
            hkrpg: None,
            nap: None,
        };
        match pool_name {
            "hk4e" => v4_store.hk4e = Some(vec![account]),
            "hkrpg" => v4_store.hkrpg = Some(vec![account]),
            "nap" => v4_store.nap = Some(vec![account]),
            _ => return Err(anyhow!("Unknown UIGF v4 pool name")),
        }
        serde_json::to_string_pretty(&v4_store)?
    } else {
        serde_json::to_string_pretty(&json_parser::UigfV3Store { info: Some(info_value), list: export_list })?
    };

    let file_name = format!("STELLAR_UIGF_{}_{}_{}.json", uigf_version, final_uid, now.format("%Y%m%d_%H%M%S"));

    info!("[EXPORTER] Data {} berhasil diubah ke format JSON standar.", game_id);
    
    Ok(ExportResult { content: export_data, file_name })
}

/// Fungsi utama untuk mengambil data dari URL dan menyimpannya ke JSON
pub async fn fetch_and_save_history(sink: StreamSink<ProgressUpdate>, url: String, storage_dir: String, meta: Box<dyn GachaMetadata>) -> Result<()> {
    let game_id = meta.get_game_id();
    let save_path = Path::new(&storage_dir).join(format!("wish_{}.json", game_id));

    info!("[PARSER] Memulai impor untuk game: {}. Path: {:?}", game_id, save_path);

    // 1. Muat data lama jika ada agar tidak hilang dan menghindari duplikat
    let mut entries_map: HashMap<String, GachaLogEntry> = HashMap::new();
    let mut existing_meta = (None, None);
    if save_path.exists() {
        if let Ok(data) = fs::read_to_string(&save_path) {
            if let Ok(store) = serde_json::from_str::<WishHistoryStore>(&data) {
                for entry in store.entries {
                    entries_map.insert(entry.id.clone(), entry);
                }
                existing_meta = (store.uid, store.lang);
            }
        }
    }
    info!("[PARSER] Database lokal dimuat: {} entri ditemukan.", entries_map.len());

    let mut completed_banner_details_list: Vec<CompletedBannerInfo> = Vec::new();
    let clean_url = url.trim().trim_matches('"').trim_matches('\'').replace("&amp;", "&");
    let filtered_query = if let Some(q_start) = clean_url.find('?') {
        let after_q = &clean_url[q_start + 1..];
        let raw_params = after_q.split('#').next().unwrap_or(after_q);

        // Hapus gacha_type, size, dan end_id dari query asli agar tidak bentrok saat kita append
        raw_params.split('&')
            .filter(|p| {
                !p.starts_with("gacha_type=") && 
                !p.starts_with("size=") && 
                !p.starts_with("end_id=") &&
                !p.starts_with("page=")
            })
            .collect::<Vec<_>>()
            .join("&")
    } else {
        return Err(anyhow!("URL tidak valid: Parameter tidak ditemukan"));
    };
    debug!("[PARSER] Base Query: {}", filtered_query);

    // 2. Ekstrak region untuk menentukan host API
    // Asia: os_asia, America: os_usa, Europe: os_euro, TW/HK/MO: os_cht
    let region = filtered_query.split('&')
        .find(|p| p.starts_with("region="))
        .and_then(|p| p.split('=').nth(1))
        .unwrap_or("");

    // Deteksi UID & Lang sekarang sepenuhnya mengandalkan isi respons JSON dari server
    // agar lebih akurat dibandingkan mengambil dari parameter URL.
    let mut extracted_uid: Option<String> = None;
    let mut extracted_lang: Option<String> = None;

    // 3. Ambil Config via Metadata
    let (host, path) = meta.get_api_config(region);
    let gacha_types = meta.get_gacha_types();
    
    let client = reqwest::Client::new();
    let base_api_url = format!("https://{}{}", host, path);

    for g_type in gacha_types {
        let mut last_id = "0".to_string();
        let mut current_page = 1;
        let mut retry_count = 0;
        let banner_name = meta.format_banner_title(g_type);
        info!("[PARSER] === Memulai Banner: {} (Type {}) ===", banner_name, g_type);

        meta.log_fetch_banner(g_type);

        let mut total_fetched_this_banner = 0;

        // Kirim update progres sebelum memulai fetch untuk tipe gacha ini
        let _ = sink.add(ProgressUpdate {
            gacha_type: banner_name.clone(),
            current_page,
            total_entries_fetched: entries_map.len(),
            completed_banner_details: completed_banner_details_list.clone(),
        });

        loop {
            // Konstruksi URL API dengan parameter asli + pagination (Standard Stellar Protocol)
            let fetch_url = format!("{}?{}&gacha_type={}&size=20&end_id={}&page={}", 
                base_api_url, filtered_query, g_type, last_id, current_page);

            debug!("[PARSER] Fetching Page {}: URL={}", current_page, fetch_url);

            let response_res = client.get(&fetch_url)
                .header("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
                .send()
                .await;

            let response = match response_res {
                Ok(r) => r,
                Err(e) => {
                    error!("[PARSER] Request failed for type {}: {}", g_type, e);
                    break; // Lewati banner ini jika ada masalah jaringan
                }
            };

            let body = response.text().await.unwrap_or_default();
            
            // Coba parse JSON secara manual agar bisa memberikan error context jika gagal
            let resp: GachaResponse = match serde_json::from_str(&body) {
                Ok(r) => r,
                Err(_) => {
                    error!("[PARSER] Server returned non-JSON response for type {}", g_type);
                    break; 
                }
            };

            // Deteksi UID & Lang dari isi list jika tidak ada di URL
            if let Some(ref data) = resp.data {
                if let Some(first) = data.list.first() {
                    if extracted_uid.is_none() { extracted_uid = first.uid.clone(); }
                    if extracted_lang.is_none() { extracted_lang = first.lang.clone(); }
                }
            }

            if resp.retcode != 0 {
                // Tangani Rate Limit (visit too frequently)
                if resp.message.contains("visit too frequently") && retry_count < 3 {
                    retry_count += 1;
                    warn!("[PARSER] Rate limit terdeteksi. Menunggu 5 detik sebelum mencoba lagi (Retry {}/3)...", retry_count);
                    tokio::time::sleep(std::time::Duration::from_secs(5)).await;
                    continue; // Coba lagi halaman yang sama
                }

                if resp.retcode == -101 || resp.message.contains("authkey") {
                    error!("[PARSER] Authkey Expired! Berhenti.");
                    return Err(anyhow!("Authkey expired. Please refresh the history page in-game."));
                }

                error!("[PARSER] API Error for type {}: {}", g_type, resp.message);
                break; // Abaikan banner yang tidak valid/kosong bagi user tersebut
            } else {
                // Reset retry jika berhasil
                retry_count = 0;
            }

            if let Some(data) = resp.data {
                if data.list.is_empty() { 
                    info!("[PARSER] Selesai: Tidak ada data lagi di halaman {}.", current_page);
                    break; 
                }
                
                let list_len = data.list.len();
                let mut new_in_page = 0;
                last_id = data.list.last().map(|i| i.id.clone()).unwrap_or(last_id);

                for entry in data.list {
                    if !entries_map.contains_key(&entry.id) {
                        new_in_page += 1;
                        entries_map.insert(entry.id.clone(), entry);
                    }
                }

                total_fetched_this_banner += list_len;
                info!("[PARSER] Page {} OK: Dapat {}, Baru {}, Total Banner: {}", current_page, list_len, new_in_page, total_fetched_this_banner);

                current_page += 1;

                // Kirim update progres setelah setiap halaman berhasil di-fetch
                let _ = sink.add(ProgressUpdate {
                    gacha_type: banner_name.clone(),
                    current_page,
                    total_entries_fetched: entries_map.len(),
                    completed_banner_details: completed_banner_details_list.clone(),
                });
                
                // Delay lebih manusiawi agar tidak terkena rate limit (standar 1 detik)
                tokio::time::sleep(std::time::Duration::from_millis(1000)).await;
            } else {
                break;
            }
        }
        completed_banner_details_list.push(CompletedBannerInfo {
            gacha_type: banner_name, entries_count: total_fetched_this_banner,
        });

        // SIMPAN PER BANNER: Memastikan jika banner berikutnya gagal, banner sebelumnya sudah tersimpan.
        let store = WishHistoryStore { 
            entries: entries_map.values().cloned().collect(),
            uid: extracted_uid.clone().or(existing_meta.0.clone()),
            lang: extracted_lang.clone().or(existing_meta.1.clone()),
        };
        match serde_json::to_string_pretty(&store) {
            Ok(json_data) => {
                let _ = fs::write(&save_path, json_data);
                info!("[PARSER] Progress tersimpan ke disk. Total global: {}", entries_map.len());
            },
            Err(e) => error!("[PARSER] Gagal serialisasi data: {}", e),
        }

        // Jeda antar tipe banner agar server tidak curiga
        tokio::time::sleep(std::time::Duration::from_secs(2)).await;
    }

    // 5. Final Sink Update
    let _ = sink.add(ProgressUpdate {
        gacha_type: "Finished".to_string(),
        current_page: 0,
        total_entries_fetched: entries_map.len(),
        completed_banner_details: completed_banner_details_list,
    });
    info!("[PARSER] Seluruh proses impor selesai.");
    AnyOk(())
}

/// Memuat dari JSON dan menghitung Pity
pub fn calculate_pity(storage_dir: String, meta: Box<dyn GachaMetadata>) -> Result<Vec<BannerSummary>> {
    let game_id = meta.get_game_id();
    let path = Path::new(&storage_dir).join(format!("wish_{}.json", game_id));
    if !path.exists() { return Ok(Vec::new()); }

    let data = fs::read_to_string(path)?;
    let store: WishHistoryStore = serde_json::from_str(&data)?;

    let mut summaries = Vec::new();
    // Kelompokkan berdasarkan gacha_type
    let mut grouped: HashMap<String, Vec<GachaLogEntry>> = HashMap::new();
    for entry in store.entries {
        let g_type = meta.map_gacha_type(&entry.gacha_type);
        grouped.entry(g_type).or_default().push(entry);
    }

    for (g_type, mut items) in grouped {
        // Urutkan berdasarkan ID secara numerik (u64) dari yang terbaru ke terlama
        items.sort_by(|a, b| {
            let id_a = a.id.parse::<u64>().unwrap_or(0);
            let id_b = b.id.parse::<u64>().unwrap_or(0);
            id_b.cmp(&id_a)
        });

        let mut pity = 0;
        let mut pity_4_star = 0;
        let mut total_4_star = 0;
        let mut last_5_star = "None".to_string();
        let mut last_5_star_pity = 0;
        let mut history_5_star = Vec::new();
        let mut history_4_star = Vec::new();
        let mut monthly_map: HashMap<(i32, i32), i32> = HashMap::new();

        // Hitung statistik bulanan untuk semua item (termasuk B3)
        for item in &items {
            if let Some(date_part) = item.time.split_whitespace().next() {
                let parts: Vec<&str> = date_part.split('-').collect();
                if parts.len() >= 2 {
                    if let (Ok(y), Ok(m)) = (parts[0].parse::<i32>(), parts[1].parse::<i32>()) {
                        *monthly_map.entry((y, m)).or_insert(0) += 1;
                    }
                }
            }
        }
        let mut is_guaranteed = false;
        let mut found_5_star = false;
        
        let is_event_banner = meta.is_event_banner(&g_type);

        // Hitung riwayat bintang 5 dari yang terlama ke terbaru untuk kalkulasi pity yang benar
        let mut last_idx = items.len();
        for (i, item) in items.iter().enumerate().rev() {
            if item.rank_type == "5" {
                let p = (last_idx - i) as i32;
                history_5_star.push(FiveStarHistory { 
                    name: item.name.clone(), 
                    pity: p,
                    is_standard: meta.is_standard_item(&item.name),
                    time: item.time.clone(),
                    item_type: item.item_type.clone(),
                });
                last_idx = i;
            }
        }

        // Hitung riwayat bintang 4
        let mut last_4_idx = items.len();
        for (i, item) in items.iter().enumerate().rev() {
            if item.rank_type == "4" {
                let p = (last_4_idx - i) as i32;
                history_4_star.push(FiveStarHistory { 
                    name: item.name.clone(), 
                    pity: p,
                    is_standard: meta.is_standard_item(&item.name),
                    time: item.time.clone(),
                    item_type: item.item_type.clone(),
                });
                last_4_idx = i;
            }
        }
        
        // Hitung total 4-star dan current 4-star pity
        let mut found_4_star = false;
        for (i, item) in items.iter().enumerate() {
            if item.rank_type == "4" {
                total_4_star += 1;
                if !found_4_star {
                    pity_4_star = i as i32;
                    found_4_star = true;
                }
            }
        }
        if !found_4_star {
            pity_4_star = items.len() as i32;
        }

        let total_5star = history_5_star.len();
        let avg_pity = if total_5star > 0 {
            history_5_star.iter().map(|h| h.pity).sum::<i32>() as f64 / total_5star as f64
        } else { 0.0 };

        // Balikkan urutan agar yang terbaru ada di atas untuk UI
        history_5_star.reverse();
        history_4_star.reverse();

        for (i, item) in items.iter().enumerate() {
            if item.rank_type == "5" {
                if !found_5_star {
                    pity = i as i32;
                    last_5_star = item.name.clone();
                    last_5_star_pity = history_5_star.first().map(|h| h.pity).unwrap_or(0);
                    is_guaranteed = is_event_banner && meta.is_standard_item(&item.name);
                    found_5_star = true;
                }
            }
        }

        if !found_5_star { pity = items.len() as i32; }

        let mut monthly_stats: Vec<crate::wish_parser::MonthlyStat> = monthly_map.into_iter()
            .map(|((year, month), total_pulls)| crate::wish_parser::MonthlyStat { year, month, total_pulls })
            .collect();
        monthly_stats.sort_by(|a, b| b.year.cmp(&a.year).then(b.month.cmp(&a.month)));

        summaries.push(BannerSummary {
            title: meta.format_banner_title(&g_type),
            pity,
            last_5_star,
            last_5_star_pity,
            is_guaranteed,
            total_wishes: items.len() as i32,
            history_5_star,
            history_4_star,
            avg_pity,
            total_4_star,
            pity_4_star,
            monthly_stats,
        });
    }

    // Urutkan summary agar posisi card di UI tidak berpindah-pindah
    summaries.sort_by_cached_key(|s| meta.sort_order(&s.title));

    Ok(summaries)
}