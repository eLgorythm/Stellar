pub mod genshin;
pub mod hsr;
pub mod zzz;
pub mod json_parser;
pub mod core_parser;

pub trait GachaMetadata: Send + Sync {
    fn get_game_id(&self) -> &'static str;
    fn get_api_config(&self, region: &str) -> (&'static str, &'static str);
    fn get_gacha_types(&self) -> Vec<&'static str>;
    fn format_banner_title(&self, gacha_type: &str) -> String;
    fn is_standard_item(&self, name: &str) -> bool;
    fn map_gacha_type(&self, gacha_type: &str) -> String; // Untuk Pity Sharing
    fn is_event_banner(&self, gacha_type: &str) -> bool;
    fn sort_order(&self, title: &str) -> i32;
    fn get_uigf_pool_name(&self) -> &'static str;
    fn log_fetch_banner(&self, _g_type: &str) {}
}

pub fn get_metadata(game: &str) -> Box<dyn GachaMetadata> {
    match game {
        "gi" => Box::new(genshin::GenshinMetadata),
        "hsr" => Box::new(hsr::HsrMetadata),
        "zzz" => Box::new(zzz::ZzzMetadata),
        _ => panic!("Game {} tidak didukung", game),
    }
}