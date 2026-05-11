// Pure-function validators — no Flutter imports, straightforward to unit test.
// Each function takes the raw field string and returns true when the rule passes.

bool isValidEmailFormat(String v) =>
    RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(v.trim());

bool hasNoSpaces(String v) => !v.contains(' ');

bool isNotEmpty(String v) => v.isNotEmpty;

bool hasLetter(String v) => RegExp(r'[a-zA-Z]').hasMatch(v);

bool hasUppercase(String v) => RegExp(r'[A-Z]').hasMatch(v);

bool hasNumber(String v) => RegExp(r'[0-9]').hasMatch(v);

bool hasMinLength8(String v) => v.length >= 8;
