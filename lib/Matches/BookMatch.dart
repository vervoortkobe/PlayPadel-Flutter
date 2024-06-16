import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // for date formatting

class BookMatch extends StatefulWidget {
  final DocumentSnapshot<Object?> place;

  BookMatch({required this.place});

  @override
  _BookMatch createState() => _BookMatch(place: place);
}

class _BookMatch extends State<BookMatch> {
  User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DocumentSnapshot<Object?> place;

  DateTime selectedDate = DateTime.now();
  TimeOfDay? startTime;

  _BookMatch({required this.place});

  final List<TimeOfDay> availableTimes = [];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2025),
    );
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
        startTime = null; // Reset the start time when date changes
      });
    }
  }

  Widget getTimes() {
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

          // Filter matches by place
          documents = documents
              .where((DocumentSnapshot snapshot) =>
                  snapshot.id.toString().trim() == place.reference.id)
              .toList();

          DocumentSnapshot placedoc = documents.first;

          DateTime openingHour = DateTime.fromMicrosecondsSinceEpoch(
              (placedoc['openingHour'] as Timestamp).microsecondsSinceEpoch);
          DateTime closingHour = DateTime.fromMicrosecondsSinceEpoch(
              (placedoc['closingHour'] as Timestamp).microsecondsSinceEpoch);

          int time = closingHour.hour - openingHour.hour;

          availableTimes.clear();

          for (int i = 0; i < time; i += 2) {
            TimeOfDay timeOfDay =
                TimeOfDay(hour: openingHour.hour + i, minute: 0);
            DateTime fullDateTime = DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              timeOfDay.hour,
              timeOfDay.minute,
            );
            if (fullDateTime.isAfter(DateTime.now())) {
              availableTimes.add(timeOfDay);
            }
          }

          // Get booked times
          return StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('matches')
                  .where('place', isEqualTo: place.reference)
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> matchSnapshot) {
                if (matchSnapshot.hasError) {
                  return Text('Error: ${matchSnapshot.error}');
                }

                if (matchSnapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator(
                    color: Colors.amber,
                  );
                }

                List<DocumentSnapshot> matchDocuments =
                    matchSnapshot.data!.docs;

                Set<DateTime> bookedTimes = matchDocuments.map((doc) {
                  DateTime timeStarted =
                      (doc['timeStarted'] as Timestamp).toDate();
                  return timeStarted;
                }).toSet();

                List<TimeOfDay> filteredTimes = availableTimes
                    .where((time) => !bookedTimes.contains(DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        time.hour,
                        time.minute)))
                    .toList();

                return SizedBox(
                  width: 250,
                  child: Card(
                    color: const Color.fromARGB(68, 255, 255, 255),
                    elevation: 3.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    margin: const EdgeInsets.all(16.0),
                    child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: buildTimesColumn(filteredTimes)),
                  ),
                );
              });
        });
  }

  Widget buildTimesColumn(List<TimeOfDay> filteredTimes) {
    if (filteredTimes.length > 0) {
      return Column(
          children: filteredTimes
              .map((time) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextButton(
                      onPressed: () => setState(() => startTime = time),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: startTime == time
                            ? Colors.amber[700]
                            : Colors.grey[300],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        textStyle: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(
                          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'),
                    ),
                  ))
              .toList());
    } else {
      return const Text(
          "Sorry but there are no matches available for this day.",
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center);
    }
  }

  Future<void> bookMatch() async {
    if (startTime == null) {
      showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Select Time'),
          content: const Text("Please select a time for your match."),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Convert selectedDate and startTime to DateTime
    final DateTime startDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      startTime!.hour,
      startTime!.minute,
    );

    // Add the match details to the Firestore database
    try {
      // Get the current user
      final collection = _firestore.collection('users').doc(user!.uid);

      final users = await collection.get();

      DocumentSnapshot dbuser = users;
      await FirebaseFirestore.instance.collection('matches').add({
        'place': place.reference,
        'player0': dbuser.reference,
        'player1': null,
        'player2': null,
        'player3': null,
        'started': false,
        'teamWon': 0,
        'timeStarted': Timestamp.fromDate(startDateTime),
      });

      showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Match booked!'),
          content: const Text("Your match has been booked successfully."),
          actions: <Widget>[
            TextButton(
              onPressed: () => {
                Navigator.of(context).pop(),
                Navigator.of(context).pop(),
              },
              child: const Text('Back to matches overview'),
            ),
          ],
        ),
      );
    } catch (e) {
      showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Sorry! Something went wrong.'),
          content: Text(e.toString()),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Book Padel Match',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.amber,
      ),
      body: Stack(children: <Widget>[
        Positioned.fill(
          child: Image.asset(
            'images/background.png',
            fit: BoxFit.cover,
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Date selection with a styled button
                ElevatedButton.icon(
                  onPressed: () => _selectDate(context),
                  icon: const Icon(Icons.calendar_today, color: Colors.white),
                  label: Text(
                    DateFormat('yyyy-MM-dd').format(selectedDate),
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.amber,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
                const SizedBox(height: 20.0), // Add some space between elements
                // Time selection with styled buttons for available times
                getTimes(),
                const SizedBox(height: 20.0), // Add some space between elements
                // Button to book the match
                ElevatedButton(
                  onPressed: () {
                    bookMatch();
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.amber,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: const Text('Book Match'),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}
