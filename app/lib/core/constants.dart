class AppConstants {
  static const String appName = 'AOSA';
  static const String appVersion = '0.0.1';

  static const int defaultTotpPeriod = 30;
  static const int defaultTotpDigits = 6;
  static const String defaultTotpAlgorithm = 'SHA1';

  static const int maxPinAttempts = 5;
  static const int pinCooldownBase = 30;

  static const int maxOtpAccounts = 500;

  static const String pinVerifyToken = 'AOSA_PIN_VERIFY';
  static const int argon2Memory = 65536;
  static const int argon2Iterations = 3;
  static const int argon2Parallelism = 4;

  static const String apiVersion = 'v1';
  static const Duration syncTimeout = Duration(seconds: 15);
  static const Duration httpTimeout = Duration(seconds: 10);
}
