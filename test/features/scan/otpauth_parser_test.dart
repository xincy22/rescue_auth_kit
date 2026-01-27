import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_auth_kit/core/import/otpauth_parser.dart';

void main() {
  test('parse otpauth totp uri', () {
    const uri =
        'otpauth://totp/GitHub:xincy?secret=JBSWY3DPEHPK3PXP&issuer=GitHub&algorithm=SHA1&digits=6&period=30';
    final parsed = parseOtpauthTotpUri(uri);

    expect(parsed.issuer, 'GitHub');
    expect(parsed.accountName, 'xincy');
    expect(parsed.digits, 6);
    expect(parsed.period, 30);
  });
}
