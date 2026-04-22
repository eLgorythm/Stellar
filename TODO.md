1. UIGF v3.0

Versi ini merupakan dasar dari format standar yang banyak digunakan sebelumnya. Fokus utamanya adalah membungkus data dalam objek info dan list.

Struktur JSON:
{
  "info": {
    "uid": "123456789",
    "lang": "zh-cn",
    "export_app": "ContohApp",
    "export_app_version": "v1.0.0",
    "export_timestamp": 1610000000,
    "uigf_version": "v3.0"
  },
  "list": [
    {
      "gacha_type": "301",
      "item_id": "10000002",
      "count": "1",
      "time": "2023-01-01 18:00:00",
      "name": "Kamisato Ayaka",
      "item_type": "Character",
      "rank_type": "5",
      "id": "1234567890123456789",
      "uigf_gacha_type": "301"
    }
  ]
}

2. UIGF v4.0

Lompatan ke v4.0 memperkenalkan standarisasi yang lebih ketat untuk mendukung ekosistem game HoYoverse lainnya (seperti Star Rail melalui SRGF) dan memastikan konsistensi ID.

Perubahan Utama:

    Penambahan export_time (format string tanggal).

    Struktur list tetap sama, namun validasi terhadap item_id dan id (export ID dari game) menjadi wajib.

3. UIGF v4.1

Versi 4.1 memberikan klarifikasi pada beberapa field opsional dan peningkatan kompatibilitas metadata untuk aplikasi lintas platform.

Struktur JSON:
{
  "info": {
    "uid": "123456789",
    "lang": "en-us",
    "export_app": "UIGF-Exporter",
    "export_app_version": "v2.1.0",
    "export_timestamp": 1713770000,
    "export_time": "2024-04-22 15:00:00", // Ditambahkan di v4.x
    "uigf_version": "v4.1",
    "region_time_zone": 8 // Zona waktu server
  },
  "list": [
    {
      "gacha_type": "400", // Chronicled Wish atau banner khusus
      "item_id": "",
      "count": "1",
      "time": "2024-03-15 10:00:00",
      "name": "Diluc",
      "item_type": "Character",
      "rank_type": "5",
      "id": "1600000000000000000",
      "uigf_gacha_type": "400"
    }
  ]
}

4. UIGF v4.2 (Terbaru)

Versi 4.2 adalah iterasi terbaru yang menyempurnakan penanganan Chronicled Wish dan pemetaan banner baru di Genshin Impact. Versi ini juga memastikan bahwa atribut uigf_gacha_type digunakan secara konsisten untuk mengelompokkan jenis banner yang secara teknis berbeda tetapi berbagi pity yang sama.

Tabel Perbandingan Atribut Utama:

Atribut,    Deskripsi,  Status
uid,    User ID pemain,    Wajib
uigf_version,   "Versi standar (v3.0, v4.0, dll).", Wajib
id, ID unik dari log asli HoYoverse (19 digit).,    Wajib
uigf_gacha_type,    Kategori banner yang sudah disederhanakan oleh UIGF.,   Wajib
item_id,    ID internal item (jika tersedia).,  Opsional/harus ada di aplikasi saya