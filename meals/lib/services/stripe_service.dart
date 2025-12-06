import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import '../data/repositories/config_repository.dart';

/// Stripe payment service for handling subscriptions
class StripeService {
  static final StripeService _instance = StripeService._internal();
  factory StripeService() => _instance;
  StripeService._internal();

  final ConfigRepository _configRepo = ConfigRepository();
  bool _isInitialized = false;

  /// Initialize Stripe with the publishable key from config
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final publishableKey = await _configRepo.getStripePublishableKey();

      if (publishableKey == null || publishableKey.isEmpty) {
        debugPrint('Stripe: No publishable key configured');
        return false;
      }

      Stripe.publishableKey = publishableKey;

      // Optional: Set merchant identifier for Apple Pay
      Stripe.merchantIdentifier = 'merchant.com.meals.app';

      // Optional: Enable URL scheme for deep linking
      Stripe.urlScheme = 'mealsapp';

      await Stripe.instance.applySettings();

      _isInitialized = true;
      debugPrint('Stripe: Initialized successfully');
      return true;
    } catch (e) {
      debugPrint('Stripe: Initialization failed - $e');
      return false;
    }
  }

  /// Check if Stripe is properly configured
  Future<bool> isConfigured() async {
    return _configRepo.isStripeConfigured();
  }

  /// Check if Stripe is initialized
  bool get isInitialized => _isInitialized;

  /// Create a payment intent for subscription
  /// Note: In production, this should call your backend server
  Future<PaymentIntentResult?> createPaymentIntent({
    required int amount, // in cents
    required String currency,
    required String customerEmail,
    Map<String, String>? metadata,
  }) async {
    try {
      final secretKey = await _configRepo.getStripeSecretKey();

      if (secretKey == null || secretKey.isEmpty) {
        debugPrint('Stripe: No secret key configured');
        return null;
      }

      // WARNING: In production, NEVER call Stripe API directly from the app
      // This should go through your backend server
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': amount.toString(),
          'currency': currency,
          'receipt_email': customerEmail,
          'automatic_payment_methods[enabled]': 'true',
          if (metadata != null)
            ...metadata.map((key, value) => MapEntry('metadata[$key]', value)),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PaymentIntentResult(
          clientSecret: data['client_secret'],
          paymentIntentId: data['id'],
          status: data['status'],
        );
      } else {
        debugPrint(
          'Stripe: Failed to create payment intent - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Stripe: Error creating payment intent - $e');
      return null;
    }
  }

  /// Create a subscription for a user
  /// Note: In production, this should call your backend server
  Future<SubscriptionResult?> createSubscription({
    required String customerId,
    required String priceId,
  }) async {
    try {
      final secretKey = await _configRepo.getStripeSecretKey();

      if (secretKey == null || secretKey.isEmpty) {
        debugPrint('Stripe: No secret key configured');
        return null;
      }

      debugPrint(
        'Stripe: Creating subscription for customer: $customerId, price: $priceId',
      );

      // Build the request body as URL-encoded string for proper array expansion
      final bodyParams = [
        'customer=$customerId',
        'items[0][price]=$priceId',
        'payment_behavior=default_incomplete',
        'collection_method=charge_automatically',
        'payment_settings[save_default_payment_method]=on_subscription',
        'expand[0]=latest_invoice.payment_intent',
      ].join('&');

      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/subscriptions'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: bodyParams,
      );

      debugPrint(
        'Stripe: Subscription response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final invoice = data['latest_invoice'];
        final subscriptionId = data['id'];

        debugPrint('Stripe: Subscription created: $subscriptionId');
        debugPrint('Stripe: Subscription status: ${data['status']}');
        debugPrint('Stripe: Invoice ID: ${invoice?['id']}');
        debugPrint('Stripe: Invoice status: ${invoice?['status']}');
        debugPrint('Stripe: Invoice amount_due: ${invoice?['amount_due']}');
        debugPrint(
          'Stripe: Invoice payment_intent: ${invoice?['payment_intent']}',
        );

        String? clientSecret;
        String? invoiceId = invoice is Map ? invoice['id'] : null;

        // Get the payment intent from the invoice
        var paymentIntentId = invoice?['payment_intent'];

        // If no payment intent in response, fetch the invoice directly
        if (paymentIntentId == null && invoiceId != null) {
          debugPrint(
            'Stripe: No payment intent in response, fetching invoice...',
          );
          final fetchedInvoice = await _fetchInvoice(invoiceId, secretKey);
          paymentIntentId = fetchedInvoice?['payment_intent'];
          debugPrint(
            'Stripe: Payment intent from fetched invoice: $paymentIntentId',
          );
        }

        // If still null, list customer's payment intents and find the latest
        if (paymentIntentId == null) {
          debugPrint('Stripe: Listing customer payment intents...');
          paymentIntentId = await _getLatestPaymentIntentForCustomer(
            customerId,
            secretKey,
          );
          debugPrint(
            'Stripe: Latest payment intent for customer: $paymentIntentId',
          );
        }

        // Now fetch the payment intent to get client secret
        if (paymentIntentId != null && paymentIntentId is String) {
          clientSecret = await _getPaymentIntentClientSecret(
            paymentIntentId,
            secretKey,
          );
        }

        return SubscriptionResult(
          subscriptionId: subscriptionId,
          clientSecret: clientSecret,
          status: data['status'],
        );
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error']?['message'] ?? response.body;
        debugPrint('Stripe: Failed to create subscription - $errorMessage');
        return null;
      }
    } catch (e) {
      debugPrint('Stripe: Error creating subscription - $e');
      return null;
    }
  }

  /// Fetch payment intent client secret by ID
  Future<String?> _getPaymentIntentClientSecret(
    String paymentIntentId,
    String secretKey,
  ) async {
    try {
      debugPrint('Stripe: Fetching payment intent: $paymentIntentId');
      final response = await http.get(
        Uri.parse('https://api.stripe.com/v1/payment_intents/$paymentIntentId'),
        headers: {'Authorization': 'Bearer $secretKey'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Stripe: Got client secret from payment intent');
        return data['client_secret'];
      } else {
        debugPrint(
          'Stripe: Failed to fetch payment intent: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Stripe: Error fetching payment intent - $e');
    }
    return null;
  }

  /// Fetch invoice by ID
  Future<Map<String, dynamic>?> _fetchInvoice(
    String invoiceId,
    String secretKey,
  ) async {
    try {
      debugPrint('Stripe: Fetching invoice: $invoiceId');
      final response = await http.get(
        Uri.parse('https://api.stripe.com/v1/invoices/$invoiceId'),
        headers: {'Authorization': 'Bearer $secretKey'},
      );

      debugPrint('Stripe: Invoice fetch status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Stripe: Invoice keys: ${data.keys.toList()}');
        debugPrint(
          'Stripe: Invoice payment_intent raw: ${data['payment_intent']}',
        );
        debugPrint(
          'Stripe: Invoice payment_intent type: ${data['payment_intent']?.runtimeType}',
        );
        return data;
      } else {
        debugPrint('Stripe: Failed to fetch invoice: ${response.body}');
      }
    } catch (e) {
      debugPrint('Stripe: Error fetching invoice - $e');
    }
    return null;
  }

  /// Get the latest payment intent for a customer
  Future<String?> _getLatestPaymentIntentForCustomer(
    String customerId,
    String secretKey,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.stripe.com/v1/payment_intents?customer=$customerId&limit=1',
        ),
        headers: {'Authorization': 'Bearer $secretKey'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final paymentIntents = data['data'] as List;
        if (paymentIntents.isNotEmpty) {
          final pi = paymentIntents.first;
          debugPrint(
            'Stripe: Found payment intent: ${pi['id']}, status: ${pi['status']}',
          );
          return pi['id'];
        }
      }
      debugPrint('Stripe: No payment intents found for customer');
    } catch (e) {
      debugPrint('Stripe: Error listing payment intents - $e');
    }
    return null;
  }

  /// Create or get existing Stripe customer
  Future<String?> createOrGetCustomer({
    required String email,
    required String name,
    String? userId,
  }) async {
    try {
      final secretKey = await _configRepo.getStripeSecretKey();

      if (secretKey == null || secretKey.isEmpty) {
        debugPrint('Stripe: No secret key for customer creation');
        return null;
      }

      debugPrint('Stripe: Looking for existing customer with email: $email');

      // First check if customer exists
      final searchResponse = await http.get(
        Uri.parse(
          'https://api.stripe.com/v1/customers?email=${Uri.encodeComponent(email)}',
        ),
        headers: {'Authorization': 'Bearer $secretKey'},
      );

      debugPrint(
        'Stripe: Customer search status: ${searchResponse.statusCode}',
      );

      if (searchResponse.statusCode == 200) {
        final searchData = json.decode(searchResponse.body);
        final customers = searchData['data'] as List;

        if (customers.isNotEmpty) {
          debugPrint(
            'Stripe: Found existing customer: ${customers.first['id']}',
          );
          return customers.first['id'];
        }
      } else {
        final errorData = json.decode(searchResponse.body);
        debugPrint(
          'Stripe: Customer search failed - ${errorData['error']?['message']}',
        );
      }

      debugPrint('Stripe: Creating new customer...');

      // Create new customer
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/customers'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'email': email,
          'name': name,
          if (userId != null) 'metadata[user_id]': userId,
        },
      );

      debugPrint('Stripe: Customer creation status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Stripe: Created customer: ${data['id']}');
        return data['id'];
      } else {
        final errorData = json.decode(response.body);
        debugPrint(
          'Stripe: Customer creation failed - ${errorData['error']?['message']}',
        );
      }

      return null;
    } catch (e) {
      debugPrint('Stripe: Error creating customer - $e');
      return null;
    }
  }

  /// Present payment sheet for subscription checkout
  Future<PaymentResult> presentPaymentSheet({
    required String clientSecret,
    required String customerEmail,
    String? merchantDisplayName,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        return PaymentResult(
          success: false,
          error: 'Stripe not configured. Please contact support.',
        );
      }
    }

    try {
      debugPrint(
        'Stripe: Initializing payment sheet with clientSecret: ${clientSecret.substring(0, 20)}...',
      );

      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: merchantDisplayName ?? 'Meals App',
          style: ThemeMode.system,
          googlePay: const PaymentSheetGooglePay(
            merchantCountryCode: 'US',
            currencyCode: 'USD',
            testEnv: true, // Set to false in production
          ),
          applePay: const PaymentSheetApplePay(merchantCountryCode: 'US'),
          billingDetails: BillingDetails(email: customerEmail),
          billingDetailsCollectionConfiguration:
              const BillingDetailsCollectionConfiguration(
                name: CollectionMode.automatic,
                email: CollectionMode.automatic,
              ),
        ),
      );

      debugPrint('Stripe: Payment sheet initialized, presenting...');

      // Present the payment sheet
      await Stripe.instance.presentPaymentSheet();

      debugPrint('Stripe: Payment sheet completed successfully');

      return PaymentResult(success: true);
    } on StripeException catch (e) {
      final error = e.error;
      if (error.code == FailureCode.Canceled) {
        return PaymentResult(
          success: false,
          error: 'Payment cancelled',
          isCancelled: true,
        );
      }
      return PaymentResult(
        success: false,
        error: error.message ?? 'Payment failed',
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  /// Get subscription price IDs from config
  Future<PriceIds?> getPriceIds() async {
    final monthly = await _configRepo.getStripeMonthlyPriceId();
    final yearly = await _configRepo.getStripeYearlyPriceId();

    if (monthly == null && yearly == null) return null;

    return PriceIds(monthly: monthly, yearly: yearly);
  }

  /// Prepare subscription flow - creates subscription and returns client secret
  /// without presenting the payment sheet
  Future<SubscriptionSetupResult> prepareSubscription({
    required String email,
    required String name,
    required String userId,
    required SubscriptionPlan plan,
  }) async {
    try {
      // 1. Initialize Stripe
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) {
          return SubscriptionSetupResult(
            success: false,
            error: 'Payment system not configured. Please contact support.',
          );
        }
      }

      // 2. Get price ID
      final priceIds = await getPriceIds();
      if (priceIds == null) {
        return SubscriptionSetupResult(
          success: false,
          error: 'Subscription plans not configured.',
        );
      }

      final priceId = plan == SubscriptionPlan.monthly
          ? priceIds.monthly
          : priceIds.yearly;

      if (priceId == null) {
        return SubscriptionSetupResult(
          success: false,
          error: 'Selected plan not available.',
        );
      }

      // 3. Get or create customer
      final customerId = await createOrGetCustomer(
        email: email,
        name: name,
        userId: userId,
      );

      if (customerId == null) {
        return SubscriptionSetupResult(
          success: false,
          error: 'Could not create customer profile.',
        );
      }

      // 4. Create subscription
      final subscription = await createSubscription(
        customerId: customerId,
        priceId: priceId,
      );

      if (subscription == null || subscription.clientSecret == null) {
        return SubscriptionSetupResult(
          success: false,
          error: 'Could not create subscription.',
        );
      }

      return SubscriptionSetupResult(
        success: true,
        clientSecret: subscription.clientSecret,
        subscriptionId: subscription.subscriptionId,
        customerId: customerId,
      );
    } catch (e) {
      debugPrint('Stripe: Prepare subscription error - $e');
      return SubscriptionSetupResult(
        success: false,
        error: 'An unexpected error occurred.',
      );
    }
  }

  /// Full subscription flow
  Future<SubscriptionFlowResult> startSubscriptionFlow({
    required String email,
    required String name,
    required String userId,
    required SubscriptionPlan plan,
  }) async {
    try {
      // 1. Initialize Stripe
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) {
          return SubscriptionFlowResult(
            success: false,
            error: 'Payment system not configured. Please contact support.',
          );
        }
      }

      // 2. Get price ID
      final priceIds = await getPriceIds();
      if (priceIds == null) {
        return SubscriptionFlowResult(
          success: false,
          error: 'Subscription plans not configured.',
        );
      }

      final priceId = plan == SubscriptionPlan.monthly
          ? priceIds.monthly
          : priceIds.yearly;

      if (priceId == null) {
        return SubscriptionFlowResult(
          success: false,
          error: 'Selected plan not available.',
        );
      }

      // 3. Get or create customer
      final customerId = await createOrGetCustomer(
        email: email,
        name: name,
        userId: userId,
      );

      if (customerId == null) {
        return SubscriptionFlowResult(
          success: false,
          error: 'Could not create customer profile.',
        );
      }

      // 4. Create subscription
      final subscription = await createSubscription(
        customerId: customerId,
        priceId: priceId,
      );

      if (subscription == null || subscription.clientSecret == null) {
        return SubscriptionFlowResult(
          success: false,
          error: 'Could not create subscription.',
        );
      }

      // 5. Present payment sheet
      final paymentResult = await presentPaymentSheet(
        clientSecret: subscription.clientSecret!,
        customerEmail: email,
      );

      if (paymentResult.success) {
        return SubscriptionFlowResult(
          success: true,
          subscriptionId: subscription.subscriptionId,
          customerId: customerId,
        );
      } else {
        return SubscriptionFlowResult(
          success: false,
          error: paymentResult.error,
          isCancelled: paymentResult.isCancelled,
        );
      }
    } catch (e) {
      debugPrint('Stripe: Subscription flow error - $e');
      return SubscriptionFlowResult(
        success: false,
        error: 'An unexpected error occurred.',
      );
    }
  }
}

