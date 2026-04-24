use boring::error::ErrorStack;
use anyhow::anyhow;

/// Helper untuk mengekstraksi pesan error mendalam dari antrean internal BoringSSL.
/// Digunakan untuk mendiagnosis error "Unknown BoringSSL error" yang sering muncul pada operasi kriptografi.
pub fn detailed_boring_error(context_msg: &str) -> anyhow::Error {
    // Mengambil stack error dari thread-local storage BoringSSL
    let stack = ErrorStack::get();
    let errors = stack.errors();

    if errors.is_empty() {
        return anyhow!("{}: BoringSSL error (antrean error kosong)", context_msg);
    }

    let mut reports = Vec::new();
    for err in errors {
        let reason = err.reason().unwrap_or("unknown_reason");
        let lib = err.library().unwrap_or("unknown_lib");
        let func = err.function().unwrap_or("unknown_func");
        
        reports.push(format!("[{}] di fungsi {} ({})", reason, func, lib));
    }

    anyhow!("{}: {}", context_msg, reports.join(" -> "))
}