import 'dart:convert';

import 'package:doctordesktop/constants/Url.dart';
import 'package:doctordesktop/pharmacy/CreateSalesScreen.dart';
import 'package:doctordesktop/pharmacy/SalesHistoryScreen.dart';
import 'package:doctordesktop/pharmacy/pharmaTheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

// State class for Customer creation
class CustomerState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? createdCustomer;

  CustomerState({
    this.isLoading = false,
    this.error,
    this.createdCustomer,
  });

  CustomerState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? createdCustomer,
  }) {
    return CustomerState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      createdCustomer: createdCustomer ?? this.createdCustomer,
    );
  }
}

// Notifier for Customer state
class CustomerNotifier extends StateNotifier<CustomerState> {
  CustomerNotifier() : super(CustomerState());

  Future<void> createCustomer({
    required String name,
    required String contactNumber,
    String? email,
    String? address,
    required bool isPatient,
    required Function(Map<String, dynamic>) onSuccess,
    required Function(String) onError,
  }) async {
    // Validate inputs
    if (name.trim().isEmpty) {
      onError('Customer name is required');
      return;
    }

    if (contactNumber.trim().isEmpty) {
      onError('Contact number is required');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'name': name.trim(),
        'contactNumber': contactNumber.trim(),
        'isPatient': isPatient,
      };

      // Add optional fields if provided
      if (email != null && email.trim().isNotEmpty) {
        requestBody['email'] = email.trim();
      }

      if (address != null && address.trim().isNotEmpty) {
        requestBody['address'] = address.trim();
      }

      // Make API call
      final response = await http.post(
        Uri.parse('${KVM_URL}/pharma/createCustomer'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      // Debug log
      print(
          'Create customer response: ${response.statusCode} ${response.body}');

      // Handle response
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          state = state.copyWith(
            isLoading: false,
            createdCustomer: data['data'],
          );
          onSuccess(data['data']);
        } else {
          state = state.copyWith(
            isLoading: false,
            error: 'Failed to create customer',
          );
          onError('Failed to create customer');
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to create customer: ${response.statusCode}',
        );
        onError('Failed to create customer: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating customer: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error: $e',
      );
      onError('Error: $e');
    }
  }
}

// Provider for Customer state
final customerProvider =
    StateNotifierProvider<CustomerNotifier, CustomerState>((ref) {
  return CustomerNotifier();
});

class CreateCustomerScreen extends ConsumerStatefulWidget {
  const CreateCustomerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateCustomerScreen> createState() =>
      _CreateCustomerScreenState();
}

