import 'package:flutter/material.dart';
import 'package:frontend/selection.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SearchBarPage extends StatefulWidget {
  const SearchBarPage({super.key});

  @override
  _SearchBarPageState createState() => _SearchBarPageState();
}

class _SearchBarPageState extends State<SearchBarPage> {
  TextEditingController _searchController = TextEditingController();
  List<dynamic> parkingSlots = [];
  List<dynamic> filteredSlots = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchParkingSlots('');
  }

  Future<void> _fetchParkingSlots(String query) async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http
          .get(Uri.parse('http://172.16.66.68:3000/search?query=$query'));

      if (response.statusCode == 200) {
        setState(() {
          parkingSlots = jsonDecode(response.body);
          filteredSlots = parkingSlots;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error fetching slots: ${response.statusCode}')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching slots: $error')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterSlots(String query) {
    setState(() {
      filteredSlots = parkingSlots
          .where((slot) =>
              slot['area_name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
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
  }

  // void _navigateToDashboard(BuildContext context) {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(builder: (context) => const BookingDetailsPage()),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Search Parking Slots",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.purple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (query) {
                _filterSlots(query);
                _fetchParkingSlots(query);
              },
              decoration: InputDecoration(
                hintText: "Search parking place...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide:
                      const BorderSide(color: Colors.purple, width: 2.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide:
                      const BorderSide(color: Colors.purple, width: 2.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide:
                      const BorderSide(color: Colors.purple, width: 2.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredSlots.isEmpty
                    ? const Center(
                        child: Text(
                          'No results found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredSlots.length,
                        itemBuilder: (context, index) {
                          final slot = filteredSlots[index];
                          int totalSlots =
                              int.tryParse(slot['total_slot']) ?? 0;
                          return Card(
                            margin: const EdgeInsets.all(10),
                            child: ListTile(
                              title: Text(slot['area_name']),
                              subtitle: Text('Available Slots: $totalSlots'),
                              trailing: ElevatedButton(
                                onPressed: totalSlots > 0
                                    ? () => _bookSlot(
                                        slot['areaid']) // Pass correct ID
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: totalSlots > 0
                                      ? Colors.pinkAccent
                                      : Colors.red,
                                ),
                                child: Text(
                                  totalSlots > 0 ? 'Book' : 'Full',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
