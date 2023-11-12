import 'package:graphql/client.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopping_assistant_mobile_client/constants/jwt_claims.dart';
import 'package:uuid/uuid.dart';

class AuthenticationService {
  final GraphQLClient client = GraphQLClient(
    cache: GraphQLCache(),
    link: HttpLink('https://shopping-assistant-api-dev.azurewebsites.net/graphql'),
  );

  late SharedPreferences prefs;

  AuthenticationService() {
    SharedPreferences.getInstance().then((result) => {prefs = result});
  }

  Future<String> getAccessToken() async {
    var accessToken = prefs.getString('accessToken');
    var refreshToken = prefs.getString('refreshToken');

    if (accessToken == null && refreshToken != null) {
      print('WTF??');
    } else if (accessToken == null && refreshToken == null) {
      accessToken = await accessGuest();
      print('Got new access token $accessToken');
    } else if (JwtDecoder.isExpired(accessToken!)) {
      accessToken = await refreshAccessToken();
      print('Refreshed access token $accessToken');
    }

    print('Returned access token $accessToken');
    return accessToken!;
  }

  Future login(String? email, String? phone, String password) async {
    const String loginQuery = r'''
      mutation Login($login: AccessUserModelInput!) {
        login(login: $login) {
          accessToken
          refreshToken
        }
      }
    ''';

    final MutationOptions options = MutationOptions(
      document: gql(loginQuery),
      variables: <String, dynamic>{
        'login': {
          'email': email,
          'phone': phone,
          'password': password,
        },
      },
    );

    final QueryResult result = await client.mutate(options);

    if (result.hasException) {
      print(result.exception.toString());
    }

    final accessToken = result.data?['login']['accessToken'] as String;
    final refreshToken = result.data?['login']['refreshToken'] as String;

    prefs.setString('accessToken', accessToken);
    prefs.setString('refreshToken', refreshToken);
  }

  Future<String> accessGuest() async {
    String? guestId = prefs.getString('guestId');
    guestId ??= const Uuid().v4();
    prefs.setString('guestId', guestId);

    const String accessGuestMutation = r'''
      mutation AccessGuest($guest: AccessGuestModelInput!) {
          accessGuest(guest: $guest) {
              accessToken
              refreshToken
          }
      }
    ''';

    final MutationOptions options = MutationOptions(
      document: gql(accessGuestMutation),
      variables: <String, dynamic>{
        'guest': {'guestId': guestId},
      },
    );

    final QueryResult result = await client.mutate(options);

    if (result.hasException) {
      print(result.exception.toString());
    }

    final String accessToken =
        result.data?['accessGuest']['accessToken'] as String;
    final String refreshToken =
        result.data?['accessGuest']['refreshToken'] as String;

    prefs.setString('accessToken', accessToken);
    prefs.setString('refreshToken', refreshToken);

    return accessToken;
  }

  Future<String> refreshAccessToken() async {
    var accessToken = prefs.getString('accessToken');
    var refreshToken = prefs.getString('refreshToken');

    const String refreshAccessTokenMutation = r'''
      mutation RefreshAccessToken($model: TokensModelInput!) {
        refreshAccessToken(model: $model) {
          accessToken
          refreshToken
        }
      }
    ''';

    final QueryOptions options = QueryOptions(
      document: gql(refreshAccessTokenMutation),
      variables: <String, dynamic>{
        'model': {
          'accessToken': accessToken,
          'refreshToken': refreshToken,
        },
      },
    );

    final QueryResult result = await client.query(options);

    if (result.hasException) {
      print(result.exception.toString());
    }

    accessToken = result.data?['refreshAccessToken']['accessToken'] as String;
    refreshToken = result.data?['refreshAccessToken']['refreshToken'] as String;

    prefs.setString('accessToken', accessToken);
    prefs.setString('refreshToken', refreshToken);

    return accessToken;
  }

  String getIdFromAccessToken(String accessToken) {
    var decodedToken = JwtDecoder.decode(accessToken);
    return decodedToken[JwtClaims.id];
  }

  String getEmailFromAccessToken(String accessToken) {
    var decodedToken = JwtDecoder.decode(accessToken);
    return decodedToken[JwtClaims.email];
  }

  String getPhoneFromAccessToken(String accessToken) {
    var decodedToken = JwtDecoder.decode(accessToken);
    return decodedToken[JwtClaims.phone];
  }

  // List<String> getRolesFromAccessToken(String accessToken) {
  //   var decodedToken = JwtDecoder.decode(accessToken);
  //   List<String> roles = [];
  //   for (var role in decodedToken[JwtClaims.roles] as List<dynamic>) {
  //     roles.add(role);
  //   }
  //   return roles;
  // }
}
