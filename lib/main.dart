import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'usermodels.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.green,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum appPages { home, front, profile, settings, fidget }

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  appPages _page = appPages.home;
  String? pluralId;
  System? _system;
  PluralKitWrapper pk = PluralKitWrapper('');
  List<Switches> _switch = [];
  Map<String, Member> membersLookup = {};

  @override
  void initState() {
    _getLogin();
    super.initState();
  }

  void updateState() {
    String pid = pluralId ?? '';
    if (pk.client.token != pid) {
      pk = PluralKitWrapper(pid);
    }
    if (_system == null) {
      pk.getSystem().then((x) {
        setState(() {
          _system = x;
        });
      });
    }

    if (_switch.isEmpty) {
      pk.getSwitches(_switch).then((x) {
        if (x.isNotEmpty) {
          setState(() {
            _switch = x;
          });
        }
      });
    }

    if (membersLookup.isEmpty) {
      pk.getMembers(membersLookup).then((x) {
        setState(() {
          membersLookup = x;
        });
      });
    }
  }

  void _getLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      pluralId = prefs.getString("id");
      _counter = prefs.getInt("count") ?? 0;
      updateState();
      _page = appPages.front;
    });
  }

  void _setLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if ((pluralId ?? "").isNotEmpty) {
      await prefs.setString("id", pluralId ?? "");
    }
    await prefs.setInt("count", _counter);
  }

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    Widget mainPage;
    _setLogin();

    switch (_page) {
      case appPages.home:
        {
          mainPage = getLoginPage();
        }
        break;
      case appPages.fidget:
        {
          mainPage = getFidgetPage();
        }
        break;
      case appPages.profile:
        {
          mainPage = getSettingsPage();
        }
        break;
      case appPages.front:
        {
          mainPage = getFrontsPage();
        }
        break;
      default:
        {
          mainPage = Center(
            child: Text("hello ${_system?.name}"),
          );
        }
        break;
    }

    const home = BottomNavigationBarItem(
        icon: Icon(Icons.home), label: 'Home', backgroundColor: Colors.black);

    const frontLog = BottomNavigationBarItem(
        icon: Icon(Icons.switch_account),
        activeIcon: Icon(Icons.ac_unit),
        label: 'Front Log',
        backgroundColor: Colors.black);

    const profiles = BottomNavigationBarItem(
        icon: Icon(Icons.face),
        label: "Profiles",
        backgroundColor: Colors.black);

    const settings = BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: "Settings",
        backgroundColor: Colors.black);

    const fidget = BottomNavigationBarItem(
        icon: Icon(Icons.spa), label: "Fidget", backgroundColor: Colors.black);

    BottomNavigationBar bottomnav = BottomNavigationBar(
      onTap: (i) {
        setState(() {
          _page = appPages.values[i];
        });
      },
      items: _system == null
          ? const [home, fidget]
          : const [home, frontLog, profiles, settings, fidget],
      currentIndex: appPages.values.indexOf(_page),
    );

    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Theme(
        data: ThemeData(primarySwatch: Colors.orange),
        child: Scaffold(
          appBar: AppBar(
            // Here we take the value from the MyHomePage object that was created by
            // the App.build method, and use it to set our appbar title.
            title: Text(widget.title),
          ),
          body: mainPage,
          floatingActionButton: (_page != appPages.fidget)
              ? null
              : FloatingActionButton(
                  onPressed: _incrementCounter,
                  tooltip: 'Increment',
                  child: const Icon(Icons.add),
                ), // This trailing comma makes auto-formatting nicer for build methods.
          bottomNavigationBar: bottomnav,
        ));
  }

  Widget getLoginPage() {
    TextField field = TextField(
      obscureText: true,
      decoration:
          const InputDecoration(border: OutlineInputBorder(), labelText: "id"),
      onSubmitted: fetchValidateKey,
    );

    return Center(
        child: Column(children: [
      field,
    ]));
  }

  Widget getSettingsPage() {
    Widget mainSettings = Row(
      children: (_system != null
          ? [
              (_system?.avatarUrl != 'no'
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(_system?.avatarUrl ?? ''))
                  : const Icon(Icons.face_sharp)),
              const Text("     "),
              Column(
                children: const [
                  Text("name"),
                  Text("description"),
                  Text("color")
                ],
                crossAxisAlignment: CrossAxisAlignment.start,
              ),
              const Text("  "),
              Column(children: [
                Text(_system?.name ?? ""),
                Text(_system?.description ?? ""),
                Text(_system?.color ?? "")
              ]),
              const Spacer(
                flex: 5,
              ),
              const Text("Privacy:    "),
              Column(
                children: const [
                  Text("descriptionPrivacy"),
                  Text("memberListPrivacy"),
                  Text("groupListPrivacy"),
                  Text("frontPrivacy"),
                  Text("frontHistoryPrivacy")
                ],
                crossAxisAlignment: CrossAxisAlignment.start,
              ),
              const Text("  "),
              Column(
                children: [
                  Text(_system?.privacy.descriptionPrivacy ?? ''),
                  Text(_system?.privacy.memberListPrivacy ?? ''),
                  Text(_system?.privacy.groupListPrivacy ?? ''),
                  Text(_system?.privacy.frontPrivacy ?? ''),
                  Text(_system?.privacy.frontHistoryPrivacy ?? '')
                ],
                crossAxisAlignment: CrossAxisAlignment.start,
              ),
              const Spacer()
            ]
          : [
              const Flexible(child: Text("User Not Logged In")),
            ]),
    );

    return Center(
      child: Column(children: [mainSettings, memberSettings()]),
    );
  }

  Widget memberSettings() {
    return Column(
      children: membersLookup.values.map(memberCard).toList(),
    );
  }

  Widget memberCard(Member mem) {
    return Card(
      child: ExpansionTile(
        title: Text(mem.displayName ?? mem.name),
        children: [
              RichText(
                  text: TextSpan(text: mem.name, children: [
                mem.pronouns != null
                    ? TextSpan(
                        text: "(${mem.pronouns})",
                        style: const TextStyle(fontWeight: FontWeight.bold))
                    : const TextSpan()
              ])),
              Text(mem.descripiton ?? ""),
              Text("Created: ${mem.created}"),
              const Text("")
            ] +
            [
              for (var prox in mem.proxyTags)
                Text("Proxy: ${prox.prefix ?? ''}Text${prox.suffix ?? ''}")
            ],
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        expandedAlignment: Alignment.topLeft,
      ),
    );
  }

  Widget getFidgetPage() {
    return Center(
      // Center is a layout widget. It takes a single child and positions it
      // in the middle of the parent.
      child: Column(
        // Column is also a layout widget. It takes a list of children and
        // arranges them vertically. By default, it sizes itself to fit its
        // children horizontally, and tries to be as tall as its parent.
        //
        // Invoke "debug painting" (press "p" in the console, choose the
        // "Toggle Debug Paint" action from the Flutter Inspector in Android
        // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
        // to see the wireframe for each widget.
        //
        // Column has various properties to control how it sizes itself and
        // how it positions its children. Here we use mainAxisAlignment to
        // center the children vertically; the main axis here is the vertical
        // axis because Columns are vertical (the cross axis would be
        // horizontal).
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text(
            'You have pushed the button this many times:',
          ),
          Text(
            '$_counter',
            style: Theme.of(context).textTheme.headline4,
          ),
        ],
      ),
    );
  }

  Widget getFrontsPage() {
    if (_switch.isEmpty) {
      return const Text("No Data Here Yet");
    }
    int offset = 0;
    bool justFlipped = false;

    return CustomScrollView(
      slivers: [
        SliverList(delegate:
            SliverChildBuilderDelegate((BuildContext context, int index) {
          index = index - offset;
          if (_switch.length - index == 1) {
            pk.getMoreSwitches(_switch).then((x) {
              if (x.isNotEmpty) {
                setState(() {
                  _switch = x;
                });
              }
            });
          }
          if (index < _switch.length) {
            if ((_switch[index].timestamp.day !=
                    _switch[(index - 1) % _switch.length].timestamp.day) &
                !justFlipped) {
              justFlipped = true;
              offset++;
              return Text(dateString(_switch[index].timestamp));
            }
            justFlipped = false;
            return getFrontLog(context, index);
          }
          return null;
        }))
      ],
    );
  }

  Widget getFrontLog(BuildContext context, int i) {
    Switches _swit = _switch[i];

    List<Member> fronters = [];
    for (var member in _swit.members) {
      fronters.add(membersLookup[member] ?? defaultMember(member));
    }

    Widget frontersWidget = fronters.isEmpty
        ? const Spacer()
        : Column(children: [
            for (var i = 0; i <= (fronters.length / 3); i++)
              Row(
                children: fronters
                    .getRange(i * 3, min((i + 1) * 3, fronters.length))
                    .map(displayFronter)
                    .toList(),
              )
          ]);

    return Container(
      alignment: Alignment.centerLeft,
      color: Colors.teal[100 * (i % 9)],
      child: Flex(direction: Axis.horizontal, children: [
        Text('${timeString(_swit.timestamp)} - Fronters:'),
        const Text("      "),
        frontersWidget,
        const Spacer(
          flex: 3,
        )
      ]),
    );
  }

  Widget displayFronter(Member e) {
    return Flex(
      direction: Axis.horizontal,
      children: [
        e.avatarUrl == null
            ? CircleAvatar(
                backgroundColor: Colors.brown.shade800,
                child: Text(e.name[0]),
                minRadius: 1.5,
                maxRadius: 10.0,
              )
            : CircleAvatar(
                backgroundImage: NetworkImage(e.avatarUrl ?? ""),
              ),
        Text("  " + (e.displayName ?? e.name) + "  "),
      ],
    );
  }

  void fetchValidateKey(String value) async {
    if (value.length != 64) {
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: const Text('uh oh!'),
              content: Text(
                  'You typed "$value", which has length ${value.characters.length}. we were expecting a token of length X'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                )
              ]);
        },
      );
      return;
    }

    setState(() {
      pluralId = value;
      updateState();
      _page = appPages.front;
    });
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            title: const Text('Thanks!'),
            content: Text(
                'You typed "$value", which has length ${value.characters.length}.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              )
            ]);
      },
    );
  }
}

String dateString(DateTime timestamp) {
  return '${timestamp.year}-${NumberFormat("00").format(timestamp.month)}-${NumberFormat("00").format(timestamp.day)}';
}

String timeString(DateTime timestamp) {
  return '    ${NumberFormat("00").format(timestamp.hour)}:${NumberFormat("00").format(timestamp.minute)}:${NumberFormat("00").format(timestamp.second)}';
}
