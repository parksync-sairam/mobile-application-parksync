import 'package:flutter/material.dart';
import 'package:frontend/admin.dart';
import 'package:frontend/booking-details.dart';
import 'package:frontend/login.dart';
import 'package:frontend/receipt.dart';
import 'package:frontend/search.dart';
import 'package:frontend/selection.dart'; // Ensure this file exists
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Parking Slot Booking',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> parkingSlots = [];

  @override
  void initState() {
    super.initState();
    _fetchParkingSlots();
  }

  Future<void> _fetchParkingSlots() async {
    try {
      final response =
          await http.get(Uri.parse('http://172.16.66.68:3000/slots'));

      if (response.statusCode == 200) {
        List<dynamic> slots = jsonDecode(response.body);

        if (mounted) {
          // Check if the widget is still in the tree
          setState(() {
            parkingSlots = slots;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load parking slots')),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    }
  }

  Future<void> _bookSlot(int? areaId) async {
    if (areaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid area ID, cannot book slot.')),
      );
      return;
    }

    final response = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdvanceBookingPage(),
      ),
    );

    if (response == true) {
      _fetchParkingSlots(); // Refresh slot count after successful booking
    }
  }

  void _navigateToDashboard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BookingHistoryPage()),
    );
  }

//   void _paymentreceipt(BuildContext context) {
//    Navigator.push(
//   context,
//   MaterialPageRoute(
//     builder: (context) => PaymentReceiptPage(
//       bookingDetails: bookingD,
//       paymentId: paymentId,
//       paymentStatus: "Success",
//     ),
//   ),
// );

//   }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          'Advance Booking Page',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: parkingSlots.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SearchBarPage()),
                      );
                    },
                    child: TextField(
                      controller: _searchController,
                      enabled: false, // Disable keyboard opening
                      decoration: InputDecoration(
                        hintText: "Search...",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: parkingSlots.length,
                    itemBuilder: (context, index) {
                      final parkingSlot = parkingSlots[index];

                      // Handle missing area_name
                      String areaName = parkingSlot.containsKey('area_name') &&
                              parkingSlot['area_name'] != null
                          ? parkingSlot['area_name'].toString()
                          : 'Unknown Area';

                      // Handle missing total_slot
                      int totalSlots = int.tryParse(
                              parkingSlot['total_slot']?.toString() ?? '0') ??
                          0;

                      // Handle missing areaid
                      int? areaId = parkingSlot['areaid'] != null
                          ? int.tryParse(parkingSlot['areaid'].toString())
                          : null;

                      return Card(
                        margin: const EdgeInsets.all(10),
                        child: ListTile(
                          title: Text(areaName),
                          subtitle: Text(
                            'Available Slots: $totalSlots',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: ElevatedButton(
                            onPressed:
                                totalSlots > 0 ? () => _bookSlot(areaId) : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: totalSlots > 0
                                  ? Colors.pinkAccent
                                  : Colors.grey,
                            ),
                            child: Text(
                              totalSlots > 0 ? 'Book' : 'No Slots Available',
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      drawer: Drawer(
        child: ListView(
          children: [
            Container(
              height: 80,
              color: Colors.purple,
              padding: const EdgeInsets.only(left: 16.0, top: 20.0),
              alignment: Alignment.centerLeft,
              child: const Text(
                'Menu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            ListTile(
              title: const Text("Dashboard"),
              onTap: () => _navigateToDashboard(context),
            ),
            ListTile(
              title: const Text("Logout"),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }
}
