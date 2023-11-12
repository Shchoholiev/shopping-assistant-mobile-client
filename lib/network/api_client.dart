import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:graphql/client.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_assistant_mobile_client/models/enums/search_event_type.dart';
import 'package:shopping_assistant_mobile_client/models/global_instances/global_user.dart';
import 'package:shopping_assistant_mobile_client/models/server_sent_event.dart';
import 'package:shopping_assistant_mobile_client/network/authentication_service.dart';

class ApiClient {
  final String _apiBaseUrl = 'https://shopping-assistant-api-dev.azurewebsites.net/';
  late String _accessToken;

  final AuthenticationService _authenticationService = AuthenticationService();

  late GraphQLClient _graphqlClient;
  final http.Client _httpClient = http.Client();

  Future<Map<String, dynamic>?> query(QueryOptions options) async {
    await _setAuthentication();

    final QueryResult result = await _graphqlClient.query(options);

    if (result.hasException) {
      print(result.exception.toString());
    }

    return result.data;
  }

  Future<Map<String, dynamic>?> mutate(MutationOptions options) async {
    await _setAuthentication();

    final QueryResult result = await _graphqlClient.mutate(options);

    if (result.hasException) {
      print(result.exception.toString());
    }

    return result.data;
  }

  Stream<ServerSentEvent> getServerSentEventStream(String urlPath, Map<dynamic, dynamic> requestBody) async* {
    await _setAuthentication();

    final url = Uri.parse('$_apiBaseUrl$urlPath');
    final request = http.Request('POST', url);
    request.body = jsonEncode(requestBody);
    request.headers.addAll({
      HttpHeaders.authorizationHeader: 'Bearer $_accessToken',
      HttpHeaders.contentTypeHeader: 'application/json'
    });
    final response = await _httpClient.send(request);
    
    var eventType = SearchEventType.message;
    await for (var line in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
      if (line.startsWith('event: ')) {
        var type = line.substring('event: '.length);
        switch (type) {
          case 'Message':
            eventType = SearchEventType.message;
            break;
          case 'Suggestion':
            eventType = SearchEventType.suggestion;
            break;
          case 'Product':
            eventType = SearchEventType.product;
            break;
          case 'Wishlist':
            eventType = SearchEventType.wishlist;
            break;
        }
      }
      if (line.startsWith('data: ')) {
        yield ServerSentEvent(eventType, line.substring('data: '.length));
      }
    }
  }

  Future _setAuthentication() async {
    _accessToken = await _authenticationService.getAccessToken();

    GlobalUser.id = _authenticationService.getIdFromAccessToken(_accessToken);
    GlobalUser.email = _authenticationService.getEmailFromAccessToken(_accessToken);
    GlobalUser.phone = _authenticationService.getPhoneFromAccessToken(_accessToken);
    // GlobalUser.roles = _authenticationService.getRolesFromAccessToken(_accessToken);

    final httpLink = HttpLink('${_apiBaseUrl}graphql/', defaultHeaders: {
      HttpHeaders.authorizationHeader: 'Bearer $_accessToken'
    });

    _graphqlClient = GraphQLClient(
      cache: GraphQLCache(),
      link: httpLink
    );
  }
}
