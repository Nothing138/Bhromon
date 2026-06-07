// screens/shop/checkout_page.dart
// ✅ সম্পূর্ণ FIXED VERSION - সব syntax error সমাধান করা

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../providers/theme_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/ssl_commerce_payment_service.dart';
import '../../services/order_service.dart';
import 'order_success_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  late SSLCommercePaymentService _paymentService;
  late OrderService _orderService;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    try {
      _paymentService = SSLCommercePaymentService();
      _orderService = OrderService();

      _paymentService.initialize(
        onSuccess: _handlePaymentSuccess,
        onFailure: _handlePaymentFailure,
      );
    } catch (e) {
      print('❌ Error initializing checkout: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    try {
      _paymentService.dispose();
    } catch (e) {
      print('Error disposing payment service: $e');
    }
    super.dispose();
  }

  Future<void> _handlePaymentSuccess(String transactionId) async {
    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      if (cartProvider.cartItems.isEmpty) {
        _showErrorDialog('Error', 'Cart is empty');
        return;
      }

      // Validate customer details
      if (_nameController.text.trim().isEmpty ||
          _emailController.text.trim().isEmpty ||
          _phoneController.text.trim().isEmpty ||
          _addressController.text.trim().isEmpty) {
        _showErrorDialog('Error', 'Please fill all fields');
        return;
      }

      final orderId = _paymentService.generateOrderId();

      // Create order in database
      final order = await _orderService.createOrder(
        orderId: orderId,
        items: cartProvider.cartItems,
        subtotal: cartProvider.subtotal,
        gst: cartProvider.gst,
        deliveryCharges: cartProvider.deliveryCharges,
        grandTotal: cartProvider.grandTotal,
        paymentId: transactionId,
        customerName: _nameController.text.trim(),
        customerEmail: _emailController.text.trim(),
        customerPhone: _phoneController.text.trim(),
        deliveryAddress: _addressController.text.trim(),
        userId: 'demo_user_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (order != null) {
        print('✅ Order created successfully: ${order.orderId}');
        // Clear cart
        cartProvider.clearCart();

        // Navigate to success page
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => OrderSuccessPage(order: order),
            ),
          );
        }
      } else {
        if (mounted) {
          _showErrorDialog(
            'Order Creation Failed',
            'Failed to create order. Please try again.',
          );
        }
      }
    } catch (e) {
      print('❌ Error handling payment success: $e');
      if (mounted) {
        _showErrorDialog('Error', 'An error occurred: $e');
      }
    }
  }

  void _handlePaymentFailure(String error) {
    print('❌ Payment failed: $error');

    // পেমেন্ট গেটওয়ে লিংক
    if (error.startsWith('PAYMENT_REDIRECT:')) {
      final redirectUrl = error.replaceFirst('PAYMENT_REDIRECT:', '');
      _openPaymentGateway(redirectUrl);
    } else {
      if (mounted) {
        _showErrorDialog('Payment Failed', error);
      }
    }
  }

  void _openPaymentGateway(String paymentUrl) {
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentWebView(
          paymentUrl: paymentUrl,
          onPaymentSuccess: () {
            Navigator.pop(context);
            _handlePaymentSuccess('verified');
          },
          onPaymentFailed: () {
            Navigator.pop(context);
            _showErrorDialog('Payment Failed', 'Payment was not completed');
          },
        ),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (title == 'Order Creation Failed') {
                setState(() => _isProcessing = false);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _processPayment() {
    if (!_formKey.currentState!.validate()) {
      _showErrorDialog('Validation Error', 'Please fill all fields correctly');
      return;
    }

    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // Additional validation
    if (cartProvider.cartItems.isEmpty) {
      _showErrorDialog('Empty Cart', 'Please add items to cart');
      return;
    }

    if (cartProvider.grandTotal <= 0) {
      _showErrorDialog('Invalid Amount', 'Cart total must be greater than 0');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final orderId = _paymentService.generateOrderId();

      _paymentService.processPayment(
        orderId: orderId,
        amount: cartProvider.grandTotal,
        customerName: _nameController.text.trim(),
        customerEmail: _emailController.text.trim(),
        customerPhone: _phoneController.text.trim(),
        ipAddress: _paymentService.getDeviceIpAddress(),
        description:
            'Travel Gear Purchase - ${cartProvider.cartItems.length} items',
      );
    } catch (e) {
      print('❌ Error processing payment: $e');
      if (mounted) {
        _showErrorDialog('Payment Error', 'Error: ${e.toString()}');
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final accentColor = themeProvider.accentColor;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Checkout",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: _buildBody(isDark, accentColor, textColor, cartProvider),
    );
  }

  Widget _buildBody(
    bool isDark,
    Color accentColor,
    Color textColor,
    CartProvider cartProvider,
  ) {
    if (cartProvider.cartItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: textColor.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Your cart is empty',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back to Shop'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Summary
              _buildOrderSummaryCard(
                isDark,
                accentColor,
                textColor,
                cartProvider,
              ),
              const SizedBox(height: 24),

              // Delivery Details Header
              Text(
                "📦 Delivery Details",
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Name Field
              _buildTextField(
                controller: _nameController,
                label: "Full Name",
                hint: "Enter your full name",
                isDark: isDark,
                textColor: textColor,
                accentColor: accentColor,
                icon: Icons.person,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return "Name is required";
                  }
                  if (value!.length < 2) {
                    return "Name must be at least 2 characters";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Email Field
              _buildTextField(
                controller: _emailController,
                label: "Email Address",
                hint: "Enter your email",
                isDark: isDark,
                textColor: textColor,
                accentColor: accentColor,
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return "Email is required";
                  }
                  if (!RegExp(
                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                  ).hasMatch(value!)) {
                    return "Please enter a valid email";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Phone Field
              _buildTextField(
                controller: _phoneController,
                label: "Phone Number",
                hint: "Enter your phone number",
                isDark: isDark,
                textColor: textColor,
                accentColor: accentColor,
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return "Phone number is required";
                  }
                  if (value!.length < 10) {
                    return "Please enter a valid phone number (min 10 digits)";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Address Field
              _buildTextField(
                controller: _addressController,
                label: "Delivery Address",
                hint: "Enter your full address",
                isDark: isDark,
                textColor: textColor,
                accentColor: accentColor,
                icon: Icons.location_on,
                maxLines: 3,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return "Address is required";
                  }
                  if (value!.length < 10) {
                    return "Please enter a complete address";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Order Total Summary
              _buildOrderTotalCard(
                isDark,
                textColor,
                accentColor,
                cartProvider,
              ),
              const SizedBox(height: 24),

              // Payment Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    disabledBackgroundColor: accentColor.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isProcessing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "💳 Proceed to Payment (SSL Commerce)",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Test Information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "🧪 TEST MODE (সম্পূর্ণ ফ্রি)",
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "✅ আপনি এখন টেস্ট মোডে আছেন\n"
                      "✅ এখানে টাকা কাটা হবে না\n"
                      "✅ যেকোনো কার্ড দিয়ে পেমেন্ট করতে পারেন\n\n"
                      "কার্ড: 4232 0522 8000 1638\n"
                      "এক্সপায়ারি: যেকোনো ভবিষ্যত তারিখ\n"
                      "CVV: যেকোনো ৩ সংখ্যা",
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    required Color textColor,
    required Color accentColor,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          minLines: maxLines == 1 ? 1 : null,
          validator: validator,
          style: TextStyle(color: textColor, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: textColor.withOpacity(0.5),
              fontSize: 13,
            ),
            prefixIcon:
                icon != null ? Icon(icon, color: accentColor, size: 20) : null,
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: textColor.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: textColor.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummaryCard(
    bool isDark,
    Color accentColor,
    Color textColor,
    CartProvider cartProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.2)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "📋 Order Summary",
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ...cartProvider.cartItems.take(3).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "${item.name} x${item.quantity}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "৳${item.totalPrice.toStringAsFixed(0)}",
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          if (cartProvider.cartItems.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "+${cartProvider.cartItems.length - 3} more items",
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderTotalCard(
    bool isDark,
    Color textColor,
    Color accentColor,
    CartProvider cartProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.3)),
        boxShadow: [
          if (!isDark)
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            "Subtotal",
            "৳${cartProvider.subtotal.toStringAsFixed(2)}",
            textColor,
          ),
          const SizedBox(height: 10),
          _buildSummaryRow(
            "GST (5%)",
            "৳${cartProvider.gst.toStringAsFixed(2)}",
            textColor,
          ),
          const SizedBox(height: 10),
          _buildSummaryRow(
            "Delivery Charges",
            cartProvider.deliveryCharges == 0
                ? "FREE"
                : "৳${cartProvider.deliveryCharges.toStringAsFixed(2)}",
            textColor,
          ),
          Divider(color: textColor.withOpacity(0.2), height: 16),
          _buildSummaryRow(
            "Grand Total",
            "৳${cartProvider.grandTotal.toStringAsFixed(2)}",
            accentColor,
            isBold: true,
            fontSize: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    Color textColor, {
    bool isBold = false,
    double fontSize = 13,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textColor.withOpacity(0.7),
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Payment WebView - SSL Commerce পেমেন্ট গেটওয়ে
class PaymentWebView extends StatefulWidget {
  final String paymentUrl;
  final VoidCallback onPaymentSuccess;
  final VoidCallback onPaymentFailed;

  const PaymentWebView({
    required this.paymentUrl,
    required this.onPaymentSuccess,
    required this.onPaymentFailed,
    super.key,
  });

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late WebViewController _webViewController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
            print('🌐 Loading: $url');

            // সাকসেস URL চেক করুন
            if (url.contains('payment-success')) {
              widget.onPaymentSuccess();
            }
            // ফেইল URL চেক করুন
            else if (url.contains('payment-fail') ||
                url.contains('payment-cancel')) {
              widget.onPaymentFailed();
            }
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            print('❌ Web error: ${error.description}');
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SSL Commerce Payment'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          if (_isLoading)
            Center(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
