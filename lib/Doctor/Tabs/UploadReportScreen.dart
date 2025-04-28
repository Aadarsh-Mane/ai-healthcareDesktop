import 'dart:convert';
import 'dart:io';

import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:doctordesktop/constants/Url.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class UploadReportScreen extends StatefulWidget {
  final String investigationId;

  const UploadReportScreen({
    Key? key,
    required this.investigationId,
  }) : super(key: key);

  @override
  _UploadReportScreenState createState() => _UploadReportScreenState();
}

class _UploadReportScreenState extends State<UploadReportScreen> {
  // Form controllers
  final TextEditingController _performerNameController =
      TextEditingController();
  final TextEditingController _performerDesignationController =
      TextEditingController();
  final TextEditingController _facilityNameController = TextEditingController();
  final TextEditingController _findingsController = TextEditingController();
  final TextEditingController _impressionController = TextEditingController();
  final TextEditingController _recommendationsController =
      TextEditingController();
  final TextEditingController _costController = TextEditingController();

  // File handling
  File? _selectedFile;
  String? _selectedFileName;
  bool _isAbnormal = false;
  bool _isUploading = false;
  bool _isLoading = true;
  String? _uploadError;
  Map<String, dynamic>? _investigationDetails;

  // For normal ranges and numerical results
  final List<NormalRangeItem> _normalRanges = [
    NormalRangeItem(parameter: "WBC", normalRange: "4,500-11,000/μL"),
    NormalRangeItem(parameter: "RBC", normalRange: "4.5-5.9 million/μL"),
    NormalRangeItem(parameter: "Hemoglobin", normalRange: "13.5-17.5 g/dL"),
  ];

  final List<NumericalResultItem> _numericalResults = [
    NumericalResultItem(parameter: "WBC", value: ""),
    NumericalResultItem(parameter: "RBC", value: ""),
    NumericalResultItem(parameter: "Hemoglobin", value: ""),
  ];

  @override
  void initState() {
    super.initState();
    _fetchInvestigationDetails();
  }

