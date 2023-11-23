// search_service.dart

import 'package:graphql_flutter/graphql_flutter.dart';
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

  Future<void> initializeAuthenticationService() async {
    await _authenticationService.initialize();
  }

  Future<void> startPersonalWishlist(String message, Function(Message) handleSSEMessage) async {
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

      await for (final chunk in sseStream) {
        print('${chunk.event}: ${chunk.data}');
        handleSSEMessage(Message(text: '${chunk.event}: ${chunk.data}'));
      }
    }
  }
}
