// screens/auth/agency_register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/auth_service.dart';
import '../../models/travel_agency_model.dart';
import 'otp_verification_screen.dart';

class AgencyRegisterScreen extends StatefulWidget {
  const AgencyRegisterScreen({super.key});

  @override
  State<AgencyRegisterScreen> createState() => _AgencyRegisterScreenState();
}

class _AgencyRegisterScreenState extends State<AgencyRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Step 1: Basic Info
  final _agencyNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _ownerPhoneController = TextEditingController();

  // Step 2: Business Details
  final _officeAddressController = TextEditingController();
  final _officePhoneController = TextEditingController();
  final _businessLicenseController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _websiteController = TextEditingController();

  // Step 3: Financial
  final _bankAccountHolderController = TextEditingController();
  final _bankAccountNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _branchNameController = TextEditingController();

  // Step 4: Credentials
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _agreeToTerms = false;

  final Map<String, String> _documentUrls = {};

  @override
  void dispose() {
    _agencyNameController.dispose();
    _ownerNameController.dispose();
    _ownerEmailController.dispose();
    _ownerPhoneController.dispose();
    _officeAddressController.dispose();
    _officePhoneController.dispose();
    _businessLicenseController.dispose();
    _taxIdController.dispose();
    _websiteController.dispose();
    _bankAccountHolderController.dispose();
    _bankAccountNumberController.dispose();
    _bankNameController.dispose();
    _branchNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateStep1() {
    return _agencyNameController.text.isNotEmpty &&
        _ownerNameController.text.isNotEmpty &&
        _ownerEmailController.text.isNotEmpty &&
        _ownerPhoneController.text.isNotEmpty &&
        _ownerEmailController.text.contains('@');
  }

  bool _validateStep2() {
    return _officeAddressController.text.isNotEmpty &&
        _businessLicenseController.text.isNotEmpty &&
        _taxIdController.text.isNotEmpty;
  }

  bool _validateStep3() {
    return _bankAccountHolderController.text.isNotEmpty &&
        _bankAccountNumberController.text.isNotEmpty &&
        _bankNameController.text.isNotEmpty;
  }

  bool _validateStep4() {
    if (_passwordController.text.length < 8) return false;
    if (!_passwordController.text.contains(RegExp(r'[A-Z]'))) return false;
    if (!_passwordController.text.contains(RegExp(r'[0-9]'))) return false;
    if (_passwordController.text != _confirmPasswordController.text) {
      return false;
    }
    return _agreeToTerms;
  }

  Future<void> _handleRegisterAgency() async {
    if (!_validateStep4()) {
      _showErrorDialog('Please complete all required fields correctly');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = AgencyRegistrationRequest(
        agencyName: _agencyNameController.text.trim(),
        ownerFullName: _ownerNameController.text.trim(),
        ownerEmail: _ownerEmailController.text.trim(),
        ownerPhone: _ownerPhoneController.text.trim(),
        password: _passwordController.text.trim(),
        officeAddress: _officeAddressController.text.trim(),
        officePhone: _officePhoneController.text.trim(),
        businessLicenseNumber: _businessLicenseController.text.trim(),
        taxId: _taxIdController.text.trim(),
        websiteUrl: _websiteController.text.trim(),
        bankAccountHolder: _bankAccountHolderController.text.trim(),
        bankAccountNumber: _bankAccountNumberController.text.trim(),
        bankName: _bankNameController.text.trim(),
        branchName: _branchNameController.text.trim(),
      );

      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.registerAgency(
        request: request,
        documentUrls: _documentUrls,
      );

      if (!mounted) return;

      //  UPDATED: Better dialog message
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text(' Registration Successful!'),
          content: const Text(
            'Your agency account has been created successfully.\n\n'
            'An OTP has been sent to your email address.\n\n'
            'Please verify your email with the OTP to complete the setup and log in.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OtpVerificationScreen(),
                  ),
                );
              },
              child: const Text('Verify OTP'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(_extractErrorMessage(e.toString()));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _extractErrorMessage(String error) {
    return error
        .replaceAll('Exception: ', '')
        .replaceAll('Agency registration error: ', '');
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: !_isLoading
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: themeProvider.accentColor,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          'Agency Registration',
          style: TextStyle(
            color: themeProvider.accentColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 3) {
            setState(() => _currentStep++);
          } else if (_currentStep == 3) {
            _handleRegisterAgency();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          }
        },
        steps: [
          // Step 1: Basic Information
          Step(
            title: const Text('Basic Info'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0
                ? StepState.complete
                : (_validateStep1() ? StepState.complete : StepState.indexed),
            content: _buildStep1(),
          ),
          // Step 2: Business Details
          Step(
            title: const Text('Business Details'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1
                ? StepState.complete
                : (_validateStep2() ? StepState.complete : StepState.indexed),
            content: _buildStep2(),
          ),
          // Step 3: Financial Information
          Step(
            title: const Text('Financial Info'),
            isActive: _currentStep >= 2,
            state: _currentStep > 2
                ? StepState.complete
                : (_validateStep3() ? StepState.complete : StepState.indexed),
            content: _buildStep3(),
          ),
          // Step 4: Credentials & Documents
          Step(
            title: const Text('Credentials'),
            isActive: _currentStep >= 3,
            content: _buildStep4(),
          ),
        ],
      ),
    );
  }

  // ===================== STEP 1 =====================
  Widget _buildStep1() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Tell us about your agency',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _agencyNameController,
          label: 'Agency Name',
          hint: 'Your official agency name',
          icon: Icons.business,
          themeProvider: themeProvider,
          isDark: isDark,
        ),
        const SizedBox(height: 15),
        _buildTextField(
          controller: _ownerNameController,
          label: 'Owner Full Name',
          hint: 'Your full name',
          icon: Icons.person,
          themeProvider: themeProvider,
          isDark: isDark,
        ),
        const SizedBox(height: 15),
        _buildTextField(
          controller: _ownerEmailController,
          label: 'Email Address',
          hint: 'your@email.com',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          themeProvider: themeProvider,
          isDark: isDark,
        ),
        const SizedBox(height: 15),
        _buildTextField(
          controller: _ownerPhoneController,
          label: 'Phone Number',
          hint: '+880 1XXXXXXXXX',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          themeProvider: themeProvider,
          isDark: isDark,
        ),
      ],
    );
  }

  // ===================== STEP 2 =====================
  Widget _buildStep2() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Business Information',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _officeAddressController,
          label: 'Office Address *',
          hint: 'Full office address',
          icon: Icons.location_on,
          maxLines: 2,
          themeProvider: themeProvider,
          isDark: isDark,
        ),
        const SizedBox(height: 15),
        _buildTextField(
          controller: _officePhoneController,
          label: 'Office Phone',
          hint: '+880 XXX XXXXXXX',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          themeProvider: themeProvider,
          isDark: isDark,
        ),
        const SizedBox(height: 15),
        _buildTextField(
          controller: _businessLicenseController,
          label: 'Business License Number *',
          hint: 'License/Registration number',
          icon: Icons.description,
          themeProvider: themeProvider,
          isDark: isDark,
        ),
        const SizedBox(height: 15),
        _buildTextField(
          controller: _taxIdController,
          label: 'Tax ID *',
          hint: 'Tax ID number',
          icon: Icons.card_membership,
          themeProvider: themeProvider,
          isDark: isDark,
        ),
        const SizedBox(height: 15),
        _buildTextField(
          controller: _websiteController,
          label: 'Website (Optional)',
          hint: 'https://youragency.com',
          icon: Icons.language,
          keyboardType: TextInputType.url,
          themeProvider: themeProvider,
          isDark: isDark,
        ),
      ],
    );
  }

  // ===================== STEP 3 =====================
  Widget _buildStep3() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Bank Account Information',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _bankAccountHolderController,
          label: 'Account Holder Name *',
          hint: 'Name as shown in bank',
          icon: Icons.person,
          themeProvider: themeProvider,
          isDark: isDark,
        ),
        const SizedBox(height: 15),
        _buildTextField(
          controller: _bankAccountNumberController,
          label: 'Account Number *',
          hint: 'Bank account number',
          icon: Icons.account_balance,
          keyboardType: TextInputType.number,
          themeProvider: themeProvider,
          isDark: isDark,
        ),
        const SizedBox(height: 15),
        _buildTextField(
          controller: _bankNameController,
          label: 'Bank Name *',
          hint: 'Name of your bank',
          icon: Icons.business,
          themeProvider: themeProvider,
          isDark: isDark,
        ),
        const SizedBox(height: 15),
        _buildTextField(
          controller: _branchNameController,
          label: 'Branch Name',
          hint: 'Bank branch name',
          icon: Icons.location_on,
          themeProvider: themeProvider,
          isDark: isDark,
        ),
      ],
    );
  }

  // ===================== STEP 4 =====================
  Widget _buildStep4() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Create Your Credentials',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Password Field
          Text(
            'Password *',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            enabled: !_isLoading,
            obscureText: !_showPassword,
            decoration: InputDecoration(
              hintText: 'At least 8 characters',
              prefixIcon: Icon(
                Icons.lock_outline,
                color: themeProvider.accentColor,
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => _showPassword = !_showPassword);
                },
                icon: Icon(
                  _showPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: themeProvider.accentColor,
                ),
              ),
              filled: true,
              fillColor: isDark ? Colors.white10 : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Must be 8+ chars with uppercase and number',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Confirm Password Field
          Text(
            'Confirm Password *',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmPasswordController,
            enabled: !_isLoading,
            obscureText: !_showConfirmPassword,
            decoration: InputDecoration(
              hintText: 'Confirm your password',
              prefixIcon: Icon(
                Icons.lock_outline,
                color: themeProvider.accentColor,
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => _showConfirmPassword = !_showConfirmPassword);
                },
                icon: Icon(
                  _showConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: themeProvider.accentColor,
                ),
              ),
              filled: true,
              fillColor: isDark ? Colors.white10 : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 25),

          // Terms Checkbox
          CheckboxListTile(
            enabled: !_isLoading,
            value: _agreeToTerms,
            onChanged: (value) {
              setState(() => _agreeToTerms = value ?? false);
            },
            title: const Text(
              'I agree to Terms of Service and Privacy Policy',
              style: TextStyle(fontSize: 12),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: Colors.green,
          ),

          const SizedBox(height: 25),

          // Info Box - UPDATED
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: themeProvider.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: themeProvider.accentColor.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: themeProvider.accentColor,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'What Happens Next',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _infoPoint('Account created successfully'),
                _infoPoint('OTP sent to your email'),
                _infoPoint('Verify OTP to unlock your account'),
                _infoPoint('Log in with your credentials'),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ThemeProvider themeProvider,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: !_isLoading,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              color: themeProvider.accentColor,
            ),
            filled: true,
            fillColor: isDark ? Colors.white10 : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: themeProvider.accentColor,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
