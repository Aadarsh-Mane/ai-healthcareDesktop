import 'dart:io';

import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

// API URL

// State Management with Riverpod
final billProvider =
    StateNotifierProvider<BillNotifier, AsyncValue<Map<String, dynamic>>>(
  (ref) => BillNotifier(),
);

class BillNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  BillNotifier() : super(const AsyncValue.data({}));

  Future<void> generateBill(Map<String, dynamic> billData) async {
    state = const AsyncValue.loading();
    try {
      final response = await http.post(
        Uri.parse('${KVM_URL}/reception/bill'),
        body: json.encode(billData),
        headers: {'Content-Type': 'application/json'},
      );
      print(response.body);
      if (response.statusCode == 200) {
        state = AsyncValue.data(json.decode(response.body));
      } else {
        throw Exception('Failed to generate bill');
      }
    } catch (e) {
      print('Error: $e');
      // state = AsyncValue.error(e.toString('',''));
    }
  }
}

class GenerateBillScreen extends ConsumerStatefulWidget {
  final String patientId;

  const GenerateBillScreen({Key? key, required this.patientId})
      : super(key: key);

  @override
  ConsumerState<GenerateBillScreen> createState() => _GenerateBillScreenState();
}

class _GenerateBillScreenState extends ConsumerState<GenerateBillScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _icuRateController = TextEditingController();
  final TextEditingController _icuQuantityController = TextEditingController();
  final TextEditingController _icuDateController = TextEditingController();
  final TextEditingController _singleAcRateController = TextEditingController();
  final TextEditingController _singleAcQuantityController =
      TextEditingController();
  final TextEditingController _singleRoomRateController =
      TextEditingController();
  final TextEditingController _singleRoomQuantityController =
      TextEditingController();

  final TextEditingController _generalWardRateController =
      TextEditingController();
  final TextEditingController _generalWardQuantityController =
      TextEditingController();
  final TextEditingController _singleAcDateController = TextEditingController();

  final TextEditingController _singleRoomDateController =
      TextEditingController();

  final TextEditingController _generalWardDateController =
      TextEditingController();

  final TextEditingController _icuVisitingRateController =
      TextEditingController();
  final TextEditingController _icuVisitingVisitsController =
      TextEditingController();
  final TextEditingController _icuVisitingDateController = TextEditingController(
      text:
          "${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().year.toString().substring(2)}");
  final TextEditingController _generalVisitingRateController =
      TextEditingController();
  final TextEditingController _generalVisitingVisitsController =
      TextEditingController();
  final TextEditingController _generalVisitingDateController =
      TextEditingController();
  final TextEditingController _externalVisitingRateController =
      TextEditingController();
  final TextEditingController _externalVisitingVisitsController =
      TextEditingController();
  final TextEditingController _externalVisitingDateController =
      TextEditingController();
  final TextEditingController _oxygenRateController = TextEditingController();
  final TextEditingController _oxygenQuantityController =
      TextEditingController();
  final TextEditingController _oxygenDateController = TextEditingController();
  final TextEditingController _ecgRateController = TextEditingController();
  final TextEditingController _ecgQuantityController = TextEditingController();
  final TextEditingController _ecgDateController = TextEditingController();
  final TextEditingController _xrayRateController = TextEditingController();
  final TextEditingController _xrayQuantityController = TextEditingController();
  final TextEditingController _xrayDateController = TextEditingController();
  final TextEditingController _ctScanRateController = TextEditingController();
  final TextEditingController _ctScanQuantityController =
      TextEditingController();
  final TextEditingController _ctScanDateController = TextEditingController();
  final TextEditingController _sonographyRateController =
      TextEditingController();
  final TextEditingController _sonographyQuantityController =
      TextEditingController();
  final TextEditingController _sonographyDateController =
      TextEditingController();
  final TextEditingController _medicineTotalController =
      TextEditingController();

  @override
  @override
  Widget build(BuildContext context) {
    final billState = ref.watch(billProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Bill'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Bed Charges Section
              ExpansionTile(
                title: _buildSectionTitle('Bed Charges'),
                children: [
                  // ICU Section
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(_icuRateController,
                            'ICU Rate/Day', TextInputType.number),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            DateTime? selectedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (selectedDate != null) {
                              _icuDateController.text =
                                  "${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year.toString().substring(2)}";
                            }
                          },
                          child: AbsorbPointer(
                            child: _buildTextField(_icuDateController,
                                'ICU Date', TextInputType.datetime),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _icuQuantityController.text.isNotEmpty
                              ? int.tryParse(_icuQuantityController.text)
                              : null,
                          onChanged: (value) {
                            if (value != null) {
                              _icuQuantityController.text = value.toString();
                            }
                          },
                          items: List.generate(10, (index) => index)
                              .map((quantity) => DropdownMenuItem<int>(
                                    value: quantity,
                                    child: Text(quantity.toString()),
                                  ))
                              .toList(),
                          decoration:
                              const InputDecoration(labelText: 'ICU Quantity'),
                        ),
                      ),
                    ],
                  ),

                  // Single AC Section
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(_singleAcRateController,
                            'Single AC Rate/Day', TextInputType.number),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            DateTime? selectedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (selectedDate != null) {
                              _singleAcDateController.text =
                                  "${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year.toString().substring(2)}";
                            }
                          },
                          child: AbsorbPointer(
                            child: _buildTextField(_singleAcDateController,
                                'Single AC Date', TextInputType.datetime),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _singleAcQuantityController.text.isNotEmpty
                              ? int.tryParse(_singleAcQuantityController.text)
                              : null,
                          onChanged: (value) {
                            if (value != null) {
                              _singleAcQuantityController.text =
                                  value.toString();
                            }
                          },
                          items: List.generate(10, (index) => index)
                              .map((quantity) => DropdownMenuItem<int>(
                                    value: quantity,
                                    child: Text(quantity.toString()),
                                  ))
                              .toList(),
                          decoration: const InputDecoration(
                              labelText: 'Single AC Quantity'),
                        ),
                      ),
                    ],
                  ),

                  // Single Room Section
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(_singleRoomRateController,
                            'Single Room Rate/Day', TextInputType.number),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            DateTime? selectedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (selectedDate != null) {
                              _singleRoomDateController.text =
                                  "${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year.toString().substring(2)}";
                            }
                          },
                          child: AbsorbPointer(
                            child: _buildTextField(_singleRoomDateController,
                                'Single Room Date', TextInputType.datetime),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _singleRoomQuantityController.text.isNotEmpty
                              ? int.tryParse(_singleRoomQuantityController.text)
                              : null,
                          onChanged: (value) {
                            if (value != null) {
                              _singleRoomQuantityController.text =
                                  value.toString();
                            }
                          },
                          items: List.generate(10, (index) => index)
                              .map((quantity) => DropdownMenuItem<int>(
                                    value: quantity,
                                    child: Text(quantity.toString()),
                                  ))
                              .toList(),
                          decoration: const InputDecoration(
                              labelText: 'Single Room Quantity'),
                        ),
                      ),
                    ],
                  ),

                  // General Ward Section
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(_generalWardRateController,
                            'General Ward Rate/Day', TextInputType.number),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            DateTime? selectedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (selectedDate != null) {
                              _generalWardDateController.text =
                                  "${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year.toString().substring(2)}";
                            }
                          },
                          child: AbsorbPointer(
                            child: _buildTextField(_generalWardDateController,
                                'General Ward Date', TextInputType.datetime),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _generalWardQuantityController.text.isNotEmpty
                              ? int.tryParse(
                                  _generalWardQuantityController.text)
                              : null,
                          onChanged: (value) {
                            if (value != null) {
                              _generalWardQuantityController.text =
                                  value.toString();
                            }
                          },
                          items: List.generate(10, (index) => index)
                              .map((quantity) => DropdownMenuItem<int>(
                                    value: quantity,
                                    child: Text(quantity.toString()),
                                  ))
                              .toList(),
                          decoration: const InputDecoration(
                              labelText: 'General Ward Quantity'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Doctor Charges Section
              ExpansionTile(
                title: _buildSectionTitle('Doctor Charges'),
                children: [
                  // ICU Visiting Section
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(_icuVisitingRateController,
                            'ICU Visiting Rate/Visit', TextInputType.number),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            DateTime? selectedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (selectedDate != null) {
                              _icuVisitingDateController.text =
                                  "${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year.toString().substring(2)}";
                            }
                          },
                          child: AbsorbPointer(
                            child: _buildTextField(_icuVisitingDateController,
                                'ICU Visiting Date', TextInputType.datetime),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _icuVisitingVisitsController.text.isNotEmpty
                              ? int.tryParse(_icuVisitingVisitsController.text)
                              : null,
                          onChanged: (value) {
                            if (value != null) {
                              _icuVisitingVisitsController.text =
                                  value.toString();
                            }
                          },
                          items: List.generate(10, (index) => index)
                              .map((quantity) => DropdownMenuItem<int>(
                                    value: quantity,
                                    child: Text(quantity.toString()),
                                  ))
                              .toList(),
                          decoration:
                              const InputDecoration(labelText: 'ICU Visits'),
                        ),
                      ),
                    ],
                  ),

                  // General Visiting Section
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                            _generalVisitingRateController,
                            'General Visiting Rate/Visit',
                            TextInputType.number),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            DateTime? selectedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (selectedDate != null) {
                              _generalVisitingDateController.text =
                                  "${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year.toString().substring(2)}";
                            }
                          },
                          child: AbsorbPointer(
                            child: _buildTextField(
                                _generalVisitingDateController,
                                'General Visiting Date',
                                TextInputType.datetime),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value:
                              _generalVisitingVisitsController.text.isNotEmpty
                                  ? int.tryParse(
                                      _generalVisitingVisitsController.text)
                                  : null,
                          onChanged: (value) {
                            if (value != null) {
                              _generalVisitingVisitsController.text =
                                  value.toString();
                            }
                          },
                          items: List.generate(10, (index) => index)
                              .map((quantity) => DropdownMenuItem<int>(
                                    value: quantity,
                                    child: Text(quantity.toString()),
                                  ))
                              .toList(),
                          decoration: const InputDecoration(
                              labelText: 'General Visits'),
                        ),
                      ),
                    ],
                  ),

                  // External Visiting Section
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                            _externalVisitingRateController,
                            'External Visiting Rate/Visit',
                            TextInputType.number),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            DateTime? selectedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (selectedDate != null) {
                              _externalVisitingDateController.text =
                                  "${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year.toString().substring(2)}";
                            }
                          },
                          child: AbsorbPointer(
                            child: _buildTextField(
                                _externalVisitingDateController,
                                'External Visiting Date',
                                TextInputType.datetime),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value:
                              _externalVisitingVisitsController.text.isNotEmpty
                                  ? int.tryParse(
                                      _externalVisitingVisitsController.text)
                                  : null,
                          onChanged: (value) {
                            if (value != null) {
                              _externalVisitingVisitsController.text =
                                  value.toString();
                            }
                          },
                          items: List.generate(10, (index) => index)
                              .map((quantity) => DropdownMenuItem<int>(
                                    value: quantity,
                                    child: Text(quantity.toString()),
                                  ))
                              .toList(),
                          decoration: const InputDecoration(
                              labelText: 'External Visits'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Procedure Charges Section
              ExpansionTile(
                title: _buildSectionTitle('Procedure Charges'),
                children: [
                  _buildTextField(_oxygenRateController, 'Oxygen Rate/Unit',
                      TextInputType.number),
                  _buildTextField(_oxygenQuantityController, 'Oxygen Quantity',
                      TextInputType.number),
                  _buildTextField(_oxygenDateController, 'Oxygen Date',
                      TextInputType.datetime),
                ],
              ),

              // Investigation Charges Section
              ExpansionTile(
                title: _buildSectionTitle('Investigation Charges'),
                children: [
                  // ECG Section
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(_ecgRateController,
                            'ECG Rate/Test', TextInputType.number),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            DateTime? selectedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (selectedDate != null) {
                              _ecgDateController.text =
                                  "${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year.toString().substring(2)}";
                            }
                          },
                          child: AbsorbPointer(
                            child: _buildTextField(_ecgDateController,
                                'ECG Date', TextInputType.datetime),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _ecgQuantityController.text.isNotEmpty
                              ? int.tryParse(_ecgQuantityController.text)
                              : null,
                          onChanged: (value) {
                            if (value != null) {
                              _ecgQuantityController.text = value.toString();
                            }
                          },
                          items: List.generate(10, (index) => index)
                              .map((quantity) => DropdownMenuItem<int>(
                                    value: quantity,
                                    child: Text(quantity.toString()),
                                  ))
                              .toList(),
                          decoration:
                              const InputDecoration(labelText: 'ECG Quantity'),
                        ),
                      ),
                    ],
                  ),

                  // X-Ray Section
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(_xrayRateController,
                            'X-Ray Rate/Test', TextInputType.number),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            DateTime? selectedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (selectedDate != null) {
                              _xrayDateController.text =
                                  "${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year.toString().substring(2)}";
                            }
                          },
                          child: AbsorbPointer(
                            child: _buildTextField(_xrayDateController,
                                'X-Ray Date', TextInputType.datetime),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _xrayQuantityController.text.isNotEmpty
                              ? int.tryParse(_xrayQuantityController.text)
                              : null,
                          onChanged: (value) {
                            if (value != null) {
                              _xrayQuantityController.text = value.toString();
                            }
                          },
                          items: List.generate(10, (index) => index)
                              .map((quantity) => DropdownMenuItem<int>(
                                    value: quantity,
                                    child: Text(quantity.toString()),
                                  ))
                              .toList(),
                          decoration: const InputDecoration(
                              labelText: 'X-Ray Quantity'),
                        ),
                      ),
                    ],
                  ),

                  // CT Scan Section
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(_ctScanRateController,
                            'CT Scan Rate/Test', TextInputType.number),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            DateTime? selectedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (selectedDate != null) {
                              _ctScanDateController.text =
                                  "${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year.toString().substring(2)}";
                            }
                          },
                          child: AbsorbPointer(
                            child: _buildTextField(_ctScanDateController,
                                'CT Scan Date', TextInputType.datetime),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _ctScanQuantityController.text.isNotEmpty
                              ? int.tryParse(_ctScanQuantityController.text)
                              : null,
                          onChanged: (value) {
                            if (value != null) {
                              _ctScanQuantityController.text = value.toString();
                            }
                          },
                          items: List.generate(10, (index) => index)
                              .map((quantity) => DropdownMenuItem<int>(
                                    value: quantity,
                                    child: Text(quantity.toString()),
                                  ))
                              .toList(),
                          decoration: const InputDecoration(
                              labelText: 'CT Scan Quantity'),
                        ),
                      ),
                    ],
                  ),

                  // Sonography Section
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(_sonographyRateController,
                            'Sonography Rate/Test', TextInputType.number),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            DateTime? selectedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (selectedDate != null) {
                              _sonographyDateController.text =
                                  "${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year.toString().substring(2)}";
                            }
                          },
                          child: AbsorbPointer(
                            child: _buildTextField(_sonographyDateController,
                                'Sonography Date', TextInputType.datetime),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _sonographyQuantityController.text.isNotEmpty
                              ? int.tryParse(_sonographyQuantityController.text)
                              : null,
                          onChanged: (value) {
                            if (value != null) {
                              _sonographyQuantityController.text =
                                  value.toString();
                            }
                          },
                          items: List.generate(10, (index) => index + 1)
                              .map((quantity) => DropdownMenuItem<int>(
                                    value: quantity,
                                    child: Text(quantity.toString()),
                                  ))
                              .toList(),
                          decoration: const InputDecoration(
                              labelText: 'Sonography Quantity'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Medicine Charges Section
              ExpansionTile(
                title: _buildSectionTitle('Medicine Charges'),
                children: [
                  _buildTextField(_medicineTotalController,
                      'Medicine Charges Total', TextInputType.number),
                ],
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final billData = {
                      "patientId": widget.patientId,
                      "bedCharges": {
                        "icu": {
                          "ratePerDay": _icuRateController.text.isNotEmpty
                              ? int.parse(_icuRateController.text)
                              : 0,
                          "quantity": _icuQuantityController.text.isNotEmpty
                              ? int.parse(_icuQuantityController.text)
                              : 0,
                          "date": _icuDateController.text,
                        },
                        "singleAc": {
                          "ratePerDay": _singleAcRateController.text.isNotEmpty
                              ? int.parse(_singleAcRateController.text)
                              : 0,
                          "quantity":
                              _singleAcQuantityController.text.isNotEmpty
                                  ? int.parse(_singleAcQuantityController.text)
                                  : 0,
                          "date": _singleAcDateController.text,
                        },
                        "singleRoom": {
                          "ratePerDay":
                              _singleRoomRateController.text.isNotEmpty
                                  ? int.parse(_singleRoomRateController.text)
                                  : 0,
                          "quantity": _singleRoomQuantityController
                                  .text.isNotEmpty
                              ? int.parse(_singleRoomQuantityController.text)
                              : 0,
                          "date": _singleRoomDateController.text,
                        },
                        "generalWard": {
                          "ratePerDay":
                              _generalWardRateController.text.isNotEmpty
                                  ? int.parse(_generalWardRateController.text)
                                  : 0,
                          "quantity": _generalWardQuantityController
                                  .text.isNotEmpty
                              ? int.parse(_generalWardQuantityController.text)
                              : 0,
                          "date": _generalWardDateController.text,
                        },
                      },
                      "doctorCharges": {
                        "icuVisiting": {
                          "ratePerVisit":
                              _icuVisitingRateController.text.isNotEmpty
                                  ? int.parse(_icuVisitingRateController.text)
                                  : 0,
                          "visits": _icuVisitingVisitsController.text.isNotEmpty
                              ? int.parse(_icuVisitingVisitsController.text)
                              : 0,
                          "date": _icuVisitingDateController.text,
                        },
                        "generalVisiting": {
                          "ratePerVisit": _generalVisitingRateController
                                  .text.isNotEmpty
                              ? int.parse(_generalVisitingRateController.text)
                              : 0,
                          "visits": _generalVisitingVisitsController
                                  .text.isNotEmpty
                              ? int.parse(_generalVisitingVisitsController.text)
                              : 0,
                          "date": _generalVisitingDateController.text,
                        },
                        "externalVisiting": {
                          "ratePerVisit": _externalVisitingRateController
                                  .text.isNotEmpty
                              ? int.parse(_externalVisitingRateController.text)
                              : 0,
                          "visits":
                              _externalVisitingVisitsController.text.isNotEmpty
                                  ? int.parse(
                                      _externalVisitingVisitsController.text)
                                  : 0,
                          "date": _externalVisitingDateController.text,
                        },
                      },
                      "procedureCharges": {
                        "oxygen": {
                          "ratePerUnit": _oxygenRateController.text.isNotEmpty
                              ? int.parse(_oxygenRateController.text)
                              : 0,
                          "quantity": _oxygenQuantityController.text.isNotEmpty
                              ? int.parse(_oxygenQuantityController.text)
                              : 0,
                          "date": _oxygenDateController.text,
                        },
                      },
                      "investigationCharges": {
                        "ecg": {
                          "ratePerTest": _ecgRateController.text.isNotEmpty
                              ? int.parse(_ecgRateController.text)
                              : 0,
                          "quantity": _ecgQuantityController.text.isNotEmpty
                              ? int.parse(_ecgQuantityController.text)
                              : 0,
                          "date": _ecgDateController.text,
                        },
                        "xray": {
                          "ratePerTest": _xrayRateController.text.isNotEmpty
                              ? int.parse(_xrayRateController.text)
                              : 0,
                          "quantity": _xrayQuantityController.text.isNotEmpty
                              ? int.parse(_xrayQuantityController.text)
                              : 0,
                          "date": _xrayDateController.text,
                        },
                        "ctScan": {
                          "ratePerTest": _ctScanRateController.text.isNotEmpty
                              ? int.parse(_ctScanRateController.text)
                              : 0,
                          "quantity": _ctScanQuantityController.text.isNotEmpty
                              ? int.parse(_ctScanQuantityController.text)
                              : 0,
                          "date": _ctScanDateController.text,
                        },
                        "sonography": {
                          "ratePerTest":
                              _sonographyRateController.text.isNotEmpty
                                  ? int.parse(_sonographyRateController.text)
                                  : 0,
                          "quantity": _sonographyQuantityController
                                  .text.isNotEmpty
                              ? int.parse(_sonographyQuantityController.text)
                              : 0,
                          "date": _sonographyDateController.text,
                        },
                      },
                      "medicineCharges": {
                        "total": _medicineTotalController.text.isNotEmpty
                            ? int.parse(_medicineTotalController.text)
                            : 0,
                      },
                      "status": "discharged",
                    };
                    ref.read(billProvider.notifier).generateBill(billData);
                  }
                },
                child: const Text('Submit'),
              ),
              const SizedBox(height: 20),
              billState.when(
                data: (response) => _buildBillResponse(response, context),
                loading: () => const CircularProgressIndicator(),
                error: (error, stackTrace) => Text('Error: $error'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      TextInputType keyboardType) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: keyboardType,
        // validator: (value) => _validateNumber(value),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String? _validateNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // No error for empty input
    }
    final number = int.tryParse(value);
    if (number == null) {
      return 'Enter a valid number';
    }
    return null;
  }
}

