import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/booking-details.dart';
import 'package:frontend/home.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(AdminPage());
}

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AdminLoginPage(),
    );
  }
}

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  _AdminLoginPageState createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login(BuildContext context) {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username == '1' && password == '1') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminHomePage()),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text("Error"),
          content: Text("Invalid credentials!"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Login'),
        backgroundColor: Colors.yellow,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _login(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
              ),
              child: const Text(
                'Login',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  void _navigateToCreateParking(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateParkingPlacePage()),
    );
  }

  void _navigateToHomePage(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) =>
              const HomePage()), // This will navigate back to the Admin HomePage
    );
  }

  void _navigateTobooking(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) =>
              const BookingHistoryPage()), // This will navigate back to the Admin HomePage
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Page"),
        backgroundColor: Colors.yellow,
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.yellow),
              child: Center(
                child: Text(
                  'Admin Menu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ListTile(
              title: const Text("Homepage"),
              onTap: () => _navigateToHomePage(context),
            ),
            ListTile(
              title: const Text("Booking details"),
              onTap: () => _navigateTobooking(context),
            ),
            ListTile(
              title: const Text("Create a Parking Place"),
              onTap: () => _navigateToCreateParking(context),
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text(
          "Welcome to the Admin Page",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

class CreateParkingPlacePage extends StatefulWidget {
  const CreateParkingPlacePage({super.key});

  @override
  _CreateParkingPlacePageState createState() => _CreateParkingPlacePageState();
}

class _CreateParkingPlacePageState extends State<CreateParkingPlacePage> {
  final TextEditingController _parkingPlaceController = TextEditingController();
  final TextEditingController _numSlotsController = TextEditingController();

  Future<void> _submitDetails() async {
    final parkingPlace = _parkingPlaceController.text.trim();
    final numSlots = _numSlotsController.text.trim();

    if (parkingPlace.isNotEmpty && numSlots.isNotEmpty) {
      final url = Uri.parse("http://172.16.66.68:3000/create_parking");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'area_name': parkingPlace,
          'total_slot': numSlots,
        }),
      );

      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (context) => const AlertDialog(
            title: Text("Success"),
            content: Text("Parking place created successfully!"),
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => const AlertDialog(
            title: Text("Error"),
            content: Text("Failed to create parking place."),
          ),
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text("Error"),
          content: Text("Please fill all fields."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Parking Place"),
        backgroundColor: Colors.yellow,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _parkingPlaceController,
              decoration: const InputDecoration(labelText: "Parking Place"),
            ),
            TextField(
              controller: _numSlotsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Number of Slots"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
              ),
              child: const Text(
                "Submit",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
