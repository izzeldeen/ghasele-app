/// Jordanian mobile number handling, shared by every screen that asks for one.
///
/// The rules were duplicated per screen and had already started drifting, which matters
/// because the server stores whatever it is given: two screens disagreeing produce two
/// spellings of the same number on the same customer.
library;

/// Strips a leading `0`, `962` or `+962` and returns the bare 9-digit local number, or
/// null when the input is not a valid Jordan mobile number.
String? localJordanDigits(String raw) {
  String phone = raw.trim();
  if (phone.startsWith('+962')) {
    phone = phone.substring(4);
  } else if (phone.startsWith('962')) {
    phone = phone.substring(3);
  } else if (phone.startsWith('0')) {
    phone = phone.substring(1);
  }
  return phone.length == 9 ? phone : null;
}

/// The bare 9-digit local number, but only for a real Jordanian **mobile**: one that
/// dials as `07` followed by `7`, `8` or `9` and then seven more digits - ten digits in
/// all, e.g. `0791234567`.
///
/// Stricter than [localJordanDigits], which accepts any nine digits. That leniency is
/// fine for signing in - the number is only being matched against an account that
/// already exists - and wrong for a number somebody is going to be *called* on. A guest
/// ordering leaves this number as the only way the driver can reach them, so `0711111111`
/// passing the check means a pickup nobody can complete.
///
/// Accepts the same spellings as [localJordanDigits] - with or without the leading `0`,
/// `962` or `+962` - because the field that collects it already shows a `+962` prefix and
/// customers type it both ways.
String? jordanMobileDigits(String raw) {
  final digits = localJordanDigits(raw);
  if (digits == null) return null;
  // digits is the 9-digit local form, so the leading 0 is already gone: what dials as
  // 077/078/079 is 77/78/79 here.
  return RegExp(r'^7[789]\d{7}$').hasMatch(digits) ? digits : null;
}

/// The same number in E.164 (`+962…`), or null when it is not valid. E.164 is what the
/// API stores, so conversion happens once here rather than at each call site.
String? jordanPhoneToE164(String raw) {
  final digits = localJordanDigits(raw);
  return digits == null ? null : '+962$digits';
}
