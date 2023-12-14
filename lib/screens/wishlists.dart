import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:graphql/client.dart';
import 'package:shopping_assistant_mobile_client/models/wishlist.dart';
import 'package:shopping_assistant_mobile_client/network/api_client.dart';
import 'package:shopping_assistant_mobile_client/screens/cart.dart';

import 'chat.dart';

class WishlistsScreen extends StatefulWidget {
  const WishlistsScreen({super.key});

  @override
  State<WishlistsScreen> createState() => _WishlistsScreenState();
}

class _WishlistsScreenState extends State<WishlistsScreen> {
  var client = ApiClient();

  late Future _wishlistsFuture;
  late List<Wishlist> _wishlists;

  @override
  void initState() {
    super.initState();
    _wishlistsFuture = _fetchWishlistPage();
  }

  Future _fetchWishlistPage() async {
    const String personalWishlistsPageQuery = r'''
      query personalWishlistsPage($pageNumber: Int!, $pageSize: Int!) {
        personalWishlistsPage(pageNumber: $pageNumber, pageSize: $pageSize) {
          items {
            id, name, type, createdById,
          },
          hasNextPage, hasPreviousPage, pageNumber, pageSize, totalItems, totalPages,
        }
      }
    ''';

    QueryOptions queryOptions = QueryOptions(
        document: gql(personalWishlistsPageQuery),
        variables: const <String, dynamic>{
          'pageNumber': 1,
          'pageSize': 200,
        });

    var result = await client.query(queryOptions);

    _wishlists = List<Map<String, dynamic>>.from(
            result?['personalWishlistsPage']['items'])
        .map((e) => Wishlist.fromJson(e))
        .toList();

    return;
  }

  void _deleteWishlist(Wishlist wishlist) async {
    const String deletePersonalWishlistMutation = r'''
      mutation deletePersonalWishlist($wishlistId: String!) {
        deletePersonalWishlist(wishlistId: $wishlistId) {
        }
      }
    ''';

    MutationOptions mutationOptions = MutationOptions(
        document: gql(deletePersonalWishlistMutation),
        variables: <String, dynamic>{
          'wishlistId': wishlist.id,
        });

    var result = await client.mutate(mutationOptions);

    setState(() {
      _wishlists.remove(wishlist);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _wishlistsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        } else if (snapshot.connectionState == ConnectionState.done) {
          // Data loaded successfully, display the widget
          return Container(
            color: Colors.white,
            child: _wishlists.length == 0
                ? Center(
                    child: Text('No wishlists found'),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    itemCount: _wishlists.length,
                    itemBuilder: (context, index) {
                      return WishlistItem(
                        wishlist: _wishlists[index],
                        onDelete: () => _deleteWishlist(_wishlists[index]),
                      );
                    },
                  ),
          );
        }

        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}

class WishlistItem extends StatefulWidget {
  WishlistItem({
    super.key,
    required Wishlist wishlist,
    required Function() onDelete,
  })  : _wishlist = wishlist,
        _onDelete = onDelete;

  final Wishlist _wishlist;
  final Function() _onDelete;

  @override
  State<WishlistItem> createState() => _WishlistItemState();
}

class _WishlistItemState extends State<WishlistItem> {
  double _xOffset = 0;
  double _rightBorderRadius = 10.0;

  bool _isDeleting = false;

  void _transformLeft() {
    setState(() {
      _xOffset = -70;
      _rightBorderRadius = 0;
    });
  }

  void _transformRight() {
    setState(() {
      _xOffset = 0;
      _rightBorderRadius = 10;
    });
  }

  void _onDelete() async {
    setState(() {
      _isDeleting = true;
    });

    await widget._onDelete();

    setState(() {
      _isDeleting = false;
    });
    _transformRight();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      margin: EdgeInsets.only(
        bottom: 10,
        left: 20,
        right: 20,
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            child: GestureDetector(
              onTap: () => _onDelete(),
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: .25,
                  vertical: .25,
                ),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(0, 82, 204, 1),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: AlignmentDirectional.centerEnd,
                child: _isDeleting
                    ? Container(
                        margin: EdgeInsets.only(
                          right: 25,
                        ),
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 17,
                        ),
                        child: SvgPicture.asset(
                          'assets/icons/trash.svg',
                          color: Colors.white,
                          width: 20,
                        ),
                      ),
              ),
            ),
          ),
          Positioned(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(wishlistId: widget._wishlist.id, wishlistName: widget._wishlist.name, openedFromBottomBar: false),
                  ),
                );
              },
              onHorizontalDragUpdate: (DragUpdateDetails details) {
                if (details.delta.dx < -1) {
                  _transformLeft();
                } else if (details.delta.dx > 1) {
                  _transformRight();
                }
              },
              child: AnimatedContainer(
                transform: Matrix4.translationValues(_xOffset, 0, 0),
                duration: Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: Color.fromRGBO(234, 234, 234, 1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                    topRight: Radius.circular(_rightBorderRadius),
                    bottomRight: Radius.circular(_rightBorderRadius),
                  ),
                ),
                alignment: AlignmentDirectional.centerStart,
                padding: EdgeInsets.only(
                  left: 15,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        widget._wishlist.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => print(Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  CartScreen(wishlistId: widget._wishlist.id)))),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 17,
                          vertical: 17,
                        ),
                        child: SvgPicture.asset(
                          'assets/icons/cart.svg',
                          color: Color.fromRGBO(32, 32, 32, 1),
                          width: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
