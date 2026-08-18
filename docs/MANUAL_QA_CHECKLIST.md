# Manual QA Checklist — PostSA POS

Reference: PRD §8.2

## 1. Printer Hardware Test

### Thermal Printer (USB/BT)
- [ ] Connect printer via USB / Bluetooth
- [ ] Print test receipt (1 item)
- [ ] Print full receipt (multiple items, discount, tax, split payment)
- [ ] Print kitchen ticket (order items only, no price)
- [ ] Print Z-report (shift summary)
- [ ] Verify barcode/QR code prints correctly (if applicable)
- [ ] Verify cutter works after print
- [ ] Test auto-reconnect after printer disconnect

### Printer Compatibility
- [ ] Test with 58mm printer
- [ ] Test with 80mm printer
- [ ] Test with ESC/POS compatible printer
- [ ] Verify character encoding (Indonesian characters)

---

## 2. KDS (Kitchen Display System) — 2-Device Test

### Setup
- [ ] Device A: POS (kasir) — place order
- [ ] Device B: KDS (kitchen) — receive order

### Realtime Sync
- [ ] Order placed on Device A appears on Device B within 2 seconds
- [ ] Status change on Device B (MULAI MASAK) reflects on Device A
- [ ] Status change on Device B (SELESAI) reflects on Device A
- [ ] Audio chime plays on Device B when new order arrives
- [ ] Elapsed timer updates every minute
- [ ] Color changes: green (< 5m), yellow (< 10m), red (> 10m)

### Edge Cases
- [ ] Offline: orders queue locally and sync when online
- [ ] Multiple orders: kanban columns show all correctly
- [ ] Order cancellation: removed from KDS
- [ ] App restart: active orders persist

---

## 3. Biteship Ongkir Test

### Rate Calculation
- [ ] Enter pickup address + destination address
- [ ] Select courier service (JNE, JNT, SiCepat, Gojek, Grab)
- [ ] Verify rates displayed with ETD
- [ ] Verify weight affects pricing
- [ ] Test with invalid address → error message

### Shipment Creation
- [ ] Create shipment after checkout
- [ ] Verify tracking ID returned
- [ ] Verify waybill number (if applicable)
- [ ] Test cancellation of shipment

### Tracking
- [ ] Track shipment status (pending → picked_up → in_transit → delivered)
- [ ] Verify status updates reflect in app

---

## 4. Driver GPS Test

### Location Tracking
- [ ] Driver app requests location permission
- [ ] GPS coordinates update every 10 meters or 30 seconds
- [ ] Coordinates upload to `drivers` table
- [ ] Map shows driver location in realtime
- [ ] Battery usage is reasonable (< 5% per hour)

### Delivery Flow
- [ ] Driver receives assignment notification
- [ ] Accept assignment → status changes to "on_delivery"
- [ ] Reject assignment → removed from pending list
- [ ] Update status: picked_up → in_transit → delivered
- [ ] Upload proof photo (if camera available)
- [ ] Toggle off duty → stops GPS tracking

### Edge Cases
- [ ] GPS off: app prompts to enable location services
- [ ] Permission denied: app shows explanation
- [ ] Background tracking: works when app is minimized (Android)
- [ ] Route map: driver marker visible on OSM tiles

---

## 5. POS Flow Test

### Order Creation
- [ ] Select product from catalog → adds to cart
- [ ] Select variant → price updates
- [ ] Add modifiers → price updates
- [ ] Add notes to item
- [ ] Change quantity (+/-)
- [ ] Remove item from cart
- [ ] Clear entire cart

### Order Types
- [ ] Dine-in (select table)
- [ ] Takeaway
- [ ] Delivery (select address + shipping)

### Discounts & Coupons
- [ ] Apply percentage discount (e.g., 10%)
- [ ] Apply nominal discount (e.g., Rp 15.000)
- [ ] Apply coupon code
- [ ] Verify discount + coupon stack correctly
- [ ] Clear discount

### Payment
- [ ] Cash payment (exact amount)
- [ ] Cash payment (with change)
- [ ] QRIS payment
- [ ] Card payment
- [ ] Split payment (cash + QRIS)
- [ ] Verify grand total = cartTotal - discount + tax (11%)
- [ ] Complete payment → receipt prints
- [ ] Order appears in KDS

### Cashier Shift
- [ ] Open shift with starting cash
- [ ] Process orders during shift
- [ ] Close shift → Z-report generates
- [ ] Print shift summary
- [ ] Verify cash reconciliation

---

## 6. Customer App Test

### Auth
- [ ] Enter phone → receive OTP
- [ ] Enter OTP → authenticated
- [ ] Wrong OTP → error message
- [ ] Expired OTP → error message

### Catalog
- [ ] Browse products by category
- [ ] Scan QR code on table → table selected
- [ ] View promotional banners

### Loyalty
- [ ] View points balance + tier
- [ ] View challenges with progress
- [ ] View available rewards
- [ ] Redeem reward → points deducted
- [ ] View point history

### Checkout
- [ ] Select delivery address
- [ ] Add new address
- [ ] Calculate shipping rate
- [ ] Place order → confirmation

---

## 7. Admin Dashboard Test

### Analytics
- [ ] View today's sales summary
- [ ] View hourly sales chart
- [ ] View payment method breakdown
- [ ] Refresh data

### Menu Management
- [ ] Add new product
- [ ] Edit product (name, price, availability)
- [ ] Delete product (soft delete)
- [ ] Add new category

### Staff Management
- [ ] Add new staff member
- [ ] Assign role (admin/manager/kasir/kitchen)
- [ ] Toggle staff active/inactive
- [ ] Set staff PIN

---

## 8. Auth & Security Test

### Login
- [ ] Login with valid phone + PIN → success
- [ ] Login with wrong PIN → error
- [ ] Login with non-existent phone → error
- [ ] Login with inactive staff → error

### Session
- [ ] Session persists after app restart
- [ ] Session expires after 24 hours
- [ ] Logout clears session

### Role-Based Access
- [ ] Kasir cannot access Admin Dashboard
- [ ] Kitchen cannot access POS
- [ ] Manager can access Admin Dashboard
- [ ] Admin can access all features

---

## 9. Offline-First Test

### Sync
- [ ] Create order offline → queues in sync queue
- [ ] Go online → order syncs to Supabase
- [ ] Conflict resolution: server wins for existing records
- [ ] Verify sync queue clears after successful sync
- [ ] Verify error handling on sync failure

---

## 10. Cross-Platform Test

- [ ] Android (phone + tablet)
- [ ] iOS (phone + tablet) — if applicable
- [ ] Windows desktop
- [ ] Web — if applicable

---

**Tester**: _______________________
**Date**: _______________________
**Build**: _______________________
