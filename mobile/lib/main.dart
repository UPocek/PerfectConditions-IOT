// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Perfect Conditions',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class Plant {
  String plant_id = '';
  String plant_name = '';
  String plant_type_id = '';
  String plant_type_name = '';
  double light_intesity_need = 0;
  int? soil_moisture_need = 0;
  double? temperature_need = 0;
  double? humidity_need = 0;
  double? pressure_need = 0;
  Plant(this.plant_type_id, this.plant_name);
  Plant.received(
      this.plant_id,
      this.plant_name,
      this.plant_type_id,
      this.plant_type_name,
      this.light_intesity_need,
      this.humidity_need,
      this.pressure_need,
      this.soil_moisture_need,
      this.temperature_need);

  factory Plant.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'plant_id': String plant_id,
        'plant_name': String plant_name,
        'plant_type_id': String plant_type_id,
        'plant_type_name': String plant_type_name,
        'light_intesity_need': double light_intesity_need,
        'humidity_need': double humidity_need,
        'pressure_need': double pressure_need,
        'soil_moisture_need': int soil_moisture_need,
        'temperature_need': double temperature_need,
      } =>
        Plant.received(
            plant_id,
            plant_name,
            plant_type_id,
            plant_type_name,
            light_intesity_need,
            humidity_need,
            pressure_need,
            soil_moisture_need,
            temperature_need),
      _ => throw const FormatException('Failed to load plants.'),
    };
  }
}

Future<List<Plant>> fetchPlants() async {
  final response = await http
      .get(Uri.parse('https://jsonplaceholder.typicode.com/albums/1'));

  if (response.statusCode == 200) {
    return jsonDecode(response.body)
        .map((data) => Plant.fromJson(data as Map<String, dynamic>));
  } else {
    throw Exception('Failed to load plants');
  }
}

class MyAppState extends ChangeNotifier {
  var plants = <Plant>[
    Plant('1', 'Taska'),
    Plant('2', 'Lula'),
    Plant('3', 'Tula'),
    Plant('4', 'Taska'),
    Plant('5', 'Lula'),
  ];
  var typesOfPlants = {
    '1': 'yucca',
    '2': 'cactus',
    '3': 'succulent',
    '4': 'bonsai',
    '5': 'palm'
  };

  Plant? selectedPlant;

  void setPlants(List<Plant>? plants) {
    plants = plants;
    notifyListeners();
  }

  void addPlant(String name, String id) {
    plants.add(Plant(id, name));
    notifyListeners();
  }

  void selectPlant(Plant plant) {
    selectedPlant = plant;
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    Widget page;
    switch (selectedIndex) {
      case 0:
        page = PlantsPage();
      case 1:
        page = StatsPage();
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    var mainArea = ColoredBox(
      color: colorScheme.surfaceVariant,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 200),
        child: page,
      ),
    );

    return Scaffold(
      body: SafeArea(
          child: Column(
        children: [
          Expanded(child: mainArea),
          BottomNavigationBar(
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.yard),
                label: 'Plants',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics),
                label: 'Stats',
              ),
            ],
            currentIndex: selectedIndex,
            onTap: (value) {
              setState(() {
                selectedIndex = value;
              });
            },
          ),
        ],
      )),
      floatingActionButton: SafeArea(
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CreatePlantPage()),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterFloat,
    );
  }
}

class PlantsPage extends StatefulWidget {
  @override
  State<PlantsPage> createState() => _PlantsPageState();
}

class _PlantsPageState extends State<PlantsPage> {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );
    return PlantCards(
      style: style,
    );
  }
}

class PlantCards extends StatelessWidget {
  const PlantCards({
    super.key,
    required this.style,
  });
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    return FutureBuilder(
        future: fetchPlants(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            appState.setPlants(snapshot.data);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(30),
                  child: Text(
                    'You have '
                    '${appState.plants.length} plants:',
                    textScaler: TextScaler.linear(1.5),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: GridView(
                    padding: const EdgeInsets.all(10),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        maxCrossAxisExtent: 300,
                        childAspectRatio: 200 / 250),
                    children: [
                      for (var plant in appState.plants)
                        PlantCard(
                          plant: plant,
                          style: style,
                        )
                    ],
                  ),
                )
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        });
  }
}

class PlantCard extends StatelessWidget {
  const PlantCard({
    super.key,
    required this.plant,
    required this.style,
  });

