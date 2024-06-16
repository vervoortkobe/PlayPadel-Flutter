import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Slotbuilder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> joinOrSwitchSlot(
      DocumentSnapshot document, int playerSlot) async {
    final user = FirebaseAuth.instance.currentUser;
    bool isStarted = document['started'] ?? false;
    if (isStarted) {
      return;
    }

    DocumentReference? currentPlayer = document['player$playerSlot'];

    // Get player from users db
    final collection = _firestore.collection('users').doc(user?.uid);

    final users = await collection.get();

    DocumentSnapshot dbuser = users;

    if (currentPlayer == null) {
      // Check if the user is already in another slot

      int? currentSlot;
      for (int i = 0; i < 4; i++) {
        if (document['player$i'] == dbuser.reference) {
          currentSlot = i;
          break;
        }
      }
      if (currentSlot == null) {
        // Join match
        await document.reference
            .update({'player$playerSlot': dbuser.reference});
      } else {
        // Switch slot
        await document.reference.update({
          'player$currentSlot': null,
          'player$playerSlot': dbuser.reference
        });
      }
    } else if (currentPlayer == dbuser.reference) {
      // Leave match
      // If there are no players left in the match, delete the match.
      bool hasPlayers = false;
      for (int i = 0; i < 4; i++) {
        if (document['player$i'] != null &&
            document['player$i'] != dbuser.reference) {
          hasPlayers = true;
          break;
        }
      }

      if (!hasPlayers) {
        await document.reference.delete();
      } else {
        await document.reference.update({'player$playerSlot': null});
      }
    }
  }

  static Widget actionWidget(DocumentReference? currentPlayer,
      DocumentSnapshot document, int playerSlot, bool isStarted) {
    final user = FirebaseAuth.instance.currentUser;
    bool isCurrentUser = false;
    if (document['player$playerSlot'] != null) {
      isCurrentUser =
          (document['player$playerSlot'] as DocumentReference).id == user?.uid;
    }
    Color borderColor = isCurrentUser ? Colors.red : Colors.amber;
    Color iconColor = isCurrentUser ? Colors.red : Colors.amber;

    Widget circleAvatar = CircleAvatar(
      backgroundColor: const Color.fromARGB(68, 255, 255, 255),
      radius: 24.0,
      child: document['player$playerSlot'] != null
          ? Image.asset(
              'images/racket.png', // Replace with the path to your default image
              width: 32.0,
              height: 32.0,
              color: iconColor,
            )
          : const Icon(
              Icons.add,
              size: 24.0,
              color: Colors.amber,
            ),
    );

    if (document['player$playerSlot'] == null) {
      circleAvatar = CustomPaint(
        painter: DottedBorderPainter(Colors.amber),
        child: circleAvatar,
      );
    } else {
      circleAvatar = CustomPaint(
        painter: SolidBorderPainter(borderColor),
        child: circleAvatar,
      );
    }
    return buildIcons(document, circleAvatar, playerSlot, isStarted);
  }

  static Widget buildMatches(
      BuildContext context, DocumentSnapshot<Object?> place) {
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

        List<DocumentSnapshot> documents = snapshot.data!.docs;
        // Filter matches by place and not done
        final DateTime now = DateTime.now();
        documents = documents.where((DocumentSnapshot snapshot) {
          final DateTime startTime =
              (snapshot['timeStarted'] as Timestamp).toDate();
          final DateTime endTime = startTime.add(const Duration(minutes: 90));
          return snapshot['place'].id.toString().trim() == place.reference.id &&
              endTime.isAfter(now);
        }).toList();

        return ListView(
          padding: const EdgeInsets.all(8.0),
          children: documents.map((DocumentSnapshot document) {
            return buildCard(document);
          }).toList(),
        );
      },
    );
  }

  static Widget buildIcons(DocumentSnapshot document, Widget circleAvatar,
      int playerSlot, bool isStarted) {
    if (document['player$playerSlot'] != null) {
      return StreamBuilder<DocumentSnapshot>(
          stream: _firestore
              .collection('users')
              .doc((document['player$playerSlot'] as DocumentReference).id)
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return availableWidget(
                  document, circleAvatar, playerSlot, isStarted);
            }

            final users = snapshot.data;
            final DocumentSnapshot dbuser = users!;
            return Column(children: [
              GestureDetector(
                onTap: () {
                  if (!isStarted) {
                    joinOrSwitchSlot(document, playerSlot);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.all(8.0),
                  child: circleAvatar,
                ),
              ),
              Text(
                dbuser["display_name"],
                style: const TextStyle(color: Colors.white),
              ),
            ]);
          });
    }
    return availableWidget(document, circleAvatar, playerSlot, isStarted);
  }

  static Widget availableWidget(DocumentSnapshot document, Widget circleAvatar,
      int playerSlot, bool isStarted) {
    return Column(children: [
      GestureDetector(
        onTap: () {
          if (!isStarted) {
            joinOrSwitchSlot(document, playerSlot);
          }
        },
        child: Container(
          margin: const EdgeInsets.all(8.0),
          child: circleAvatar,
        ),
      ),
      const Text(
        "Available",
        style: TextStyle(color: Colors.white),
      ),
    ]);
  }

  static Widget buildCard(DocumentSnapshot document) {
    final user = FirebaseAuth.instance.currentUser;
    return Card(
      color: const Color.fromARGB(68, 255, 255, 255),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(
                Icons.event,
                color: Colors.white,
              ),
              title: Text("Match at:",
                  style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                DateFormat('dd/MM/yyyy, HH:mm')
                    .format((document['timeStarted'] as Timestamp).toDate()),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            buildPlayersRow(document),
            const SizedBox(height: 10.0),
            buildStartButton(document),
          ],
        ),
      ),
    );
  }

  static Widget buildPlayersRow(DocumentSnapshot document) {
    bool isStarted = document['started'] ?? false;

    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          actionWidget(document['player0'], document, 0, isStarted),
          actionWidget(document['player1'], document, 1, isStarted),
          SizedBox(
              width: 2.0,
              height: 48.0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.amber,
                  border: Border.all(color: Colors.amber, width: 2.0),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              )),
          actionWidget(document['player2'], document, 2, isStarted),
          actionWidget(document['player3'], document, 3, isStarted),
        ],
      ),
    );
  }

  static Widget buildStartButton(DocumentSnapshot document) {
    final user = FirebaseAuth.instance.currentUser;
    final bool isPlayerInSlot0 = document['player0'] != null &&
        (document['player0'] as DocumentReference).id == user?.uid;
    final bool isStarted = document['started'] ?? false;

    final DateTime startTime = (document['timeStarted'] as Timestamp).toDate();
    final bool isStartTimeNotOver = DateTime.now().isBefore(startTime);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: isStartTimeNotOver && isPlayerInSlot0 && !isStarted
            ? () => startMatch(document)
            : () => unlockMatch(document),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPlayerInSlot0 ? Colors.amber : Colors.grey,
        ),
        child: isPlayerInSlot0
            ? Text(
                isStarted ? 'Unlock match' : 'Lock match',
                style: const TextStyle(color: Colors.white),
              )
            : Text(
                isStarted
                    ? 'Sorry! This match is locked.'
                    : 'You cannot lock this match, only player 1 can.',
                style: const TextStyle(color: Colors.white),
              ),
      ),
    );
  }

  static Future<void> startMatch(DocumentSnapshot document) async {
    await document.reference.update({'started': true});
  }

  static Future<void> unlockMatch(DocumentSnapshot document) async {
    await document.reference.update({'started': false});
  }
}

class DottedBorderPainter extends CustomPainter {
  final Color borderColor;

  DottedBorderPainter(this.borderColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final radius = size.width / 2;
    const double dashWidth = 4.0;
    const double dashSpace = 4.0;
    double startAngle = 0.0;
    final circumference = 2 * 3.141592653589793238 * radius;
    final double dashCount = circumference / (dashWidth + dashSpace);

    for (int i = 0; i < dashCount; i++) {
      final double endAngle = startAngle + dashWidth / radius;
      canvas.drawArc(
          Rect.fromCircle(center: Offset(radius, radius), radius: radius),
          startAngle,
          endAngle - startAngle,
          false,
          paint);
      startAngle = endAngle + dashSpace / radius;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

class SolidBorderPainter extends CustomPainter {
  final Color borderColor;

  SolidBorderPainter(this.borderColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final radius = size.width / 2;
    canvas.drawCircle(Offset(radius, radius), radius, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
