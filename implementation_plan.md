# PRD Lengkap & Spesifikasi Kebutuhan Project Flutter PostSA (Point of Sale & Multi-Outlet Ecosystem)

Dokumen ini berisi **Product Requirement Document (PRD) LENGKAP**, **Spesifikasi Kebutuhan Sistem (Software Requirements Specification - SRS)**, **Arsitektur Aplikasi Flutter**, **Pemetaan Skema Database (24+ Tabel Supabase)**, dan **Panduan Struktur Folder & Roadmap Implementasi** untuk membangun project **Flutter Cross-Platform** berbasis codebase PostSA.

---

## 1. Eksekutif & Ringkasan Produk (Executive Summary)

### 1.1 Deskripsi Produk
**PostSA Flutter** adalah aplikasi *multi-tenant, cross-platform* (Android, iOS, POS Terminal hardware seperti Sunmi/iMin/PAX, serta Desktop) yang dirancang untuk mendukung operasional bisnis F&B / Retail multi-outlet secara komprehensif. 

Aplikasi Flutter ini mentransformasi seluruh kapabilitas dari ekosistem Web PostSA (Next.js + Supabase + Dexie.js) menjadi satu aplikasi mobile/tablet modern, responsif, dan **Offline-First**.

### 1.2 Peran Pengguna (User Roles & Personas)
1. **Kasir (Cashier / POS User)**: Mengelola kasir shift, pemesanan dine-in/takeaway/delivery, cetak struk via printer thermal ESC/POS, split bill, diskon/kupon, dan checkout cepat.
2. **Staf Dapur (Kitchen Staff / KDS)**: Memantau pesanan masuk secara *real-time* via WebSocket Supabase, memperbarui status dapur (*Preparing* $\rightarrow$ *Ready*), dan cetak label tiket dapur.
3. **Pelanggan (Customer / Self-Order)**: Melakukan self-order via QR meja atau catalog outlet, mengumpulkan poin loyalty, mengikuti *challenges* (stamp card, spending goal), menukar voucher, serta memilih opsi pengiriman via Biteship.
4. **Kurir (Driver / Delivery Staff)**: Menerima penugasan pengiriman, update status pengiriman (*Picked Up* $\rightarrow$ *In Transit* $\rightarrow$ *Delivered*), serta mengirim koordinat GPS live lokasi kurir.
5. **Manager & Admin Outlet**: Memantau dashboard analytics penjualan *real-time*, mengelola menu & varian, mengatur printer outlet, serta mengelola staf dan shift.

---

## 2. User Review Required & Keputusan Desain

> [!IMPORTANT]
> **Keputusan Arsitektur Utama (Flutter Tech Stack)**
> 1. **State Management & Clean Architecture**: Menggunakan **flutter_bloc** (BLoC / Cubit) dengan pembagian 3 layer (Data, Domain, Presentation).
> 2. **Offline-First Storage**: Menggunakan **Isar Database** atau **Hive** / **Drift (SQLite)** untuk menyimpan data katalog menu, draft transaksi kasir, dan antrean sinkronisasi (`SyncQueue`) saat tidak ada koneksi internet.
> 3. **Backend Service**: Menggunakan **supabase_flutter** (Auth, Realtime WebSockets, PostgREST Client, Storage).
> 4. **Hardware Thermal Printing**: Menggunakan modul **flutter_pos_printer_platform** atau **blue_thermal_printer** / **esc_pos_utils_2** untuk integrasi Thermal Printer 58mm/80mm via Bluetooth, LAN/IP, USB, dan Serial.
> 5. **Peta & Agregasi Pengiriman**: Menggunakan **flutter_map** (OpenStreetMap) atau **google_maps_flutter** + **geolocator** + API Biteship.

---

## 3. Open Questions (Pertanyaan untuk Pengguna)

> [!NOTE]
> 1. **Nama Folder & Package Name**: Apakah project Flutter baru ini akan dinamakan `postsa_mobile` (misal di folder `c:\Misi-NUS\postsa_mobile` atau dalam folder `mobile/` di repo saat ini)?
> 2. **Target Device**: Apakah fokus utama rilis pertama adalah **Tablet POS Android / Sunmi Device** + **Android/iOS Mobile**, atau juga desktop (Windows)?
> 3. **Printer Hardware**: Apakah ada merk/tipe printer thermal spesifik yang biasa dipakai (misal Sunmi built-in printer, Epson LAN/Bluetooth, atau Xprinter USB)?

---

