import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_map_polyline_point/flutter_polyline_point.dart';
import 'package:flutter_google_map_polyline_point/point_lat_lng.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'constants.dart';

import 'package:location/location.dart';

class CabTrack extends StatefulWidget {
  const CabTrack({super.key});

  @override
  State<CabTrack> createState() => _CabTrackState();
}

class _CabTrackState extends State<CabTrack> {
  List<LatLng> polylineCoordinates = [];
  LocationData? currentLocation;

  late GoogleMapController mapController;

  LatLng cabLocation = const LatLng(33.692993, 73.028469);

  static const LatLng sourceLocation = LatLng(33.692993, 73.028469);

  int carIndex = 0;

  static const LatLng destination =
      LatLng(33.687766, 73.043709); // Initial car position

  BitmapDescriptor destinationIcon = BitmapDescriptor.defaultMarkerWithHue(90);

  BitmapDescriptor cabLocationIcon = BitmapDescriptor.defaultMarkerWithHue(150);

  void getCurrentLocation() async {
    Location location = Location();

    location.getLocation().then((location) {
      currentLocation = location;

      setState(() {});
    });
  }

  void setCustomMarkerIcon() async{
   cabLocationIcon = await BitmapDescriptor.fromAssetImage(const ImageConfiguration(size: Size(13,13)), 'assets/icons/sedan.png');
  }

  void getPolyLines() async {
    var polyLinePoints = PolylinePoints();
    var result = await polyLinePoints.getRouteBetweenCoordinates(
        Constants.googleMapKey,
        PointLatLng(sourceLocation.latitude, sourceLocation.longitude),
        PointLatLng(destination.latitude, destination.longitude));

    if (result.points.isNotEmpty && result.status == 'OK') {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: currentLocation == null
            ? const Center(child: Text('Loading..'))
            : GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                      currentLocation!.latitude!, currentLocation!.longitude!),
                  zoom: 13.0,
                ),
                markers: {

                  Marker(
                    markerId: const MarkerId("cabLocation"),
                    icon:cabLocationIcon,
                    position: cabLocation,
                  ),

                  Marker(
                    markerId: const MarkerId("destination"),
                    icon: destinationIcon,
                    position: destination,
                  )
                },
                onMapCreated: (controller) {
                  mapController = controller;
                  startCarMovement();
                },


                polylines: {
                  Polyline(
                    polylineId: const PolylineId('uber_car_moving_demo'),
                    points: polylineCoordinates,
                    color: Colors.blue,
                    width: 5,
                  ),
                },
              ));
  }

  @override
  void initState() {
    getCurrentLocation();
    getPolyLines();

    setCustomMarkerIcon();
    super.initState();
  }


  void startCarMovement(){
    //Simulate car movement with a timer

    Timer.periodic(const Duration(seconds: 3), (Timer timer){

      if(carIndex <polylineCoordinates.length-1){
        //update the car position along the polyline
        setState(() {
          cabLocation = polylineCoordinates[carIndex];
          carIndex++;
        });
        mapController.animateCamera(CameraUpdate.newLatLng(cabLocation));
      }
      else{
        timer.cancel(); //stop the timer when end of polyline is reached.
      }


    });
  }
}
