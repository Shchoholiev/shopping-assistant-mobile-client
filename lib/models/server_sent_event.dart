import 'package:shopping_assistant_mobile_client/models/enums/search_event_type.dart';

class ServerSentEvent {

  SearchEventType event;
  String data;

  ServerSentEvent(this.event, this.data);
}
