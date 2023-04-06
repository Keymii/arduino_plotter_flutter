import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'coordinate.dart';
import 'package:charts_flutter/flutter.dart' as charts;

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
      sub = socket.listen(_handleDataReceived,
          onError: _handleConnectionError, onDone: _handleConnectionDone);
      socket.write("connected to phone");
      sub.onData(_handleDataReceived);
    } on SocketException catch (e) {
      print('Error connecting to Arduino: $e');
    }
  }

  void _handleDataReceived(dynamic datarcvd) {
    _receivedData += utf8.decode(datarcvd);
    print("Data received: " + _receivedData);
    // Parse the received data to extract the two parameters
    List<String> parameters = _receivedData.split(',');
    if (parameters.length == 2) {
      _parameter1 = double.tryParse(parameters[0]) ?? 0.0;
      _parameter2 = double.tryParse(parameters[1]) ?? 0.0;
      data.add(Coordinate(_parameter1, _parameter2));
      _receivedData = "";
      scrollController.animateTo(scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100), curve: Curves.ease);
      setState(() {});
    }
  }

  void _handleConnectionError(error, StackTrace trace) {
    print('Connection error: $error');
    socket.close();
  }

  void _handleConnectionDone() {
    print('Connection done.');
    socket.close();
    // _connectToArduino();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Parameter 1: $_parameter1',
            style: TextStyle(fontSize: 20.0),
          ),
          Text(
            'Parameter 2: $_parameter2',
            style: TextStyle(fontSize: 20.0),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: scrollController,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.5,
              width: MediaQuery.of(context).size.width /
                  10 *
                  (data.isEmpty ? 10 : data.length),
              child: charts.LineChart(
                [
                  charts.Series<Coordinate, double>(
                    id: 'Coordinates',
                    domainFn: (Coordinate coord, _) => coord.x,
                    measureFn: (Coordinate coord, _) => coord.y,
                    data: data,
                  )
                ],
                animate: false,
              ),
            ),
          ),
          // Add your live plot widget here
        ],
      ),
    );
  }
}
