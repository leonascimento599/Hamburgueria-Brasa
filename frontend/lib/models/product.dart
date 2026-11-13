class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.image,
    this.badge,
    this.isFeatured = false,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final String image;
  final String? badge;
  final bool isFeatured;

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String? ?? '',
        category: map['category'] as String? ?? 'Burgers',
        price: (map['price'] as num).toDouble(),
        image: map['image'] as String? ?? '',
        badge: map['badge'] as String?,
        isFeatured: map['isFeatured'] as bool? ?? false,
      );
}

class Extra {
  const Extra({required this.id, required this.name, required this.price});
  final String id;
  final String name;
  final double price;
}

class CartLine {
  CartLine({
    required this.product,
    required this.extras,
    required this.quantity,
    this.removedIngredients = const [],
  });

  final Product product;
  final List<Extra> extras;
  int quantity;
  final List<String> removedIngredients;

  double get unitPrice => product.price + extras.fold<double>(0, (sum, e) => sum + e.price);
  double get total => unitPrice * quantity;
}
