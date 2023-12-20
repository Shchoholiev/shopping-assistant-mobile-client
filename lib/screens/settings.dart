import 'package:flutter/material.dart';
import 'package:graphql/client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopping_assistant_mobile_client/network/api_client.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  var client = ApiClient();

  @override
  void initState() {
    super.initState();
  }

  void _showAccountDeletionConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Action'),
          content: Text(
              'Do you really want to delete your account? You will not be able to restore it.'),
          actions: <Widget>[
            TextButton(
              child: Text('Yes'),
              onPressed: () async {
                await _deleteAccount();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    var prefs = await SharedPreferences.getInstance();

    const String deleteAccountMutation = r'''
            mutation deletePersonalUser($guestId: String!) {
              deletePersonalUser(guestId: $guestId)
            }
          ''';

    MutationOptions mutationOptions = MutationOptions(
        document: gql(deleteAccountMutation),
        variables: <String, dynamic>{
          'guestId': prefs.getString('guestId'),
        });

    await client.mutate(mutationOptions);

    prefs.remove('accessToken');
    prefs.remove('refreshToken');
    prefs.remove('guestId');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 30,
        horizontal: 20,
      ),
      child: Container(
        height: 85,
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 20,
              margin: EdgeInsets.only(
                left: 15,
              ),
              child: Text(
                'Account',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            GestureDetector(
              onTap: _showAccountDeletionConfirmation,
              child: Container(
                height: 55,
                width: double.infinity,
                margin: EdgeInsets.only(
                  top: 10,
                ),
                padding: EdgeInsets.only(
                  left: 15,
                ),
                alignment: AlignmentDirectional.centerStart,
                decoration: BoxDecoration(
                  color: Color.fromRGBO(234, 234, 234, 1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Delete Account',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
