use crate::pair;
use crate::connect;
use crate::frb_generated::StreamSink;
use log::info;

pub fn create_log_stream(sink: StreamSink<String>) {
    pair::init_logger(sink);
    info!("Bridge: Aliran log telah tersambung ke Dart.");
}

pub async fn init_pairing(port: u16, pairing_code: String) -> anyhow::Result<String> {
    pair::init_pairing(port, pairing_code).await
}

pub async fn connect_to_device(addr: String) -> anyhow::Result<String> {
    connect::connect_to_device(addr).await
}