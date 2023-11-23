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

class SearchService {
  final AuthenticationService _authenticationService = AuthenticationService();
  final ApiClient client = ApiClient();

  final _sseController = StreamController<ServerSentEvent>();

  Stream<ServerSentEvent> get sseStream => _sseController.stream;

  Future<void> initializeAuthenticationService() async {
    await _authenticationService.initialize();
  }

  Future<void> startPersonalWishlist(String message) async {
    await _authenticationService.initialize();

    final options = MutationOptions(
      document: gql(startPersonalWishlistMutations),
      variables: <String, dynamic>{
        'dto': {'firstMessageText': message, 'type': 'Product'},
      },
    );

    final result = await client.mutate(options);

    if (result != null && result.containsKey('startPersonalWishlist')) {
      final wishlistId = result['startPersonalWishlist']['id'];
      final sseStream = client.getServerSentEventStream(
        'api/productssearch/search/$wishlistId',
        {'text': message},
      );

      StringBuffer fullMessage = StringBuffer(); // Використовуємо StringBuffer для зберігання повідомлення

      await for (final chunk in sseStream) {
        fullMessage.write(chunk.data); // Додаємо чанк до повідомлення
      }

      final cleanedMessage = fullMessage.toString().replaceAll('"', '');

      final event = ServerSentEvent(SearchEventType.message, cleanedMessage.toString().trim());
      _sseController.add(event);
    }
  }
}
