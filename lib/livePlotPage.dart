import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import './plot.dart';

class LivePlotPage extends StatefulWidget {
  @override
  _LivePlotPageState createState() => _LivePlotPageState();
}

class _LivePlotPageState extends State<LivePlotPage> {
  Socket? socket;
  String _receivedData = "";
  double _parameter1 = 0.0;
  double _parameter2 = 0.0;

  String ip = '192.168.1.104'; //edit it
  int port=80; //edit it

  @override
  void initState() {
    super.initState();
    _connectToArduino();
  }

  @override
  void dispose() {
    socket?.close();
    super.dispose();
  }

  Future<void> _connectToArduino() async {
    try {
      socket = await Socket.connect(ip, port);
      socket?.listen(_handleDataReceived,
          onError: _handleConnectionError, onDone: _handleConnectionDone);
    } on SocketException catch (e) {
      print('Error connecting to Arduino: $e');
    }
  }

  void _handleDataReceived(List<int> data) {
    setState(() {
      _receivedData += utf8.decode(data);
      // Parse the received data to extract the two parameters
      List<String> parameters = _receivedData.split(',');
      if (parameters.length == 2) {
        _parameter1 = double.tryParse(parameters[0]) ?? 0.0;
        _parameter2 = double.tryParse(parameters[1]) ?? 0.0;
        _receivedData = "";
      }
    });
  }

  void _handleConnectionError(error, StackTrace trace) {
    print('Connection error: $error');
    socket?.close();
  }

  void _handleConnectionDone() {
    print('Connection done.');
    socket?.close();
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
          SizedBox(
              height:  MediaQuery.of(context).size.height*0.5,
              width: double.infinity,
              child: RealTimePlotWidget(x: _parameter1, y: _parameter2)),
          // Add your live plot widget here
        ],
      ),
    );
  }
}
