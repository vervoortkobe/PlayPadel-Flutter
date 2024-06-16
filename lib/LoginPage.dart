import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intro_mobile_project/homepage.dart';

class LoginPage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> _signInWithEmailAndPassword(
      String email, String password, BuildContext context) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      Navigator.of(context).pushReplacementNamed('/');
    } catch (e) {
      showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('An error occurred.'),
          content: Text(e.toString()),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, AsyncSnapshot<User?> userSnapshot) {
        if (userSnapshot.hasData) {
          if (userSnapshot.data != null) return const HomePageController();
        }
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
                              padding: const EdgeInsets.only(
                                  top: 15.0, bottom: 15.0),
                              child: Center(
                                child: SizedBox(
                                  width: 200,
                                  height: 150,
                                  child:
                                      Image.asset('images/logo_play_padel.png'),
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15),
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
                                      'Enter valid email id as abc@gmail.com',
                                ),
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
                                  hintText: 'Enter secure password',
                                ),
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
                                    _signInWithEmailAndPassword(
                                      emailController.text,
                                      passwordController.text,
                                      context,
                                    );
                                  },
                                  child: const Text(
                                    'Login',
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
                                  "Don't have an account?",
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context)
                                        .pushReplacementNamed('/register');
                                  },
                                  child: Text.rich(
                                    TextSpan(
                                      text: "Register instead.",
                                      style: const TextStyle(
                                        color: Colors.amber,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          Navigator.of(context)
                                              .pushReplacementNamed(
                                                  '/register');
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
      },
    );
  }
}
