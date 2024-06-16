import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class Registerpage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController displayNameController = TextEditingController();

  Registerpage({super.key});

  Future<void> _createUserWithEmailAndPassword(String email, String password,
      String displayName, BuildContext context) async {
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      _firestore.collection("users").doc(_auth.currentUser!.uid).set({
        'display_name': displayName,
        'email': email,
        "lost": 0,
        "won": 0,
      });
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('An error occured.'),
          content: Text(e.toString()),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'OK'),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Image.asset(
              'images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Card(
                  color: const Color.fromARGB(68, 255, 255, 255),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 15.0, bottom: 15.0),
                          child: Center(
                            child: SizedBox(
                                width: 200,
                                height: 150,
                                child:
                                    Image.asset('images/logo_play_padel.png')),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 15.0, right: 15.0, top: 15.0, bottom: 15.0),
                          child: TextField(
                            controller: displayNameController,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                labelText: 'Username',
                                labelStyle: TextStyle(color: Colors.white),
                                hintText: 'Enter a username.'),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: TextField(
                            controller: emailController,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                labelText: 'Email',
                                labelStyle: TextStyle(color: Colors.white),
                                hintText:
                                    'Enter valid email id as abc@gmail.com'),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 15.0, right: 15.0, top: 15, bottom: 0),
                          child: TextField(
                            obscureText: true,
                            controller: passwordController,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                labelText: 'Password',
                                labelStyle: TextStyle(color: Colors.white),
                                hintText: 'Enter secure password'),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: Container(
                            height: 50,
                            width: 250,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TextButton(
                              onPressed: () {
                                _createUserWithEmailAndPassword(
                                  emailController.text,
                                  passwordController.text,
                                  displayNameController.text,
                                  context,
                                );
                              },
                              child: const Text(
                                'Register',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 25),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Already have an account?",
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 5),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context)
                                    .pushReplacementNamed('/login');
                              },
                              child: Text.rich(
                                TextSpan(
                                  text: "Sign in instead.",
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.of(context)
                                          .pushReplacementNamed('/login');
                                    },
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 35,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
