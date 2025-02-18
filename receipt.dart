import 'package:flutter/material.dart';
import 'package:frontend/main.dart';
import 'package:frontend/selection.dart';

class PaymentReceiptPage extends StatelessWidget {
  final Map<String, dynamic> bookingDetails;
  final String paymentStatus;
  final String paymentId;

  const PaymentReceiptPage({
    Key? key,
    required this.bookingDetails,
    required this.paymentStatus,
    required this.paymentId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: const Text('Payment Receipt'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            SizedBox(height: 10),
            Text('Vehicle Number: ${bookingDetails['vehicleNumber']}'),
            Text('Vehicle Type: ${bookingDetails['vehicleType']}'),
            Text('Area: ${bookingDetails['area_name']}'),
            Text('Date From: ${bookingDetails['dateTime_from']}'),
            Text('Date To: ${bookingDetails['dateTime_to']}'),
            Text('Amount: ₹${bookingDetails['pay_amount']}'),
            SizedBox(height: 20),
            Text(
              'Payment Status: $paymentStatus',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: paymentStatus == 'Success' ? Colors.green : Colors.red,
              ),
            ),
            Text('Payment ID: $paymentId'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SelectionPage(
                            parkingPlace: ''))); // Go back to the previous page
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              child: const Text(
                'Back to Home',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
