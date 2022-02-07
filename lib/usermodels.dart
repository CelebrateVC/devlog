import 'dart:convert';
import 'dart:developer';
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
      log("data requests too close together sleeping for ${earlier.difference(now)}");
      Future.delayed(earlier.difference(now));
    }
    earlier = later;
    later = now.add(const Duration(seconds: 2));
    request.headers['Authorization'] = token;
    return _inner.send(request);
  }
}

class SystemPrivacy {
  String descriptionPrivacy;
  String memberListPrivacy;
  String groupListPrivacy;
  String frontPrivacy;
  String frontHistoryPrivacy;

  SystemPrivacy(this.descriptionPrivacy, this.memberListPrivacy,
      this.groupListPrivacy, this.frontPrivacy, this.frontHistoryPrivacy);
}

class System {
  String id;
  String uuid;
  String name;
  String? description;
  String tag;
  String? avatarUrl;
  String? banner;
  String color;
  DateTime created;
  SystemPrivacy privacy;
  System(this.id, this.uuid, this.name, this.description, this.tag,
      this.avatarUrl, this.banner, this.color, this.created, this.privacy);
}

class ProxyTag {
  String? prefix;
  String? suffix;

  ProxyTag(this.prefix, this.suffix);
}

class MemberPrivacy {
  String descriptionPrivacy;
  String visibility;
  String namePrivacy;
  String birthdayPrivacy;
  String pronounPrivacy;
  String avatarPrivacy;
  String metadataPrivacy;

  MemberPrivacy(
      this.descriptionPrivacy,
      this.visibility,
      this.namePrivacy,
      this.birthdayPrivacy,
      this.pronounPrivacy,
      this.avatarPrivacy,
      this.metadataPrivacy);
}

class Member {
  String id;
  String uuid;
  String name;
  String? displayName;
  String color;
  String? birthday;
  String? pronouns;
  String? avatarUrl;
  String? banner;
  String? descripiton;
  DateTime? created;
  List<ProxyTag> proxyTags;
  bool keepProxy;
  MemberPrivacy privacy;
  Member(
      this.id,
      this.uuid,
      this.name,
      this.displayName,
      this.color,
      this.birthday,
      this.pronouns,
      this.avatarUrl,
      this.banner,
      this.descripiton,
      this.created,
      this.proxyTags,
      this.keepProxy,
      this.privacy);
}

class GroupPrivacy {
  String namePrivacy;
  String descriptionPrivacy;
  String iconPrivacy;
  String listPrivacy;
  String metadataPrivacy;
  String visibility;

  GroupPrivacy(this.namePrivacy, this.descriptionPrivacy, this.iconPrivacy,
      this.listPrivacy, this.metadataPrivacy, this.visibility);
}

class Group {
  String id;
  String uuid;
  String name;
  String displayName;
  String descripiton;
  String icon;
  String banner;
  String color;
  GroupPrivacy privacy;

  Group(this.id, this.uuid, this.name, this.displayName, this.descripiton,
      this.icon, this.banner, this.color, this.privacy);
}

class Switches {
  String uuid;
  DateTime timestamp = DateTime.now();
  List<String> members = [];
  Switches(this.uuid, String ts, List mem) {
    timestamp = DateTime.parse(ts);
    for (String member in mem) {
      members.add(member);
    }
  }
}

// == Unimplemented Models == //
//Message
//System Settings
//System Guild
//Member Guild

class PluralKitWrapper {
  RateLimitClient client = RateLimitClient();

  PluralKitWrapper(String token) {
    client.token = token;
  }

  Future<System?> getSystem({String systemRef = "@me"}) async {
    if (client.token.isEmpty) {
      return null;
    }
    http.Response resp = await client
        .get(Uri.parse('https://api.pluralkit.me/v2/systems/' + systemRef));

    if (resp.statusCode >= 300) {
      return null;
    }
    var decode = jsonDecode(utf8.decode(resp.bodyBytes)) as Map;

    return System(
        decode['id'],
        decode['uuid'],
        decode['name'] ?? 'no_name',
        decode['description'] ?? 'no',
        decode['tag'],
        decode['avatarUrl'] ?? 'no',
        decode['banner'],
        decode['color'] ?? 'no',
        decode['created'],
        SystemPrivacy(
            decode['privacy']['description_privacy'] ?? 'unreachable',
            decode['privacy']['member_list_privacy'] ?? 'unreachable',
            decode['privacy']['group_list_privacy'] ?? 'unreachable',
            decode['privacy']['front_privacy'] ?? 'unreachable',
            decode['privacy']['front_history_privacy'] ?? 'unreachable'));
  }

