import 'package:flutter/material.dart';
import 'package:frontend/splach.dart';
import 'login.dart';
import 'signup.dart';

void main() {
  runApp(ParkingApp());
}

class ParkingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Parking App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SplashScreen(), // Start with splash screeny
    );
  }
}