## 4. Modul Utama & Kebutuhan Fungsional (Functional Requirements)

### 4.1 Modul 1: POS / Kasir Offline-First
* **Kebutuhan Shift Kasir (`cashier_shifts`)**:
  - Buka Shift (Input Modal Awal Kas).
  - Tutup Shift (Perhitungan kas aktual vs kas ekspektasi, ringkasan transaksi tunai, QRIS, e-wallet, bank transfer).
  - Laporan Penutupan Shift (Z-Report) & cetak ringkasan shift.
* **Manajemen Transaksi & Keranjang**:
  - Pilih Jenis Pesanan: Dine-In (pilih Meja), Takeaway, atau Delivery.
  - Seleksi Produk, Varian (Misal: Large/Medium), dan Group Modifier (Misal: Level Pedas, Topping).
  - Dukungan Produk Paket (Menu Bundling / Combo).
  - Input catatan kustom per item maupun per pesanan.
  - Penerapan Diskon (Persentase / Nominal), Kode Kupon (`coupons`), dan Poin Loyalty Pelanggan.
* **Pembayaran & Printing**:
  - Metode Pembayaran: Cash (kalkulasi kembalian otomatis), QRIS Dynamic/Static, Bank Transfer, E-Wallet, Card.
  - Integration ESC/POS Printing: Cetak Struk Pelanggan, Cetak Struk Dapur, dan Cetak Bill/Prabayar.
  - Mode Offline: Transaksi tersimpan ke local DB Isar/Hive dan otomatis dikirim ke Supabase via `SyncQueue` saat internet kembali aktif.

### 4.2 Modul 2: Kitchen Display System (KDS) & Printer Dapur
* **Stream Pesanan Dapur**:
  - Real-time listening menggunakan Supabase Realtime Channel pada tabel `orders` dan `order_items`.
  - Filter item berdasarkan `categories.is_kitchen = true`.
  - Grid / Kanban view tiket dapur berdasarkan urutan waktu masuk.
  - Notifikasi suara / chime saat ada pesanan dapur baru masuk.
* **Perubahan Status Dapur**:
  - Tombol aksi cepat: *Mark as Preparing*, *Mark as Ready*.
  - Cetak Label Makanan/Minuman Dapur via Printer Thermal Dapur.

### 4.3 Modul 3: Customer Self-Order & Loyalty Program
* **Katalog Outlet & Self-Order**:
  - Geolocation outlet picker atau Scan Meja QR Code (`/outlet/[slug]?table=X`).
  - Tampilan Banner Promo dinamik (`banners` table).
  - Otentikasi Pelanggan via Nomor HP + OTP (`otp_codes` table).
* **Loyalty Gamification & Tiers**:
  - Sistem Poin & Tier Loyalty (Bronze, Silver, Gold, Platinum) sesuai `min_lifetime_points` dan `earning_rate`.
  - Tantangan Pelanggan (*Challenges*): Stamp card, spending target, frekuensi kunjungan.
  - Rewards Catalog: Penukaran poin dengan voucher diskon, produk gratis, atau gratis ongkir.
* **Checkout & Delivery (Biteship)**:
  - Input Alamat Pengiriman Pelanggan (`delivery_addresses`).
  - Hitung Biaya Ongkir via Biteship API berdasarkan koordinat lat/long dan zona pengiriman (`delivery_zones`).
  - Tracking status pengiriman (*Pending* $\rightarrow$ *Allocated* $\rightarrow$ *Picked Up* $\rightarrow$ *In Transit* $\rightarrow$ *Delivered*).

### 4.4 Modul 4: Kurir / Driver App
* **Penugasan & Status Driver**:
  - Status Toggle Driver: Active, On Delivery, Off Duty.
  - Pop-up Notifikasi Penugasan Pengiriman Baru (`delivery_assignments`).
  - Aksi Accept / Reject Tugas Pengiriman.
* **Navigasi & Pelacakan Live**:
  - Peta rute pengiriman ke lokasi pelanggan.
  - Background Location Tracking (`geolocator` / `background_location`) untuk mengunggah koordinat lat/long kurir ke tabel `drivers`.
  - Konfirmasi pengiriman selesai dengan unggah bukti foto.

### 4.5 Modul 5: Admin & Manager Dashboard
* **Ringkasan Analytics**:
  - Total Penjualan Hari Ini, Total Pesanan, Rata-rata Nilai Pesanan.
  - Grafik Penjualan per Jam / per Hari (Syncfusion / FL Chart).
  - Ringkasan Penjualan per Metode Pembayaran & Outlet.
