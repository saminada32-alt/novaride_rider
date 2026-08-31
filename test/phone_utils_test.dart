import 'package:flutter_test/flutter_test.dart';
import 'package:novaride_rider/core/utils/phone_utils.dart';

/// Mirrors the backend's Syrian phone validator:
/// `/^(\+?963|0)?9[0-9]{8}$/` (src/auth/dto/auth.dto.ts). If a normalized
/// phone can't satisfy this, real users get rejected by /auth/send-otp.
final backendPhoneRegex = RegExp(r'^(\+?963|0)?9[0-9]{8}$');

void main() {
  group('buildAuthPhone', () {
    test('local number typed with leading 0', () {
      expect(buildAuthPhone('+963', '0944123456'), '+963944123456');
    });

    test('local number typed without leading 0', () {
      expect(buildAuthPhone('+963', '944123456'), '+963944123456');
    });

    test('dedupes country code already present in the local input', () {
      expect(buildAuthPhone('+963', '963944123456'), '+963944123456');
    });

    test('strips non-digit characters (spaces, dashes)', () {
      expect(buildAuthPhone('+963', '094 412-3456'), '+963944123456');
    });

    test('result satisfies the backend phone validator', () {
      final phone = buildAuthPhone('+963', '0944123456');
      expect(backendPhoneRegex.hasMatch(phone), isTrue, reason: phone);
    });
  });

  group('normalizePhoneForTel', () {
    test('null/blank input returns null', () {
      expect(normalizePhoneForTel(null), isNull);
      expect(normalizePhoneForTel(''), isNull);
      expect(normalizePhoneForTel('   '), isNull);
    });

    test('local 9-digit number gets +963 prefix', () {
      expect(normalizePhoneForTel('944123456'), '+963944123456');
    });

    test('leading-0 local number is normalized', () {
      expect(normalizePhoneForTel('0944123456'), '+963944123456');
    });

    test('already-international number passes through', () {
      expect(normalizePhoneForTel('+963944123456'), '+963944123456');
    });

    test('00-prefixed international number is normalized', () {
      expect(normalizePhoneForTel('00963944123456'), '+963944123456');
    });

    test('double country code (e.g. from a buggy stored value) is collapsed', () {
      expect(normalizePhoneForTel('963963944123456'), '+963944123456');
    });

    test('invalid numbers (wrong length, non-mobile prefix) return null', () {
      expect(normalizePhoneForTel('12345'), isNull);
      expect(normalizePhoneForTel('+963844123456'), isNull); // land line-ish, not 9xxxxxxxx
    });
  });
}
