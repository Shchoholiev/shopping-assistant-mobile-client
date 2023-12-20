class Wishlist {
  Wishlist(
      {required this.id,
      required this.name,
      required this.type,
      required this.createdById});

  String id;

  String name;

  String type;

  String createdById;

  Wishlist.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        name = json['name'] as String,
        type = json['type'] as String,
        createdById = json['createdById'] as String;
}
