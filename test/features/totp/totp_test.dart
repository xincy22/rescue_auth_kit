import 'package:flutter_test/flutter_test.dart';
import 'package:otp/otp.dart';

void main() {
  test('RFC6238 SHA1 vector', () {
    const secretBase32 = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';
    final code = OTP.generateTOTPCodeString(
      secretBase32,
      59000,
      length: 8,
      interval: 30,
      algorithm: Algorithm.SHA1,
      isGoogle: true,
    );
    expect(code, '94287082');
  });
}
