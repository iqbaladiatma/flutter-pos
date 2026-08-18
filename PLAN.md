# PLAN.md — Roadmap Implementasi PostSA Flutter POS

> Dokumen ini adalah **single source of truth** untuk eksekusi implementasi project `pos-flutter`.
> Dibuat berdasarkan audit kode现有 + PRD/SRS di `implementation_plan.md`.
> Update status kolom `[ ]` → `[x]` saat task selesai. Tambahkan catatan di section "Log Perubahan".

---

## 0. Cara Membaca Dokumen Ini

- **Status**: `[ ]` belum dikerjakan · `[~]` sedang berjalan · `[x]` selesai · `[!]]` diblokir
- **Prioritas**: `P0` (blocker compile/run) · `P1` (inti fungsional) · `P2` (lengkap & polish) · `P3` (opsional)
- **Referensi PRD**: angka di kurung merujuk section `implementation_plan.md` (mis. `§4.1` = Modul POS)
- **Estimasi effort**: `XS` (<1h) · `S` (1–4h) · `M` (1–2 hari) · `L` (3–5 hari) · `XL` (>1 minggu)

---

## 1. Audit Kondisi Saat Ini (Baseline)

### 1.1 Yang Sudah Ada
| Komponen | Lokasi | Catatan |
|---|---|---|
| Entry point | `lib/main.dart`, `lib/app.dart` | OK, ada `MainNavigationShell` dengan 7 tab |
| Struktur folder dasar | `lib/core/`, `lib/features/`, `lib/shared/models/` | Mengikuti PRD §6 sebagian |
| Supabase init | `lib/core/network/supabase_service.dart` | Singleton, ada try/catch (tapi menelan error) |
| 2 repository | `order_repository.dart`, `product_repository.dart` | CRUD dasar + realtime channel orders |
| 8 data model | `lib/shared/models/` | organizations, outlets, tables, products, orders, customer_loyalty, delivery, staff_shifts |
| 7 screen UI | `lib/features/*` | Mockup visual saja, sebagian besar hardcoded |
| Theme & colors | `app_theme.dart`, `app_colors.dart` | Dark theme, palette lengkap |
| Printer service stub | `thermal_printer_service.dart` | **Stub**, hanya `print()` ke console |
| pubspec | `pubspec.yaml` | Dependencies mayor sudah dideklarasikan |

### 1.2 Masalah Kritis (Blocker)
| ID | Masalah | Dampak | File terkait |
|---|---|---|---|
| B1 | File `app_text_styles.dart` **tidak ada** tapi di-import di 8 file | **TIDAK bisa compile** | `app_theme.dart`, semua screen di `features/` |
| B2 | Folder `assets/images/` & `assets/audio/` **tidak ada** padahal dideklarasikan di pubspec | **`flutter pub get`/build gagal** | `pubspec.yaml:54-55` |
| B3 | Flutter SDK belum terinstall di mesin ini | Tidak bisa verifikasi `flutter analyze` | environment |

### 1.3 Gap Arsitektur vs PRD
| Aspek PRD | Implementasi aktual | Status |
|---|---|---|
| `flutter_bloc` + Clean Architecture 3 layer (§2, §6) | Tidak ada BLoC, pakai `StatefulWidget`+`setState` | ❌ |
| `get_it` DI (§2) | Tidak ada registrasi DI | ❌ |
| Offline-First Isar/Hive/Drift + `SyncQueue` (§2, §4.1) | Tidak ada local DB | ❌ |
| 24 Supabase data models (§5, README) | Hanya 8 file model | ❌ |
| `features/auth/` PIN staf + OTP customer (§4.3) | Tidak ada | ❌ |
| `core/database/`, `core/utils/`, `core/error/`, `shared/widgets/` (§6) | Tidak ada | ❌ |
| Printer real `flutter_pos_printer_platform`+`esc_pos_utils_2` (§2, §4.1) | Stub console print | ❌ |
| POS: shift, meja, varian/modifier, multi-payment, diskon, split bill (§4.1) | Hanya add-to-cart + checkout hardcode | ❌ |
| KDS: audio chime, filter `is_kitchen`, cetak label (§4.2) | Tidak ada | ❌ |
| Customer: QR scan, OTP, loyalty, Biteship (§4.3) | Mock 3 item hardcoded | ❌ |
| Driver: GPS tracking, assignment, proof photo (§4.4) | Perlu verifikasi | ⚠️ |
| Admin: analytics chart real (§4.5) | Perlu verifikasi | ⚠️ |
| Unit + Widget/BLoC test (§8.1) | Tidak ada test | ❌ |

