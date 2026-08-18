import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/supabase_service.dart';

/// Remote data source for cashier shifts via Supabase.
class CashierShiftRemoteDataSource {
  final SupabaseService _supabaseService;

  CashierShiftRemoteDataSource({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService();

  SupabaseClient get _client => _supabaseService.client;

  /// Inserts a new cashier shift row.
  Future<Map<String, dynamic>> insertShift({
    required String outletId,
    required String staffId,
    required double openingCash,
  }) async {
    final response = await _client.from('cashier_shifts').insert({
      'outlet_id': outletId,
      'staff_id': staffId,
      'opening_cash': openingCash,
      'opened_at': DateTime.now().toUtc().toIso8601String(),
    }).select().single();
    return response;
  }

  /// Fetches the active (unclosed) shift for a staff member at an outlet.
  Future<Map<String, dynamic>?> getActiveShift({
    required String outletId,
    required String staffId,
  }) async {
    final response = await _client
        .from('cashier_shifts')
        .select()
        .eq('outlet_id', outletId)
        .eq('staff_id', staffId)
        .filter('closed_at', 'is', null)
        .order('opened_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return response;
  }

  /// Closes a shift by setting closing_cash, expected_cash, closed_at.
  Future<Map<String, dynamic>> closeShift({
    required String shiftId,
    required double closingCash,
    required double expectedCash,
  }) async {
    final response = await _client
        .from('cashier_shifts')
        .update({
          'closing_cash': closingCash,
          'expected_cash': expectedCash,
          'closed_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', shiftId)
        .select()
        .single();
    return response;
  }

  /// Fetches all shifts for an outlet on a specific date.
  Future<List<Map<String, dynamic>>> getShiftsByDate({
    required String outletId,
    required DateTime date,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final response = await _client
        .from('cashier_shifts')
        .select()
        .eq('outlet_id', outletId)
        .gte('opened_at', startOfDay.toUtc().toIso8601String())
        .lt('opened_at', endOfDay.toUtc().toIso8601String())
        .order('opened_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetches order summary for a shift (for Z-Report).
  Future<Map<String, dynamic>> getShiftOrderSummary({
    required String shiftId,
  }) async {
    // Get the shift to determine time range
    final shift = await _client
        .from('cashier_shifts')
        .select()
        .eq('id', shiftId)
        .single();

    final openedAt = DateTime.parse(shift['opened_at'] as String);
    final closedAt = shift['closed_at'] != null
        ? DateTime.parse(shift['closed_at'] as String)
        : DateTime.now();

    // Fetch orders in that time range
    final orders = await _client
        .from('orders')
        .select('total, status, payment_method, discount_amount, tax_amount')
        .gte('created_at', openedAt.toUtc().toIso8601String())
        .lte('created_at', closedAt.toUtc().toIso8601String())
        .neq('status', 'cancelled');

    // Aggregate
    double grossSales = 0;
    double totalDiscounts = 0;
    double totalTax = 0;
    final salesByMethod = <String, double>{};

    for (final order in orders) {
      final total = (order['total'] as num?)?.toDouble() ?? 0;
      final discount = (order['discount_amount'] as num?)?.toDouble() ?? 0;
      final tax = (order['tax_amount'] as num?)?.toDouble() ?? 0;
      final method = order['payment_method'] as String? ?? 'cash';

      grossSales += total;
      totalDiscounts += discount;
      totalTax += tax;
      salesByMethod[method] = (salesByMethod[method] ?? 0) + total;
    }

    return {
      'total_orders': orders.length,
      'gross_sales': grossSales,
      'total_discounts': totalDiscounts,
      'total_tax': totalTax,
      'net_sales': grossSales - totalDiscounts,
      'sales_by_method': salesByMethod,
      'shift': shift,
    };
  }

  /// Fetches staff name by ID (for Z-Report).
  Future<String> getStaffName(String staffId) async {
    try {
      final response = await _client
          .from('staff')
          .select('name')
          .eq('id', staffId)
          .maybeSingle();
      return response?['name'] as String? ?? 'Unknown';
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Get staff name error: $e');
      }
      return 'Unknown';
    }
  }
}