  final Plant plant;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return GestureDetector(
      onTap: () {
        appState.selectPlant(plant);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PlantPreviewPage()),
        );
      },
      child: Material(
        type: MaterialType.card,
        borderRadius: BorderRadius.all(Radius.circular(16.0)),
        color: Theme.of(context).colorScheme.primary,
        surfaceTintColor: Theme.of(context).colorScheme.primaryContainer,
        shadowColor: Theme.of(context).colorScheme.shadow,
        elevation: 5.0,
        child: Column(
          children: [
            Expanded(
              child: Container(
                height: 150,
                margin: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(16),
                  ),
                  image: DecorationImage(
                      image: Image.asset(
                        "images/${appState.typesOfPlants[plant.plant_type_id]}.jpeg",
                      ).image,
                      fit: BoxFit.cover),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                plant.plant_name,
                style:
                    style.copyWith(fontWeight: FontWeight.normal, fontSize: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var appState = context.watch<MyAppState>();

    return Center(
      child: Text("Stats"),
    );
  }
}

class CreatePlantPage extends StatefulWidget {
  @override
  State<CreatePlantPage> createState() => _CreatePlantPageState();
}

class _CreatePlantPageState extends State<CreatePlantPage> {
  final plantTypeController = TextEditingController();
  final nameController = TextEditingController();
  String? selectedType;
  String? plantName;

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var theme = Theme.of(context);
    var style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onBackground,
    );
    var errorStyle = theme.textTheme.displaySmall!.copyWith(
      color: theme.colorScheme.error,
    );

    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        appBar: AppBar(
          title: const Text('Add New Plant'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(30),
          child: Center(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    "Tell us about your plant",
                    style: style.copyWith(
                        fontWeight: FontWeight.normal, fontSize: 24),
                  ),
                ),
                DropdownMenu(
                  controller: plantTypeController,
                  expandedInsets: EdgeInsets.all(0),
                  requestFocusOnTap: true,
                  label: const Text('Maintenance'),
                  onSelected: (String? type) {
                    setState(() {
                      selectedType = type;
                      print(type);
                    });
                  },
                  dropdownMenuEntries: appState.typesOfPlants.keys
                      .map<DropdownMenuEntry<String>>((String k) {
                    return DropdownMenuEntry(
                      value: k,
                      label: appState.typesOfPlants[k]!,
                      enabled: true,
                    );
                  }).toList(),
                ),
                SizedBox(
                  height: 20,
                ),
                TextField(
                  onChanged: (value) => setState(() {
                    plantName = value;
                  }),
                  controller: nameController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter the name of your plant',
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (selectedType == null ||
                          plantName!.isEmpty ||
                          plantName == null) {
                        showDialog(
                          useRootNavigator: false,
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text("Error"),
                              contentTextStyle: errorStyle,
                              titleTextStyle: errorStyle,
                              backgroundColor: theme.colorScheme.errorContainer,
                              content: Text(
                                "You didn't fill in the required info.",
                              ),
                            );
                          },
                        );
                      } else {
                        appState.addPlant(plantName!, selectedType!);
                        showDialog(
                          useRootNavigator: true,
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              actions: [
                                ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Go back!'))
                              ],
                              title: Text("Success"),
                              content: Text(
                                "You added a new plant!🥳",
                              ),
                            );
                          },
                        );
                      }
                    },
                    icon: Icon(Icons.compost),
                    label: Text('Add'),
                  ),
                )
              ],
            ),
          ),
        ));
  }
}

class PlantPreviewPage extends StatefulWidget {
  @override
  State<PlantPreviewPage> createState() => _PlantPreviewPageState();
}

class _PlantPreviewPageState extends State<PlantPreviewPage> {
  final TextEditingController _controller = TextEditingController();
  final _channel = WebSocketChannel.connect(
    Uri.parse('wss://echo.websocket.events'),
  );

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var theme = Theme.of(context);
    return StreamBuilder(
      stream: _channel.stream,
      builder: (context, snapshot) {
        // appState.selectPlant(snapshot as Plant);
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          appBar: AppBar(),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: Column(
                children: [
                  PlantNotifications(),
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 150,
                      margin: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(16),
                        ),
                        image: DecorationImage(
                            image: Image.asset(
                              "images/${appState.typesOfPlants[appState.selectedPlant?.plant_type_id]}.jpeg",
                            ).image,
                            fit: BoxFit.fitHeight),
                      ),
                    ),
                  ),
                  DataInputs(
                      label: "Name",
                      inputValue: appState.selectedPlant!.plant_name),
                  DataInputs(
                      label: "Type",
                      inputValue: appState.selectedPlant!.plant_type_name),
                  DataInputs(
                      label: "Light Intesity",
                      inputValue: appState.selectedPlant!.light_intesity_need
                          .toString()),
                  DataInputs(
                      label: "Soil Moisture",
                      inputValue: appState.selectedPlant!.soil_moisture_need
                          .toString()),
                  DataInputs(
                      label: "Temperature",
                      inputValue:
                          appState.selectedPlant!.temperature_need.toString()),
                  DataInputs(
                      label: "Humidity",
                      inputValue:
                          appState.selectedPlant!.humidity_need.toString()),
                  DataInputs(
                      label: "Pressure",
                      inputValue: appState.selectedPlant!.soil_moisture_need
                          .toString()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      _channel.sink.add(_controller.text);
    }
  }

  @override
  void dispose() {
    _channel.sink.close();
    _controller.dispose();
    super.dispose();
  }
}

class DataInputs extends StatelessWidget {
  const DataInputs({
    super.key,
    required this.label,
    required this.inputValue,
  });

  final String label;
  final String inputValue;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var styleLabel = theme.textTheme.displaySmall!.copyWith(
        color: theme.colorScheme.onSurface,
        fontSize: 24,
        fontWeight: FontWeight.bold);

    var styleInput = theme.textTheme.displaySmall!.copyWith(
        color: theme.colorScheme.onSurface,
        fontSize: 24,
        fontWeight: FontWeight.normal);

    return Row(
      children: [
        Padding(
            padding: EdgeInsets.all(5),
            child: Text(
              "$label:",
              textAlign: TextAlign.left,
              style: styleLabel,
            )),
        Padding(
            padding: EdgeInsets.all(5),
            child: Text(
              inputValue,
              textAlign: TextAlign.left,
              style: styleInput,
            ))
      ],
    );
  }
}

class PlantNotifications extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _PlantNotifications();
}

class _PlantNotifications extends State<PlantNotifications> {
  var notifications = <String>["Decrease temp"];
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var styleLabel = theme.textTheme.displaySmall!.copyWith(
        color: theme.colorScheme.onSurface,
        fontSize: 24,
        fontWeight: FontWeight.bold);

    return Column(
      children: [
        Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              "Take care of:",
              style: styleLabel,
            )),
        for (var not in notifications)
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            tileColor: theme.colorScheme.primaryContainer,
            leading: IconButton(
              icon: Icon(Icons.check),
              onPressed: () {
                setState(() {
                  notifications.remove(not);
                });
              },
            ),
            title: Text(
              not,
            ),
          ),
      ],
    );
  }
}
