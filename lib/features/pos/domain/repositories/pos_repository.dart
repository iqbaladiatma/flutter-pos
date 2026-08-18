import '../../../../core/error/either.dart';
import '../../../../shared/models/order_model.dart';
import '../../../../shared/models/product_model.dart';

/// Abstract repository contract for the POS feature (domain layer).
///
/// The UI/BLoC depends on this interface, not on the concrete implementation.
/// This enables swapping data sources (Supabase, local DB, mock) and
/// simplifies unit testing with fake repositories.
abstract class PosRepository {
  /// Fetches all active categories.
  Future<Result<List<CategoryModel>>> getCategories();

  /// Fetches active products, optionally filtered by [categoryId].
  Future<Result<List<ProductModel>>> getProducts({String? categoryId});

  /// Creates a new order in the backend.
  Future<Result<OrderModel>> createOrder({
    required String outletId,
    String? tableId,
    required OrderType orderType,
    required double subtotal,
    required double total,
    required List<Map<String, dynamic>> items,
    String? notes,
  });
}
