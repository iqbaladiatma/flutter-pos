# Supabase RLS (Row Level Security) Policy Documentation

## Overview

This document describes the recommended Row Level Security (RLS) policies for the PostSA POS Supabase database. These policies enforce data access control at the database level, complementing the application-level role-based access control (RBAC) implemented in Flutter.

## Roles

PostSA staff roles (stored in `staff_outlets.role`):
- **admin** — Full access to organization data
- **manager** — Access to outlet data (all features except org-level settings)
- **kasir** — Access to POS, cashier shift, orders
- **kitchen** — Access to kitchen display, order status updates

## Prerequisites

1. Enable RLS on all tables:
   ```sql
   ALTER TABLE <table_name> ENABLE ROW LEVEL SECURITY;
   ```

2. Create a helper function to get the current staff's role and outlet:
   ```sql
   CREATE OR REPLACE FUNCTION auth.staff_outlet()
   RETURNS TABLE (staff_id UUID, outlet_id UUID, role TEXT, organization_id UUID)
   LANGUAGE sql
   SECURITY DEFINER
   AS $$
     SELECT
       so.staff_id,
       so.outlet_id,
       so.role,
       o.organization_id
     FROM staff_outlets so
     JOIN outlets o ON o.id = so.outlet_id
     WHERE so.staff_id = auth.uid()
   $$;
   ```

## Policy Recommendations

### 1. `outlets`
- **SELECT**: Admin can see all org outlets; others see only their outlet
  ```sql
  CREATE POLICY "staff_read_outlets" ON outlets
    FOR SELECT USING (
      id IN (SELECT outlet_id FROM auth.staff_outlet())
    );
  ```

### 2. `staff` & `staff_outlets`
- **SELECT**: Admin can see all staff in org; others see only themselves
- **INSERT/UPDATE**: Admin only
  ```sql
  CREATE POLICY "staff_read_self" ON staff
    FOR SELECT USING (
      id = auth.uid() OR
      EXISTS (
        SELECT 1 FROM auth.staff_outlet() so
        WHERE so.role = 'admin'
      )
    );

  CREATE POLICY "staff_modify_admin" ON staff
    FOR ALL USING (
      EXISTS (
        SELECT 1 FROM auth.staff_outlet() so
        WHERE so.role = 'admin'
      )
    );
  ```

### 3. `products` & `categories`
- **SELECT**: All staff in the outlet
- **INSERT/UPDATE/DELETE**: Admin and manager only
  ```sql
  CREATE POLICY "products_read_outlet" ON products
    FOR SELECT USING (
      outlet_id IN (SELECT outlet_id FROM auth.staff_outlet())
    );

  CREATE POLICY "products_modify_manager" ON products
    FOR ALL USING (
      EXISTS (
        SELECT 1 FROM auth.staff_outlet() so
        WHERE so.role IN ('admin', 'manager')
        AND so.outlet_id = products.outlet_id
      )
    );
  ```

### 4. `orders` & `order_items`
- **SELECT**: All staff in the outlet
- **INSERT**: Kasir, manager, admin
- **UPDATE**: Kitchen (status only), kasir, manager, admin
  ```sql
  CREATE POLICY "orders_read_outlet" ON orders
    FOR SELECT USING (
      outlet_id IN (SELECT outlet_id FROM auth.staff_outlet())
    );

  CREATE POLICY "orders_insert_cashier" ON orders
    FOR INSERT WITH CHECK (
      EXISTS (
        SELECT 1 FROM auth.staff_outlet() so
        WHERE so.role IN ('admin', 'manager', 'kasir')
        AND so.outlet_id = orders.outlet_id
      )
    );

  CREATE POLICY "orders_update_staff" ON orders
    FOR UPDATE USING (
      EXISTS (
        SELECT 1 FROM auth.staff_outlet() so
        WHERE so.outlet_id = orders.outlet_id
      )
    );
  ```

### 5. `cashier_shifts`
- **SELECT**: All staff in the outlet
- **INSERT/UPDATE**: Kasir, manager, admin

### 6. `delivery_assignments` & `deliveries`
- **SELECT**: Driver sees their own; admin/manager sees all outlet
- **UPDATE**: Driver (status only), admin, manager

### 7. `customers` & `customer_loyalty`
- **SELECT**: All staff (for POS lookup)
- **INSERT/UPDATE**: Admin, manager, kasir

### 8. `point_transactions` & `customer_redemptions`
- **SELECT**: All staff
- **INSERT**: System (service role), kasir, admin

### 9. `banners`
- **SELECT**: Public (customer app)
- **INSERT/UPDATE/DELETE**: Admin, manager

### 10. `otp_codes`
- **SELECT**: No direct access (use service role + function)
- **INSERT**: Public (customer OTP request via anon key + rate limit)

## Customer App Access

For the customer self-order app (anon key):
- `products` / `categories`: SELECT only (where `is_available = true`)
- `banners`: SELECT only (where active and within date range)
- `tables`: SELECT only (for QR scan lookup)
- `customers`: INSERT (self-registration), UPDATE (self only)
- `otp_codes`: INSERT (request OTP), SELECT (verify — rate limited)
- `orders`: INSERT (place order), SELECT (own orders only)
- `delivery_addresses`: SELECT/INSERT/UPDATE (own only)

## Notes

1. **Service Role**: Use Supabase service role key ONLY on the backend (Edge Functions). Never expose it in the Flutter app.
2. **Anon Key**: Used for customer app. RLS policies must allow public read for catalog and controlled write for orders.
3. **Auth Key**: Used for staff app. RLS policies enforce role-based access.
4. **Rate Limiting**: OTP requests must be rate-limited at the API/Edge Function level (e.g., max 3 requests per phone per 10 minutes).
5. **Audit Trail**: All sensitive operations (status changes, redemptions, shift close) should be logged in audit tables with `staff_id` and timestamp.
