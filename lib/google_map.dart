import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Completer<GoogleMapController> _controller = Completer();
  static const CameraPosition _kGoogle = CameraPosition(
    target: LatLng(12.9822, 80.1639),
    zoom: 14,
  );

  Polyline _polyline = Polyline(
    polylineId: PolylineId('route'),
    color: Colors.green,
    points: [],
  );

  List<LatLng> latLen = [];

  LatLng currentLocation = LatLng(0, 0);

  GoogleMapController? mapController;

  @override
  void initState() {
    super.initState();
    getRouteDirections();
  }

  void getRouteDirections() async {
    try {
      var response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json?origin=12.923532200546905,80.12114351882244&destination=12.844851255513841,80.06168993118087&key=AIzaSyAXl2s7Nsv3uAczGYOeZvXiELPgqe8FLcc',
        ),
      );

      var directions = jsonDecode(response.body);
      var routes = directions['routes'];

      if (routes.isNotEmpty) {
        var legs = routes[0]['legs'];

        if (legs.isNotEmpty) {
          var steps = legs[0]['steps'];

          for (var step in steps) {
            var polyline = step['polyline'];
            var points = polyline['points'];

            List<LatLng> decodedPoints = PolylinePoints()
                .decodePolyline(points)
                .map((point) => LatLng(point.latitude, point.longitude))
                .toList();
            latLen.addAll(decodedPoints);
          }

          updatePolyline();
        } else {
          print('Legs array is empty.');
        }
      } else {
        print('Routes array is empty.');
      }
    } catch (error) {
      print("Request failed: $error");
    }
  }

  void updatePolyline() {
    int index = 0;
    for (int i = 0; i < latLen.length; i++) {
      if (latLen[i].latitude > currentLocation.latitude) {
        index = i;
        break;
      }
    }
    List<LatLng> remainingPoints = latLen.sublist(index);

    setState(() {
      _polyline = Polyline(
        polylineId: PolylineId('route'),
        width: 5,
        color: Colors.green,
        points: remainingPoints,
      );
    });
  }

  void onLocationChanged(LatLng newLocation) {
    setState(() {
      currentLocation = newLocation;
    });
    updatePolyline();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        title: Text("Driving Mode"),
      ),
      body: GoogleMap(
        initialCameraPosition: _kGoogle,
        mapType: MapType.normal,
        polylines: {_polyline},
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
          mapController = controller;
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
