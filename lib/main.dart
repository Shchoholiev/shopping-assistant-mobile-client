import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shopping_assistant_mobile_client/screens/wishlists.dart';
import 'package:shopping_assistant_mobile_client/screens/cart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const List<String> _pageNameOptions = <String>[
    'Wishlists',
    'New Chat',
    'Settings',
  ];

  static const List<Widget> _widgetOptions = <Widget>[
    WishlistsScreen(),
    Text(''),
    Text(''),
  ];

  static const Color _selectedColor = Color.fromRGBO(36, 36, 36, 1);
  static const Color _unselectedColor = Color.fromRGBO(144, 144, 144, 1);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CartScreen()
    );
  }
  //State<MyApp> createState() => _MyAppState();
}

// class _MyAppState extends State<MyApp> {
//   int _selectedIndex = 0;
//
//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       theme: ThemeData(
//         useMaterial3: true,
//         appBarTheme: AppBarTheme(),
//         textTheme: TextTheme(
//           bodyMedium: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ),
//       home: Scaffold(
//         appBar: AppBar(
//           title: Text(MyApp._pageNameOptions[_selectedIndex]),
//           centerTitle: true,
//           bottom: PreferredSize(
//             preferredSize: const Size.fromHeight(1),
//             child: Container(
//               color: Color.fromRGBO(234, 234, 234, 1),
//               height: 1,
//             ),
//           ),
//         ),
//         body: MyApp._widgetOptions[_selectedIndex],
//         bottomNavigationBar: BottomNavigationBar(
//           items: <BottomNavigationBarItem>[
//             BottomNavigationBarItem(
//               icon: SvgPicture.asset(
//                 'assets/icons/wishlists.svg',
//                 color: _selectedIndex == 0
//                     ? MyApp._selectedColor
//                     : MyApp._unselectedColor,
//               ),
//               label: 'Wishlists',
//             ),
//             BottomNavigationBarItem(
//               icon: SvgPicture.asset(
//                 'assets/icons/start-new-search.svg',
//                 color: _selectedIndex == 1
//                     ? MyApp._selectedColor
//                     : MyApp._unselectedColor,
//               ),
//               label: 'New Chat',
//             ),
//             BottomNavigationBarItem(
//               icon: SvgPicture.asset(
//                 'assets/icons/settings.svg',
//                 color: _selectedIndex == 2
//                     ? MyApp._selectedColor
//                     : MyApp._unselectedColor,
//               ),
//               label: 'Settings',
//             ),
//           ],
//           selectedItemColor: MyApp._selectedColor,
//           unselectedItemColor: MyApp._unselectedColor,
//           selectedFontSize: 14,
//           unselectedFontSize: 14,
//           currentIndex: _selectedIndex,
//           onTap: _onItemTapped,
//         ),
//       ),
//     );
//   }
// }





// Use to seed wishlists for new user
//final ApiClient client = ApiClient();
//
// const String startPersonalWishlistMutations = r'''
//   mutation startPersonalWishlist($dto: WishlistCreateDtoInput!) {
//   startPersonalWishlist(dto: $dto) {
//     createdById, id, name, type
//   }
// }
// ''';
//
// MutationOptions mutationOptions = MutationOptions(
//     document: gql(startPersonalWishlistMutations),
//     variables: const <String, dynamic>{
//       'dto': {
//         'firstMessageText': 'Gaming mechanical keyboard',
//         'type': 'Product'
//       },
//     });
//
// var client = ApiClient();
// // for (var i = 0; i < 5; i++) {
// //   client
// //       .mutate(mutationOptions)
// //       .then((result) => print(jsonEncode(result)));
// //   sleep(Duration(milliseconds: 100));
// // }
//
