import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:graphql/client.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shopping_assistant_mobile_client/models/product.dart';
import 'package:shopping_assistant_mobile_client/network/api_client.dart';


class CartScreen extends StatefulWidget {
  CartScreen({super.key, required this.wishlistId});

  final String wishlistId;

  @override
  State<CartScreen> createState() => _CartScreenState(wishlistId: wishlistId);
}

class _CartScreenState extends State<CartScreen> {
  _CartScreenState({required this.wishlistId});

  var client = ApiClient();

  final String wishlistId;

  late Future _productsFuture;
  late List<Product> _products;

  @override
  void initState(){
    super.initState();
    _productsFuture = _fetchProducts();
  }

  Future _fetchProducts() async {
    const String productsPageFromPersonalWishlistQuery = r'''
    query ProductsPageFromPersonalWishlist($wishlistId: String!, $pageNumber: Int!, $pageSize: Int!) {
      productsPageFromPersonalWishlist(
        wishlistId: $wishlistId,
        pageNumber: $pageNumber,
        pageSize: $pageSize
    ) {
        items {
            id
            url
            name
            rating
            price
            imagesUrls
        }
    }
}''';

    QueryOptions queryOptions = QueryOptions(
        document: gql(productsPageFromPersonalWishlistQuery),
        variables: <String, dynamic>{
          'wishlistId': wishlistId,
          'pageNumber': 1,
          'pageSize': 10,
        });

    var result = await client.query(queryOptions);
    print(result);

    _products = List<Map<String, dynamic>>.from(
        result?['productsPageFromPersonalWishlist']['items'])
      .map((e) => Product.fromJson(e))
      .toList();

    return;
  }

  @override
  Widget build(BuildContext context){
    return FutureBuilder(
        future: _productsFuture,
        builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: Text('Error: ${snapshot.error}'),
        );
      } else if (snapshot.connectionState == ConnectionState.done) {
        // Data loaded successfully, display the widget
        return Scaffold(
          appBar: AppBar(
            title: Text("Cart"),
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          body: _products.length == 0 ?
            Center(child: Text("The cart is empty", style: TextStyle(fontSize: 18),),)
            : ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 30),
              itemCount: _products.length,
              itemBuilder: (context, index){
                return CartItem(product: _products[index]);
              }
            ),
          backgroundColor: Colors.white,
        );
      };

      return Center(
        child: CircularProgressIndicator(),
      );
    }
    );
  }
}

class CartItem extends StatelessWidget{
  CartItem({
    super.key,
    required Product product,
}) : _product = product;

  final Product _product;


  Widget _buildRatingStar(int index) {
    int whole = _product.rating.floor().toInt();
    double fractional = _product.rating - whole;

    if (index < whole) {
      return Icon(Icons.star, color: Colors.yellow[600], size: 20);
    }
    if (fractional >= 0.25 && fractional <= 0.75) {
      return Icon(Icons.star_half, color: Colors.yellow[600], size: 20);
    }
    if (fractional > 0.75) {
      return Icon(Icons.star, color: Colors.yellow[600], size: 20);
    }else {
      return Icon(Icons.star_border, color: Colors.grey, size: 20);
    }
  }

  List<Widget> _buildRatingStars() {
    List<Widget> stars = [];
    for (int i = 0; i < 5; i++) {
      stars.add(_buildRatingStar(i));
    }
    return stars;
  }


  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) throw 'Could not launch $url';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 140,
      margin: EdgeInsets.all(10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(10)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 2,
              offset: Offset(1, 2),
            )
          ]
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 100,
            alignment: Alignment.center,
            child: CachedNetworkImage(
              imageUrl: _product.imageUrls[0],
              placeholder: (context, url) => CircularProgressIndicator(),
              errorWidget: (context, url, error) => Container(color: Colors.white,),
            ),
          ),
          SizedBox(width: 20),
          Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _product.name,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                  ),
                  Row(
                    children: [
                      Row(
                        children: <Widget>[
                          Text(_product.rating.toStringAsFixed(1), style: TextStyle(fontSize: 14))
                        ] + _buildRatingStars(),
                      ),
                      Text("\$" + _product.price.toStringAsFixed(2), style: TextStyle(fontSize: 14)),
                    ],
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  ),
                  Container(
                    width: double.infinity,
                    height: 35,
                    child: ElevatedButton.icon(
                      onPressed: () => _launchUrl(_product.url),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      icon: SvgPicture.asset("../assets/icons/amazon.svg", height: 15),
                      label: Text(""),
                    ),
                  )
                ],
              )
          )
        ],
      ),
    );
  }
}