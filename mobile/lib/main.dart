// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

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
  double light_intensity_need = 0;
  int? soil_moisture_need = 0;
  double? temperature_need = 0;
  double? humidity_need = 0;
  double? pressure_need = 0;
  double current_heat_index = 0;
  double? current_humidity = 0;
  double? current_lux = 0;
  double? current_moisture = 0;
  double? current_pressure = 0;
  double? current_temperature = 0;
  Plant(this.plant_type_id, this.plant_name);
  Plant.received(
    this.plant_id,
    this.plant_name,
    this.plant_type_id,
    this.plant_type_name,
    this.light_intensity_need,
    this.humidity_need,
    this.pressure_need,
    this.soil_moisture_need,
    this.temperature_need,
    this.current_heat_index,
    this.current_humidity,
    this.current_lux,
    this.current_moisture,
    this.current_pressure,
    this.current_temperature,
  );

  factory Plant.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'plant_id': String plant_id,
        'plant_name': String plant_name,
        'plant_type_id': String plant_type_id,
        'plant_type_name': String plant_type_name,
        'light_intensity_need': double light_intensity_need,
        'soil_moisture_need': int soil_moisture_need,
        'temperature_need': double temperature_need,
        'humidity_need': double humidity_need,
        'pressure_need': double pressure_need,
        'current_heat_index': double current_heat_index,
        'current_humidity': double current_humidity,
        'current_lux': double current_lux,
        'current_moisture': double current_moisture,
        'current_pressure': double current_pressure,
        'current_temperature': double current_temperature,
      } =>
        Plant.received(
            plant_id,
            plant_name,
            plant_type_id,
            plant_type_name,
            light_intensity_need,
            humidity_need,
            pressure_need,
            soil_moisture_need,
            temperature_need,
            current_heat_index,
            current_humidity,
            current_lux,
            current_moisture,
            current_pressure,
            current_temperature),
      _ => throw const FormatException('Failed to load plants.'),
    };
  }

  Map<String, dynamic> toJson() => {
        'plant_type_id': plant_type_id,
        'plant_name': plant_name,
      };
}

class PlantType {
  String id;
  String type_name;
  PlantType(this.id, this.type_name);

  factory PlantType.fromJson(Map<dynamic, dynamic> json) {
    return switch (json) {
      {
        'type_id': String id,
        'type_name': String type_name,
      } =>
        PlantType(
          id,
          type_name,
        ),
      _ => throw const FormatException('Failed to load plants.'),
    };
  }
}

Future<dynamic> fetchPlants() async {
  final response =
      await http.get(Uri.parse('http://127.0.0.1:8000/api/all_plants'));

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to load plants');
  }
}

Future<dynamic> fetchPlantTypes() async {
  final response =
      await http.get(Uri.parse('http://127.0.0.1:8000/api/all_types_basic'));

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to load plants');
  }
}

Future<dynamic> fetchHistory(
    String readingName, String period, int precision) async {
  final response = await http.get(Uri.parse(
      'http://127.0.0.1:8000/api/history/${readingName}/${period}/${precision.toString()}'));

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to load plants');
  }
}

class MyAppState extends ChangeNotifier {
  var plants = <Plant>[];
  var typesOfPlants = [];

  Plant? selectedPlant;

  void setPlants() async {
    var temp = await fetchPlants();
    plants = temp
        .map<Plant>((data) => Plant.fromJson(data as Map<String, dynamic>))
        .toList();
  }

  void setTypes() async {
    var temp = await fetchPlantTypes();
    typesOfPlants = temp
        .map<PlantType>(
            (data) => PlantType.fromJson(data as Map<dynamic, dynamic>))
        .toList();
  }

