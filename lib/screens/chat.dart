// search_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:logger/logger.dart';
import 'package:shopping_assistant_mobile_client/network/search_service.dart';

class Message {
  final String text;
  final String role;
  bool isProduct;
  bool isSuggestion;

  Message({required this.text, this.role = "", this.isProduct = false, this.isSuggestion = false});
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
          maxWidth: 300.0,
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
              style: TextStyle(color: isOutgoing ? Colors.white : Colors.black,
                  fontSize: 18.0
              ),
            ),
            if (isProduct)
              ElevatedButton(
                onPressed: () {
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
  var logger = Logger();
  final SearchService _searchService = SearchService();
  List<Message> messages = [];
  final TextEditingController _messageController = TextEditingController();
  bool buttonsVisible = true;
  bool isSendButtonEnabled = false;
  bool showButtonsContainer = true;
  bool isWaitingForResponse = false;
  final ScrollController _scrollController = ScrollController();
  late Widget appBarTitle;

  String wishlistId = '';

  void initState() {
    super.initState();
    appBarTitle = Text('New Chat', style: TextStyle(fontSize: 18.0));
    _searchService.sseStream.listen((event) {
      _handleSSEMessage(Message(text: '${event.data}'));
    });
    Future.delayed(Duration(milliseconds: 2000));
    if(!wishlistId.isEmpty)
    {
      _loadPreviousMessages();
      showButtonsContainer = false;
      buttonsVisible = false;
    }
  }

  Future<void> _loadPreviousMessages() async {
    final pageNumber = 1;
    final pageSize = 200;
    try {
      final previousMessages = await _searchService.getMessagesFromPersonalWishlist("6560b4c210686c50ed4b9fec", pageNumber, pageSize);
      final reversedMessages = previousMessages.reversed.toList();
      setState(() {
        messages.addAll(reversedMessages);
      });
      logger.d('Previous Messages: $previousMessages');

      for(final message in messages)
      {
        logger.d("MESSAGES TEXT: ${message.text}");
        logger.d("MESSAGES ROLE: ${message.role}");
      }
    } catch (error) {
      logger.d('Error loading previous messages: $error');
    }
  }

  void _handleSSEMessage(Message message) {
    setState(() {
      isWaitingForResponse = true;
      final lastMessage = messages.isNotEmpty ? messages.last : null;
      message.isProduct = _searchService.checkerForProduct();
      message.isSuggestion = _searchService.checkerForSuggestion();
      logger.d("Product status: ${message.isProduct}");
      if (lastMessage != null && lastMessage.role != "User" && message.role != "User") {
        final updatedMessage = Message(
            text: "${lastMessage.text}${message.text}",
            role: "Application",
            isProduct: message.isProduct);
        messages.removeLast();
        messages.add(updatedMessage);
      } else {
        messages.add(message);
      }
    });
    setState(() {
      isWaitingForResponse = false;
    });
    _scrollToBottom();
  }

  Future<void> updateChatTitle(String wishlistId) async {
    final wishlistName = await _searchService.generateNameForPersonalWishlist(wishlistId);
    if (wishlistName != null) {
      setState(() {
        appBarTitle = Text(wishlistName, style: TextStyle(fontSize: 18.0));
      });
    }
  }

  Future<void> _startPersonalWishlist(String message) async {
    setState(() {
      buttonsVisible = false;
      showButtonsContainer = false;
      isWaitingForResponse = true;
    });
    wishlistId = await _searchService.startPersonalWishlist(message);
    await _sendMessageToAPI(message);
    await updateChatTitle(_searchService.wishlistId.toString());
    _scrollToBottom();

    setState(() {
      isWaitingForResponse = false;
    });
  }

  Future<void> _sendMessageToAPI(String message)async {
    setState(() {
      buttonsVisible = false;
      showButtonsContainer = false;
      isWaitingForResponse = true;
    });
    await _searchService.sendMessages(message);
    _scrollToBottom();

    setState(() {
      isWaitingForResponse = false;
    });
  }

  void _sendMessage() {
    final message = _messageController.text;

    if (wishlistId.isEmpty) {
      setState(() {
        messages.add(Message(text: "What are you looking for?", role: "Application"));
        messages.add(Message(text: message, role: "User"));
      });
      _startPersonalWishlist(message);
    } else {
      setState(() {
        messages.add(Message(text: message, role: "User"));
      });
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
                    'What are you looking for?',
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
          SizedBox(height: 16.0),
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
                  isOutgoing: message.role == "User",
                  isProduct: message.isProduct,
                );
              },
            ),
          ),
          if (isWaitingForResponse)
            SpinKitFadingCircle(
              color: Colors.blue,
              size: 25.0,
            ),
          if (messages.any((message) => message.isSuggestion))
            Container(
              padding: EdgeInsets.all(8.0),
              color: Colors.grey[300],
              child: Row(
                children: [
                  Icon(Icons.lightbulb),
                  SizedBox(width: 8.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: messages
                        .where((message) => message.isSuggestion)
                        .map((message) => Text(message.text))
                        .toList(),
                  ),
                ],
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
                      setState(() {
                        isSendButtonEnabled = text.isNotEmpty;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter your message...',
                        contentPadding: EdgeInsets.symmetric(vertical: 20.0)
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