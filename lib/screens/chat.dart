// search_screen.dart

import 'package:flutter/material.dart';
import 'package:shopping_assistant_mobile_client/network/search_service.dart';

class Message {
  final String text;
  final bool isUser;
  bool isProduct;

  Message({required this.text, this.isUser = false, this.isProduct = false});
}

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isOutgoing;
  final bool isProduct;

  MessageBubble({required this.message, this.isOutgoing = true, this.isProduct = false});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.all(8.0),
        padding: const EdgeInsets.all(16.0),
        constraints: BoxConstraints(
          maxWidth: 300.0, // Максимальна ширина контейнера
        ),
        decoration: BoxDecoration(
          color: isOutgoing ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(color: isOutgoing ? Colors.white : Colors.black),
            ),
            if (isProduct) // Виводимо кнопку тільки для повідомлень типу Product
              ElevatedButton(
                onPressed: () {
                  // Обробка натискання на кнопку "View Product"
                  print('View Product button pressed');
                },
                style: ElevatedButton.styleFrom(
                    primary: Colors.indigo,
                    onPrimary: Colors.white,
                    minimumSize: Size(300, 50)
                ),
                child: Text('View Product'),
              ),
          ],
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
  bool isSendButtonEnabled = false;
  bool showButtonsContainer = true;
  final ScrollController _scrollController = ScrollController();
  late Widget appBarTitle;

  String wishlistId = '';

  void initState() {
    super.initState();
    appBarTitle = Text('New Chat');
    _searchService.sseStream.listen((event) {
      _handleSSEMessage(Message(text: '${event.data}'));
    });
  }

  void _handleSSEMessage(Message message) {
    setState(() {
      final lastMessage = messages.isNotEmpty ? messages.last : null;
      message.isProduct = _searchService.checkerForProduct();
      print("Product status: ${message.isProduct}");
      if (lastMessage != null && !lastMessage.isUser && !message.isUser) {
        final updatedMessage = Message(
            text: "${lastMessage.text}${message.text}",
            isProduct: message.isProduct);
        messages.removeLast();
        messages.add(updatedMessage);
      } else {
        messages.add(message);
      }
    });
    _scrollToBottom();
  }

  Future<void> updateChatTitle(String wishlistId) async {
    final wishlistName = await _searchService.generateNameForPersonalWishlist(wishlistId);
    if (wishlistName != null) {
      setState(() {
        // Оновіть назву чату з результатом методу generateNameForPersonalWishlist
        appBarTitle = Text(wishlistName);
      });
    }
  }

  Future<void> _startPersonalWishlist(String message) async {
    setState(() {
      buttonsVisible = false;
      showButtonsContainer = false;
    });
    await _searchService.initializeAuthenticationService();
    await _searchService.startPersonalWishlist(message);
    updateChatTitle(_searchService.wishlistId.toString());
    _scrollToBottom();
  }

  Future<void> _sendMessageToAPI(String message) async {
    setState(() {
      buttonsVisible = false;
      showButtonsContainer = false;
    });
    await _searchService.startPersonalWishlist(message);
    _scrollToBottom();

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
    _scrollToBottom();
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

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
        title: appBarTitle,
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
                          padding: EdgeInsets.symmetric(
                              horizontal: 30, vertical: 16),
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
                          padding: EdgeInsets.symmetric(
                              horizontal: 30, vertical: 16),
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
          SizedBox(height: 16.0), // Відступ вниз
          Visibility(
            visible: showButtonsContainer,
            child: Container(
              margin: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.all(8),
                    child: ElevatedButton(
                      onPressed: () {
                        _messageController.text = 'Christmas gift🎁';
                        _sendMessage();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        primary: Colors.white,
                        onPrimary: Colors.blue,
                        side: BorderSide(color: Colors.blue, width: 2.0),
                      ),
                      child: Text('Christmas gift🎁', style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.all(8),
                    child: ElevatedButton(
                      onPressed: () {
                        _messageController.text = 'Birthday gift🎉';
                        _sendMessage();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        primary: Colors.white,
                        onPrimary: Colors.blue,
                        side: BorderSide(color: Colors.blue, width: 2.0),
                      ),
                      child: Text('Birthday gift🎉', style: TextStyle(color: Colors.grey)),
                    ),
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
                  isProduct: message.isProduct,
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
                    onChanged: (text) {
                      // Коли текст змінюється, оновлюємо стан кнопки
                      setState(() {
                        isSendButtonEnabled = text.isNotEmpty;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter your message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: isSendButtonEnabled ? _sendMessage : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}