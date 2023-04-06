import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class RealTimePlotWidget extends StatefulWidget {
  final double x;
  final double y;

  RealTimePlotWidget({required this.x, required this.y});

  @override
  _RealTimePlotWidgetState createState() => _RealTimePlotWidgetState();
}

class _RealTimePlotWidgetState extends State<RealTimePlotWidget> {
  late List<charts.Series<Coordinate, double>> _seriesData;
  List<Coordinate> _data = [];
  @override
  void initState() {
    super.initState();
    // _data.add(Coordinate(2.0,2.0));
    // _data.add(Coordinate(3.0,3.0));
    // _data.add(Coordinate(5.0,4.0));


    _seriesData = [
      charts.Series(
        id: 'Coordinates',
        domainFn: (Coordinate coord, _) => coord.x,
        measureFn: (Coordinate coord, _) => coord.y,
        data: _data,
      ),
    ];
  }

  void _addDataPoint(double x, double y) {
    setState(() {
      _data.add(Coordinate(x, y));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.x != null && widget.y != null) {
      _addDataPoint(widget.x, widget.y);
    }
    return charts.LineChart(
      _seriesData,
      animate: false,
    );
  }
}

class Coordinate {
  final double x;
  final double y;

  Coordinate(this.x, this.y);
}
