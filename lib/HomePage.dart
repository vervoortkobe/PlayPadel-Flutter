import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intro_mobile_project/Matches/PlaceDetail.dart';
import 'package:intro_mobile_project/User/Profile.dart';
import 'package:intro_mobile_project/map.dart';

class HomePageController extends StatefulWidget {
  const HomePageController({super.key});

  @override
  State<HomePageController> createState() => HomePage();
}

class HomePage extends State<HomePageController> {
  User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void goToPlaceDetail(BuildContext context, DocumentSnapshot document) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PlaceDetail(place: document)),
    );
  }

  Widget _buildPlaces() {
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

        final List<DocumentSnapshot> documents = snapshot.data!.docs;
        return ListView(
          padding: const EdgeInsets.all(8.0),
          children: documents.map((DocumentSnapshot document) {
            return Card(
              color: const Color.fromARGB(68, 255, 255, 255),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.place, color: Colors.white),
                    subtitle: Text(
                      document['placeLocationString'],
                      style: const TextStyle(color: Colors.white),
                    ),
                    title: Text(
                      document['placeName'],
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: FilledButton(
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.amber),
                        ),
                        onPressed: () => goToPlaceDetail(context, document),
                        child: const Text('View matches')),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget home(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(user!.uid).snapshots(),
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator(
              color: Colors.amber,
            );
          }

          final users = snapshot.data;
          final DocumentSnapshot dbuser = users!;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Home Page'),
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
                      child: Text(
                        'Welcome, ${dbuser["display_name"]}!',
                        style: const TextStyle(
                          fontSize: 20.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    Expanded(
                      child: _buildPlaces(),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
  }

  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: Colors.amber,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.map),
            icon: Icon(Icons.map_outlined),
            label: 'Map',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.person),
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
      body: <Widget>[
        home(context),
        PlaceMap(),
        Profile(),
      ][currentPageIndex],
    );
  }
}
