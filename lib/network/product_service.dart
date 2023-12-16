import 'package:graphql/client.dart';
import 'package:shopping_assistant_mobile_client/models/product.dart';
import 'package:shopping_assistant_mobile_client/network/api_client.dart';

class ProductService {
  final ApiClient client = ApiClient();

  Future<void> addProductToPersonalWishlist(Product product, String wishlisId) async {
    final options = MutationOptions(
      document: gql('''
      mutation AddProductToPersonalWishlist(\$wishlistId: String!, \$dto: ProductCreateDtoInput!) {
        addProductToPersonalWishlist(wishlistId: \$wishlistId, dto: \$dto) {
    
        }
      }
    '''),
      variables: {'wishlistId': wishlisId,
        'dto': {
          'wasOpened': product.wasOpened,
          'url': product.url,
          'rating': product.rating,
          'price': product.price,
          'name': product.name,
          'imagesUrls': product.imageUrls,
          'description': product.description,
        }},
    );

    final result = await client.mutate(options);
  }
}