class _CreateCustomerScreenState extends ConsumerState<CreateCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isPatient = false;

  @override
  void dispose() {
    _nameController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: PharmaTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PharmaTheme.radiusS),
        ),
      ),
    );
  }

  // Create customer method
  void _createCustomer() {
    if (_formKey.currentState!.validate()) {
      ref.read(customerProvider.notifier).createCustomer(
            name: _nameController.text,
            contactNumber: _contactNumberController.text,
            email: _emailController.text.isEmpty ? null : _emailController.text,
            address: _addressController.text.isEmpty
                ? null
                : _addressController.text,
            isPatient: _isPatient,
            onSuccess: (customer) {
              // Navigate to CreateSaleScreen with customer data
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateSaleScreenWithCustomer(
                    customer: customer,
                  ),
                ),
              );
            },
            onError: _showErrorSnackBar,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(customerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Customer'),
        backgroundColor: PharmaTheme.primary,
        foregroundColor: PharmaTheme.textLight,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: PharmaTheme.background,
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(maxWidth: 600),
              margin: EdgeInsets.all(PharmaTheme.spacingL),
              padding: EdgeInsets.all(PharmaTheme.spacingL),
              decoration: BoxDecoration(
                color: PharmaTheme.surface,
                borderRadius: BorderRadius.circular(PharmaTheme.radiusM),
                boxShadow: PharmaTheme.shadowMedium,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Form header
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: PharmaTheme.primary.withOpacity(0.1),
                          radius: 20,
                          child: Icon(
                            Icons.person_add_alt_1,
                            color: PharmaTheme.primary,
                          ),
                        ),
                        SizedBox(width: PharmaTheme.spacingM),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer Information',
                              style: PharmaTheme.headingMedium,
                            ),
                            Text(
                              'Add a new customer to your pharmacy',
                              style: PharmaTheme.bodyMedium.copyWith(
                                color: PharmaTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: PharmaTheme.spacingL),

                    // Customer name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Customer Name *',
                        hintText: 'Enter full name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(PharmaTheme.radiusM),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Customer name is required';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: PharmaTheme.spacingM),

                    // Contact number
                    TextFormField(
                      controller: _contactNumberController,
                      decoration: InputDecoration(
                        labelText: 'Contact Number *',
                        hintText: 'Enter mobile number',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(PharmaTheme.radiusM),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Contact number is required';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: PharmaTheme.spacingM),

                    // Email (optional)
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email (Optional)',
                        hintText: 'Enter email address',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(PharmaTheme.radiusM),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),

                    SizedBox(height: PharmaTheme.spacingM),

                    // Address (optional)
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Address (Optional)',
                        hintText: 'Enter address',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(PharmaTheme.radiusM),
                        ),
                      ),
                      maxLines: 2,
                    ),

                    SizedBox(height: PharmaTheme.spacingM),

                    // Patient toggle
                    SwitchListTile(
                      title: Text('Is this customer a patient?'),
                      subtitle: Text(
                        'Toggle this if the customer is also a patient',
                        style: PharmaTheme.bodySmall.copyWith(
                          color: PharmaTheme.textSecondary,
                        ),
                      ),
                      value: _isPatient,
                      activeColor: PharmaTheme.accent,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        setState(() {
                          _isPatient = value;
                        });
                      },
                    ),

                    SizedBox(height: PharmaTheme.spacingL),

                    // Submit button
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: PharmaTheme.accent,
                              padding: EdgeInsets.symmetric(
                                vertical: PharmaTheme.spacingM,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(PharmaTheme.radiusM),
                              ),
                            ),
                            onPressed: customerState.isLoading
                                ? null
                                : _createCustomer,
                            child: customerState.isLoading
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: PharmaTheme.textLight,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.save),
                                      SizedBox(width: PharmaTheme.spacingXs),
                                      Text(
                                        'Save & Continue',
                                        style: PharmaTheme.bodyLarge.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: PharmaTheme.spacingM),

                    // Cancel button
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: PharmaTheme.spacingM,
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Wrapper class for CreateSaleScreen that auto-selects the customer
class CreateSaleScreenWithCustomer extends ConsumerStatefulWidget {
  final Map<String, dynamic> customer;

  const CreateSaleScreenWithCustomer({
    Key? key,
    required this.customer,
  }) : super(key: key);

  @override
  ConsumerState<CreateSaleScreenWithCustomer> createState() =>
      _CreateSaleScreenWithCustomerState();
}

class _CreateSaleScreenWithCustomerState
    extends ConsumerState<CreateSaleScreenWithCustomer> {
  @override
  void initState() {
    super.initState();

    // Initialize customer selection on the next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCustomer();
    });
  }

  Future<void> _initializeCustomer() async {
    // Wait for customers to be loaded
    await ref.read(createSaleProvider.notifier).fetchCustomers();

    // Set the selected customer
    ref
        .read(createSaleProvider.notifier)
        .setSelectedCustomer(widget.customer['_id']);

    // Show confirmation snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Customer "${widget.customer['name']}" has been added'),
            ],
          ),
          backgroundColor: PharmaTheme.success,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PharmaTheme.radiusS),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Return the regular CreateSaleScreen
    return CreateSaleScreen();
  }
}