Widget _buildBillResponse(Map<String, dynamic> response, BuildContext context) {
  final billDetails = response['billDetails'] ?? {};
  final fileLink = response['fileLink'] ?? '';
  print("this os it $fileLink");
  if (billDetails.isEmpty) {
    return const Text(
      'No bill details available.',
      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
    );
  }
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16.0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (response != null) ...[
        Text(
          response['message'] ?? '',
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
        ),
        const SizedBox(height: 20),
        if (response['billDetails'] != null) ...[
          Text('Patient Details',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          Text('Name: ${response['billDetails']['name']}'),
          Text('Patient ID: ${response['billDetails']['patientId']}'),
          Text('Gender: ${response['billDetails']['gender']}'),
          Text('Contact: ${response['billDetails']['contact']}'),
          Text('Weight: ${response['billDetails']['weight']}'),
          Text('Age: ${response['billDetails']['age']}'),
          Text('Admission Date: ${response['billDetails']['admissionDate']}'),
          Text('Discharge Date: ${response['billDetails']['dischargeDate']}'),
          Text(
              'Reason for Admission: ${response['billDetails']['reasonForAdmission']}'),
          Text(
              'Condition at Discharge: ${response['billDetails']['conditionAtDischarge']}'),
          const SizedBox(height: 20),
          Text('Doctor: ${response['billDetails']['doctorName']}'),
          const SizedBox(height: 20),
          Text('Charges Breakdown',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          Text('Bed Charges',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text('ICU: ${response['billDetails']['bedCharges']['icu']['total']}'),
          Text(
              'Single AC: ${response['billDetails']['bedCharges']['singleAc']['total']}'),
          Text(
              'Total Bed Charges: ${response['billDetails']['bedCharges']['total']}'),
          const Divider(),
          Text('Procedure Charges',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(
              'Oxygen: ${response['billDetails']['procedureCharges']['oxygen']['total']}'),
          Text(
              'Total Procedure Charges: ${response['billDetails']['procedureCharges']['total']}'),
          const Divider(),
          Text('Doctor Charges',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(
              'ICU Visiting: ${response['billDetails']['doctorCharges']['icuVisiting']['total']}'),
          Text(
              'General Visiting: ${response['billDetails']['doctorCharges']['generalVisiting']['total']}'),
          Text(
              'Total Doctor Charges: ${response['billDetails']['doctorCharges']['total']}'),
          const Divider(),
          Text('Investigation Charges',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(
              'ECG: ${response['billDetails']['investigationCharges']['ecg']['total']}'),
          Text(
              'X-Ray: ${response['billDetails']['investigationCharges']['xray']['total']}'),
          Text(
              'Total Investigation Charges: ${response['billDetails']['investigationCharges']['total']}'),
          const Divider(),
          Text(
              'Medicine Charges: ${response['billDetails']['medicineCharges']['total']}'),
          const Divider(),
          Text(
              'Total Amount Due: ${response['billDetails']['totalAmountDue']}'),
          Text('Amount Paid: ${response['billDetails']['amountPaid']}'),
          Text(
              'Remaining Balance: ${response['billDetails']['remainingBalance']}'),
          Text(
              'Discharge Status: ${response['billDetails']['dischargeStatus']}'),
          Text('Payment Mode: ${response['billDetails']['paymentMode']}'),
          Text(
              'Insurance Company: ${response['billDetails']['insuranceCompany']}'),
          Text(
              'Condition at Discharge Point: ${response['billDetails']['conditionAtDischargePoint']}'),
        ],
        if (response != null && response['fileLink'] != null) ...[
          const SizedBox(height: 20),
          Text('PDF Link: ${response['fileLink']}',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            Methods().openPdf(fileLink);
          },
          child: const Text('Download Bill PDF'),
        ),
      ],
    ]),
  );
}

Widget _buildChargeDetails(String title, Map<String, dynamic> charges) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      Text('Start Date: ${charges['startDate']}'),
      Text('End Date: ${charges['endDate']}'),
      Text('Rate Per Day: ${charges['ratePerDay']}'),
      Text('Total: ${charges['total']}'),
      const SizedBox(height: 10),
    ],
  );
}

Future<void> downloadFile(
    String url, String fileName, BuildContext context) async {
  try {
    // Extract the file ID from the Google Drive URL
    final fileId = extractFileIdFromUrl(url);
    if (fileId == null) {
      throw Exception('Invalid Google Drive URL');
    }

    // Construct the direct download URL
    final directUrl = 'https://drive.google.com/uc?id=$fileId&export=download';

    // Send GET request to fetch file
    final response = await http.get(Uri.parse(directUrl));

    if (response.statusCode == 200) {
      // Get the local directory for downloads
      final directory = await getDownloadsDirectory();

      if (directory != null) {
        // Construct the file path in the downloads directory
        final filePath = '${directory.path}/$fileName';

        // Write the file to the specified location
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File downloaded: $filePath')),
        );
      } else {
        throw Exception('Unable to find downloads directory');
      }
    } else {
      throw Exception(
          'Failed to download file. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print("Error: $e");

    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error downloading file: $e')),
    );
  }
}

// Function to extract the file ID from a Google Drive URL
String? extractFileIdFromUrl(String url) {
  final regex = RegExp(r'/d/([a-zA-Z0-9_-]+)');
  final match = regex.firstMatch(url);
  return match?.group(1); // Return the file ID or null if not found
}
