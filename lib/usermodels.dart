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
      print(
          "data requests too close together sleeping for ${earlier.difference(now)}");
      Future.delayed(earlier.difference(now));
    }
    earlier = later;
    later = now.add(const Duration(seconds: 2));
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

class Switches {
  String uuid;
  late DateTime timestamp;
  late List<String> members;
  Switches(this.uuid, String ts, List mem) {
    timestamp = DateTime.parse(ts);
    members = [];
    for (String member in mem) {
      members.add(member);
    }
  }
}

Future<Account?> accountFromToken(RateLimitClient client) async {
  if (client.token.isEmpty) {
    return null;
  }
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

Future<List<Switches>> _getSwitches(
    RateLimitClient client, List<Switches> existing, Uri url) async {
  if (client.token.isEmpty) {
    return [];
  }
  http.Response res = await client.get(url);

  var decode = jsonDecode(utf8.decode(res.bodyBytes)) as List;

  var switches =
      decode.map((x) => Switches(x["id"], x["timestamp"], x["members"]));

  bool added = false;
  for (var element in switches) {
    if (!existing.any((x) => x.timestamp == element.timestamp)) {
      existing.add(element);
      added = true;
    }
  }
  if (added) {
    existing.sort((a, b) => -a.timestamp.compareTo(b.timestamp));

    return existing;
  } else {
    return [];
  }
}

Future<Map<String, String>> getMembers(
    RateLimitClient client, Map<String, String> map) async {
  print("getting members");
  if (map.isNotEmpty | client.token.isEmpty) {
    print("map is empty? ${map.isEmpty}");
    return map;
  }
  http.Response res = await client
      .get(Uri.parse("https://api.pluralkit.me/v2/systems/@me/members"));
  var decode = jsonDecode(utf8.decode(res.bodyBytes)) as List;

  print(decode);

  Map<String, String> result = {};
  for (var member in decode) {
    result[member['id']] = member['name'];
  }
  return result;
}

Future<List<Switches>> getSwitches(
    RateLimitClient client, List<Switches> existing) async {
  return _getSwitches(client, existing,
      Uri.parse("https://api.pluralkit.me/v2/systems/@me/switches"));
}

Future<List<Switches>> getMoreSwitches(
    RateLimitClient client, List<Switches> existing) {
  String st = "https://api.pluralkit.me/v2/systems/@me/switches?before=";

  Switches earliest =
      existing.reduce((a, b) => (a.timestamp.isAfter(b.timestamp)) ? b : a);

  st += earliest.timestamp.toIso8601String();

  print(st);

  return _getSwitches(client, existing, Uri.parse(st));
}
