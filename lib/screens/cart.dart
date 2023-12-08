import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:graphql/client.dart';
import 'package:shopping_assistant_mobile_client/models/product.dart';
import 'package:shopping_assistant_mobile_client/network/api_client.dart';

const String defaultUrl = 'https://s3-alpha-sig.figma.com/img/b8d6/7b6f/59839f0f3abfdeed91ca32d3501cbfa3?Expires=1702252800&Signature=aDWc2xO9d01Criwp829ZjhWE1pu~XGezZiM9oNOGkVZOYyGwxfDq5lVOSV0WOEkYdBR83hW7a-I2LY-U5R9evtoKf0BRGY1VVZ0H1wkp5WOHlC196gKr5tLPfseWahP2GWsQNSxfsgxg0cg8l8LamgqS1sUmD1Qt8jWdsqVcwlvTBY8X0q~ScDeCGn1n-7Npj315r4CbVLYMLfZWjpXROcR~Jpx-sqKVaxakw5OWdjegw7YBn~MAY6~yNi~Ylf44oFLkBpzI2aA65Z-TiRMPJ7HoLqJ3id8Eq7NoJ2PKxL88aZ2cOk9ZduRU7jI8FO-PvEBT-Qiwz0tUyEzmbiziDg__&Key-Pair-Id=APKAQ4GOSFWCVNEHN3O4';


class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // final _products = [
  //   Product(name : '1', id: "Belkin USB C to VGA + Charge Adapter - USB C to VGA Cable for MacBook", price: 12.57, rating: 4.34, url: 'a', imageUrls: [defaultUrl,'a','b']),
  //   Product(id : '1', name: "USB C to VGA 2", price: 12.57, rating: 4.5, url: 'a', imageUrls: [defaultUrl,'a','b']),
  //   Product(id : '1', name: "USB C to VGA 2", price: 12.57, rating: 4.2, url: 'a', imageUrls: [defaultUrl,'a','b']),
  //   Product(id : '1', name: "USB C to VGA 2", price: 12.57, rating: 4.7, url: 'a', imageUrls: [defaultUrl,'a','b']),
  //   Product(id : '1', name: "USB C to VGA 2", price: 12.57, rating: 4.8, url: 'a', imageUrls: [defaultUrl,'a','b'])
  // ];

  var client = ApiClient();

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
        variables: const <String, dynamic>{
          'wishlistId': "657310c6892da98a23091bdf",
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
            //titleTextStyle: TextStyle(color: Colors.black),
            //backgroundColor: ,
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                print('Back button pressed');
              },
            ),
          ),
          body: ListView.builder(
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
    // return Scaffold(
    //   appBar: AppBar(
    //     title: Text("Cart"),
    //     centerTitle: true,
    //     //titleTextStyle: TextStyle(color: Colors.black),
    //     //backgroundColor: ,
    //     leading: IconButton(
    //       icon: Icon(Icons.arrow_back),
    //       onPressed: () {
    //         print('Back button pressed');
    //       },
    //     ),
    //   ),
    //   body: ListView.builder(
    //     padding: EdgeInsets.symmetric(vertical: 30),
    //     itemCount: _products.length,
    //     itemBuilder: (context, index){
    //       return CartItem(product: _products[index]);
    //     }
    //   ),
    //   backgroundColor: Colors.white,
    // );
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
            child: Image(image: NetworkImage(_product.imageUrls[0]),),
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
                      onPressed: ()=>{},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,// Блакитний колір фону кнопки
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