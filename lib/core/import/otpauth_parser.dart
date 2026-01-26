import '../vault/vault_models.dart';

class OtpAuthParseException implements Exception {
  const OtpAuthParseException(this.message);
  final String message;
  @override
  String toString() => 'OtpAuthParseException: $message';
}

class ParsedTotp {
  final String issuer;
  final String accountName;
  final String secretBase32;
  final TotpHashAlgorithm algorithm;
  final int digits;
  final int period;

  const ParsedTotp({
    required this.issuer,
    required this.accountName,
    required this.secretBase32,
    required this.algorithm,
    required this.digits,
    required this.period,
  });
}

String normalizeBase32Secret(String raw) {
  var s = raw.trim().replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
  s = s.replaceAll('=', '');
  final pad = (8 - (s.length % 8)) % 8;
  return s + '=' * pad;
}

ParsedTotp parseOtpauthTotpUri(String rawUri) {
  final text = rawUri.trim();

  if (text.startsWith('otpauth-migration://')) {
    throw const OtpAuthParseException(
      'otpauth-migration URIs are not supported.',
    );
  }

  late final Uri uri;
  try {
    uri = Uri.parse(text);
  } catch (_) {
    throw const OtpAuthParseException('Invalid URI format.');
  }

  if (uri.scheme.toLowerCase() != 'otpauth' ||
      uri.host.toLowerCase() != 'totp') {
    throw const OtpAuthParseException('Not a valid otpauth TOTP URI.');
  }

  final secretRaw = uri.queryParameters['secret'];
  if (secretRaw == null || secretRaw.trim().isEmpty) {
    throw const OtpAuthParseException('Missing secret parameter.');
  }
  final secret = normalizeBase32Secret(secretRaw);

  final label = Uri.decodeComponent(uri.path).replaceFirst('/', '');
  if (label.isEmpty) {
    throw const OtpAuthParseException('Missing label in URI path.');
  }

  String issuerFromLabel = '';
  String accountName = label;
  if (label.contains(':')) {
    final parts = label.split(':');
    issuerFromLabel = parts.first.trim();
    accountName = parts.sublist(1).join(':').trim();
  }

  final issuer = (uri.queryParameters['issuer'] ?? issuerFromLabel).trim();

  final algorithmStr = (uri.queryParameters['algorithm'] ?? 'SHA1').trim();
  final algorithm = TotpHashAlgorithmX.fromOtpauthName(algorithmStr);

  final digits = int.tryParse(uri.queryParameters['digits'] ?? '') ?? 6;
  final period = int.tryParse(uri.queryParameters['period'] ?? '') ?? 30;

  if (digits < 6 || digits > 10) {
    throw const OtpAuthParseException('Digits not in valid range (6-10).');
  }
  if (period <= 0 || period > 120) {
    throw const OtpAuthParseException('Period not in valid range (1-120).');
  }

  return ParsedTotp(
    issuer: issuer,
    accountName: accountName,
    secretBase32: secret,
    algorithm: algorithm,
    digits: digits,
    period: period,
  );
}
