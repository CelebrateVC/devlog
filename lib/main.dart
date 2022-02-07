import 'package:flutter/material.dart';
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
  RateLimitClient client = RateLimitClient();
  List<Switches> _switch = [];
  Map<String, String> membersLookup = {};

  @override
  void initState() {
    _getLogin();
    super.initState();
  }

  void updateState() {
    client.token = pluralId ?? '';
    systemFromToken(client).then((x) {
      setState(() {
        _system = x;
      });
    });
    getSwitches(client, _switch).then((x) {
      if (x.isNotEmpty) {
        setState(() {
          _switch = x;
        });
      }
    });
    getMembers(client, membersLookup).then((x) {
      setState(() {
        membersLookup = x;
      });
    });
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
    // TODO: Nest Members also
    return Center(
      child: Flex(
        direction: Axis.horizontal,
        children: (_system != null
            ? [
                Flexible(
                    child: _system?.avatarUrl != 'no'
                        ? Image.network(_system?.avatarUrl ?? '')
                        : const Icon(Icons.face_sharp)),
                Column(children: [
                  Text("name " + (_system?.name ?? "")),
                  Text("description " + (_system?.description ?? "")),
                  Text("avatarUrl " + (_system?.avatarUrl ?? "")),
                  Text("color " + (_system?.color ?? "")),
                  Text("privacy.descriptionPrivacy " +
                      (_system?.privacy.descriptionPrivacy ?? '')),
                  Text("privacy.memberListPrivacy " +
                      (_system?.privacy.memberListPrivacy ?? '')),
                  Text("privacy.groupListPrivacy " +
                      (_system?.privacy.groupListPrivacy ?? '')),
                  Text("privacy.frontPrivacy " +
                      (_system?.privacy.frontPrivacy ?? '')),
                  Text("privacy.frontHistoryPrivacy " +
                      (_system?.privacy.frontHistoryPrivacy ?? '')),
                ])
              ]
            : [
                const Flexible(child: Text("User Not Logged In")),
              ]),
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

    return CustomScrollView(
      slivers: [
        SliverList(delegate:
            SliverChildBuilderDelegate((BuildContext context, int index) {
          if (_switch.length - index == 1) {
            getMoreSwitches(client, _switch).then((x) {
              if (x.isNotEmpty) {
                setState(() {
                  _switch = x;
                });
              }
            });
          }
          if (index < _switch.length) {
            return getFrontLog(context, index);
          }
        }))
      ],
    );
  }

  Widget getFrontLog(BuildContext context, int i) {
    // TODO: PFP of the fronter

    print(i);
    print(membersLookup);
    Switches _swit = _switch[i];

    List<String> fronters = [];
    for (var member in _swit.members) {
      fronters.add(membersLookup[member] ?? "Unknown Member");
    }

    return Container(
      alignment: Alignment.centerLeft,
      color: Colors.teal[100 * (i % 9)],
      child: Text('${_swit.timestamp} - Fronters: $fronters'),
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