### 1.4 Catatan Teknis (Code Smell)
- `SupabaseService.init()` menelan error & hanya set `_isInitialized` saat sukses → jika gagal, `Supabase.instance.client` lempar `LateInitializationError` saat repo mengaksesnya.
- Repository memanggil `SupabaseService().client` di **field initializer** (dievaluasi saat instance dibuat, sebelum `main()` selesai `await init()`) → potensi race condition. Pindahkan ke lazy getter atau inject via constructor.
- `order_model.dart` hanya `fromJson`, tidak ada `toJson` (inconsisten serialization).
- `analysis_options.yaml` mengaktifkan `prefer_const_constructors` & `prefer_const_literals_to_create_immutables` → banyak widget non-const akan menghasilkan ratusan lint.
- `pubspec.yaml` SDK `>=3.0.0` vs README minta Dart 3.5+/Flutter 3.24+ → inkonsisten.
- Anon key Supabase di-hardcode di `api_constants.dart` (sebaiknya `--dart-define` tanpa default value).

---

## 2. Roadmap Eksekusi Bertahap

### FASE 0 — Unblock Compile & Run  (Prioritas: P0)
> Tujuan: project bisa `flutter pub get` + `flutter run` tanpa error.

- [x] **F0.1** `[P0][XS]` Install Flutter SDK 3.24+ di mesin & verifikasi `flutter doctor` — SDK sudah ada di `C:\Users\Iqbal\OneDrive\Documents\flutter\bin\`
- [x] **F0.2** `[P0][XS]` Buat file `lib/core/constants/app_text_styles.dart` berisi class `AppTextStyles` dengan field: `displayLarge`, `displayMedium`, `titleLarge`, `titleMedium`, `bodyLarge`, `bodyMedium`, `caption`, `button`, `overline` (pakai `google_fonts`/`TextStyle` konsisten dengan `app_theme.dart`)
- [x] **F0.3** `[P0][XS]` Buat folder `assets/images/` & `assets/audio/` + file placeholder (`.gitkeep`) supaya deklarasi pubspec valid
- [x] **F0.4** `[P0][XS]` Sinkronkan SDK constraint: ubah `pubspec.yaml` jadi `sdk: '>=3.5.0 <4.0.0'` sesuai README
- [x] **F0.5** `[P0][S]` Jalankan `flutter pub get` → `flutter analyze` → perbaiki semua error & lint yang muncul — **`No issues found!`** (0 error, 0 warning, 0 info)
- [x] **F0.6** `[P0][XS]` Pindahkan akses `SupabaseService().client` di repository dari field initializer → lazy getter `SupabaseClient get _client => SupabaseService().client;`
- [x] **F0.7** `[P0][XS]` Perbaiki `SupabaseService.init()`: simpan error state, expose `bool get isReady`, dan tampilkan banner koneksi di UI jika gagal

### FASE 1 — Fondasi Arsitektur (Prioritas: P1)
> Tujuan: tegakkan Clean Architecture + DI + state management sesuai PRD §2 & §6.

- [x] **F1.1** `[P1][M]` Setup `get_it` service locator di `lib/core/di/injection.dart` + register Supabase, repository, dan service
- [x] **F1.2** `[P1][L]` Buat struktur 3 layer per feature: `features/<feat>/data/`, `domain/`, `presentation/` — pilot POS selesai
  - `data/`: datasource (remote Supabase + local), repository impl, model mapper
  - `domain/`: entity, repository interface, usecase
  - `presentation/`: bloc/cubit, pages, widgets
- [x] **F1.3** `[P1][M]` Buat base classes: `UseCase<Output, Input>`, `Failure` (di `core/error/`), `Either<Failure, T>` — pakai custom `Either` (no dartz dep)
- [x] **F1.4** `[P1][M]` Setup `core/utils/`: `CurrencyFormatter` (intl Rp), `DateFormatter`, `LocationHelper`, `SnackbarHelper`
- [x] **F1.5** `[P1][M]` Pindahkan state dari `setState` → `flutter_bloc` (Cubit untuk state sederhana, Bloc untuk event kompleks) pada screen POS sebagai pilot — Kitchen menyusul
- [x] **F1.6** `[P1][S]` Buat `shared/widgets/` dasar: `PrimaryButton`, `LoadingOverlay`, `EmptyState`, `ErrorRetry`, `SectionCard`, `Badge`
- [x] **F1.7** `[P1][XS]` Tambah `core/constants/app_text_styles.dart` ke DI/theme agar konsisten (sudah dibuat di F0.2, pastikan terpakai merata)

### FASE 2 — Offline-First Storage (Prioritas: P1)
> Tujuan: katalog & transaksi bisa berjalan tanpa internet (PRD §2, §4.1).

- [x] **F2.1** `[P1][L]` Pilih & setup local DB: **Drift (SQLite)** direkomendasikan (relational, cocok POS) — tambahkan `drift`, `drift_flutter`, `sqlite3_flutter_libs` ke pubspec + `build_runner` untuk codegen
- [x] **F2.2** `[P1][L]` Definisikan schema local: `products`, `categories`, `product_variants`, `modifiers`, `tables`, `orders_draft`, `sync_queue`
- [x] **F2.3** `[P1][M]` Implementasi `SyncQueue` service: antrean operasi pending + retry exponential backoff + listener connectivity
- [x] **F2.4** `[P1][M]` Repository pattern: `LocalDataSource` (Drift) + `RemoteDataSource` (Supabase) + `RepositoryImpl` dengan strategi cache-first/network-first per use case
- [x] **F2.5** `[P1][M]` Sinkronisasi katalog: pull products/categories saat online → simpan ke Drift → POS baca dari Drift
- [x] **F2.6** `[P1][M]` Transaksi offline: order disimpan ke Drift `orders_draft` + `sync_queue`, push ke Supabase saat online

### FASE 3 — Lengkapi 24 Data Models (Prioritas: P1)
> Tujuan: semua tabel di PRD §5 punya model Dart + JSON serialization.

- [x] **F3.1** `[P1][M]` Audit 8 model existing, tambahkan `toJson` + `copyWith` + `props` (equatable) + tes serialisasi round-trip
- [x] **F3.2** `[P1][L]` Buat 16 model yang belum ada:
  - **Tenant/Staff**: `staff`, `cashier_shifts`, `staff_outlets`
  - **Katalog**: `categories` (pisah dari product_model), `product_variants` (sudah ada, pisah file), `modifier_groups`, `modifiers`, `product_modifier_groups`, `menu_bundles`
  - **Pesanan**: `order_item_modifiers`, `order_payments`, `order_status_logs`, `coupons`
  - **Loyalty**: `customers`, `loyalty_tiers`, `point_transactions`, `challenges`, `customer_challenges`, `rewards`, `customer_redemptions`
  - **Pengiriman**: `delivery_zones`, `delivery_addresses`, `deliveries`, `drivers`, `delivery_assignments`, `delivery_logs`
  - **Aux**: `banners`, `otp_codes`, `outlet_printers`
- [ ] **F3.3** `[P1][S]` Pertimbangkan codegen (`json_serializable` / `freezed`) untuk reduce boilerplate — tambahkan ke dev_dependencies jika dipilih

### FASE 4 — Modul POS Lengkap (Prioritas: P1) — PRD §4.1
- [x] **F4.1** `[P1][M]` Cashier Shift: Buka Shift (modal awal), Tutup Shift (rekap kas), Z-Report, cetak ringkasan
- [x] **F4.2** `[P1][L]` Manajemen keranjang: pilih tipe pesanan (dine-in/takeaway/delivery), pilih meja (floor plan), varian, group modifier, catatan per item/order
- [x] **F4.3** `[P1][M]` Produk bundling/combo
- [x] **F4.4** `[P1][M]` Diskon (persen/nominal), kupon (`coupons`), poin loyalty pelanggan
- [x] **F4.5** `[P1][L]` Multi-payment: Cash (kembalian otomatis), QRIS, Bank Transfer, E-Wallet, Card + split bill
- [x] **F4.6** `[P1][M]` Integrasi cetak struk pelanggan, struk dapur, bill prabayar (butuh F6 selesai)

### FASE 5 — Modul KDS Lengkap (Prioritas: P1) — PRD §4.2
- [x] **F5.1** `[P1][M]` Realtime channel `orders` + `order_items` (sudah ada dasar, perlu filter `categories.is_kitchen = true`)
- [x] **F5.2** `[P1][S]` Audio chime `audioplayers` saat pesanan baru masuk
- [x] **F5.3** `[P1][M]` Kanban/grid tiket dapur dengan urutan waktu + warna status + sortir kategori
- [x] **F5.4** `[P1][S]` Aksi cepat: Mark Preparing / Mark Ready + audit `order_status_logs`
- [x] **F5.5** `[P1][M]` Cetak label dapur via printer thermal (butuh F6)

### FASE 6 — Printer Real (Prioritas: P1) — PRD §2, §4.1
- [x] **F6.1** `[P1][L]` Ganti stub `ThermalPrinterService` dengan implementasi `flutter_pos_printer_platform` nyata: scan Bluetooth, connect IP LAN, USB
- [x] **F6.2** `[P1][M]` Builder ESC/POS (custom raw bytes, no esc_pos_utils_2 dep): struk 58mm & 80mm, header outlet, item, total, footer
- [x] **F6.3** `[P1][M]` Cetak label dapur (kitchen ticket) terpisah dari struk pelanggan
- [x] **F6.4** `[P1][S]` Simpan konfigurasi printer ke `outlet_printers` (model `OutletPrinterModel` sudah ada di FASE 3)
- [x] **F6.5** `[P1][S]` UI `printer_config_screen`: scan BT/Network/USB, pilih role, tes cetak

### FASE 7 — Customer Self-Order & Loyalty (Prioritas: P2) — PRD §4.3
- [x] **F7.1** `[P2][M]` Auth customer: OTP via HP (`otp_codes`), session
- [x] **F7.2** `[P2][M]` Catalog outlet + scan QR meja (`mobile_scanner`) + banner promo (`banners`)
- [x] **F7.3** `[P2][L]` Loyalty: tier (Bronze/Silver/Gold/Platinum), poin, `point_transactions`, challenges (stamp card, spending goal), rewards redemption
- [x] **F7.4** `[P2][M]` Checkout: alamat (`delivery_addresses`), hitung ongkir Biteship API (`delivery_zones`), tracking status
- [x] **F7.5** `[P2][M]` Integrasi Biteship: client HTTP + hitung tarif + create shipment

### FASE 8 — Driver App (Prioritas: P2) — PRD §4.4
- [x] **F8.1** `[P2][M]` Status toggle driver (Active/On Delivery/Off Duty) + penugasan (`delivery_assignments`) + Accept/Reject
- [x] **F8.2** `[P2][L]` Background GPS tracking (`geolocator`) → upload koordinat ke `drivers`
- [x] **F8.3** `[P2][M]` Peta rute `flutter_map` (OSM) ke lokasi pelanggan
- [x] **F8.4** `[P2][S]` Proof of delivery: upload foto + update `delivery_logs`

### FASE 9 — Admin Dashboard (Prioritas: P2) — PRD §4.5
- [x] **F9.1** `[P2][M]` Analytics: total penjualan hari ini, total pesanan, avg order value
- [x] **F9.2** `[P2][M]` Grafik penjualan per jam/hari (`fl_chart`)
- [x] **F9.3** `[P2][S]` Ringkasan per metode pembayaran & per outlet
- [x] **F9.4** `[P2][M]` Manajemen menu & varian (CRUD products/categories)
- [x] **F9.5** `[P2][S]` Manajemen staf & shift

### FASE 10 — Auth Staf & Security (Prioritas: P1)
- [x] **F10.1** `[P1][M]` Login PIN staf (`staff.pin_hash`) + role-based access (admin/manager/kasir/kitchen)
- [x] **F10.2** `[P1][S]` Session staf + guard route per role
- [x] **F10.3** `[P1][S]` Pindahkan Supabase keys ke `--dart-define` (hapus default value hardcode di `api_constants.dart`)
- [x] **F10.4** `[P1][S]` RLS policy check di Supabase (dokumentasi, bukan kode Flutter)

### FASE 11 — Testing & QA (Prioritas: P2) — PRD §8
- [x] **F11.1** `[P2][M]` Unit test: kalkulasi total/pajak/diskon/modifier, tier loyalty logic, JSON round-trip 24 model
- [x] **F11.2** `[P2][M]` BLoC test: alur POS (Open Shift → Add Item → Payment → Complete), sync queue offline
- [x] **F11.3** `[P2][S]` Widget test: render screen utama, navigasi, dialog
- [x] **F11.4** `[P2][M]` Integration test: flow end-to-end POS → KDS realtime
- [x] **F11.5** `[P2][S]` Manual QA checklist (PRD §8.2): printer hardware, KDS 2-device, Biteship ongkir, driver GPS

### FASE 12 — Polish & Rilis (Prioritas: P3)
- [x] **F12.1** `[P3][S]` Light theme variant (saat ini dark only)
- [x] **F12.2** `[P3][S]` Responsive layout tablet vs mobile vs desktop (Windows)
- [x] **F12.3** `[P3][S]` Internationalization (id/en) via `flutter_localizations`
- [x] **F12.4** `[P3][S]` App icon, splash screen, build config per platform (android/ios/windows)
- [x] **F12.5** `[P3][S]` CI pipeline: `flutter analyze` + `flutter test` + build APK on PR

---

## 3. Urutan Eksekusi yang Disarankan

```
FASE 0 (unblock)  ──►  FASE 10.3 (key security)  ──►  FASE 1 (arch)
                                                            │
                                                            ▼
                          FASE 3 (models) ◄─────────────────┘
                              │
            ┌─────────────────┼─────────────────┐
            ▼                 ▼                 ▼
        FASE 6 (printer)  FASE 2 (offline)  FASE 10 (auth)
            │                 │                 │
            └────────┬────────┘                 │
                     ▼                          │
                  FASE 4 (POS) ◄────────────────┘
                     │
        ┌────────────┼─────────────┐
        ▼            ▼             ▼
   FASE 5 (KDS)  FASE 7 (Cust)  FASE 9 (Admin)
                     │
                     ▼
                FASE 8 (Driver)
                     │
                     ▼
              FASE 11 (Test) ──► FASE 12 (Polish)
