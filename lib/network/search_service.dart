// search_service.dart
import 'dart:async';
import 'package:logger/logger.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../models/enums/search_event_type.dart';
import '../models/server_sent_event.dart';
import '../network/api_client.dart';
import '../screens/chat.dart';

const String startPersonalWishlistMutations = r'''
  mutation startPersonalWishlist($dto: WishlistCreateDtoInput!) {
    startPersonalWishlist(dto: $dto) {
      createdById, id, name, type
    }
  }
''';

var logger = Logger();

SearchEventType type = SearchEventType.message;

class SearchService {
  final ApiClient client = ApiClient();

  late final _sseController = StreamController<ServerSentEvent>();

  Stream<ServerSentEvent> get sseStream => _sseController.stream;

  bool checkerForProduct() {
    return type == SearchEventType.product;
  }

  bool checkerForSuggestion() {
    return type == SearchEventType.suggestion;
  }

  String? wishlistId;

  Future<String?> generateNameForPersonalWishlist(String wishlistId) async {
    final options = MutationOptions(
      document: gql('''
      mutation GenerateNameForPersonalWishlist(\$wishlistId: String!) {
        generateNameForPersonalWishlist(wishlistId: \$wishlistId) {
          id
          name
        }
      }
    '''),
      variables: {'wishlistId': wishlistId},
    );

    final result = await client.mutate(options);

    if (result != null && result.containsKey('generateNameForPersonalWishlist')) {
      final name = result['generateNameForPersonalWishlist']['name'];
      return name;
    }

    return null;
  }

  Future<String> startPersonalWishlist(String message) async {

    if (wishlistId == null) {
      final options = MutationOptions(
        document: gql(startPersonalWishlistMutations),
        variables: <String, dynamic>{
          'dto': {'firstMessageText': "What are you looking for?", 'type': 'Product'},
        },
      );

      final result = await client.mutate(options);

      if (result != null && result.containsKey('startPersonalWishlist')) {
        wishlistId = result['startPersonalWishlist']['id'];
      }
    }
    return wishlistId.toString();
  }

  Future<void> sendMessages(String message) async {

    if (wishlistId != null) {
      final sseStream = client.getServerSentEventStream(
        'api/productssearch/search/$wishlistId',
        {'text': message},
      );

      await for (final chunk in sseStream) {
        print("Original chunk.data: ${chunk.event}");
        final cleanedMessage = chunk.data.replaceAll(RegExp(r'(^"|"$)'), '');

        final event = ServerSentEvent(chunk.event, cleanedMessage);
        type = chunk.event;
        _sseController.add(event);
      }
    }
  }

  Future<List<Message>> getMessagesFromPersonalWishlist(String wishlistIdPar, int pageNumber, int pageSize) async {
    final options = QueryOptions(
      document: gql('''
        query MessagesPageFromPersonalWishlist(\$wishlistId: String!, \$pageNumber: Int!, \$pageSize: Int!) {
          messagesPageFromPersonalWishlist(wishlistId: \$wishlistId, pageNumber: \$pageNumber, pageSize: \$pageSize) {
            items {
              id
              text
              role
              createdById
            }
          }
        }
      '''),
      variables: {
        'wishlistId': wishlistIdPar,
        'pageNumber': pageNumber,
        'pageSize': pageSize,
      },
    );

    logger.d("DOCUMENT: ${options.document}");

    final result = await client.query(options);

    print("RESULT: ${result}");
    print(result);
    if (result != null &&
        result.containsKey('messagesPageFromPersonalWishlist') &&
        result['messagesPageFromPersonalWishlist'] != null &&
        result['messagesPageFromPersonalWishlist']['items'] != null) {
      final List<dynamic> items = result['messagesPageFromPersonalWishlist']['items'];

      final List<Message> messages = items.map((item) {
        return Message(
          text: item['text'],
          role: item['role'],
          isProduct: false,
        );
      }).toList();

      return messages;
    }
    return [];
  }
}