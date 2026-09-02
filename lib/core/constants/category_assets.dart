import 'package:flutter/material.dart';

class CategoryAssetHelper {
  static const String milk =
      'Assets/categories_icon/5eef4eaa2330203a89f01ddbc89298c8-removebg-preview.png';
  static const String babyBottle =
      'Assets/categories_icon/0690212bbc494d11bf92fc28b6afc812-removebg-preview.png';
  static const String stroller =
      'Assets/categories_icon/40c89690a5c627d937446fc227120768-removebg-preview.png';
  static const String clothing =
      'Assets/categories_icon/8a229370d67d38667a95c7b00b39e467-removebg-preview.png';
  static const String bath =
      'Assets/categories_icon/afd59b219aa142f35d93b7e68c6b5540-removebg-preview.png';
  static const String crib =
      'Assets/categories_icon/b13f46a6e30e3db10d663d20958473ea-removebg-preview.png';
  static const String shoes =
      'Assets/categories_icon/shoes.png';

  /// Returns the asset image path corresponding to the given category name if available.
  static String? getAssetPath(String category) {
    switch (category.trim().toLowerCase()) {
      case 'clothing':
      case 'fashion':
      case 'baby clothing':
      case 'rompers':
      case 'bodysuit':
      case 'bodysuits':
      case 'outfit':
      case "men's clothing":
      case "women's clothing":
        return clothing;

      case 'travel & gear':
      case 'strollers':
      case 'stroller':
      case 'gear':
      case 'travel':
      case 'pram':
      case 'prams':
        return stroller;

      case 'furniture':
      case 'home & decor':
      case 'cribs':
      case 'crib':
      case 'nursery':
      case 'cradle':
      case 'cradles':
      case 'bedding':
        return crib;

      case 'bath & skin':
      case 'bath':
      case 'skincare':
      case 'bathing':
      case 'hygiene':
        return bath;

      case 'milk':
      case 'formula':
      case 'dairy':
        return milk;

      case 'feeding':
      case 'feeding & nursing':
      case 'feeding & teething':
      case 'bottles':
      case 'bottle':
      case 'nutrition':
        return babyBottle;

      case 'shoes':
      case 'shoe':
      case 'footwear':
      case 'booties':
      case 'sneakers':
      case 'sandals':
        return shoes;

      default:
        return null;
    }
  }

  /// Returns a fallback IconData if no image asset is available for the given category.
  static IconData getFallbackIcon(String category) {
    switch (category.trim().toLowerCase()) {
      case 'clothing':
      case 'fashion':
      case 'baby clothing':
      case 'rompers':
      case "men's clothing":
      case "women's clothing":
        return Icons.checkroom_rounded;
      case 'travel & gear':
      case 'strollers':
      case 'gear':
        return Icons.child_friendly_rounded;
      case 'furniture':
      case 'home & decor':
      case 'cribs':
      case 'nursery':
        return Icons.crib_rounded;
      case 'bath & skin':
      case 'bath':
      case 'skincare':
        return Icons.bathtub_rounded;
      case 'toy & play':
      case 'toys':
      case 'toy':
        return Icons.toys_rounded;
      case 'diapering & care':
      case 'diapering':
      case 'diapers':
        return Icons.baby_changing_station_rounded;
      case 'milk':
      case 'feeding & nursing':
      case 'feeding':
      case 'bottles':
        return Icons.local_drink_rounded;
      case 'shoes':
      case 'shoe':
      case 'footwear':
      case 'booties':
      case 'sneakers':
      case 'sandals':
        return Icons.roller_skating_rounded;
      case 'all':
        return Icons.grid_view_rounded;
      default:
        return Icons.child_care_rounded;
    }
  }
}

/// A reusable widget to render either category image asset or fallback Flutter Icon.
class CategoryIconWidget extends StatelessWidget {
  final String category;
  final double size;
  final Color? color;
  final IconData? customFallbackIcon;

  const CategoryIconWidget({
    super.key,
    required this.category,
    this.size = 18,
    this.color,
    this.customFallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = CategoryAssetHelper.getAssetPath(category);

    if (assetPath != null) {
      return Image.asset(
        assetPath,
        width: size,
        height: size,
        color: color,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            customFallbackIcon ?? CategoryAssetHelper.getFallbackIcon(category),
            size: size,
            color: color,
          );
        },
      );
    }

    return Icon(
      customFallbackIcon ?? CategoryAssetHelper.getFallbackIcon(category),
      size: size,
      color: color,
    );
  }
}
