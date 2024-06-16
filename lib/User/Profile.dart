import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intro_mobile_project/modules/slotbuilder.dart';

class Profile extends StatelessWidget {
  User? user = FirebaseAuth.instance.currentUser;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    user = FirebaseAuth.instance.currentUser;
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
            title: const Text('Profile'),
          ),
          body: Stack(
            children: <Widget>[
              Image.asset(
                'images/background.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
              Center(
                child: Column(
                  children: [
                    // Profile picture and email with spacing
                    Center(
                        child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        const CircleAvatar(
                          backgroundImage: AssetImage(
                              'images/metalized_logo_play_padel.png'),
                          radius: 50.0,
                        ),
                        const SizedBox(height: 10),
                        Text('${dbuser["display_name"]}'),
                        const SizedBox(height: 10),
                        Text('${user!.email}'),
                      ],
                    )),
                    const SizedBox(height: 20),

                    // Logout button
                    FilledButton(
                      onPressed: () => _logout(context),
                      child: const Text('Logout'),
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.amber),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Matches section
                    Expanded(
                      child: _buildMatches(dbuser),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await _auth.signOut();
      // Clear any additional user data from local storage (if needed)
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/login', (Route route) => false);
    } on FirebaseAuthException catch (e) {
      // Handle logout errors (e.g., show a snackbar)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: ${e.toString()}'),
        ),
      );
    }
  }

  Widget _buildMatchesWithPlace(List<DocumentSnapshot> myMatches) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('places').snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(
            color: Colors.amber,
          );
        }
        final places = snapshot.data!.docs;
        return ListView(
          padding: const EdgeInsets.all(8.0),
          children: myMatches.map((DocumentSnapshot document) {
            final DocumentSnapshot place =
                places.firstWhere((doc) => doc.id == document["place"].id);
            return Card(
              color: const Color.fromARGB(68, 255, 255, 255),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.place,
                      color: Colors.white,
                    ),
                    title: Text(place["placeName"],
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy, HH:mm').format(
                          (document['timeStarted'] as Timestamp).toDate()),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      children: [
                        Slotbuilder.buildPlayersRow(document),
                        Slotbuilder.buildStartButton(document),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMatchesByUserDb(
      List<DocumentSnapshot> matches, DocumentSnapshot dbuser) {
    try {
      List<DocumentSnapshot> myMatches = matches
          .where((doc) => {
                'player0': doc['player0'] == dbuser.reference,
                'player1': doc['player1'] == dbuser.reference,
                'player2': doc['player2'] == dbuser.reference,
                'player3': doc['player3'] == dbuser.reference,
              }.containsValue(true))
          .toList();

      // Filter matches by place and not done
      final DateTime now = DateTime.now();
      myMatches = myMatches.where((DocumentSnapshot snapshot) {
        final DateTime startTime =
            (snapshot['timeStarted'] as Timestamp).toDate();
        final DateTime endTime = startTime.add(const Duration(minutes: 90));
        return endTime.isAfter(now);
      }).toList();

      // Handle no matches case
      if (myMatches.isEmpty) {
        return const Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('You have no matches yet.'),
          ],
        ));
      }

      return _buildMatchesWithPlace(myMatches);
    } catch (e) {
      // Handle errors
      print('Error getting user: $e');
    }
    return const CircularProgressIndicator(
      color: Colors.amber,
    );
  }

  Widget _buildMatches(DocumentSnapshot dbuser) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore.collection('matches').orderBy("timeStarted").snapshots(),
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

        return _buildMatchesByUserDb(documents, dbuser);
      },
    );
  }
}
