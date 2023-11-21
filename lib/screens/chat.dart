import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shopping_assistant_mobile_client/network/api_client.dart';

const String startPersonalWishlistMutations = r'''
  mutation startPersonalWishlist($dto: WishlistCreateDtoInput!) {
    startPersonalWishlist(dto: $dto) {
      createdById, id, name, type
    }
  }
''';

const String sendMessageMutation = r'''
  mutation sendMessage($wishlistId: ID!, $message: String!) {
    sendMessage(wishlistId: $wishlistId, message: $message) {
      // Опис того, що ви очікуєте від відповіді
    }
  }
''';

final ApiClient client = ApiClient();

class ChatScreen extends StatefulWidget {
  @override
  State createState() => ChatScreenState();
}

class MessageBubble extends StatelessWidget {
  final String message;

  MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.all(8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Text(
          message,
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class ChatScreenState extends State<ChatScreen> {

  final TextEditingController _messageController = TextEditingController();
  List<String> messages = [];
  bool buttonsVisible = true;
  final ScrollController _scrollController = ScrollController();


  String wishlistId = '';

  // Функція для старту першої вішлісту при відправці першого повідомлення
  Future<void> _startPersonalWishlist() async {
    final options = MutationOptions(
      document: gql(startPersonalWishlistMutations),
      variables: <String, dynamic>{
        'dto': {'firstMessageText': messages.first, 'type': 'Product'},
      },
    );

    final result = await client.mutate(options);

    if (result != null && result.containsKey('startPersonalWishlist')) {
      setState(() {
        wishlistId = result['startPersonalWishlist']['id'];
      });
    }
  }

  // Функція для відправки повідомлення до API
  Future<void> _sendMessageToAPI(String message) async {
    final options = MutationOptions(
      document: gql(sendMessageMutation),
      variables: <String, dynamic>{'wishlistId': wishlistId, 'message': message},
    );

    final result = await client.mutate(options);

    // Обробка результатів відправки повідомлення
    if (result != null && result.containsKey('sendMessage')) {
      // Отримання та обробка відповідей з GPT-4
      var sseStream = client.getServerSentEventStream(
        'api/productssearch/search/$wishlistId',
        {'text': message},
      );

      await for (var chunk in sseStream) {
        print('${chunk.event}: ${chunk.data}');
        // Оновлення UI або збереження результатів, якщо необхідно
      }
    }
  }

  // Функція для відправки повідомлення
  void _sendMessage() {
    String message = _messageController.text;
    setState(() {
      messages.insert(0, message);
    });

    if (wishlistId.isEmpty) {
      // Якщо вішліст не створено, стартуємо його
      _startPersonalWishlist().then((_) {
        // Після створення вішлісту, відправляємо перше повідомлення до API
        _sendMessageToAPI(message);
      });
    } else {
      // Якщо вішліст вже існує, відправляємо повідомлення до API
      _sendMessageToAPI(message);
    }

    _messageController.clear();
    _scrollController.animateTo(
      0.0,
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
        title: Text('New Chat'),
        centerTitle: true, // Відцентрувати заголовок
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // Обробник для кнопки "Назад"
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
                          // Обробник для кнопки "Product"
                          print('Product button pressed');
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // Закруглення країв
                          ),
                          primary: Colors.blue, // Колір кнопки
                          onPrimary: Colors.white, // Колір тексту на активній кнопці
                        ),
                        child: Text('Product'),
                      ),
                      SizedBox(width: 16.0), // Простір між кнопками
                      ElevatedButton(
                        onPressed: _showGiftNotAvailable,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // Закруглення країв
                          ),
                          primary: Colors.white, // Колір кнопки "Gift"
                          onPrimary: Colors.black, // Колір тексту на активній кнопці
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
            child: ListView(
              controller: _scrollController,
              reverse: true, // Щоб список був у зворотньому порядку
              children: <Widget>[
                // Повідомлення користувача
                for (var message in messages)
                  MessageBubble(
                    message: message,
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