/// Result of creating a payment intent
class PaymentIntentResult {
  final String clientSecret;
  final String paymentIntentId;
  final String status;

  PaymentIntentResult({
    required this.clientSecret,
    required this.paymentIntentId,
    required this.status,
  });
}

/// Result of creating a subscription
class SubscriptionResult {
  final String subscriptionId;
  final String? clientSecret;
  final String status;

  SubscriptionResult({
    required this.subscriptionId,
    this.clientSecret,
    required this.status,
  });
}

/// Result of payment attempt
class PaymentResult {
  final bool success;
  final String? error;
  final bool isCancelled;

  PaymentResult({required this.success, this.error, this.isCancelled = false});
}

/// Result of full subscription flow
class SubscriptionFlowResult {
  final bool success;
  final String? subscriptionId;
  final String? customerId;
  final String? error;
  final bool isCancelled;

  SubscriptionFlowResult({
    required this.success,
    this.subscriptionId,
    this.customerId,
    this.error,
    this.isCancelled = false,
  });
}

/// Result of subscription setup (without payment sheet)
class SubscriptionSetupResult {
  final bool success;
  final String? clientSecret;
  final String? subscriptionId;
  final String? customerId;
  final String? error;

  SubscriptionSetupResult({
    required this.success,
    this.clientSecret,
    this.subscriptionId,
    this.customerId,
    this.error,
  });
}

/// Subscription price IDs
class PriceIds {
  final String? monthly;
  final String? yearly;

  PriceIds({this.monthly, this.yearly});
}

/// Subscription plan type
enum SubscriptionPlan { monthly, yearly }
