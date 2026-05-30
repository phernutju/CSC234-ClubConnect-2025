import 'package:flutter_test/flutter_test.dart';
import 'package:csc234_clubconnect/utils/validators.dart' as v;

void main() {
  group('isValidEmailFormat', () {
    test('valid email passes', () {
      expect(v.isValidEmailFormat('user@example.com'), isTrue);
      expect(v.isValidEmailFormat('a.b-c@sub.domain.co'), isTrue);
    });
    test('missing @ fails',
        () => expect(v.isValidEmailFormat('userexample.com'), isFalse));
    test('missing domain fails',
        () => expect(v.isValidEmailFormat('user@'), isFalse));
    test('empty string fails', () => expect(v.isValidEmailFormat(''), isFalse));
    test('trims whitespace before checking', () {
      expect(v.isValidEmailFormat('  user@example.com  '), isTrue);
    });
  });

  group('hasNoSpaces', () {
    test('no spaces passes', () => expect(v.hasNoSpaces('hello'), isTrue));
    test('space in middle fails',
        () => expect(v.hasNoSpaces('hel lo'), isFalse));
    test('leading space fails', () => expect(v.hasNoSpaces(' hello'), isFalse));
    test('empty string passes', () => expect(v.hasNoSpaces(''), isTrue));
  });

  group('isNotEmpty', () {
    test('non-empty passes', () => expect(v.isNotEmpty('a'), isTrue));
    test('empty fails', () => expect(v.isNotEmpty(''), isFalse));
    test('spaces-only is non-empty per impl',
        () => expect(v.isNotEmpty('  '), isTrue));
  });

  group('hasLetter', () {
    test('contains letter passes', () => expect(v.hasLetter('abc'), isTrue));
    test('mixed passes', () => expect(v.hasLetter('123a'), isTrue));
    test('digits only fails', () => expect(v.hasLetter('123'), isFalse));
    test('empty fails', () => expect(v.hasLetter(''), isFalse));
  });

  group('hasUppercase', () {
    test('uppercase present passes',
        () => expect(v.hasUppercase('Hello'), isTrue));
    test('all lower fails', () => expect(v.hasUppercase('hello'), isFalse));
    test('empty fails', () => expect(v.hasUppercase(''), isFalse));
  });

  group('hasNumber', () {
    test('digit present passes', () => expect(v.hasNumber('abc1'), isTrue));
    test('no digits fails', () => expect(v.hasNumber('abc'), isFalse));
    test('empty fails', () => expect(v.hasNumber(''), isFalse));
  });

  group('hasMinLength8', () {
    test('exactly 8 passes', () => expect(v.hasMinLength8('12345678'), isTrue));
    test('9 chars passes', () => expect(v.hasMinLength8('123456789'), isTrue));
    test('7 chars fails', () => expect(v.hasMinLength8('1234567'), isFalse));
    test('empty fails', () => expect(v.hasMinLength8(''), isFalse));
  });
}
