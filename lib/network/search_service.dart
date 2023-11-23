// search_service.dart

import 'dart:async';

import 'package:graphql_flutter/graphql_flutter.dart';
import '../models/enums/search_event_type.dart';
import '../models/server_sent_event.dart';
import '../network/api_client.dart';
import '../network/authentication_service.dart';
import '../screens/chat.dart';

const String startPersonalWishlistMutations = r'''
  mutation startPersonalWishlist($dto: WishlistCreateDtoInput!) {
    startPersonalWishlist(dto: $dto) {
      createdById, id, name, type
    }
  }
''';

SearchEventType type = SearchEventType.message;

class SearchService {
  final AuthenticationService _authenticationService = AuthenticationService();
  final ApiClient client = ApiClient();

  final _sseController = StreamController<ServerSentEvent>();

  Stream<ServerSentEvent> get sseStream => _sseController.stream;

  Future<void> initializeAuthenticationService() async {
    await _authenticationService.initialize();
  }

  bool checkerForProduct() {
    return type == SearchEventType.product;
  }

  String? wishlistId;

  Future<void> startPersonalWishlist(String message) async {
    await _authenticationService.initialize();

    // Перевіряємо, чи вже створений wishlist
    if (wishlistId == null) {
      final options = MutationOptions(
        document: gql(startPersonalWishlistMutations),
        variables: <String, dynamic>{
          'dto': {'firstMessageText': message, 'type': 'Product'},
        },
      );

      final result = await client.mutate(options);

      if (result != null && result.containsKey('startPersonalWishlist')) {
        wishlistId = result['startPersonalWishlist']['id'];
      }
    }

    if (wishlistId != null) {
      final sseStream = client.getServerSentEventStream(
        'api/productssearch/search/$wishlistId',
        {'text': message},
      );

      await for (final chunk in sseStream) {
        print("Original chunk.data: ${chunk.event}");
        final cleanedMessage = chunk.data.replaceAll(RegExp(r'(^"|"$)'), '');
        if(chunk.event == SearchEventType.message)
        {
          type = SearchEventType.message;
        }
        if(chunk.event == SearchEventType.product)
        {
          type = SearchEventType.product;
        }

        final event = ServerSentEvent(type, cleanedMessage);
        _sseController.add(event);
      }
    }
  }
}