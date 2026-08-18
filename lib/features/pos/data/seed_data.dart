import '../../shared/models/product_model.dart';

/// Seed data untuk demo/fallback saat Supabase belum ada data atau gagal.
/// Memungkinkan app tetap usable untuk testing UI/flow tanpa backend.
class SeedData {
  SeedData._();

  static const List<CategoryModel> categories = [
    CategoryModel(
      id: 'cat-coffee',
      name: 'Coffee',
      slug: 'coffee',
      isKitchen: false,
      isActive: true,
    ),
    CategoryModel(
      id: 'cat-food',
      name: 'Food',
      slug: 'food',
      isKitchen: true,
      isActive: true,
    ),
    CategoryModel(
      id: 'cat-drinks',
      name: 'Cold Drinks',
      slug: 'cold-drinks',
      isKitchen: false,
      isActive: true,
    ),
    CategoryModel(
      id: 'cat-snacks',
      name: 'Snacks',
      slug: 'snacks',
      isKitchen: true,
      isActive: true,
    ),
  ];

  static const List<ProductModel> products = [
    ProductModel(
      id: 'prod-espresso',
      categoryId: 'cat-coffee',
      name: 'Espresso',
      slug: 'espresso',
      description: 'Single shot espresso',
      basePrice: 18000,
      isActive: true,
      variants: [
        ProductVariantModel(
            id: 'var-espresso-single',
            name: 'Single',
            priceAdjustment: 0,
            isDefault: true),
        ProductVariantModel(
            id: 'var-espresso-double',
            name: 'Double',
            priceAdjustment: 5000),
      ],
    ),
    ProductModel(
      id: 'prod-americano',
      categoryId: 'cat-coffee',
      name: 'Americano',
      slug: 'americano',
      description: 'Espresso with hot water',
      basePrice: 22000,
      isActive: true,
    ),
    ProductModel(
      id: 'prod-cappuccino',
      categoryId: 'cat-coffee',
      name: 'Cappuccino',
      slug: 'cappuccino',
      description: 'Espresso with steamed milk foam',
      basePrice: 28000,
      isActive: true,
    ),
    ProductModel(
      id: 'prod-latte',
      categoryId: 'cat-coffee',
      name: 'Caffe Latte',
      slug: 'caffe-latte',
      description: 'Espresso with steamed milk',
      basePrice: 30000,
      isActive: true,
    ),
    ProductModel(
      id: 'prod-nasgor',
      categoryId: 'cat-food',
      name: 'Nasi Goreng Spesial',
      slug: 'nasi-goreng-spesial',
      description: 'Nasi goreng dengan telur, ayam, dan kerupuk',
      basePrice: 35000,
      isActive: true,
    ),
    ProductModel(
      id: 'prod-miegor',
      categoryId: 'cat-food',
      name: 'Mie Goreng',
      slug: 'mie-goreng',
      description: 'Mie goreng dengan sayuran dan ayam',
      basePrice: 28000,
      isActive: true,
    ),
    ProductModel(
      id: 'prod-ayam',
      categoryId: 'cat-food',
      name: 'Ayam Bakar',
      slug: 'ayam-bakar',
      description: 'Ayam bakar dengan nasi dan lalapan',
      basePrice: 38000,
      isActive: true,
    ),
    ProductModel(
      id: 'prod-icetea',
      categoryId: 'cat-drinks',
      name: 'Es Teh Manis',
      slug: 'es-teh-manis',
      description: 'Teh manis dingin',
      basePrice: 8000,
      isActive: true,
    ),
    ProductModel(
      id: 'prod-lemon',
      categoryId: 'cat-drinks',
      name: 'Lemon Tea',
      slug: 'lemon-tea',
      description: 'Teh lemon dingin',
      basePrice: 15000,
      isActive: true,
    ),
    ProductModel(
      id: 'prod-orange',
      categoryId: 'cat-drinks',
      name: 'Orange Juice',
      slug: 'orange-juice',
      description: 'Jus jeruk fresh',
      basePrice: 18000,
      isActive: true,
    ),
    ProductModel(
      id: 'prod-kentang',
      categoryId: 'cat-snacks',
      name: 'Kentang Goreng',
      slug: 'kentang-goreng',
      description: 'French fries dengan saus',
      basePrice: 20000,
      isActive: true,
    ),
    ProductModel(
      id: 'prod-pisgor',
      categoryId: 'cat-snacks',
      name: 'Pisang Goreng',
      slug: 'pisang-goreng',
      description: 'Pisang goreng crispy',
      basePrice: 15000,
      isActive: true,
    ),
  ];
}
