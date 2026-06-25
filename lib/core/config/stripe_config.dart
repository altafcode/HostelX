class StripeConfig {
  StripeConfig._();

  static const publishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
  );

  static const secretKey = String.fromEnvironment(
    'STRIPE_SECRET_KEY',
  );

  static const apiBaseUrl = 'https://api.stripe.com/v1';
  static const currency = 'pkr';
  static const checkoutSuccessUrl = 'https://hostelx.com/stripe/success';
  static const checkoutCancelUrl = 'https://hostelx.com/stripe/cancel';

  static bool get hasSecretKey => secretKey.trim().isNotEmpty;
}