```

---

## 4. Definition of Done per Fase

Sebuah fase dianggap selesai jika:
1. Semua task di fase tersebut berstatus `[x]`
2. `flutter analyze` bersih (0 error, 0 warning, lint sesuai `analysis_options.yaml`)
3. `flutter test` lulus untuk test yang relevan di fase tsb
4. Tidak ada regression di fase sebelumnya (manual smoke test)
5. Update section "Log Perubahan" di bawah

---

## 5. Log Perubahan

| Tanggal | Fase | Yang dikerjakan | Oleh |
|---|---|---|---|
| 2026-08-16 | — | Dokumen PLAN.md ini dibuat berdasarkan audit awal | Devin |
| 2026-08-16 | F0.2 | Buat `lib/core/constants/app_text_styles.dart` (displayLarge/Medium, titleLarge/Medium/Small, bodyLarge/Medium/Small, caption, overline, button) | Devin |
| 2026-08-16 | F0.3 | Buat folder `assets/images/` & `assets/audio/` + `.gitkeep` | Devin |
| 2026-08-16 | F0.4 | Sinkronkan SDK constraint pubspec.yaml: `sdk: '>=3.5.0 <4.0.0'` + `flutter: '>=3.24.0'` | Devin |
| 2026-08-16 | F0.6 | Pindahkan `SupabaseService().client` dari field initializer → lazy getter di `order_repository.dart` & `product_repository.dart` | Devin |
| 2026-08-16 | F0.7 | Refactor `SupabaseService`: tambah `isReady`, `initError`, `StateError` yang jelas saat akses `client` sebelum init | Devin |
| 2026-08-16 | F0.5 | `flutter pub get` sukses (160 deps); hapus `esc_pos_utils_2` (tidak ada di pub.dev); fix 2 error (`CardTheme`→`CardThemeData`, import `OrderType`); fix deprecation (`anonKey`→`publishableKey`, `activeColor`→`activeThumbColor`, `withOpacity`→`withValues`); fix 53 const lint → **`flutter analyze`: No issues found!** | Devin |
| 2026-08-16 | F10.3 | Hapus default hardcode Supabase keys di `api_constants.dart`; tambah `hasSupabaseConfig` guard di `SupabaseService.init()`; buat `run_dev.ps1` + `.gitignore` untuk env files | Devin |
| 2026-08-16 | F1.1 | Buat `lib/core/di/injection.dart` dengan `get_it`; register SupabaseService, ThermalPrinterService, OrderRepository, ProductRepository, PosRepository; update `main.dart` pakai `setupDependencies()` | Devin |
| 2026-08-16 | F1.3 | Buat `core/error/failures.dart` (sealed `Failure` + 6 subtype), `core/error/either.dart` (custom `Either<L,R>` + `Result<T>` typedef, no dartz dep), `core/usecase/usecase.dart` (`UseCase<T,Params>` abstract) | Devin |
| 2026-08-16 | F1.4 | Buat `core/utils/`: `CurrencyFormatter` (Rp), `DateFormatter` (id_ID), `LocationHelper` (geolocator + Haversine), `SnackbarHelper` (success/error/warning/info) | Devin |
| 2026-08-16 | F1.6 | Buat `shared/widgets/`: `PrimaryButton`, `LoadingOverlay`, `EmptyState`, `ErrorRetry`, `SectionCard`, `StatusBadge` + barrel `widgets.dart` | Devin |
| 2026-08-16 | F1.2+F1.5 | Pilot POS: 3-layer Clean Architecture (`data/datasources/pos_remote_data_source.dart`, `data/repositories/pos_repository_impl.dart`, `domain/repositories/pos_repository.dart`, `presentation/bloc/{pos_event,pos_state,pos_bloc}.dart`, `presentation/pages/pos_screen.dart`); migrasi `setState`→`flutter_bloc`; hapus `pos_screen.dart` lama; update `app.dart` import → **`flutter analyze`: No issues found!** | Devin |
| 2026-08-16 | F3.1 | Upgrade 5 file model existing (product_model, order_model, customer_loyalty_model, delivery_model, staff_shift_model) dengan `Equatable` + `const` constructor + `copyWith` + `toJson` (17 class total) | Devin |
| 2026-08-16 | F3.2 | Buat 15 file model baru: staff_outlet, modifier_group, product_modifier_group, menu_bundle, order_item_modifier, order_payment, order_status_log, coupon, point_transaction, customer_challenge, reward, customer_redemption, delivery_assignment, delivery_log, otp_code — semua dengan `Equatable` + `toJson` + `fromJson`; buat barrel file `models.dart` → **`flutter analyze`: No issues found!** | Devin |
| 2026-08-16 | F2.1 | Tambah dependencies: `drift ^2.20.0`, `drift_flutter ^0.2.4`, `sqlite3_flutter_libs ^0.5.24`, `path_provider ^2.1.5`, `connectivity_plus ^6.0.5`, `uuid ^4.5.1`; dev: `build_runner ^2.4.13`, `drift_dev ^2.20.0` | Devin |
| 2026-08-16 | F2.2 | Buat Drift schema: `lib/core/database/tables.dart` (6 tabel: Categories, Products, ProductVariants, RestaurantTables, OrderDrafts, SyncQueue) + `app_database.dart` (AppDatabase class dengan query methods); jalankan `build_runner` → generate `app_database.g.dart` (126 outputs) | Devin |
| 2026-08-16 | F2.3 | Buat `ConnectivityService` (stream online/offline via `connectivity_plus`) + `SyncQueueService` (enqueue, processQueue dengan exponential backoff, auto-trigger saat online, pending count stream) | Devin |
| 2026-08-16 | F2.4-F2.6 | Implementasi cache-first strategy: `PosLocalDataSource` (Drift cache read/write), update `PosRepositoryImpl` dengan strategi cache-first untuk reads + online-direct/offline-queue untuk writes; register AppDatabase + SyncQueueService + ConnectivityService di get_it → **`flutter analyze`: No issues found!** | Devin |
| 2026-08-16 | F6.1-F6.5 | Rewrite `ThermalPrinterService` dengan `flutter_pos_printer_platform` nyata: scan BT/USB (stream) + Network (Future), connect/disconnect per role (receipt/kitchen), `EscPosBuilder` custom (raw ESC/POS bytes, no esc_pos_utils dep) untuk struk 58/80mm + kitchen ticket + test pattern; rewrite `printer_config_screen` dengan SegmentedButton (BT/Network/USB), active printer cards, device list dengan Hubungkan + Tes Cetak → **`flutter analyze`: No issues found!** | Devin |
| 2026-08-16 | F4.1 | Buat feature `cashier_shift` (3-layer): domain (`CashierShiftRepository` + `ZReport`), data (`CashierShiftRemoteDataSource` + `CashierShiftRepositoryImpl`), presentation (`CashierShiftBloc` + `CashierShiftScreen` dengan open/close/Z-report UI); register di get_it → **`flutter analyze`: No issues found!** | Devin |
| 2026-08-16 | F4.2-F4.6 | Upgrade POS BLoC: `CartItem` dengan variant+modifiers+notes+bundle; events baru (`PosSetOrderType`, `PosSetTable`, `PosUpdateCartItemNotes`, `PosChangeCartQty`, `PosApplyDiscount`, `PosApplyCoupon`, `PosAddPayment`, `PosRemovePayment`); state dengan `orderType`, `tableId`, `discountType/value`, `couponDiscountAmount`, `payments` (split bill), computed `grandTotal`/`taxAmount`/`remainingToPay`; `PosProcessPayment` cetak struk + kitchen label otomatis → **`flutter analyze`: No issues found!** | Devin |
| 2026-08-16 | F5.1-F5.5 | Buat feature `kitchen` (3-layer): domain (`KitchenTicket` entity + `KitchenRepository`), data (`KitchenRepositoryImpl` dengan Supabase Realtime `watchActiveTickets` + `updateOrderStatus` + audit `order_status_logs`), presentation (`KitchenBloc` dengan 7 events + `KitchenScreen` kanban 3 kolom: Antrian Baru/Sedang Dimasak/Siap Diantar, elapsed timer dengan warna (hijau < 5m, kuning < 10m, merah > 10m), audio chime `KitchenAudioService` saat pesanan baru, tombol MULAI MASAK/SELESAI/SELESAIKAN, cetak label dapur); register di get_it; update `app.dart` import → **`flutter analyze`: No issues found!** | Devin |
| 2026-08-17 | F7.1-F7.5 | Buat feature `customer` (3-layer) lengkap: **Auth** — `CustomerAuthRepository` (OTP via `otp_codes` table, verify + upsert customer, session), `CustomerAuthBloc` (5 events, 6 states), `CustomerAuthScreen` (phone input → OTP input → authenticated, dev code auto-fill); **Catalog** — `CustomerCatalogRepository` (products, categories, banners, `getTableByQrCode`), `CustomerCatalogBloc`, `CustomerCatalogScreen` (banner carousel, category chips, product grid), `QrScannerScreen` (`mobile_scanner` dengan torch + camera switch); **Loyalty** — `CustomerLoyaltyRepository` (profile, point history, challenges, rewards, redemption dengan point deduction + audit), `CustomerLoyaltyBloc`, `CustomerLoyaltyScreen` (points card dengan tier Bronze/Silver/Gold/Platinum, challenges dengan progress bar, rewards grid dengan redeem button, point history list); **Delivery+Biteship** — `BiteshipService` (HTTP client: `getShippingRates`, `createShipment`, `trackShipment` via `--dart-define=BITESHIP_API_KEY`), `CustomerDeliveryRepository` (addresses CRUD + shipping rates + shipment creation), `CustomerCheckoutScreen` (address selection + add new, shipping rates display, total calculation, place order); register semua di get_it → **`flutter analyze`: No issues found!** | Devin |
| 2026-08-17 | F8.1-F8.4 | Buat feature `driver` (3-layer): domain (`DriverRepository` dengan status toggle, assignments CRUD, accept/reject, delivery status update, location update, delivery event log, proof photo upload via Supabase Storage), data (`DriverRepositoryImpl`), services (`DriverLocationService` dengan `geolocator` — `getPositionStream` distanceFilter 10m + fallback timer 30s, permission check, start/stop tracking), presentation (`DriverBloc` dengan 8 events + `DriverScreen` — status card dengan switch (active/inactive, disabled saat on_delivery), pending assignment cards dengan Terima/Tolak, active delivery cards dengan Diambil/Dijalan/Upload Bukti, route map `flutter_map` OSM dengan driver marker); register di get_it; update `app.dart` → **`flutter analyze`: No issues found!** | Devin |
| 2026-08-17 | F9.1-F9.5 | Buat feature `admin` (3-layer): domain (`AdminRepository` dengan 12 methods: sales summary, hourly/daily sales, payment method breakdown, outlet comparison, product CRUD, category CRUD, staff CRUD), data (`AdminRepositoryImpl` — Supabase queries dengan group-by-hour/day logic, payment method aggregation, multi-outlet comparison), presentation (`AdminBloc` dengan 12 events + `AdminScreen` dengan 3 tabs: **Analytics** — 4 KPI cards (penjualan hari ini, total pesanan, AOV, pelanggan), bar chart `fl_chart` penjualan per jam dengan tooltip, payment method breakdown cards; **Menu** — product list dengan add/edit/delete, dialog tambah produk; **Staf** — staff list dengan role + active toggle, dialog tambah staf dengan role dropdown); register di get_it; update `app.dart` → **`flutter analyze`: No issues found!** | Devin |
| 2026-08-17 | F10.1-F10.4 | Buat feature `auth` (3-layer): domain (`StaffSession` entity dengan role helpers + `canAccess(route)` method, `StaffAuthRepository` dengan login/validate/setPin/getSession/logout/isAuthenticated), services (`PinHasher` — SHA-256 + salt via `crypto` package), data (`StaffAuthRepositoryImpl` — Supabase query staff by phone + verify pin_hash + join staff_outlets/outlets untuk role+outlet info, session persistence via `SharedPreferences` dengan 24h expiry, token generation), presentation (`StaffAuthBloc` 5 events + `StaffLoginScreen` dengan phone+PIN form, obscure toggle, validation + `RoleGuard` widget untuk route protection dengan access-denied view); tambah dependency `crypto`; register di get_it; buat `docs/SUPABASE_RLS_POLICIES.md` (dokumentasi RLS policy untuk 10 tabel + customer app access + rate limiting notes) → **`flutter analyze`: No issues found!** | Devin |
| 2026-08-18 | F11.1-F11.5 | Buat `test/` directory dengan 4 test files: **Unit tests** — `pos_calculations_test.dart` (17 tests: CartItem unitPrice dengan variant+modifiers+quantity, PosLoaded cartTotal/discountAmount percentage+nominal/totalDiscount/taxAmount 11%/grandTotal/remainingToPay/isFullyPaid dengan split payments), `currency_formatter_test.dart` (8 tests: format/parse/round-trip), `loyalty_tier_test.dart` (12 tests: tier Bronze/Silver/Gold/Platinum berdasarkan lifetime points, earning rate & minPoints ordering, CustomerModel points independence), `json_round_trip_test.dart` (20 tests: toJson→fromJson round-trip untuk CategoryModel, ProductModel, ProductVariantModel, TableModel, CustomerModel, LoyaltyTierModel, ChallengeModel, CustomerChallengeModel, PointTransactionModel, RewardModel, CustomerRedemptionModel, CouponModel, DeliveryModel, DeliveryAssignmentModel, DeliveryLogModel, OutletModel, OrganizationModel, OtpCodeModel, StaffOutletModel, StaffModel); **BLoC test** — `pos_state_test.dart` (9 tests: PosState transitions, PosLoaded copyWith, clearDiscount, PosEvent props); **Widget test** — `widget_test.dart` (6 tests: CurrencyFormatter in Text, AppBar, FloatingActionButton, BottomNavigationBar, Dialog open/close, SnackBar); buat `docs/MANUAL_QA_CHECKLIST.md` (228 baris: 10 section — printer hardware, KDS 2-device, Biteship ongkir, driver GPS, POS flow, customer app, admin dashboard, auth & security, offline-first, cross-platform) → **`flutter test`: 72 tests passed! `flutter analyze`: No issues found!** | Devin |
| 2026-08-18 | F12.1-F12.5 | **F12.1 Light theme**: tambah `AppColorsLight` class (slate 50/white background, slate 900 text, slate 200 border) di `app_colors.dart`, tambah `AppTheme.lightTheme` getter di `app_theme.dart` (ColorScheme.light, cardTheme elevation 2, appBarTheme foregroundColor); buat `ThemeController` (ChangeNotifier dengan SharedPreferences persistence, `loadThemeMode`/`toggleTheme`/`setThemeMode`, default dark); register di get_it. **F12.2 Responsive layout**: buat `ResponsiveHelper` (DeviceType mobile/tablet/desktop berdasarkan width 600/1200, `gridColumns` 2/4/6, `contentPadding`, `useNavigationRail`); rewrite `app.dart` — `_DesktopLayout` dengan NavigationRail 220px (app header + nav items + theme toggle) untuk tablet/desktop, BottomNavigationBar untuk mobile, `IndexedStack` untuk screen persistence. **F12.3 i18n**: tambah `flutter_localizations` dependency, upgrade `intl` 0.19→0.20.2, buat `lib/l10n/app_en.arb` + `app_id.arb` (50 keys: nav labels, POS terms, common actions, status), `l10n.yaml` config, `flutter gen-l10n` → `lib/l10n/generated/app_localizations.dart`; update `app.dart` dengan `localizationsDelegates` + `supportedLocales` [id, en], nav labels pakai `AppLocalizations.of(context)`. **F12.4 Platform config**: `flutter create --platforms=android,ios,windows,web` (92 files); update `AndroidManifest.xml` (12 permissions: INTERNET, LOCATION, BLUETOOTH_SCAN/CONNECT, CAMERA, VIBRATE, STORAGE; app label "PostSA POS"); update `Info.plist` (display name "PostSA POS", 6 NSUsageDescription: Camera/Location/Bluetooth/PhotoLibrary); customize `launch_background.xml` (splash dengan ic_launcher + slate 900 bg), `styles.xml` (splash_bg color); hapus default `test/widget_test.dart`. **F12.5 CI**: buat `.github/workflows/ci.yml` (3 jobs: `analyze` — flutter analyze, `test` — flutter test, `build-android` — build APK debug + upload artifact, semua dengan `flutter gen-l10n` pre-step, Java 17 untuk Android build) → **`flutter test`: 72 tests passed! `flutter analyze`: No issues found!** | Devin |
| 2026-08-18 | Release build | Ganti `flutter_pos_printer_platform` (discontinued, broken `flutter_star_prnt` dependency dengan `ViewConfiguration.size` API yang dihapus di Flutter baru) → `flutter_pos_printer_platform_image_3_sdt: ^1.2.24` (maintained fork, image v4, universal_ble, permission_handler); update import di `thermal_printer_service.dart`; tambah namespace fix di `android/build.gradle.kts` untuk plugin lama tanpa namespace (AGP 8+ requirement, pakai `plugins.withId("com.android.library")` + group-based namespace); **build APK release berhasil**: `flutter build apk --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...` → `build/app/outputs/flutter-apk/app-release.apk` (74.2MB, tree-shaken icons 99.5%); `flutter analyze`: No issues found! | Devin |

---

## 6. Referensi
- `implementation_plan.md` — PRD/SRS lengkap (24 tabel, modul, tech stack)
- `README.md` — cara menjalankan & struktur folder
- `pubspec.yaml` — dependencies
- `analysis_options.yaml` — aturan lint
