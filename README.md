# PostSA Flutter POS & Multi-Outlet System

Aplikasi Mobile & Tablet Cross-Platform (Android, iOS, POS Terminal, Windows) untuk Sistem Kasir (POS), Kitchen Display System (KDS), Customer Self-Order & Loyalty, Kurir Pengiriman, dan Dashboard Admin.

---

## 🌟 Fitur Utama

1. **Kasir POS (Offline-First)**
   - Kasir Shift (Buka Shift, Input Kas Awal, Tutup Shift, Z-Report).
   - Katalog Produk, Varian, Modifiers & Bundling.
   - Manajemen Meja Dine-in (Floor Plan).
   - Multi Payment (Cash, QRIS, Bank Transfer, E-Wallet).
   - Cetak Struk ESC/POS via Bluetooth, IP LAN, USB.

2. **Kitchen Display System (KDS)**
   - Ticket Stream Real-time via Supabase WebSocket.
   - Chime Audio Alert saat ada pesanan baru.
   - Filter Kategori Dapur & Cetak Label Tiket.

3. **Customer Self-Order & Loyalty Gamification**
   - Catalog Outlet & Scan QR Meja.
   - Sistem Poin, Loyalty Tiers (Bronze, Silver, Gold, Platinum).
   - Stamp Card Challenges & Penukaran Reward.
   - Integrasi Ongkir Biteship.

4. **Driver / Kurir App**
   - Penugasan Pengiriman & Status Driver.
   - Live GPS Location Tracking.

5. **Admin Dashboard & Printer Setup**
   - Analytics Penjualan Real-time.
   - Discovery Printer Bluetooth & Setup Role Printer (Struk/Dapur).

---

## 🛠️ Cara Mengembangkan / Jalankan App

### Prerequisites
- Flutter SDK 3.24+
- Dart SDK 3.5+
- Android Studio / VS Code

### Steps
```bash
# 1. Masuk ke folder pos-flutter
cd pos-flutter

# 2. Install dependencies
flutter pub get

# 3. Jalankan aplikasi
flutter run
```

---

## 📁 Struktur Project

```text
pos-flutter/
├── lib/
│   ├── main.dart             # App Entrypoint
│   ├── app.dart              # Main MaterialApp & Theme Setup
│   ├── core/                 # Constants, Network, Theme, Printers
│   ├── shared/
│   │   └── models/           # 24 Supabase Data Models
│   └── features/             # POS, Kitchen, Customer, Loyalty, Driver, Admin, Printer Config
└── pubspec.yaml
```
