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
              message.trim(),
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
  String wishlistId;
  String wishlistName;
  bool openedFromBottomBar; 

  ChatScreen({Key? key, required this.wishlistId, required this.wishlistName, required this.openedFromBottomBar}) : super(key: key);

  @override
  State createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  var logger = Logger();
  SearchService _searchService = SearchService();
  List<Message> messages = [];
  TextEditingController _messageController = TextEditingController();
  List<String> suggestions = [];
  bool showBackButton = false;
  bool buttonsVisible = true;
  bool isSendButtonEnabled = false;
  bool showButtonsContainer = true;
  bool isWaitingForResponse = false;
  ScrollController _scrollController = ScrollController();
  late Widget appBarTitle;

  void initState() {
    super.initState();
    if (widget.openedFromBottomBar) {
      _resetState();
    }
    appBarTitle = Text('New Chat', style: TextStyle(fontSize: 18.0));
    _searchService.sseStream.listen((event) {
      _handleSSEMessage(Message(text: '${event.data}'));
    });
    Future.delayed(Duration(milliseconds: 2000));
    if(!widget.wishlistId.isEmpty)
    {
      _loadPreviousMessages();
      showBackButton = true;
      showButtonsContainer = false;
      buttonsVisible = false;
    }
  }

  void _resetState() {
    widget.wishlistId = '';
    widget.wishlistName = '';
    _searchService = SearchService();
    messages = [];
    _messageController = TextEditingController();
    showBackButton = false;
    buttonsVisible = true;
    isSendButtonEnabled = false;
    showButtonsContainer = true;
    isWaitingForResponse = false;
    _scrollController = ScrollController();
    appBarTitle = const Text('New Chat', style: TextStyle(fontSize: 18.0));
  }

  Future<void> _loadPreviousMessages() async {
    final pageNumber = 1;
    final pageSize = 200;
    appBarTitle = Text(widget.wishlistName, style: TextStyle(fontSize: 18.0));
    try {
      final previousMessages = await _searchService.getMessagesFromPersonalWishlist(widget.wishlistId, pageNumber, pageSize);
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
      if(message.isSuggestion){
        suggestions.add(message.text);
      }
      logger.d("Product status: ${message.isProduct}");
      logger.d("Suggestion status: ${message.isSuggestion}");
      logger.d("Message text: ${message.text}");
      if (lastMessage != null && lastMessage.role != "User" && message.role != "User" && !message.isSuggestion) {
        String fullMessageText = lastMessage.text + message.text;
        fullMessageText = fullMessageText.replaceAll("\\n", "");
        logger.d("fullMessageText: $fullMessageText");
        final updatedMessage = Message(
            text: fullMessageText,
            role: "Application",
            isProduct: message.isProduct);
        messages.removeLast();
        messages.add(updatedMessage);
      } else {
        String messageText = message.text.replaceAll("\\n", "");
        if (!message.isSuggestion) {
          messages.add(Message(text: messageText, role: message.role, isProduct: message.isProduct, isSuggestion: message.isSuggestion));
        }
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
    widget.wishlistId = await _searchService.startPersonalWishlist(message);
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

    if (widget.wishlistId.isEmpty) {
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
    suggestions.clear();
    _scrollToBottom();
  }

  void _handleSuggestion(String suggestion) {
    _messageController.text = suggestion;
    _sendMessage();
    suggestions.clear();
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

  Widget _generateSuggestionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Several possible options',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: suggestions.map((suggestion) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: ElevatedButton(
                  onPressed: () {
                    _handleSuggestion(suggestion);
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
                  child: Text(suggestion, style: TextStyle(color: Colors.black)),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: appBarTitle,
        centerTitle: true,
        leading: showBackButton
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            : null,
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
          if (suggestions.isNotEmpty)
            _generateSuggestionButtons(),
          Container(
            margin: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 15.0), // Adjust the left padding as needed
                    child: TextField(
                      controller: _messageController,
                      onChanged: (text) {
                        setState(() {
                          isSendButtonEnabled = text.isNotEmpty;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter your message...',
                        contentPadding: EdgeInsets.symmetric(vertical: 20.0),
                      ),
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
