class ProductEntity {
  final String id;
  final String title;
  final double price;
  final double? originalPrice;
  final String description;
  final String category;
  final String image;
  final List<String> images;
  final double rating;
  final int ratingCount;
  final List<String> availableColors;
  final List<String> availableSizes;
  final bool isFlashDeal;
  final int discountPercentage;
  final int stock;
  final List<ProductReviewEntity> reviews;

  const ProductEntity({
    required this.id,
    required this.title,
    required this.price,
    this.originalPrice,
    required this.description,
    required this.category,
    required this.image,
    required this.images,
    this.rating = 4.5,
    this.ratingCount = 120,
    required this.availableColors,
    required this.availableSizes,
    this.isFlashDeal = false,
    this.discountPercentage = 0,
    this.stock = 25,
    required this.reviews,
  });

  ProductEntity copyWith({
    String? id,
    String? title,
    double? price,
    double? originalPrice,
    String? description,
    String? category,
    String? image,
    List<String>? images,
    double? rating,
    int? ratingCount,
    List<String>? availableColors,
    List<String>? availableSizes,
    bool? isFlashDeal,
    int? discountPercentage,
    int? stock,
    List<ProductReviewEntity>? reviews,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      description: description ?? this.description,
      category: category ?? this.category,
      image: image ?? this.image,
      images: images ?? this.images,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      availableColors: availableColors ?? this.availableColors,
      availableSizes: availableSizes ?? this.availableSizes,
      isFlashDeal: isFlashDeal ?? this.isFlashDeal,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      stock: stock ?? this.stock,
      reviews: reviews ?? this.reviews,
    );
  }
}

class ProductReviewEntity {
  final String userName;
  final String userAvatar;
  final double rating;
  final String comment;
  final String date;

  const ProductReviewEntity({
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.comment,
    required this.date,
  });
}
