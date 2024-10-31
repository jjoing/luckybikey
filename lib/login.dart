import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/home.dart';
import 'register.dart';

class login extends StatefulWidget {
  const login({super.key});

  @override
  State<login> createState() => _loginState();
}

class _loginState extends State<login> {
  final _authentication = FirebaseAuth.instance;

  final _formKey = GlobalKey<FormState>();

  String userEmail = '';
  String userPassword = '';

  late ScrollController scrollController;

  void _tryValidation() {
    final isValid = _formKey.currentState!.validate();
    if (isValid) {
      _formKey.currentState!.save();
    }
  }

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Center(
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 50,
                  ),
                  Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.lightGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 40
                    ),
                  ),
                  SizedBox(
                    height: 50,
                  ),
                  SizedBox(
                    width: 278.0,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email',),
                          const SizedBox(height: 5.0,),
                          Column(
                            children: [
                              TextFormField(
                                key: const ValueKey(1),
                                keyboardType: TextInputType.emailAddress,
                                onTap: () {
                                  scrollAnimate();
                                },
                                onSaved: (value) {
                                  userEmail = value!;
                                },
                                onChanged: (value) {
                                  userEmail = value;
                                },
                                validator: (value) {
                                  if (value!.isEmpty || value.length < 5) {
                                    return 'Please enter at least 5 characters.';
                                  }
                                  return null;
                                },
                                scrollPadding: EdgeInsets.only(
                                    bottom: MediaQuery.of(context)
                                        .viewInsets
                                        .bottom),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.all(6.0),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Color(0xff415e91),),
                                    borderRadius: BorderRadius.circular(9.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Color(0xff415e91),),
                                    borderRadius: BorderRadius.circular(9.0),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.red,),
                                    borderRadius: BorderRadius.circular(9.0),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.red,),
                                    borderRadius: BorderRadius.circular(9.0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0,),

                  // user password text field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Password',
                      ),
                      const SizedBox(
                        height: 5.0,
                      ),
                      Column(
                        children: [
                          SizedBox(
                            width: 278,
                            child: TextFormField(
                              key: const ValueKey(1),
                              obscureText: true,
                              onTap: () {
                                scrollAnimate();
                              },
                              onSaved: (value) {
                                userPassword = value!;
                              },
                              onChanged: (value) {
                                userPassword = value;
                              },
                              validator: (value) {
                                if (value!.isEmpty || value.length < 5) {
                                  return 'Please enter at least 5 characters.';
                                }
                                return null;
                              },
                              scrollPadding: EdgeInsets.only(
                                  bottom: MediaQuery.of(context).viewInsets.bottom),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.all(6.0),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Color(0xff415e91),
                                  ),
                                  borderRadius: BorderRadius.circular(9.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Color(0xff415e91),
                                  ),
                                  borderRadius: BorderRadius.circular(9.0),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                  ),
                                  borderRadius: BorderRadius.circular(9.0),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                  ),
                                  borderRadius: BorderRadius.circular(9.0),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  // button linked to register page
                  Positioned(
                    bottom: 13,
                    left: 18.9,
                    child: TextButton(
                      style: ButtonStyle(
                        padding: MaterialStateProperty.all(
                          EdgeInsets.zero,
                        ),
                      ),
                      child: Text(
                        'New Here? Register',
                      ),
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => register()));
                      },
                    ),
                  ),
                  // login button
                  Positioned(
                    bottom: 19.13,
                    right: 27.26,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.transparent,
                        side: const BorderSide(
                          color: Colors.white,
                        ),
                        fixedSize: const Size(129.6, 54.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.3),
                        ),
                      ),
                      onPressed: () async {
                        try {
                          _tryValidation();

                          final newUser =
                              await _authentication.signInWithEmailAndPassword(
                            email: userEmail,
                            password: userPassword,
                          );

                          if (newUser.user != null) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Home()));
                          }
                        } catch (err) {
                          print(err);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'Please check your email and password.'),
                              backgroundColor: Colors.blue,
                            ),
                          );
                        }
                      },
                      child: Text(
                        'Login',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  void scrollAnimate() {
    Future.delayed(const Duration(milliseconds: 600), () {
      scrollController.animateTo(
        MediaQuery.of(context).viewInsets.bottom,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeIn,
      );
    });
  }
}