  Future<Map<String, Member>> getMembers(Map<String, Member> map,
      {String systemRef = "@me"}) async {
    if (map.isNotEmpty | client.token.isEmpty) {
      log("map is empty? ${map.isEmpty}");
      return map;
    }

    String uri =
        "https://api.pluralkit.me/v2/systems/" + systemRef + "/members";

    http.Response res = await client.get(Uri.parse(uri));
    var decode = jsonDecode(utf8.decode(res.bodyBytes)) as List;

    Map<String, Member> result = {};
    for (var member in decode) {
      List<ProxyTag> proxyTags = [];
      for (var tag in member['proxy_tags']) {
        proxyTags.add(ProxyTag(tag['prefix'], tag['suffix']));
      }
      Map<String, String> priv = member['privacy'];
      MemberPrivacy privacy = MemberPrivacy(
          priv['description_privacy'] ?? 'unknown',
          priv['visibility'] ?? 'unknown',
          priv['name_privacy'] ?? 'unknown',
          priv['birthday_privacy'] ?? 'unknown',
          priv['pronoun_privacy'] ?? 'unknown',
          priv['avatar_privacy'] ?? 'unknown',
          priv['metadata_privacy'] ?? 'unknown');

      Member mem = Member(
          member['id'],
          member['uuid'],
          member['name'],
          member['display_name'],
          member['color'],
          member['birthday'],
          member['pronouns'],
          member['avatar_url'],
          member['banner'],
          member['description'],
          member['created'],
          proxyTags,
          member['keep_proxy'],
          privacy);
      result[member['id']] = mem;
    }
    return result;
  }

  Future<List<Switches>> _getSwitches(List<Switches> existing, Uri url) async {
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

  Future<List<Switches>> getSwitches(List<Switches> existing,
      {String systemRef = "@me"}) async {
    return _getSwitches(existing,
        Uri.parse("https://api.pluralkit.me/v2/systems/@me/switches"));
  }

  Future<List<Switches>> getMoreSwitches(List<Switches> existing,
      {String systemRef = "@me"}) {
    String st = "https://api.pluralkit.me/v2/systems/@me/switches?before=";

    Switches earliest =
        existing.reduce((a, b) => (a.timestamp.isAfter(b.timestamp)) ? b : a);

    st += earliest.timestamp.toIso8601String();

    log('Earliest Switch: '+st);

    return _getSwitches(existing, Uri.parse(st));
  }

  /* 
  === Unimplemented Methods ===
  AS of V2: https://pluralkit.me/api/endpoints/#switches
  for current state of the applicaiton, there is no need to implement these
  if in the future this is maintained as the official Flutter library => to do

  - System - 
  PATCH  /systems/{sysRef}
  GET    /systems/{sysRef}/settings
  PATCH  /systems/{sysRef}/settings
  GET    /systems/{sysRef}/guilds/{guildID}
  PATCH  /systems/{sysRef}/guilds/{guildID}

  - Members -
  POST   /members
  GET    /members/{memberRef}
  PATCH  /members/{memberRef}
  DELETE /members/{memberRef}
  GET    /members/{memberRef}/groups/add
  POST   /members/{memberRef}/groups/remove
  POST   /members/{memberRef}/groups/overwrite
  GET    /members/{memberRef}/guilds/{guildId}
  PATCH  /members/{memberRef}/guilds/{guildId}

 - Groups -
  GET    /systems/{sysRef}/groups
  POST   /groups
  GET    /groups/{groupRef}
  PATCH  /groups/{groupRef}
  DELETE /groups/{groupRef}
  GET    /groups/{groupRef}/members
  POST   /groups/{groupRef}/add
  POST   /groups/{groupRef}/remove
  POST   /groups/{groupRef}/overwrite

  - Switches -
  GET    /systems/{sysRef}/fronters
  POST   /systems/{sysRef}/switches
  GET    /systems/{sysRef}/switches/{switchRef}
  PATCH  /systems/{sysRef}/switches/{switchRef}
  PATCH  /systems/{sysRef}/switches/{switchRef}/members
  DELETE /systems/{sysRef}/switches/{switchRef}


  */

}
