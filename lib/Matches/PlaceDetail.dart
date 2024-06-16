import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intro_mobile_project/Matches/bookmatch.dart';
import 'package:intro_mobile_project/modules/slotbuilder.dart';

class PlaceDetail extends StatelessWidget {
  final DocumentSnapshot<Object?> place;

  PlaceDetail({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(place["placeName"]),
      ),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Image.asset(
              'images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: FilledButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => BookMatch(place: place)),
                    );
                  },
                  style: ButtonStyle(
                    minimumSize: MaterialStateProperty.all(
                        const Size(200.0, 50.0)), // Adjust size as desired
                    backgroundColor: MaterialStateProperty.all(Colors.amber),
                  ),
                  child: const Text(
                    'Book a match now',
                    style: TextStyle(
                        fontSize: 18.0), // Adjust font size as desired
                  ),
                ),
              ),
              const Divider(
                color: Colors.amber, // Change this to your desired color
                thickness: 1, // Adjust thickness as needed
                height:
                    20, // Controls the vertical space occupied by the divider
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Available Matches',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 18.0), // Adjust font size as needed
                ),
              ),
              Expanded(child: Slotbuilder.buildMatches(context, place)),
            ],
          ),
        ],
      ),
    );
  }
}