* **Manajemen Perangkat & Printer (`outlet_printers`)**:
  - Pindai Perangkat Bluetooth / Network Thermal Printer.
  - Konfigurasi Ukuran Kertas (58mm / 80mm), IP Address, Port, Bluetooth MAC Address / UUID.
  - Tes Cetak Printer.

---

## 5. Pemetaan Skema Database Supabase (24 Tabel)

Semua tabel Supabase berikut telah dipetakan secara presisi ke dalam Data Models Dart:

| Kategori | Nama Tabel | Deskripsi & Fungsi di Flutter |
| :--- | :--- | :--- |
| **Tenant & Outlet** | `organizations` | Data organisasi F&B, setting pajak, mata uang, logo. |
| | `outlets` | Data cabang/outlet, koordinat lokasi, jam operasional. |
| | `tables` | Denah meja dine-in, kapasitas, koordinat layout, status meja (`available`, `occupied`, `reserved`, `bill_printed`). |
| **Staff & Shift** | `staff` | Data karyawan, role (`admin`, `manager`, `kasir`, `kitchen`), hash PIN kasir. |
| | `cashier_shifts` | Sesi shift kasir (modal awal, waktu buka/tutup, kas aktual vs ekspektasi). |
| | `staff_outlets` | Pemetaan akses staf ke satu atau beberapa outlet. |
| **Katalog & Menu** | `categories` | Kategori produk, `sort_order`, flag `is_kitchen`. |
| | `products` | Master produk F&B, harga dasar, deskripsi, image URL. |
| | `product_variants` | Varian ukuran/rasa (misal: Reguler, Large). |
| | `modifier_groups` | Kelompok opsi tambahan (misal: Extra Topping, Level Pedas). |
| | `modifiers` | Item opsi tambahan beserta harga penambah. |
| | `product_modifier_groups` | Pivot table produk & kelompok modifier. |
| | `menu_bundles` / Combo | Paket bundling produk F&B hemat. |
| **Pesanan & Bayar** | `orders` | Header pesanan, tipe (`dine_in`, `takeaway`, `delivery`), status, subtotal, diskon, tax, total. |
| | `order_items` | Detail item pesanan, varian, qty, harga satuan, catatan. |
| | `order_item_modifiers` | Detail modifier yang dipilih pada item pesanan. |
| | `order_payments` | Record pembayaran pesanan (metode: `cash`, `qris`, `bank_transfer`, `ewallet`, `card`). |
| | `order_status_logs` | Audit trail perubahan status pesanan. |
| **Loyalty & Customer**| `customers` | Data pelanggan, total poin, lifetime poin, tier ID. |
| | `loyalty_tiers` | Tingkatan tier (Bronze, Silver, Gold, Platinum), earning rate & benefit. |
| | `point_transactions` | Riwayat dapat poin (`earn`) dan tukar poin (`redeem`). |
| | `challenges` | Master tantangan gamifikasi (stamp card, spending goal). |
| | `customer_challenges` | Progress tantangan per pelanggan & rincian klaim reward. |
| | `rewards` | Katalog hadiah poin (diskon, produk gratis, gratis ongkir). |
| | `customer_redemptions` | Voucher / kupon reward yang telah ditukarkan pelanggan. |
| **Pengiriman & Driver**| `delivery_zones` | Zona area pengiriman outlet, max jarak km, tarif dasar. |
| | `delivery_addresses` | Alamat simpanan pelanggan (lat, long, kelurahan, kecamatan). |
| | `deliveries` | Record pengiriman Biteship/Internal driver, tracking ID, waybill URL, status. |
| | `drivers` | Data driver internal outlet, plat motor, koordinat GPS terkini. |
| | `delivery_assignments`| Penugasan pengiriman ke driver internal & status konfirmasi. |
| | `delivery_logs` | Log tracking perjalanan paket. |
| **Konfigurasi & Aux**| `banners` | Banner promosi aktif di halaman utama customer. |
| | `otp_codes` | Kode OTP SMS/WhatsApp untuk verifikasi login nomor HP. |
| | `outlet_printers` | Konfigurasi printer thermal per outlet (IP, Bluetooth MAC, Paper Width). |

---

## 6. Struktur Folder Project Flutter & Clean Architecture

Struktur folder project Flutter yang akan dibuat di folder baru:

