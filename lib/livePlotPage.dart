import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'coordinate.dart';
import 'package:syncfusion_flutter_charts/charts.dart' as charts;

class LivePlotPage extends StatefulWidget {
  @override
  _LivePlotPageState createState() => _LivePlotPageState();
}

class _LivePlotPageState extends State<LivePlotPage> {
  late Socket socket;
  late StreamSubscription sub;
  String _receivedData = "";
  double _parameter1 = 0.0;
  double _parameter2 = 0.0;
  List<Coordinate> data = [];

  String ip = '192.168.169.89'; //edit it
  int port = 8000; //edit it
  ScrollController scrollController = ScrollController();

  String arduinoStatus = "Connection Status: disconnected";
  Color arduinoStatusColor = Colors.red;
  bool isConnected = false;
  String machineStatus = "Machine Status: -";
  Color machineStatusColor = Colors.grey;
  double maxThresh = 500;
  double minThresh = 200;
  int graphConc = 30;

  @override
  void initState() {
    super.initState();
    _connectToArduino();
  }

  @override
  void dispose() {
    socket.close();
    super.dispose();
  }

  Future<void> _connectToArduino() async {
    try {
      print("Connecting to Arduino");
      socket = await Socket.connect(ip, port);
      print("Connected to Arduino");
      arduinoStatus = "Connection Status: connected";
      arduinoStatusColor = Colors.green;
      isConnected = true;
      setState(() {});
      sub = socket.listen(_handleDataReceived,
          onError: _handleConnectionError, onDone: _handleConnectionDone);
      socket.write("connected to phone");
      sub.onData(_handleDataReceived);
    } on SocketException catch (e) {
      arduinoStatus = "Connection Status: error";
      arduinoStatusColor = Colors.red;
      machineStatus = "Machine Status: -";
      machineStatusColor = Colors.grey;
      isConnected = false;
      setState(() {});
      print('Error connecting to Arduino: $e');
    }
  }

  void _handleDataReceived(dynamic datarcvd) {
    _receivedData = utf8.decode(datarcvd);
    print("Data received: " + _receivedData);
    arduinoStatus = "Connection Status: connected";
    arduinoStatusColor = Colors.green;
    isConnected = true;
    // Parse the received data to extract the two parameters
    List<String> parameters = _receivedData.split(',');
    if (parameters.length == 2) {
      _parameter1 = double.tryParse(parameters[0]) ?? 0.0;
      _parameter2 = double.tryParse(parameters[1]) ?? 0.0;
      data.add(Coordinate(_parameter1, _parameter2));
      if (_parameter2 >= maxThresh || _parameter2 <= minThresh) {
        machineStatus = "Machine Status: Danger";
        machineStatusColor = Colors.red;
      } else {
        machineStatus = "Machine Status: clear";
        machineStatusColor = Colors.green;
      }
      _receivedData = "";
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
      // duration: const Duration(milliseconds: 100), curve: Curves.ease);
      setState(() {});
    }
  }

  void _handleConnectionError(error, StackTrace trace) {
    arduinoStatus = "Connection Status: error";
    arduinoStatusColor = Colors.red;
    machineStatus = "Machine Status: -";
    machineStatusColor = Colors.grey;
    isConnected = false;
    setState(() {});
    print('Connection error: $error');
    socket.close();
  }

  void _handleConnectionDone() {
    arduinoStatus = "Connection Status: disconnected";
    arduinoStatusColor = Colors.red;
    machineStatus = "Machine Status: -";
    machineStatusColor = Colors.grey;
    isConnected = false;
    setState(() {});
    print('Connection done.');
    socket.close();
    // _connectToArduino();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Plot"),
        actions: [
          IconButton(
            onPressed: isConnected
                ? () {
                    socket.write("power off");
                  }
                : null,
            icon: const Icon(Icons.power_settings_new),
            color: Colors.black,
          ),
          IconButton(
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Are you sure you want to refresh?"),
                    content: Text("All data would be cleared"),
                    actions: [
                      TextButton(
                        onPressed: () {
                          data.clear();
                          machineStatus = "Machine Status: -";
                          machineStatusColor = Colors.grey;
                          setState(() {});
                          Navigator.of(context).pop();
                        },
                        child: Text("Ok"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text("Cancel"),
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(Icons.refresh),
            color: Colors.black,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Text(
              //   'Parameter 1: $_parameter1',
              //   style: TextStyle(fontSize: 20.0),
              // ),
              // Text(
              //   'Parameter 2: $_parameter2',
              //   style: TextStyle(fontSize: 20.0),
              // ),
              Text(
                arduinoStatus,
                style: TextStyle(
                  color: arduinoStatusColor,
                  fontSize: 20.0,
                ),
              ),
              Text(
                machineStatus,
                style: TextStyle(
                  color: machineStatusColor,
                  fontSize: 20.0,
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: scrollController,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.5,
                  width: MediaQuery.of(context).size.width /
                      graphConc *
                      (data.length < graphConc ? graphConc : data.length),
                  child: charts.SfCartesianChart(
                    series: [
                      charts.LineSeries<Coordinate, double>(
                        // id: 'Coordinates',
                        xValueMapper: (Coordinate coord, _) => coord.x,
                        yValueMapper: (Coordinate coord, _) => coord.y,
                        dataSource: data,
                      )
                    ],
                    // animate: false,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: ip,
                      decoration: InputDecoration(
                          hintText: "Server IP", label: Text("Server IP")),
                      onChanged: (value) => ip = value,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      initialValue: port.toString(),
                      decoration: InputDecoration(
                          hintText: "Server port", label: Text("Server port")),
                      onChanged: (value) => port = int.tryParse(value) ?? 8000,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      onPressed: _connectToArduino,
                      child: const Text(
                        "Reconnect to Arduino",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      initialValue: minThresh.toString(),
                      decoration: const InputDecoration(
                          hintText: "Min value", label: Text("Min value")),
                      onChanged: (value) =>
                          minThresh = double.tryParse(value) ?? minThresh,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      initialValue: maxThresh.toString(),
                      decoration: const InputDecoration(
                          hintText: "Max Value", label: Text("Max value")),
                      onChanged: (value) =>
                          maxThresh = double.tryParse(value) ?? maxThresh,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
