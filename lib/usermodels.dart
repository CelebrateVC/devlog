import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class RateLimitClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  DateTime earlier = DateTime.utc(1989, 11, 9);
  DateTime later = DateTime.utc(1989, 11, 10);
  late String token;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    var now = DateTime.now();
    if (now.isBefore(earlier)) {
      sleep(now.difference(earlier));
    }
    earlier = later;
    later = now.add(const Duration(minutes: 1));
    request.headers['Authorization'] = token;
    return _inner.send(request);
  }
}

class Privacy {
  String descriptionPrivacy;
  String memberListPrivacy;
  String groupListPrivacy;
  String frontPrivacy;
  String frontHistoryPrivacy;

  Privacy(this.descriptionPrivacy, this.memberListPrivacy,
      this.groupListPrivacy, this.frontPrivacy, this.frontHistoryPrivacy);
}

class Account {
  String name;
  String description;
  String avatarUrl;
  String color;
  Privacy privacy;
  Account(
      this.name, this.description, this.avatarUrl, this.color, this.privacy);
}

Future<Account?> accountFromToken(String token, RateLimitClient client) async {
  if (token.isEmpty) {
    return null;
  }
  print(token);
  http.Response res =
      await client.get(Uri.parse('https://api.pluralkit.me/v2/systems/@me'));
  return accountFromResp(res);
}

Account? accountFromResp(http.Response resp) {
  print(resp);
  if (resp.statusCode >= 300) {
    return null;
  }
  var decode = jsonDecode(utf8.decode(resp.bodyBytes)) as Map;
  print(decode);
  return Account(
      decode['name'] ?? 'no_name',
      decode['description'] ?? 'no',
      decode['avatarUrl'] ?? 'no',
      decode['color'] ?? 'no',
      Privacy(
          decode['privacy']['description_privacy'] ?? 'unreachable',
          decode['privacy']['member_list_privacy'] ?? 'unreachable',
          decode['privacy']['group_list_privacy'] ?? 'unreachable',
          decode['privacy']['front_privacy'] ?? 'unreachable',
          decode['privacy']['front_history_privacy'] ?? 'unreachable'));
}
