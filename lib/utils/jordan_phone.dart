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

/// The same number in E.164 (`+962…`), or null when it is not valid. E.164 is what the
/// API stores, so conversion happens once here rather than at each call site.
String? jordanPhoneToE164(String raw) {
  final digits = localJordanDigits(raw);
  return digits == null ? null : '+962$digits';
}
