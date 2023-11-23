// search_screen.dart

import 'package:flutter/material.dart';
import 'package:shopping_assistant_mobile_client/network/search_service.dart';

class Message {
  final String text;
  final bool isUser;

  Message({required this.text, this.isUser = false});
}

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isOutgoing;

  MessageBubble({required this.message, this.isOutgoing = true});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.all(8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isOutgoing ? Colors.blue : Colors.white38,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Text(
          message,
          style: TextStyle(color: isOutgoing ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  State createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final SearchService _searchService = SearchService();
  List<Message> messages = [];
  final TextEditingController _messageController = TextEditingController();
  bool buttonsVisible = true;
  final ScrollController _scrollController = ScrollController();

  String wishlistId = '';

  @override
  void initState() {
    super.initState();
    _searchService.sseStream.listen((event) {
      _handleSSEMessage(Message(text: '${event.event}: ${event.data}'));
    });
  }

  void _handleSSEMessage(Message message) {
    setState(() {
      messages.add(message);
    });
  }

  Future<void> _startPersonalWishlist(String message) async {
    await _searchService.initializeAuthenticationService();
    await _searchService.startPersonalWishlist(message);
  }

  Future<void> _sendMessageToAPI(String message) async {
    await _searchService.startPersonalWishlist(message);

    setState(() {
      messages.add(Message(text: message, isUser: true));
    });
  }

  void _sendMessage() {
    final message = _messageController.text;
    setState(() {
      messages.add(Message(text: message, isUser: true));
    });

    if (wishlistId.isEmpty) {
      _startPersonalWishlist(message);
    } else {
      _sendMessageToAPI(message);
    }

    _messageController.clear();
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );}

  void _showGiftNotAvailable() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Gift Functionality'),
          content: Text('This function is currently unavailable.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Chat'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            print('Back button pressed');
          },
        ),
      ),
      body: Column(
        children: <Widget>[
          Visibility(
            visible: buttonsVisible,
            child: Align(
              alignment: Alignment.topCenter,
              child: Column(
                children: [
                  Text(
                    'Choose an Option',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: () {
                          print('Product button pressed');
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          primary: Colors.blue,
                          onPrimary: Colors.white,
                        ),
                        child: Text('Product'),
                      ),
                      SizedBox(width: 16.0),
                      ElevatedButton(
                        onPressed: _showGiftNotAvailable,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          primary: Colors.white,
                          onPrimary: Colors.black,
                        ),
                        child: Text('Gift'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: false,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return MessageBubble(
                  message: message.text,
                  isOutgoing: message.isUser,
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Enter your message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}