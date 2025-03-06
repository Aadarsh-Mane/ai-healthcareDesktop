import 'dart:convert';
import 'package:doctordesktop/Doctor/Animate.dart';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GenerateIpdBillScreen extends StatefulWidget {
  final String patientId;
  final String remainingAmount;
  const GenerateIpdBillScreen(
      {Key? key, required this.patientId, required this.remainingAmount})
      : super(key: key);

  @override
  _GenerateOpdBillScreenState createState() => _GenerateOpdBillScreenState();
}

class _GenerateOpdBillScreenState extends State<GenerateIpdBillScreen> {
  final _formKey = GlobalKey<FormState>();
  // bool _isLoading = false; // Track loading state
  bool _isLoadingReceipt = false; // Track loading state for OPD Receipt

  final _biilingAmountController = TextEditingController();
  final _amountPaidController = TextEditingController();

  Future<void> _generateOpdReceipt() async {
    if (!_formKey.currentState!.validate()) return;

    final url = Uri.parse('${KVM_URL}/reception/generateOpdReceipt');
    final data = {
      "patientId": widget.patientId,
      "billingAmount": int.parse(_biilingAmountController.text),
      "amountPaid": int.parse(_amountPaidController.text),
    };
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      print(data);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final fileLink = data['fileLink'];
        print("working ${fileLink}");
        if (fileLink != null) {
          Methods().openPdf(fileLink);
          // Methods().downloadFile(fileLink, 'doctor_advice.pdf', context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No file link found in the response')),
          );
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bill generated successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate bill.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Generate IPD Bill')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Patient ID: ${widget.patientId}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'Remaining Amount: ${widget.remainingAmount}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _biilingAmountController,
                decoration: InputDecoration(labelText: 'Billing Amount'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Billing  Amount';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _amountPaidController,
                decoration: InputDecoration(labelText: ' Amount Paid'),
                keyboardType: TextInputType.datetime,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount  paid';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _isLoadingReceipt = true; // Start loading animation
                  });

                  // Perform the fetch operation
                  await _generateOpdReceipt();

                  setState(() {
                    _isLoadingReceipt = false; // Stop loading animation
                  });
                },
                child: _isLoadingReceipt
                    ? const CustomLoadingAnimation() // Show loading animation
                    : const Text(
                        'Generate IPD Receipt'), // Show button text when not loading
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
