import '../../domain/entities/product_entity.dart';

class ProductReviewModel extends ProductReviewEntity {
  const ProductReviewModel({
    required super.userName,
    required super.userAvatar,
    required super.rating,
    required super.comment,
    required super.date,
  });

  factory ProductReviewModel.fromJson(Map<String, dynamic> json) => ProductReviewModel(
        userName: (json['userName'] ?? json['name'] ?? 'Verified Buyer').toString(),
        userAvatar: (json['userAvatar'] ??
                json['avatar'] ??
                'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150')
            .toString(),
        rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
        comment: (json['comment'] ?? json['review'] ?? '').toString(),
        date: (json['date'] ??
                json['createdAt']?.toString().split('T').first ??
                'Recently')
            .toString(),
      );

  Map<String, dynamic> toJson() => {
        'userName': userName,
        'userAvatar': userAvatar,
        'rating': rating,
        'comment': comment,
        'date': date,
      };
}

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.title,
    required super.price,
    super.originalPrice,
    required super.description,
    required super.category,
    required super.image,
    required super.images,
    super.rating = 4.5,
    super.ratingCount = 120,
    required super.availableColors,
    required super.availableSizes,
    super.isFlashDeal = false,
    super.discountPercentage = 0,
    super.stock = 25,
    super.reviews = ProductModel.defaultReviewModels,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final String idVal = (json['_id'] ?? json['id'] ?? '').toString();
    
    // Rating calculation
    double ratingVal = 4.5;
    if (json['rating'] is num) {
      ratingVal = (json['rating'] as num).toDouble();
    } else if (json['rating'] is Map) {
      ratingVal = (json['rating']['rate'] as num?)?.toDouble() ?? 4.5;
    }

    final int ratingCountVal = (json['numReviews'] as num?)?.toInt() ??
        (json['rating'] is Map ? (json['rating']['count'] as num?)?.toInt() : null) ??
        14;

    final String mainImg = json['image'] as String? ??
        'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800';

    // Image gallery from main image + colorImages + productDetailImages
    final List<String> imgList = [mainImg];
    if (json['colorImages'] is List && (json['colorImages'] as List).isNotEmpty) {
      for (final item in json['colorImages'] as List) {
        if (item is Map && item['image'] != null) {
          final url = item['image'].toString().trim();
          if (url.isNotEmpty && url.startsWith('http') && !imgList.contains(url)) {
            imgList.add(url);
          }
        }
      }
    }
    if (json['productDetailImages'] is List && (json['productDetailImages'] as List).isNotEmpty) {
      final additional = (json['productDetailImages'] as List)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty && e.startsWith('http'))
          .toList();
      for (final url in additional) {
        if (!imgList.contains(url)) {
          imgList.add(url);
        }
      }
    }

    // Colors
    List<String> colorsList = const [];
    if (json['colors'] is List && (json['colors'] as List).isNotEmpty) {
      final parsed = (json['colors'] as List)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (parsed.isNotEmpty) colorsList = parsed;
    }

    // Sizes
    List<String> sizesList = const [];
    if (json['sizes'] is List && (json['sizes'] as List).isNotEmpty) {
      final parsed = (json['sizes'] as List)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (parsed.isNotEmpty) sizesList = parsed;
    }

    final double rawPrice = (json['price'] as num?)?.toDouble() ?? 0.0;
    final double? dbDiscountPrice = (json['discountPrice'] as num?)?.toDouble();

    double effectivePrice = rawPrice;
    double? origPrice = (json['originalPrice'] as num?)?.toDouble() ??
        (json['compareAtPrice'] as num?)?.toDouble();
    int discount = (json['discountPercentage'] as num?)?.toInt() ?? 0;

    // Direct Database discountPrice handling:
    // In backend MongoDB: "price" is regular price, "discountPrice" is the promotional sale price
    if (dbDiscountPrice != null && dbDiscountPrice > 0 && dbDiscountPrice < rawPrice) {
      effectivePrice = dbDiscountPrice;
      origPrice = rawPrice;
      discount = (((rawPrice - dbDiscountPrice) / rawPrice) * 100).round();
    } else if (origPrice != null && origPrice > rawPrice && origPrice > 0) {
      discount = (((origPrice - rawPrice) / origPrice) * 100).round();
    } else if (discount > 0 && origPrice == null) {
      origPrice = rawPrice * (1 + (discount / 100));
    }

    // Strictly sanitize discount & original price: If discount <= 0 or original price isn't higher, reset
    if (discount <= 0 || origPrice == null || origPrice <= effectivePrice) {
      discount = 0;
      origPrice = null;
    }

    // Flash Deal flag is strictly true ONLY if the product has a genuine positive discount
    final bool isFlash = discount > 0;

    // Stock
    final int stockVal = (json['countInStock'] as num?)?.toInt() ??
        (json['stock'] as num?)?.toInt() ??
        25;

    // Reviews parsing
    List<ProductReviewModel> parsedReviews = [];
    if (json['reviews'] is List && (json['reviews'] as List).isNotEmpty) {
      parsedReviews = (json['reviews'] as List).map((r) {
        if (r is Map<String, dynamic>) {
          final revDate = r['date']?.toString() ??
              r['createdAt']?.toString().split('T').first ??
              'Recently';
          return ProductReviewModel(
            userName: (r['userName'] ?? r['name'] ?? 'Verified Buyer').toString(),
            userAvatar: (r['userAvatar'] ?? r['avatar'] ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150').toString(),
            rating: (r['rating'] as num?)?.toDouble() ?? 5.0,
            comment: (r['comment'] ?? r['review'] ?? 'Great quality product!').toString(),
            date: revDate,
          );
        }
        return const ProductReviewModel(
          userName: 'Verified Buyer',
          userAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
          rating: 5.0,
          comment: 'Great product!',
          date: 'Recently',
        );
      }).toList();
    } else {
      parsedReviews = defaultReviewModels;
    }

    return ProductModel(
      id: idVal,
      title: json['title'] as String? ?? '',
      price: effectivePrice,
      originalPrice: origPrice,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      image: mainImg,
      images: imgList,
      rating: ratingVal,
      ratingCount: ratingCountVal,
      availableColors: colorsList,
      availableSizes: sizesList,
      isFlashDeal: isFlash,
      discountPercentage: discount,
      stock: stockVal,
      reviews: parsedReviews,
    );
  }

  factory ProductModel.fromEntity(ProductEntity entity) {
    return ProductModel(
      id: entity.id,
      title: entity.title,
      price: entity.price,
      originalPrice: entity.originalPrice,
      description: entity.description,
      category: entity.category,
      image: entity.image,
      images: entity.images,
      rating: entity.rating,
      ratingCount: entity.ratingCount,
      availableColors: entity.availableColors,
      availableSizes: entity.availableSizes,
      isFlashDeal: entity.isFlashDeal,
      discountPercentage: entity.discountPercentage,
      stock: entity.stock,
      reviews: entity.reviews.map((r) => r is ProductReviewModel
          ? r
          : ProductReviewModel(
              userName: r.userName,
              userAvatar: r.userAvatar,
              rating: r.rating,
              comment: r.comment,
              date: r.date,
            )).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'price': price,
        'originalPrice': originalPrice,
        'description': description,
        'category': category,
        'image': image,
        'images': images,
        'rating': rating,
        'ratingCount': ratingCount,
        'availableColors': availableColors,
        'availableSizes': availableSizes,
        'isFlashDeal': isFlashDeal,
        'discountPercentage': discountPercentage,
        'stock': stock,
        'reviews': reviews
            .map((e) => e is ProductReviewModel
                ? e.toJson()
                : {
                    'userName': e.userName,
                    'userAvatar': e.userAvatar,
                    'rating': e.rating,
                    'comment': e.comment,
                    'date': e.date,
                  })
            .toList(),
      };

  static const List<ProductReviewModel> defaultReviewModels = [
    ProductReviewModel(
      userName: 'Sophia Martinez',
      userAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      rating: 5.0,
      comment: 'Exceptional build quality! Surpassed my expectations in every way.',
      date: '2 days ago',
    ),
    ProductReviewModel(
      userName: 'Alexander Wright',
      userAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      rating: 4.5,
      comment: 'Super fast delivery and packaging was pristine. Highly recommended.',
      date: '1 week ago',
    ),
    ProductReviewModel(
      userName: 'Elena Rostova',
      userAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      rating: 4.8,
      comment: 'Matches the description perfectly. Fits great and feels very premium.',
      date: '2 weeks ago',
    ),
  ];
}
