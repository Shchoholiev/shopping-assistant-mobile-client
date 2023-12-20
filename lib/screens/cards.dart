import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shopping_assistant_mobile_client/models/product.dart';
import 'package:shopping_assistant_mobile_client/network/product_service.dart';


class Cards extends StatefulWidget {
  final String wishlistId;
  final String wishlistName;
  List<String> inputProducts = [];
  List<Product> products = [];

  Cards({required this.wishlistName, required this.inputProducts, required this.wishlistId});

  @override
  _CardsState createState() => _CardsState();
}

class _CardsState extends State<Cards> {
  int currentProduct = 0;
  ProductService productService = ProductService();
  List<Product> cart = [];

  @override
  void initState(){
    for(String productName in this.widget.inputProducts){
      this.widget.products.add(
          Product(
              id: '',
              name: productName,
              url: 'link',
              imageUrls: [],
              rating: 0.0,
              price: 0.0,
              description: '',
              wasOpened: false,
          )
      );
    }
  }

  Widget buildRatingStars(double rating) {
    int whole = rating.floor();
    double fractal = rating - whole;

    List<Widget> stars = [];

    for (int i = 0; i < 5; i++) {
      if (i < whole) {
        // Whole star
        stars.add(SvgPicture.asset(
          'assets/icons/star.svg',
          width: 19,
          height: 19,
        ));
      } else if (fractal != 0.0) {
        // Half star
        stars.add(SvgPicture.asset(
          'assets/icons/half-star.svg',
          width: 19,
          height: 19,
        ));
        fractal -= fractal;
      } else {
        // Empty star
        stars.add(SvgPicture.asset(
          'assets/icons/empty-star.svg',
          width: 19,
          height: 19,
        ));
      }
    }

    return Row(
      children: stars,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasCards = widget.products.isNotEmpty;
    bool isLastProduct = currentProduct == widget.products.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.wishlistName),
        centerTitle: true,
      ),
      body: Center(
        child: Stack(
          children: [
            if (currentProduct < widget.products.length - 1)
              Positioned(
                child: Transform.rotate(
                  angle: -5 * 3.1415926535 / 180,
                  child: Container(
                    width: 300,
                    height: 600,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                      border: Border.all(
                        color: Color(0xFF009FFF),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF0165FF),
                          blurRadius: 8.0,
                          spreadRadius: 0.0,
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              child: Container(
                width: 300,
                height: 600,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  border: Border.all(
                    color: Color(0xFF009FFF),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF0165FF),
                      blurRadius: 8.0,
                      spreadRadius: 0.0,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/img/default-white.png'), // Replace with your image path
                          fit: BoxFit.scaleDown,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      currentProduct < widget.products.length
                          ? widget.products[currentProduct].name
                          : "The cards ended.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (currentProduct == widget.products.length)
                      Text(
                        "Swipe right to show more or left to exit.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    SizedBox(height: 10),
                    if (!isLastProduct)
                      Column(
                        children: [
                          Text(
                            currentProduct < widget.products.length
                                ? widget.products[currentProduct].description
                                : "Product description not available.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              buildRatingStars(currentProduct < widget.products.length
                                  ? widget.products[currentProduct].rating
                                  : 0.0),
                              SizedBox(width: 20),
                              Text(
                                '\$${currentProduct < widget.products.length ? widget.products[currentProduct].price : "-"}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    SizedBox(height: 50),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: currentProduct < widget.products.length
                              ? SvgPicture.asset(
                            'assets/icons/x.svg',
                            width: 30,
                            height: 30,
                          )
                              : SvgPicture.asset(
                            'assets/icons/exit-cards.svg',
                            width: 30,
                            height: 30,
                          ),
                          onPressed: () {
                            if (currentProduct < widget.products.length) {
                              showNextProduct();
                            } else {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                        IconButton(
                          icon: SvgPicture.asset(
                            'assets/icons/back.svg',
                            width: 30,
                            height: 30,
                          ),
                          onPressed: () {
                            showPreviousProduct();
                          },
                        ),
                        IconButton(
                          icon: currentProduct < widget.products.length
                              ? SvgPicture.asset(
                            'assets/icons/heart.svg',
                            width: 30,
                            height: 30,
                            color: Colors.blue,
                          )
                              : SvgPicture.asset(
                            'assets/icons/add-products.svg',
                            width: 30,
                            height: 30,
                          ),
                          onPressed: () async {
                            if (currentProduct < widget.products.length) {
                              if (!cart.contains(widget.products[currentProduct])) {
                                await productService.addProductToPersonalWishlist(
                                  widget.products[currentProduct],
                                  widget.wishlistId,
                                );
                                cart.add(widget.products[currentProduct]);
                              }
                              showNextProduct();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showNextProduct() {
    setState(() {
      if(currentProduct < widget.products.length) {
        ++currentProduct;
      }
    });
  }

  void showPreviousProduct() {
    setState(() {
      if(currentProduct > 0 ) {
        --currentProduct;
      }
    });
  }
}
