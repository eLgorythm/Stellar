use super::GachaMetadata;
use anyhow::Result;

pub struct HsrMetadata;

impl GachaMetadata for HsrMetadata {
    fn get_game_id(&self) -> &'static str { "hsr" }

    fn get_api_config(&self, region: &str) -> (&'static str, &'static str) {
        let h = if region.starts_with("cn_") { "public-operation-hkrpg.mihoyo.com" } else { "public-operation-hkrpg-sg.hoyoverse.com" };
        (h, "/common/gacha_record/api/getGachaLog")
    }
    fn get_gacha_types(&self) -> Vec<&'static str> { vec!["1", "2", "11", "12"] }
    fn format_banner_title(&self, gacha_type: &str) -> String { "HSR Banner".to_string() }
    fn is_standard_item(&self, name: &str) -> bool { false }
    fn map_gacha_type(&self, gacha_type: &str) -> String { gacha_type.to_string() }
    fn is_event_banner(&self, gacha_type: &str) -> bool { matches!(gacha_type, "11" | "12") }
    fn sort_order(&self, _: &str) -> i32 { 1 }
    fn get_uigf_pool_name(&self) -> &'static str { "hkrpg" }
}