  Future<void> _fetchInvestigationDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse(
            '${KVM_URL}/investigate/getInvestigationDetails/${widget.investigationId}'),
        // headers: {
        //   'Authorization': 'Bearer $token',
        //   'Content-Type': 'application/json',
        // },
      );
      print(response.body);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Handle the nested structure of the response
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];

          setState(() {
            _investigationDetails = data;

            // Pre-fill fields if the investigation has some results already
            if (data['results'] != null) {
              final results = data['results'];

              if (results['findings'] != null)
                _findingsController.text = results['findings'];
              if (results['impression'] != null)
                _impressionController.text = results['impression'];
              if (results['recommendations'] != null)
                _recommendationsController.text = results['recommendations'];
              if (results['isAbnormal'] != null)
                _isAbnormal = results['isAbnormal'];

              // Handle normal ranges if they exist
              if (results['normalRanges'] != null) {
                final ranges = results['normalRanges'] as Map<String, dynamic>;
                _normalRanges.clear();
                ranges.forEach((key, value) {
                  _normalRanges.add(NormalRangeItem(
                      parameter: key, normalRange: value.toString()));
                });
              }

              // Handle numerical results if they exist
              if (results['numericalResults'] != null) {
                final numbers =
                    results['numericalResults'] as Map<String, dynamic>;
                _numericalResults.clear();
                numbers.forEach((key, value) {
                  _numericalResults.add(NumericalResultItem(
                      parameter: key, value: value.toString()));
                });
              }
            }

            // Pre-fill other fields if they exist
            if (data['performedBy'] != null) {
              final performer = data['performedBy'];
              if (performer['name'] != null)
                _performerNameController.text = performer['name'];
              if (performer['designation'] != null)
                _performerDesignationController.text = performer['designation'];
              if (performer['facility'] != null)
                _facilityNameController.text = performer['facility'];
            }

            if (data['billing'] != null && data['billing']['cost'] != null) {
              _costController.text = data['billing']['cost'].toString();
            }
          });
        } else {
          _showErrorSnackBar('Invalid data format in response');
        }
      } else {
        _showErrorSnackBar('Failed to fetch investigation details');
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'docx', 'xlsx'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _selectedFileName = result.files.single.name;
        });
      }
    } on PlatformException catch (e) {
      _showErrorSnackBar('File picker error: ${e.message}');
    } catch (e) {
      _showErrorSnackBar('Unknown error: ${e.toString()}');
    }
  }

  Future<void> _uploadReport() async {
    // Validate the form
    if (_performerNameController.text.isEmpty) {
      _showErrorSnackBar('Performer name is required');
      return;
    }

    if (_performerDesignationController.text.isEmpty) {
      _showErrorSnackBar('Performer designation is required');
      return;
    }

    if (_facilityNameController.text.isEmpty) {
      _showErrorSnackBar('Facility name is required');
      return;
    }

    if (_findingsController.text.isEmpty) {
      _showErrorSnackBar('Findings are required');
      return;
    }

    if (_selectedFile == null) {
      _showErrorSnackBar('Please select a report file to upload');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadError = null;
    });

    try {
      // Prepare normal ranges and numerical results as JSON
      final Map<String, String> normalRangesMap = {};
      for (var item in _normalRanges) {
        if (item.parameter.isNotEmpty && item.normalRange.isNotEmpty) {
          normalRangesMap[item.parameter] = item.normalRange;
        }
      }

      final Map<String, dynamic> numericalResultsMap = {};
      for (var item in _numericalResults) {
        if (item.parameter.isNotEmpty && item.value.isNotEmpty) {
          // Try to parse as number, fallback to string if not possible
          try {
            numericalResultsMap[item.parameter] = double.parse(item.value);
          } catch (e) {
            numericalResultsMap[item.parameter] = item.value;
          }
        }
      }

      // Create multipart request
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
            '${KVM_URL}/investigate/${widget.investigationId}/upload-report'),
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Add text fields
      request.fields['performerName'] = _performerNameController.text;
      request.fields['performerDesignation'] =
          _performerDesignationController.text;
      request.fields['facilityName'] = _facilityNameController.text;
      request.fields['findings'] = _findingsController.text;
      request.fields['impression'] = _impressionController.text;
      request.fields['recommendations'] = _recommendationsController.text;
      request.fields['isAbnormal'] = _isAbnormal.toString();
      request.fields['normalRanges'] = json.encode(normalRangesMap);
      request.fields['numericalResults'] = json.encode(numericalResultsMap);

      if (_costController.text.isNotEmpty) {
        try {
          request.fields['cost'] = _costController.text;
        } catch (e) {
          _showErrorSnackBar('Invalid cost value');
          setState(() {
            _isUploading = false;
          });
          return;
        }
      }

      // Add file
      request.files.add(await http.MultipartFile.fromPath(
        'reportFile',
        _selectedFile!.path,
        filename: _selectedFileName,
      ));

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Navigate back after successful upload
        Navigator.of(context).pop(true);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _uploadError = 'Failed to upload report: ${response.body}';
        });
        _showErrorSnackBar(_uploadError!);
      }
    } catch (e) {
      setState(() {
        _uploadError = 'Error: ${e.toString()}';
      });
      _showErrorSnackBar(_uploadError!);
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _addNormalRangeField() {
    setState(() {
      _normalRanges.add(NormalRangeItem(parameter: '', normalRange: ''));
    });
  }

  void _removeNormalRangeField(int index) {
    setState(() {
      _normalRanges.removeAt(index);
    });
  }

  void _addNumericalResultField() {
    setState(() {
      _numericalResults.add(NumericalResultItem(parameter: '', value: ''));
    });
  }

  void _removeNumericalResultField(int index) {
    setState(() {
      _numericalResults.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: HospitalTheme.buildAppBar(
        context: context,
        title: 'Upload Investigation Report',
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
              child: Container(
                constraints: BoxConstraints(
                    maxWidth: isDesktop ? 1200 : double.infinity),
                margin: EdgeInsets.symmetric(horizontal: isDesktop ? 64.0 : 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Investigation details card
                    if (_investigationDetails != null)
                      _buildInvestigationDetailsCard(),
                    SizedBox(height: 24),

                    // Upload form
                    HospitalTheme.buildCard(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Form(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Report Details',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: HospitalTheme.primary,
                                ),
                              ),
                              SizedBox(height: 24),

                              // File upload section
                              _buildFileUploadSection(),
                              SizedBox(height: 32),

                              // Report sections - using responsive layout
                              isDesktop
                                  ? Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                            child: _buildPerformerSection()),
                                        SizedBox(width: 32),
                                        Expanded(
                                            child: _buildFindingsSection()),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        _buildPerformerSection(),
                                        SizedBox(height: 24),
                                        _buildFindingsSection(),
                                      ],
                                    ),
                              SizedBox(height: 32),

                              // Normal ranges and numerical results
                              isDesktop
                                  ? Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                            child: _buildNormalRangesSection()),
                                        SizedBox(width: 32),
                                        Expanded(
                                            child:
                                                _buildNumericalResultsSection()),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        _buildNormalRangesSection(),
                                        SizedBox(height: 24),
                                        _buildNumericalResultsSection(),
                                      ],
                                    ),
                              SizedBox(height: 32),

                              // Cost and submission
                              Row(
                                children: [
                                  Expanded(
                                    flex: isDesktop ? 1 : 2,
                                    child: _buildCostSection(),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    flex: isDesktop ? 3 : 2,
                                    child: _buildSubmitButton(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInvestigationDetailsCard() {
    return HospitalTheme.buildCard(
      hasShadow: true,
      backgroundColor: HospitalTheme.surfaceLight,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.science_outlined,
                  color: HospitalTheme.primary,
                  size: 28,
                ),
                SizedBox(width: 12),
                Text(
                  'Investigation Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 16),

            // Investigation details
            Wrap(
              spacing: 32,
              runSpacing: 16,
              children: [
                _buildInfoItem(
                  label: 'Investigation Type',
                  value: _investigationDetails!['investigationType'] == 'Other'
                      ? _investigationDetails!['otherInvestigationType'] ??
                          'Unknown'
                      : _investigationDetails!['investigationType'] ??
                          'Unknown',
                  icon: Icons.category_outlined,
                ),
                _buildInfoItem(
                  label: 'Patient ID',
                  value: _investigationDetails!['patientIdNumber'] ?? 'Unknown',
                  icon: Icons.person_outline,
                ),
                _buildInfoItem(
                  label: 'Patient Name',
                  value: _investigationDetails!['patientId'] != null &&
                          _investigationDetails!['patientId'] is Map
                      ? _investigationDetails!['patientId']['name'] ?? 'Unknown'
                      : 'Unknown',
                  icon: Icons.person,
                ),
                _buildInfoItem(
                  label: 'Ordered By',
                  value: _investigationDetails!['doctorName'] ?? 'Unknown',
                  icon: Icons.medical_services_outlined,
                ),
                _buildInfoItem(
                  label: 'Order Date',
                  value: _formatDate(_investigationDetails!['orderDate']),
                  icon: Icons.calendar_today_outlined,
                ),
                _buildInfoItem(
                  label: 'Scheduled Date',
                  value: _formatDate(_investigationDetails!['scheduledDate']),
                  icon: Icons.event,
                ),
                _buildInfoItem(
                  label: 'Status',
                  value: _investigationDetails!['status'] ?? 'Unknown',
                  icon: Icons.info_outline,
                ),
                _buildInfoItem(
                  label: 'Priority',
                  value: _investigationDetails!['priority'] ?? 'Routine',
                  icon: Icons.flag_outlined,
                ),
              ],
            ),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 16),

            // Additional information sections
            if (_investigationDetails!['reasonForInvestigation'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Reason: ${_investigationDetails!['reasonForInvestigation']}',
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: HospitalTheme.textMedium,
                  ),
                ),
              ),

            if (_investigationDetails!['clinicalHistory'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Clinical History: ${_investigationDetails!['clinicalHistory']}',
                  style: TextStyle(
                    fontSize: 16,
                    color: HospitalTheme.textMedium,
                  ),
                ),
              ),

            if (_investigationDetails!['tags'] != null &&
                _investigationDetails!['tags'] is List &&
                (_investigationDetails!['tags'] as List).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (_investigationDetails!['tags'] as List)
                      .map<Widget>((tag) {
                    return HospitalTheme.buildStatusBadge(
                      tag.toString(),
                      color: HospitalTheme.info,
                      outline: true,
                    );
                  }).toList(),
                ),
              ),

            if (_investigationDetails!['investigationDetails'] != null &&
                _investigationDetails!['investigationDetails']['parameters'] !=
                    null &&
                _investigationDetails!['investigationDetails']['parameters']
                    is List)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Parameters:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.textDark,
                      ),
                    ),
                    SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (_investigationDetails!['investigationDetails']
                              ['parameters'] as List)
                          .map<Widget>((param) {
                        return HospitalTheme.buildStatusBadge(
                          param.toString(),
                          color: HospitalTheme.medical,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      width: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: HospitalTheme.medical,
            size: 18,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: HospitalTheme.textMedium,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: HospitalTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildFileUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload Report File',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: HospitalTheme.textDark,
          ),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: HospitalTheme.surfaceLight.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: HospitalTheme.border),
          ),
          child: Column(
            children: [
              Icon(
                Icons.upload_file,
                size: 48,
                color: HospitalTheme.secondary,
              ),
              SizedBox(height: 16),
              Text(
                _selectedFileName ?? 'No file selected',
                style: TextStyle(
                  fontWeight: _selectedFile != null
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: _selectedFile != null
                      ? HospitalTheme.textDark
                      : HospitalTheme.textLight,
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                icon: Icon(Icons.attach_file),
                label: Text('Choose File'),
                onPressed: _pickFile,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Supported formats: PDF, JPG, PNG, DOCX, XLSX',
                style: TextStyle(
                  fontSize: 12,
                  color: HospitalTheme.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performer Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: HospitalTheme.textDark,
          ),
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _performerNameController,
          decoration: InputDecoration(
            labelText: 'Performer Name*',
            prefixIcon: Icon(Icons.person),
          ),
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _performerDesignationController,
          decoration: InputDecoration(
            labelText: 'Performer Designation*',
            prefixIcon: Icon(Icons.work),
          ),
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _facilityNameController,
          decoration: InputDecoration(
            labelText: 'Facility Name*',
            prefixIcon: Icon(Icons.business),
          ),
        ),
        SizedBox(height: 24),
        Row(
          children: [
            Checkbox(
              value: _isAbnormal,
              onChanged: (value) {
                setState(() {
                  _isAbnormal = value ?? false;
                });
              },
              activeColor: HospitalTheme.error,
            ),
            Text(
              'Mark results as abnormal',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color:
                    _isAbnormal ? HospitalTheme.error : HospitalTheme.textDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFindingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Clinical Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: HospitalTheme.textDark,
          ),
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _findingsController,
          decoration: InputDecoration(
            labelText: 'Findings*',
            prefixIcon: Icon(Icons.find_in_page),
            alignLabelWithHint: true,
          ),
          maxLines: 3,
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _impressionController,
          decoration: InputDecoration(
            labelText: 'Impression',
            prefixIcon: Icon(Icons.article),
            alignLabelWithHint: true,
          ),
          maxLines: 2,
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _recommendationsController,
          decoration: InputDecoration(
            labelText: 'Recommendations',
            prefixIcon: Icon(Icons.recommend),
            alignLabelWithHint: true,
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildNormalRangesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Normal Ranges',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
            IconButton(
              icon: Icon(Icons.add_circle, color: HospitalTheme.success),
              onPressed: _addNormalRangeField,
              tooltip: 'Add more normal ranges',
            ),
          ],
        ),
        SizedBox(height: 8),

        // List of normal range fields
        Container(
          decoration: BoxDecoration(
            color: HospitalTheme.surfaceLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: HospitalTheme.border),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _normalRanges.length,
            separatorBuilder: (context, index) => Divider(height: 1),
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: _normalRanges[index].parameter,
                        decoration: InputDecoration(
                          labelText: 'Parameter',
                          isDense: true,
                          contentPadding: EdgeInsets.all(12),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _normalRanges[index].parameter = value;
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        initialValue: _normalRanges[index].normalRange,
                        decoration: InputDecoration(
                          labelText: 'Normal Range',
                          isDense: true,
                          contentPadding: EdgeInsets.all(12),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _normalRanges[index].normalRange = value;
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: HospitalTheme.error),
                      onPressed: () => _removeNormalRangeField(index),
                      tooltip: 'Remove',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNumericalResultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Numerical Results',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: HospitalTheme.textDark,
              ),
            ),
            IconButton(
              icon: Icon(Icons.add_circle, color: HospitalTheme.success),
              onPressed: _addNumericalResultField,
              tooltip: 'Add more results',
            ),
          ],
        ),
        SizedBox(height: 8),

        // List of numerical result fields
        Container(
          decoration: BoxDecoration(
            color: HospitalTheme.surfaceLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: HospitalTheme.border),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _numericalResults.length,
            separatorBuilder: (context, index) => Divider(height: 1),
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: _numericalResults[index].parameter,
                        decoration: InputDecoration(
                          labelText: 'Parameter',
                          isDense: true,
                          contentPadding: EdgeInsets.all(12),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _numericalResults[index].parameter = value;
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        initialValue: _numericalResults[index].value,
                        decoration: InputDecoration(
                          labelText: 'Value',
                          isDense: true,
                          contentPadding: EdgeInsets.all(12),
                        ),
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        onChanged: (value) {
                          setState(() {
                            _numericalResults[index].value = value;
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: HospitalTheme.error),
                      onPressed: () => _removeNumericalResultField(index),
                      tooltip: 'Remove',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCostSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Billing Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: HospitalTheme.textDark,
          ),
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _costController,
          decoration: InputDecoration(
            labelText: 'Cost',
            prefixIcon: Icon(Icons.attach_money),
            helperText: 'Enter the cost of this investigation',
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Submit Report',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: HospitalTheme.textDark,
          ),
        ),
        SizedBox(height: 16),
        HospitalTheme.buildGradientButton(
          label: _isUploading ? 'Uploading...' : 'Upload Report',
          onPressed: _isUploading ? () {} : _uploadReport,
          icon: Icons.upload_file,
          isLoading: _isUploading,
          width: double.infinity,
          height: 54,
        ),
        if (_uploadError != null)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(
              _uploadError!,
              style: TextStyle(
                color: HospitalTheme.error,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }
}

// Model classes for form fields
class NormalRangeItem {
  String parameter;
  String normalRange;

  NormalRangeItem({
    required this.parameter,
    required this.normalRange,
  });
}

class NumericalResultItem {
  String parameter;
  String value;

  NumericalResultItem({
    required this.parameter,
    required this.value,
  });
}
