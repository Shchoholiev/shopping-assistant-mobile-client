import 'package:flutter/material.dart';

class Cards extends StatefulWidget {
  final String wishlistName;
  List<String> products = [];

  Cards({required this.wishlistName, required this.products});

  @override
  _CardsState createState() => _CardsState();
}

class _CardsState extends State<Cards> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.wishlistName),
        centerTitle: true,
      ),
      body: Center(
        child: Stack(
          children: [
            // Back Card with increased rotation effect
            Positioned(
              left: 10, // Adjust the left position as needed
              child: Transform.rotate(
                angle: -5 * 3.1415926535 / 180, // Rotation angle
                child: Container(
                  width: 400, // Increased width
                  height: 600, // Increased height
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                    border: Border.all(
                      color: Color(0xFF009FFF),
                    ),
                  ),
                ),
              ),
            ),
            // Main Card
            Container(
              width: 300, // Set the width of the main card
              height: 500, // Set the height of the main card
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
                border: Border.all(
                  color: Color(0xFF009FFF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

