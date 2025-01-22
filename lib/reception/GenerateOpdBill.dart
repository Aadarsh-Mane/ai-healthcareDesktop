import 'dart:convert';
import 'package:doctordesktop/Doctor/Animate.dart';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GenerateOpdBillScreen extends StatefulWidget {
  final String patientId;

  const GenerateOpdBillScreen({Key? key, required this.patientId})
      : super(key: key);

  @override
  _GenerateOpdBillScreenState createState() => _GenerateOpdBillScreenState();
}

class _GenerateOpdBillScreenState extends State<GenerateOpdBillScreen> {
  final _formKey = GlobalKey<FormState>();
  // bool _isLoading = false; // Track loading state
  bool _isLoadingBill = false; // Track loading state for OPD Bill
  bool _isLoadingReceipt = false; // Track loading state for OPD Receipt

  // Controllers for input fields
  final _labAmountController = TextEditingController();
  final _labDateController = TextEditingController();
  final _otherAmountController = TextEditingController();
  final _otherDateController = TextEditingController();
  final _biilingAmountController = TextEditingController();
  final _amountPaidController = TextEditingController();

  // Function to send data to the backend
  Future<void> _generateOpdBill() async {
    // if (!_formKey.currentState!.validate()) return;

    final url = Uri.parse('${VERCEL_URL}/reception/generateOpdBill');
    final data = {
      "patientId": widget.patientId,
      "labCharges": {
        "amount": int.parse(_labAmountController.text),
        "date": _labDateController.text
      },
      "otherCharges": {
        "amount": int.parse(_otherAmountController.text),
        "date": _otherDateController.text
      }
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      print(response.body);
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

  Future<void> _generateOpdReceipt() async {
    if (!_formKey.currentState!.validate()) return;

    final url = Uri.parse('${VERCEL_URL}/reception/generateOpdReceipt');
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
      print(response.body);
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
      appBar: AppBar(title: Text('Generate OPD Bill')),
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
              SizedBox(height: 16),
              TextFormField(
                controller: _labAmountController,
                decoration: InputDecoration(labelText: 'Lab Charges Amount'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Lab Charges Amount';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _labDateController,
                decoration: InputDecoration(labelText: 'Lab Charges Date'),
                keyboardType: TextInputType.datetime,
                readOnly: true, // Prevent manual editing
                onTap: () async {
                  DateTime? selectedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (selectedDate != null) {
                    _labDateController.text =
                        "${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year.toString().substring(2)}";
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Lab Charges Date';
                  }
                  return null;
                },
              ),

              TextFormField(
                controller: _otherDateController,
                decoration: InputDecoration(labelText: 'Other Charges Date'),
                keyboardType: TextInputType.datetime,
                readOnly: true, // Prevent manual editing
                onTap: () async {
                  DateTime? selectedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (selectedDate != null) {
                    _otherDateController.text =
                        "${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year.toString().substring(2)}";
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Other Charges Date';
                  }
                  return null;
                },
              ),

              // TextFormField(
              //   controller: _labDateController,
              //   decoration: InputDecoration(labelText: 'Lab Charges Date'),
              //   keyboardType: TextInputType.datetime,
              //   validator: (value) {
              //     if (value == null || value.isEmpty) {
              //       return 'Please enter Lab Charges Date';
              //     }
              //     return null;
              //   },
              // ),
              TextFormField(
                controller: _otherAmountController,
                decoration: InputDecoration(labelText: 'Other Charges Amount'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Other Charges Amount';
                  }
                  return null;
                },
              ),
              // TextFormField(
              //   controller: _otherDateController,
              //   decoration: InputDecoration(labelText: 'Other Charges Date'),
              //   keyboardType: TextInputType.datetime,
              //   validator: (value) {
              //     if (value == null || value.isEmpty) {
              //       return 'Please enter Other Charges Date';
              //     }
              //     return null;
              //   },
              // ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _isLoadingBill = true; // Start loading animation
                  });

                  // Perform the fetch operation
                  await _generateOpdBill();

                  setState(() {
                    _isLoadingBill = false; // Stop loading animation
                  });
                },
                child: _isLoadingBill
                    ? const CustomLoadingAnimation() // Show loading animation
                    : const Text(
                        'Generate OPD Bill'), // Show button text when not loading
              ),
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
                        'Generate OPD Receipt'), // Show button text when not loading
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _labAmountController.dispose();
    _labDateController.dispose();
    _otherAmountController.dispose();
    _otherDateController.dispose();
    super.dispose();
  }
}
