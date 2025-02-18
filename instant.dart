import 'package:flutter/material.dart';
import 'package:frontend/home.dart';
import 'package:frontend/receipt.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class InstantBookingPage extends StatefulWidget {
  const InstantBookingPage({Key? key}) : super(key: key);

  @override
  _InstantBookingPageState createState() => _InstantBookingPageState();
}

class _InstantBookingPageState extends State<InstantBookingPage> {
  final TextEditingController _vehicleNumberController =
      TextEditingController();
  final TextEditingController _dateTimeFromController = TextEditingController();
  final TextEditingController _dateTimeToController = TextEditingController();

  String _selectedVehicleType = 'Select';
  int? _selectedAreaId;
  List<Map<String, dynamic>> _areas = [];
  double _calculatedAmount = 0.0; // Stores calculated payment
  bool _isPaymentInitiated = false;

  late Razorpay _razorpay;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fetchAreas();

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    // Set the default datetime_from to the current time
    _dateTimeFromController.text =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _fetchAreas() async {
    try {
      final response =
          await http.get(Uri.parse('http://172.16.66.68:3000/get-areas'));
      if (response.statusCode == 200) {
        setState(() {
          _areas = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error fetching areas')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network Error: $e')),
      );
    }
  }

  void _calculatePayment() {
    if (_dateTimeFromController.text.isEmpty ||
        _dateTimeToController.text.isEmpty ||
        _selectedVehicleType == 'Select') {
      setState(() {
        _calculatedAmount = 0.0;
      });
      return;
    }

    DateTime fromTime =
        DateFormat('yyyy-MM-dd HH:mm:ss').parse(_dateTimeFromController.text);
    DateTime toTime =
        DateFormat('yyyy-MM-dd HH:mm:ss').parse(_dateTimeToController.text);

    // Check if the gap between fromTime and toTime is at least 10 minutes
    if (toTime.difference(fromTime).inMinutes < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'The gap between from time and to time must be at least 10 minutes.')),
      );
      return;
    }

    int durationMinutes = toTime.difference(fromTime).inMinutes;

    double ratePerMinute = (_selectedVehicleType == 'Four-Wheeler')
        ? 0.83
        : (_selectedVehicleType == 'Two-Wheeler')
            ? 0.43
            : 0.0;

    setState(() {
      _calculatedAmount = durationMinutes * ratePerMinute;
    });
  }

  Future<void> _storeUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('user_id', userId); // Store the user_id in SharedPreferences
  }

  Future<int?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    int? userId =
        prefs.getInt('userId'); // Retrieve the user_id from SharedPreferences

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not logged in. Please log in again.')),
      );
    }

    return userId;
  }

  Future<void> _pickDateTime(BuildContext context,
      TextEditingController controller, bool isFromDateTime) async {
    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      final DateTime pickedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      // Check if the selected date and time is at least 10 minutes ahead of now (for dateTime_from)
      if (isFromDateTime &&
          pickedDateTime.isBefore(now.add(Duration(minutes: 10)))) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Please select a time at least 10 minutes from now.')),
        );
        return;
      }

      controller.text =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(pickedDateTime);
      _calculatePayment();
    }
  }

  Widget _buildDateTimeField(
      String label, TextEditingController controller, bool isFromDateTime,
      {bool isReadOnly = false}) {
    return TextFormField(
      controller: controller,
      readOnly: true, // Make the field read-only
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: isReadOnly ? null : const Icon(Icons.calendar_today),
      ),
      onTap: isReadOnly
          ? null
          : () => _pickDateTime(context, controller, isFromDateTime),
      validator: (value) =>
          (value == null || value.isEmpty) ? 'Please select $label' : null,
    );
  }

  void _startPayment() async {
    var options = {
      'key': 'rzp_test_cIeCwAX1qqUKB5', // Replace with your Razorpay API key
      'amount': (_calculatedAmount * 100).toInt(), // Convert to paise
      'currency': 'INR',
      'name': 'Parking Booking',
      'description': 'Instant Parking Booking Payment',
      'prefill': {'contact': '9876543210', 'email': 'user@example.com'},
      'theme': {'color': '#673AB7'}
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _reduceSlotCountOnBackend(int areaId) async {
    try {
      final response = await http.post(
        Uri.parse('http://172.16.66.68:3000/reduce-slot-count'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'areaid': areaId}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slot count updated successfully.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error reducing slot count: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network Error: $e')),
      );
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment Successful! Booking Confirmed.')),
    );

    // Now that payment is successful, submit the booking details to the server
    await _submitBookingToServer();

    // After successfully submitting, reduce the slot count on backend
    if (_selectedAreaId != null) {
      await _reduceSlotCountOnBackend(_selectedAreaId!);
    }

    // Prepare booking details to pass to the receipt page
    final bookingDetails = {
      'vehicleNumber': _vehicleNumberController.text.trim(),
      'vehicleType': _selectedVehicleType,
      'dateTime_from': _dateTimeFromController.text,
      'dateTime_to': _dateTimeToController.text,
      'area_name': _areas
          .firstWhere((area) => area['areaid'] == _selectedAreaId)['area_name'],
      'pay_amount': double.parse(_calculatedAmount.toStringAsFixed(2)),
    };

    // Navigate to the payment receipt page and pass the necessary data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentReceiptPage(
          bookingDetails: bookingDetails,
          paymentStatus: response.paymentId != null ? 'Success' : 'Failed',
          paymentId: response.paymentId ?? 'N/A',
        ),
      ),
    );
  }


  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message}')),
    );

    // Redirect to home page after payment failure
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
      (route) => false, // Clears the navigation stack
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('External Wallet Selected: ${response.walletName}')),
    );
  }

  Future<void> _submitBookingToServer() async {
    const String apiUrl = 'http://172.16.66.68:3000/instant-booking';

    // Fetch user_id dynamically
    final userId = await _getUserId();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    final bookingData = {
      'user_id': userId, // Use dynamic user_id
      'vehicleNumber': _vehicleNumberController.text.trim(),
      'vehicleType': _selectedVehicleType,
      'dateTime_from': _dateTimeFromController.text,
      'dateTime_to': _dateTimeToController.text,
      'areaid': _selectedAreaId,
      'area_name': _areas
          .firstWhere((area) => area['areaid'] == _selectedAreaId)['area_name'],
      'pay_amount':
          double.parse(_calculatedAmount.toStringAsFixed(2)).toString(),
      'slot_id': _selectedAreaId, // Add slot_id based on your logic
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bookingData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking Submitted Successfully!')),
        );

        // Reduce slot count after successful booking submission
        if (_selectedAreaId != null) {
          await _reduceSlotCountOnBackend(_selectedAreaId!);
        }

        // Navigate back or to confirmation page
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting booking: ${response.body}')),
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
        backgroundColor: Colors.purple,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Instant Booking',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 16),
              TextFormField(
                controller: _vehicleNumberController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Number',
                ),
                validator: (value) {
                  final RegExp vehicleNumberRegExp =
                      RegExp(r'^[A-Z]{2}\d{2}[A-Z]{2}\d{4}$');

                  if (value == null || value.isEmpty) {
                    return 'Please enter your vehicle number';
                  } else if (!vehicleNumberRegExp.hasMatch(value)) {
                    return 'Enter a valid format: TN00AB0000';
                  }
                  return null;
                },
                keyboardType: TextInputType.text,
                textCapitalization:
                    TextCapitalization.characters, // Auto capitalizes letters
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedVehicleType,
                hint: const Text('Select Vehicle Type'),
                items: const [
                  DropdownMenuItem(
                    value: 'Select',
                    child: Text('Select Vehicle Type'),
                  ),
                  DropdownMenuItem(
                    value: 'Four-Wheeler',
                    child: Text('Four-Wheeler'),
                  ),
                  DropdownMenuItem(
                    value: 'Two-Wheeler',
                    child: Text('Two-Wheeler'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedVehicleType = value!;
                  });
                  _calculatePayment();
                },
                validator: (value) =>
                    value == 'Select' ? 'Select Vehicle Type' : null,
              ),
              DropdownButtonFormField<int>(
                value: _selectedAreaId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Parking Place'),
                items: _areas.map<DropdownMenuItem<int>>((area) {
                  return DropdownMenuItem<int>(
                    value: area['areaid'],
                    child: Text(area['area_name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAreaId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildDateTimeField(
                  'From DateTime', _dateTimeFromController, true,
                  isReadOnly: true), // Predefined and not editable

              const SizedBox(height: 16),
              _buildDateTimeField(
                'To DateTime',
                _dateTimeToController,
                false,
              ),
              const SizedBox(height: 16),
              Text(
                'Payment Amount:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8), // Space between label and amount
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '₹${_calculatedAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() == true) {
                    _startPayment(); // Trigger payment first
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Submit Booking',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
