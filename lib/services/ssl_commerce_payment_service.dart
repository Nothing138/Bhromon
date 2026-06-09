// services/ssl_commerce_payment_service.dart

import 'package:http/http.dart' as http;

typedef PaymentSuccessCallback = Future<void> Function(String transactionId);
typedef PaymentFailureCallback = void Function(String error);

class SSLCommercePaymentService {
  static final SSLCommercePaymentService _instance =
      SSLCommercePaymentService._internal();

  factory SSLCommercePaymentService() {
    return _instance;
  }

  SSLCommercePaymentService._internal();

  static const String STORE_ID = 'bhrom6a286b58cab14'; // Test Store ID
  static const String STORE_PASSWORD =
      'bhrom6a286b58cab14@ssl'; // Test Store Password
  static const String BASE_URL =
      'https://sandbox.sslcommerz.com/gwprocess/v4/api.php';
  static const String VALIDATION_URL =
      'https://sandbox.sslcommerz.com/validator/api/validationserverAPI.php';

  PaymentSuccessCallback? _onSuccess;
  PaymentFailureCallback? _onFailure;
  bool _isInitialized = false;

  void initialize({
    required PaymentSuccessCallback onSuccess,
    required PaymentFailureCallback onFailure,
  }) {
    try {
      if (_isInitialized) {
        print('⚠️  Payment service already initialized');
        return;
      }

      _onSuccess = onSuccess;
      _onFailure = onFailure;
      _isInitialized = true;

      print('✅ SSL Commerce Payment Service initialized (Test Mode)');
      print('💡 টেস্ট মোডে আপনি এই কার্ড দিয়ে পেমেন্ট করতে পারবেন:');
      print('   কার্ড নম্বর: 4232 0522 8000 1638');
      print('   এক্সপায়ারি: যেকোনো ভবিষ্যত তারিখ');
      print('   CVV: যেকোনো ৩ সংখ্যা');
    } catch (e) {
      print('❌ Error initializing payment service: $e');
      _onFailure?.call('Failed to initialize payment: $e');
    }
  }

  /// প্রধান পেমেন্ট ফাংশন
  Future<void> processPayment({
    required String orderId,
    required double amount,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String ipAddress,
    String description = "Travel Gear Purchase",
  }) async {
    try {
      // ভ্যালিডেশন
      if (amount <= 0) {
        _onFailure?.call('Invalid amount: Amount must be greater than 0');
        return;
      }

      if (customerName.isEmpty ||
          customerEmail.isEmpty ||
          customerPhone.isEmpty) {
        _onFailure?.call('Invalid customer details');
        return;
      }

      print('💳 Initiating SSL Commerce payment for order: $orderId');
      print('   Amount: ৳$amount');

      // SSL Commerce এ পাঠানোর ডেটা
      final Map<String, String> postData = {
        'store_id': STORE_ID,
        'store_passwd': STORE_PASSWORD,
        'total_amount': amount.toStringAsFixed(2),
        'currency': 'BDT',
        'tran_id': orderId,
        'success_url': 'https://yourapp.com/payment-success',
        'fail_url': 'https://yourapp.com/payment-fail',
        'cancel_url': 'https://yourapp.com/payment-cancel',
        'ipn_url': 'https://yourapp.com/payment-ipn',
        'emi_option': '0',
        'cus_name': customerName,
        'cus_email': customerEmail,
        'cus_phone': customerPhone,
        'cus_add1': 'N/A',
        'cus_city': 'Dhaka',
        'cus_country': 'Bangladesh',
        'shipping_method': 'NO',
        'product_name': description,
        'product_category': 'Travel Gear',
        'product_profile': 'general',
      };

      // SSL Commerce API-তে রিকোয়েস্ট পাঠান
      final response =
          await http.post(Uri.parse(BASE_URL), body: postData).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          _onFailure?.call('Payment request timeout');
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final responseBody = response.body;
        print('✅ SSL Commerce response received');
        print('Response: $responseBody');

        // লিংক এক্সট্র্যাক্ট করুন
        if (responseBody.contains('REDIRECT_URL')) {
          // নরমাল রেসপন্স পার্সিং
          final lines = responseBody.split('\n');
          String? redirectUrl;

          for (var line in lines) {
            if (line.startsWith('redirectGatewayURL')) {
              redirectUrl = line.split('=')[1];
              break;
            }
          }

          if (redirectUrl != null && redirectUrl.isNotEmpty) {
            print('🌐 Redirect URL: $redirectUrl');
            _onFailure?.call('PAYMENT_REDIRECT:$redirectUrl');
          } else {
            _onFailure?.call(
              'Unable to get payment gateway link. Please try again.',
            );
          }
        } else {
          // এরর রেসপন্স
          _onFailure?.call('Payment initiation failed: $responseBody');
        }
      } else {
        _onFailure?.call('Payment service error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error processing payment: $e');
      _onFailure?.call('Error processing payment: ${e.toString()}');
    }
  }

  /// পেমেন্ট ভেরিফাই করুন (IPN থেকে)
  Future<bool> validatePayment({
    required String transactionId,
    required double amount,
  }) async {
    try {
      final Map<String, String> postData = {
        'store_id': STORE_ID,
        'store_passwd': STORE_PASSWORD,
        'val_id': transactionId,
      };

      final response = await http
          .post(Uri.parse(VALIDATION_URL), body: postData)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseBody = response.body;
        print('✅ Payment validation response: $responseBody');

        // রেসপন্স পার্সিং
        if (responseBody.contains('VALID')) {
          print('✅ Payment validated successfully');
          return true;
        } else {
          print('❌ Payment validation failed');
          return false;
        }
      }
      return false;
    } catch (e) {
      print('❌ Error validating payment: $e');
      return false;
    }
  }

  void dispose() {
    try {
      print('✅ Payment service disposed');
    } catch (e) {
      print('⚠️  Error disposing payment service: $e');
    }
  }

  /// অর্ডার আইডি জেনারেট করুন
  String generateOrderId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return '${timestamp}_$random';
  }

  /// ডিভাইসের IP অ্যাড্রেস পান (সিম্পল ডেমো)
  String getDeviceIpAddress() {
    return '192.168.1.1'; // বাস্তব অ্যাপে proper IP ফেচ করুন
  }

  bool get isInitialized => _isInitialized;
}
