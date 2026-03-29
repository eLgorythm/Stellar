class ConnectLogic {
  static Future<String> connect() async {
    // Di sini nantinya Anda akan memanggil fungsi Rust untuk koneksi shell
    await Future.delayed(const Duration(seconds: 1));
    return "Fitur koneksi akan segera hadir menggunakan sertifikat yang tersimpan.";
  }
}