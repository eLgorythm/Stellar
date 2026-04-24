use super::GachaMetadata;
use anyhow::Result;
use log::info;

pub struct GenshinMetadata;

impl GachaMetadata for GenshinMetadata {
    fn get_game_id(&self) -> &'static str { "gi" }

    fn get_api_config(&self, region: &str) -> (&'static str, &'static str) {
        let host = if region.starts_with("cn_") {"public-operation-hk4e.mihoyo.com"} else {"public-operation-hk4e-sg.hoyoverse.com"};
        (host, "/gacha_info/api/getGachaLog")
    }

    fn get_gacha_types(&self) -> Vec<&'static str> {
        vec!["100", "301", "302", "200", "500"]
    }

    fn format_banner_title(&self, gacha_type: &str) -> String {
        match gacha_type {
            "301" | "400" => "Character Event".to_string(),
            "302" => "Weapon Event".to_string(),
            "200" => "Standard Wish".to_string(),
            "500" => "Chronicled Wish".to_string(),
            "100" => "Novice Wish".to_string(),
            _ => format!("GI Type {}", gacha_type),
        }
    }

    fn is_standard_item(&self, name: &str) -> bool {
        let standard = [
            "Diluc", "Jean", "Qiqi", "Mona", "Keqing", "Tighnari", "Dehya", "Yumemizuki Mizuki",
            "Skyward Pride", "Skyward Blade", "Skyward Atlas", "Skyward Harp", "Skyward Spine", 
            "Aquila Favonia", "Amos' Bow", "Lost Prayer to the Sacred Winds", 
            "Primordial Jade Winged-Spear", "Wolf's Gravestone"
        ];
        standard.contains(&name)
    }

    fn map_gacha_type(&self, gacha_type: &str) -> String {
        if gacha_type == "400" { "301".to_string() } else { gacha_type.to_string() }
    }

    fn is_event_banner(&self, gacha_type: &str) -> bool {
        matches!(gacha_type, "301" | "302" | "500")
    }

    fn sort_order(&self, title: &str) -> i32 {
        match title {
            "Character Event" => 1, "Weapon Event" => 2, "Standard Wish" => 3, "Chronicled Wish" => 4, _ => 99
        }
    }

    fn get_uigf_pool_name(&self) -> &'static str { "hk4e" }

    fn log_fetch_banner(&self, g_type: &str) {
        if g_type == "301" {
            info!("[PARSER] Tipe 301 terdeteksi: Mengambil gabungan data Character Event 1 & 2.");
        }
    }
}