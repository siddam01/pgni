import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class OwnerRegistrationScreen extends StatefulWidget {
  @override
  _OwnerRegistrationScreenState createState() =>
      _OwnerRegistrationScreenState();
}

class _OwnerRegistrationScreenState extends State<OwnerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _termsAccepted = false;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _gstinController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessAddressController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    super.dispose();
  }

  // Validate GSTIN format
  bool _validateGSTIN(String gstin) {
    final gstinRegex =
        RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
    return gstinRegex.hasMatch(gstin);
  }

  // Validate PAN format
  bool _validatePAN(String pan) {
    final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
    return panRegex.hasMatch(pan);
  }

  Future<void> _registerOwner() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_termsAccepted) {
      showErrorDialog(context, 'Please accept Terms & Conditions');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      showErrorDialog(context, 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await api(
          'onboarding/register',
          {
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': _phoneController.text.trim(),
            'password': _passwordController.text,
            'gstin': _gstinController.text.trim().toUpperCase(),
            'pan': _panController.text.trim().toUpperCase(),
            'business_name': _businessNameController.text.trim(),
            'business_address': _businessAddressController.text.trim(),
          },
          context,
          'POST');

      if (response['meta']['code'] == '201') {
        final adminId = response['data']['admin_id'];

        showSuccessDialog(context, 'Registration successful!', () {
          // Navigate to property setup screen
          Navigator.pushReplacementNamed(
            context,
            '/property-setup',
            arguments: {'admin_id': adminId},
          );
        });
      } else {
        showErrorDialog(context, response['meta']['message']);
      }
    } catch (e) {
      showErrorDialog(context, 'Registration failed: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ModalProgressHUD(
        inAsyncCall: _isLoading,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue[700]!,
                Colors.blue[500]!,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 500),
                    padding: EdgeInsets.all(32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo and Title
                          Icon(
                            Icons.business,
                            size: 64,
                            color: Colors.blue[700],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'PG Owner Registration',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Start managing your properties today',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 32),

                          // Personal Information
                          Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 16),

                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Full Name *',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Name is required';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),

                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email *',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email is required';
                              }
                              if (!value.contains('@')) {
                                return 'Enter valid email';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),

                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            decoration: InputDecoration(
                              labelText: 'Phone Number *',
                              prefixIcon: Icon(Icons.phone),
                              border: OutlineInputBorder(),
                              counterText: '',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Phone is required';
                              }
                              if (value.length != 10) {
                                return 'Enter 10 digit phone number';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 24),

                          // Business Information
                          Text(
                            'Business Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 16),

                          TextFormField(
                            controller: _businessNameController,
                            decoration: InputDecoration(
                              labelText: 'Business Name *',
                              prefixIcon: Icon(Icons.store),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Business name is required';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),

                          TextFormField(
                            controller: _gstinController,
                            maxLength: 15,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              labelText: 'GSTIN *',
                              prefixIcon: Icon(Icons.receipt_long),
                              border: OutlineInputBorder(),
                              hintText: '22AAAAA0000A1Z5',
                              counterText: '',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'GSTIN is required';
                              }
                              if (!_validateGSTIN(value.toUpperCase())) {
                                return 'Invalid GSTIN format';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),

                          TextFormField(
                            controller: _panController,
                            maxLength: 10,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              labelText: 'PAN Card Number *',
                              prefixIcon: Icon(Icons.credit_card),
                              border: OutlineInputBorder(),
                              hintText: 'ABCDE1234F',
                              counterText: '',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'PAN is required';
                              }
                              if (!_validatePAN(value.toUpperCase())) {
                                return 'Invalid PAN format';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),

                          TextFormField(
                            controller: _businessAddressController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Business Address',
                              prefixIcon: Icon(Icons.location_on),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 24),

                          // Password
                          Text(
                            'Security',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 16),

                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password *',
                              prefixIcon: Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),

                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password *',
                              prefixIcon: Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Confirm password is required';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 24),

                          // Terms and Conditions
                          Row(
                            children: [
                              Checkbox(
                                value: _termsAccepted,
                                onChanged: (value) {
                                  setState(() {
                                    _termsAccepted = value ?? false;
                                  });
                                },
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _termsAccepted = !_termsAccepted;
                                    });
                                  },
                                  child: Text(
                                    'I accept the Terms & Conditions',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24),

                          // Register Button
                          ElevatedButton(
                            onPressed: _registerOwner,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.blue[700],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Register & Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: 16),

                          // Already have account
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('Already have an account? Login'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
