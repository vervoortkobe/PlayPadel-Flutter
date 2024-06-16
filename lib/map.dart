import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intro_mobile_project/Matches/PlaceDetail.dart';
import 'package:latlong2/latlong.dart';

class PlaceMap extends StatelessWidget {
  User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MapController _mapController = MapController();

  Widget buildMarkers() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('places').snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(
            color: Colors.amber,
          );
        }

        List<DocumentSnapshot> documents = snapshot.data!.docs;

        return MarkerLayer(
          markers: documents.map((DocumentSnapshot document) {
            return Marker(
              width: 100,
              height: 100,
              point: LatLng(document['placeLocation'].latitude,
                  document['placeLocation'].longitude),
              child: Column(children: [
                Card(
                    child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(document['placeName'],
                            textAlign: TextAlign.center))),
                TextButton(
                  child: Icon(Icons.location_on, color: Colors.red),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PlaceDetail(place: document)),
                  ),
                ),
              ]),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text('Map'),
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          //center: LatLng(51.23016715, 4.4161294643975015), zoom: 14.0),
          initialCameraFit: CameraFit.bounds(
              bounds: LatLngBounds.fromPoints([
            LatLng(50.20087, 4.46214),
            LatLng(52.19827, 4.47352),
          ])),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'dev.fleaflet.flutter_map.example',
          ),
          buildMarkers(),
        ],
      ),
    );
  }
}
