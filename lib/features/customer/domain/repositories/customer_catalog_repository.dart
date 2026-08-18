import '../../../../core/error/either.dart';
import '../../../../shared/models/product_model.dart';
import '../../../../shared/models/table_model.dart';

/// Domain contract for customer-facing catalog and outlet browsing.
abstract class CustomerCatalogRepository {
  /// Fetches all products for an outlet, optionally filtered by category.
  Future<Result<List<ProductModel>>> getOutletProducts({
    required String outletId,
    String? categoryId,
  });

  /// Fetches all categories for an outlet.
  Future<Result<List<CategoryModel>>> getOutletCategories({
    required String outletId,
  });

  /// Fetches promotional banners for an outlet.
  Future<Result<List<Banner>>> getBanners({required String outletId});

  /// Fetches a table by its QR code identifier.
  ///
  /// Used when a customer scans a QR code on the table.
  Future<Result<TableModel>> getTableByQrCode({
    required String outletId,
    required String qrCode,
  });
}

/// Promotional banner shown on the customer home screen.
class Banner {
  final String id;
  final String title;
  final String? imageUrl;
  final String? ctaText;
  final String? ctaUrl;
  final DateTime? startDate;
  final DateTime? endDate;
  final int sortOrder;

  const Banner({
    required this.id,
    required this.title,
    this.imageUrl,
    this.ctaText,
    this.ctaUrl,
    this.startDate,
    this.endDate,
    this.sortOrder = 0,
  });

  factory Banner.fromJson(Map<String, dynamic> json) => Banner(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        imageUrl: json['image_url'] as String?,
        ctaText: json['cta_text'] as String?,
        ctaUrl: json['cta_url'] as String?,
        startDate: json['start_date'] != null
            ? DateTime.tryParse(json['start_date'] as String)
            : null,
        endDate: json['end_date'] != null
            ? DateTime.tryParse(json['end_date'] as String)
            : null,
        sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      );
}
