import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({Key? key}) : super(key: key);

  @override
  _BookingHistoryPageState createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  List<Map<String, dynamic>> _bookingHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchBookingHistory();
  }

  Future<void> _fetchBookingHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final int? userId = prefs.getInt('userId');

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in!')),
      );
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            'http://172.16.66.68:3000/user-booking-history?user_id=$userId'),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        List<Map<String, dynamic>> bookings =
            List<Map<String, dynamic>>.from(data);
        setState(() {
          _bookingHistory = bookings;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(data['error'] ?? 'Error fetching booking history')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.purple,
        title: const Text('Booking History',
            style: TextStyle(color: Colors.white)),
      ),
      body: _bookingHistory.isEmpty
          ? const Center(child: Text('No booking history found.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _bookingHistory.length,
              itemBuilder: (context, index) {
                final booking = _bookingHistory[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 10.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vehicle: ${booking['vehicle_number']}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        Text('Vehicle Type: ${booking['vehicle_type']}'),
                        Text('Slot ID: ${booking['slot_id']}'),
                        Text('Area: ${booking['area_name']}'),
                        Text('Area ID: ${booking['areaid']}'),
                        Text('From: ${booking['datetime_from']}'),
                        Text('To: ${booking['datetime_to']}'),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