  Future<void> addPlant(String name, String id) async {
    final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/new_plant'),
        body: json.encode(Plant(id, name)));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load plants');
    }
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MyAppState>().setPlants();
      context.read<MyAppState>().setTypes();
    });
  }

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
          if (snapshot.hasData || appState.plants.length != null) {
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
                        "images/${plant.plant_type_name.toLowerCase()}.jpeg",
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

class DataPoint {
  double value;
  String time;
  DataPoint(this.value, this.time);

  factory DataPoint.fromJson(Map<dynamic, dynamic> json) {
    return switch (json) {
      {
        'value': double value,
        'time': String time,
      } =>
        DataPoint(
          value,
          time,
        ),
      _ => throw const FormatException('Failed to load data.'),
    };
  }
}

class StatsPage extends StatefulWidget {
  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  var luxPoints = <DataPoint>[];
  var moisturePoints = <DataPoint>[];
  var temperaturePoints = <DataPoint>[];
  var humidityPoints = <DataPoint>[];
  var pressurePoints = <DataPoint>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setDataPoints();
    });
  }

  void setDataPoints() async {
    var temp1 = await fetchHistory('lux', '30d', 6000);
    var temp2 = await fetchHistory('moisture', '30d', 6000);
    var temp3 = await fetchHistory('temperature', '30d', 6000);
    var temp4 = await fetchHistory('humidity', '30d', 6000);
    var temp5 = await fetchHistory('pressure', '30d', 6000);

    setState(() {
      luxPoints = temp1
          .map<DataPoint>(
              (data) => DataPoint.fromJson(data as Map<String, dynamic>))
          .toList();
    });
    setState(() {
      moisturePoints = temp2
          .map<DataPoint>(
              (data) => DataPoint.fromJson(data as Map<String, dynamic>))
          .toList();
    });
    setState(() {
      temperaturePoints = temp3
          .map<DataPoint>(
              (data) => DataPoint.fromJson(data as Map<String, dynamic>))
          .toList();
    });
    setState(() {
      humidityPoints = temp4
          .map<DataPoint>(
              (data) => DataPoint.fromJson(data as Map<String, dynamic>))
          .toList();
    });
    setState(() {
      pressurePoints = temp5
          .map<DataPoint>(
              (data) => DataPoint.fromJson(data as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var appState = context.watch<MyAppState>();

    return Scaffold(
        body: luxPoints != []
            ? SingleChildScrollView(
                child: Container(
                    child: Column(
                children: [
                  SizedBox(
                      child: SfCartesianChart(
                          palette: const <Color>[
                            Color.fromRGBO(226, 167, 16, 1)
                          ],
                          title: ChartTitle(text: "Lux history"),
                          // Initialize category axis
                          primaryXAxis: CategoryAxis(),
                          primaryYAxis: NumericAxis(maximum: 2000),
                          legend: Legend(isVisible: true),
                          series: <LineSeries<DataPoint, String>>[
                            LineSeries<DataPoint, String>(
                                // Bind data source
                                dataSource: luxPoints,
                                dataLabelSettings:
                                    DataLabelSettings(isVisible: true),
                                xValueMapper: (DataPoint point, _) =>
                                    point.time.split('T')[0],
                                yValueMapper: (DataPoint point, _) =>
                                    point.value)
                          ])),
                  SizedBox(
                      child: SfCartesianChart(
                          title: ChartTitle(text: "Moisture history"),
                          // Initialize category axis
                          primaryXAxis: CategoryAxis(),
                          primaryYAxis: NumericAxis(maximum: 100),
                          legend: Legend(isVisible: true),
                          series: <LineSeries<DataPoint, String>>[
                        LineSeries<DataPoint, String>(
                            // Bind data source
                            dataSource: moisturePoints,
                            dataLabelSettings:
                                DataLabelSettings(isVisible: true),
                            xValueMapper: (DataPoint point, _) =>
                                point.time.split('T')[0],
                            yValueMapper: (DataPoint point, _) => point.value)
                      ])),
                  SizedBox(
                      child: SfCartesianChart(
                          title: ChartTitle(text: "Temperature history"),
                          palette: const <Color>[
                            Color.fromRGBO(226, 16, 222, 1)
                          ],
                          primaryXAxis: CategoryAxis(),
                          primaryYAxis: NumericAxis(maximum: 40),
                          legend: Legend(isVisible: true),
                          series: <LineSeries<DataPoint, String>>[
                            LineSeries<DataPoint, String>(
                                // Bind data source
                                dataSource: temperaturePoints,
                                dataLabelSettings:
                                    DataLabelSettings(isVisible: true),
                                xValueMapper: (DataPoint point, _) =>
                                    point.time.split('T')[0],
                                yValueMapper: (DataPoint point, _) =>
                                    point.value)
                          ])),
                  SizedBox(
                      child: SfCartesianChart(
                          title: ChartTitle(text: "Humidity history"),
                          palette: const <Color>[
                            Color.fromRGBO(51, 226, 16, 1)
                          ],
                          primaryXAxis: CategoryAxis(),
                          primaryYAxis: NumericAxis(maximum: 100),
                          legend: Legend(isVisible: true),
                          series: <LineSeries<DataPoint, String>>[
                            LineSeries<DataPoint, String>(
                                // Bind data source
                                dataSource: humidityPoints,
                                dataLabelSettings:
                                    DataLabelSettings(isVisible: true),
                                xValueMapper: (DataPoint point, _) =>
                                    point.time.split('T')[0],
                                yValueMapper: (DataPoint point, _) =>
                                    point.value)
                          ])),
                  SizedBox(
                      child: SfCartesianChart(
                          title: ChartTitle(text: "Pressure history"),
                          palette: const <Color>[
                            Color.fromRGBO(226, 16, 76, 1)
                          ],
                          primaryXAxis: CategoryAxis(),
                          primaryYAxis: NumericAxis(maximum: 1100),
                          legend: Legend(isVisible: true),
                          series: <LineSeries<DataPoint, String>>[
                            LineSeries<DataPoint, String>(
                                // Bind data source
                                dataSource: pressurePoints,
                                dataLabelSettings:
                                    DataLabelSettings(isVisible: true),
                                xValueMapper: (DataPoint point, _) =>
                                    point.time.split('T')[0],
                                yValueMapper: (DataPoint point, _) =>
                                    point.value)
                          ])),
                ],
              )))
            : const Center(child: CircularProgressIndicator()));
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
                DropdownMenu<PlantType>(
                  controller: plantTypeController,
                  expandedInsets: EdgeInsets.all(0),
                  requestFocusOnTap: true,
                  label: const Text('Maintenance'),
                  onSelected: (PlantType? type) {
                    setState(() {
                      selectedType = type?.id;
                    });
                  },
                  dropdownMenuEntries: appState.typesOfPlants
                      .toList()
                      .map<DropdownMenuEntry<PlantType>>((type) {
                    return DropdownMenuEntry<PlantType>(
                      value: type,
                      label: type.type_name,
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
    Uri.parse('ws://127.0.0.1:8000/ws'),
  );

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var theme = Theme.of(context);
    return StreamBuilder(
        stream: _channel.stream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Scaffold(
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              appBar: AppBar(),
              body: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Column(
                    children: [
                      PlantNotifications(
                        data: jsonDecode(snapshot.data),
                        plant: appState.selectedPlant!,
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 250,
                          margin: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(16),
                            ),
                            image: DecorationImage(
                                image: Image.asset(
                                  "images/${appState.selectedPlant?.plant_type_name.toLowerCase()}.jpeg",
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
                          inputValue: snapshot.hasData
                              ? jsonDecode(snapshot.data)['lux'].toString()
                              : appState.selectedPlant!.light_intensity_need
                                  .toString()),
                      DataInputs(
                          label: "Soil Moisture",
                          inputValue: snapshot.hasData
                              ? jsonDecode(snapshot.data)['moisture'].toString()
                              : appState.selectedPlant!.soil_moisture_need
                                  .toString()),
                      DataInputs(
                          label: "Temperature",
                          inputValue: snapshot.hasData
                              ? jsonDecode(snapshot.data)['temperature']
                                  .toString()
                              : appState.selectedPlant!.temperature_need
                                  .toString()),
                      DataInputs(
                          label: "Humidity",
                          inputValue: snapshot.hasData
                              ? jsonDecode(snapshot.data)['humidity'].toString()
                              : appState.selectedPlant!.humidity_need
                                  .toString()),
                      DataInputs(
                          label: "Pressure",
                          inputValue: snapshot.hasData
                              ? jsonDecode(snapshot.data)['pressure'].toString()
                              : appState.selectedPlant!.pressure_need
                                  .toString()),
                    ],
                  ),
                ),
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        });
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
  const PlantNotifications({
    super.key,
    required this.data,
    required this.plant,
  });
  final Map<String, dynamic> data;
  final Plant plant;

  @override
  State<StatefulWidget> createState() => _PlantNotifications();
}

class _PlantNotifications extends State<PlantNotifications> {
  var notifications = {};
  var disabled = [];

  void setNotifications() {
    var newNotifications = {};
    if (!disabled.contains("humidity") &&
        widget.plant.humidity_need! > widget.data['humidity']) {
      newNotifications['humidity'] =
          "Lower humidity. Suggested rate is at ${widget.plant.humidity_need}";
    }
    if (!disabled.contains("humidity") &&
        widget.plant.humidity_need! < widget.data['humidity']) {
      newNotifications['humidity'] =
          "Raise humidity. Suggested rate is at ${widget.plant.humidity_need}";
    }

    if (!disabled.contains("lux") &&
        widget.plant.light_intensity_need > widget.data['lux']) {
      newNotifications['lux'] =
          "Lower light intensity. Suggested rate is at ${widget.plant.light_intensity_need}";
    }
    if (!disabled.contains("lux") &&
        widget.plant.light_intensity_need < widget.data['lux']) {
      newNotifications['lux'] =
          "Raise light intensity. Suggested rate is at ${widget.plant.light_intensity_need}";
    }

    if (!disabled.contains("pressure") &&
        widget.plant.pressure_need! > widget.data['pressure']) {
      newNotifications['pressure'] =
          "Lower pressure. Suggested rate is at ${widget.plant.pressure_need}";
    }
    if (!disabled.contains("pressure") &&
        widget.plant.pressure_need! < widget.data['pressure']) {
      newNotifications['pressure'] =
          "Raise pressure. Suggested rate is at ${widget.plant.pressure_need}";
    }

    if (!disabled.contains("moisture") &&
        widget.plant.soil_moisture_need! > widget.data['moisture']) {
      newNotifications['moisture'] =
          "Lower moisture. Suggested rate is at ${widget.plant.soil_moisture_need}";
    }
    if (!disabled.contains("moisture") &&
        widget.plant.soil_moisture_need! < widget.data['moisture']) {
      newNotifications['moisture'] =
          "Raise moisture. Suggested rate is at ${widget.plant.soil_moisture_need}";
    }

    if (!disabled.contains("temperature") &&
        widget.plant.temperature_need! > widget.data['temperature']) {
      newNotifications['temperature'] =
          "Lower temperature. Suggested rate is at ${widget.plant.temperature_need}";
    }
    if (!disabled.contains("temperature") &&
        widget.plant.temperature_need! < widget.data['temperature']) {
      newNotifications['temperature'] =
          "Raise temperature. Suggested rate is at ${widget.plant.temperature_need}";
    }

    setState(() {
      notifications = newNotifications;
    });
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var styleLabel = theme.textTheme.displaySmall!.copyWith(
        color: theme.colorScheme.onSurface,
        fontSize: 24,
        fontWeight: FontWeight.bold);

    setNotifications();
    return Column(
      children: [
        Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              "Take care of:",
              style: styleLabel,
            )),
        for (var k in notifications.keys)
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            tileColor: theme.colorScheme.primaryContainer,
            leading: IconButton(
              icon: Icon(Icons.check),
              onPressed: () {
                setState(() {
                  disabled.add(k);
                });
              },
            ),
            title: Text(
              notifications[k],
            ),
          ),
      ],
    );
  }
}