```text
postsa_mobile/
├── android/
├── ios/
├── windows/
├── assets/
│   ├── icons/
│   ├── images/
│   ├── audio/              # Suara notifikasi pesanan dapur
│   └── fonts/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── constants/       # AppColors, AppTextStyles, ApiEndpoints
│   │   ├── database/        # Local Isar/Hive database & SyncQueue service
│   │   ├── network/         # Supabase Client & REST HTTP Interceptors
│   │   ├── printer/         # ThermalPrinterService (ESC/POS builder, Bluetooth/LAN connection)
│   │   ├── theme/           # Dark/Light theme data (Rich Modern Aesthetics)
│   │   ├── utils/           # CurrencyFormatter, DateFormatter, LocationHelper
│   │   └── error/           # Failure & Exception classes
│   ├── features/
│   │   ├── auth/            # Login PIN Staf, OTP Customer Login
│   │   ├── pos/             # Modul Kasir, Keranjang, Floor Plan Meja, Cashier Shift
│   │   ├── kitchen/         # Modul Dapur (KDS), Realtime Ticket Queue, Label Printing
│   │   ├── customer/        # Catalog, Self-Order, Cart, Checkout, Order Tracking
│   │   ├── loyalty/         # Tier Status, Stamp Cards, Challenges, Voucher Redemption
│   │   ├── driver/          # Task Assignment, Live GPS Tracker, Proof of Delivery
│   │   ├── admin/           # Dashboard Analytics, Report Summary, Settings
│   │   └── printer_config/  # Scan Bluetooth/IP Printer, Test Print, Printer Roles
│   └── shared/
│       ├── models/          # Dart Data Models (24 Supabase Tables + JSON serialization)
│       └── widgets/         # Custom Buttons, Badge, Shimmer, Dialogs, Cards
└── pubspec.yaml
```

---

## 7. Dependencies Utama `pubspec.yaml` (Tech Stack Flutter)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management & DI
  flutter_bloc: ^8.1.6
  get_it: ^7.7.0
  equatable: ^2.0.5

  # Backend & Network
  supabase_flutter: ^2.8.0
  http: ^1.2.1
  web_socket_channel: ^3.0.0

  # Offline Local Database
  isar: ^3.1.0+1
  isar_flutter_libs: ^3.1.0+1
  path_provider: ^2.1.3

  # Hardware Integration & Printing
  flutter_pos_printer_platform: ^1.0.8
  blue_thermal_printer: ^1.2.3
  esc_pos_utils_2: ^2.0.1
  qr_flutter: ^4.1.0
  mobile_scanner: ^5.1.1 # For scanning Table QR & Voucher Codes

  # Location & Maps
  geolocator: ^12.0.0
  flutter_map: ^7.0.2
  latlong2: ^0.9.1

  # UI Components & Analytics Charts
  google_fonts: ^6.2.1
  lucide_icons: ^0.257.0
  fl_chart: ^0.68.0
  intl: ^0.19.0
  cached_network_image: ^3.3.1
  flutter_spinkit: ^5.2.1
  audioplayers: ^6.0.0 # Audio chime notification for Kitchen KDS

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.9
  isar_generator: ^3.1.0+1
```

---

## 8. Verification Plan & Quality Assurance

### 8.1 Automated Tests
1. **Unit Testing**:
   - Pengujian kalkulasi total pesanan, pajak, diskon, dan kustom modifier.
   - Pengujian logika penentuan tier loyalty berdasarkan `lifetime_points`.
   - Pengujian serialisasi & deserialisasi JSON 24 data model Dart.
2. **Widget & BLoC Testing**:
   - Test aliran event BLoC kasir (Open Shift $\rightarrow$ Add Item $\rightarrow$ Select Payment $\rightarrow$ Complete Order).
   - Test simulasi offline-first sync queue.

### 8.2 Manual Verification Steps
1. **POS Hardware & Thermal Printer**:
   - Melakukan koneksi ke printer Thermal Bluetooth & IP LAN.
   - Menjalankan tes cetak struk kasir 58mm & 80mm serta tiket dapur.
2. **Realtime KDS Test**:
   - Membuka dua device (Device A: Kasir POS, Device B: Kitchen KDS).
   - Membuat pesanan di Kasir POS dan menguji apakah pesanan muncul secara instan (< 1 detik) di Kitchen KDS via Supabase Realtime WebSocket.
3. **Biteship Ongkir & Driver Test**:
   - Input alamat tujuan dan memverifikasi perhitungan ongkir Biteship.
   - Menguji toggle status driver dan update live koordinat GPS.
