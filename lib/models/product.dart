import 'dart:ffi';

class Product {
    Product({
        required this.id,
        required this.name,
        required this.url,
        required this.imageUrls,
        required this.rating,
        required this.price,
        required this.description,
        required this.wasOpened,
    });

    String id;
    String name;
    String url;
    List<String> imageUrls;
    double rating;
    double price;
    String description;
    bool wasOpened;

    Product.fromJson(Map<String, dynamic> json)
        : id = json['id'] as String,
          name = json['name'] as String,
          url = json['url'] as String,
          imageUrls = json['imageUrls'] as List<String>,
          rating = json['rating'] as double,
          price = json['name'] as double,
            description = json['description'] as String,
            wasOpened = json['wasOpened'] as bool;
}