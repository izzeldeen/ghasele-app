import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;

class ApiService {
  // Production API. This is the default so a release build needs no extra flags.
  //
  // The /api suffix is required - controllers are routed at "api/[controller]".
  //
  // Local development against IIS Express (binds https on localhost:44386 only) needs an
  // adb reverse tunnel so `localhost` inside the emulator resolves to this machine:
  //   adb reverse tcp:44386 tcp:44386
  //   flutter run --dart-define=API_BASE_URL=https://localhost:44386/api
  // Re-run the tunnel after restarting the emulator or the adb server.
  //
  // Against Kestrel (binds 0.0.0.0, so no tunnel needed):
  //   emulator         --dart-define=API_BASE_URL=http://10.0.2.2:5001/api
  //   device on Wi-Fi  --dart-define=API_BASE_URL=http://192.168.1.50:5001/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.cleanyjo.com/api',
  );

  /// The API origin without the `/api` suffix. Static assets such as support-ticket
  /// photos are served from here (e.g. `<origin>/uploads/support/xxx.jpg`).
  static String get originUrl => baseUrl.endsWith('/api')
      ? baseUrl.substring(0, baseUrl.length - 4)
      : baseUrl;

  /// Turns a server-relative asset path (`/uploads/...`) into an absolute URL.
  /// Passes through values that are already absolute.
  static String resolveAssetUrl(String path) {
    if (path.isEmpty) return path;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '$originUrl${path.startsWith('/') ? '' : '/'}$path';
  }

  /// Language sent to the API as `Accept-Language`, so the backend returns its
  /// error messages in the user's language. Kept in sync by LocaleProvider;
  /// defaults to Arabic to match the app's own default locale.
  static String language = 'ar';

  /// Standard headers for an API call. Pass [token] for authenticated requests,
  /// and set [json] to false for requests that carry no JSON body.
  static Map<String, String> _headers({String? token, bool json = true}) {
    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      'Accept-Language': language,
    };
  }

  /// Decodes a failed response into a uniform result.
  ///
  /// The API reports errors as `{statusCode, errorCode, message}`, but two cases
  /// carry no usable body at all: a 401 from the auth middleware is empty, and
  /// an infrastructure failure can return HTML. Callers need [statusCode] and
  /// [errorCode] to branch on - matching on [message] is unsafe because the text
  /// is localized to whatever `Accept-Language` was sent.
  static Map<String, dynamic> _errorResult(http.Response response) {
    String? errorCode;
    String? message;

    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          errorCode = decoded['errorCode'] as String?;
          message = decoded['message'] as String?;
        }
      } catch (_) {
        // Not JSON - keep the raw body, it is the only diagnostic we have.
        message = response.body;
      }
    }

    if (kDebugMode) {
      print(
        'API ERROR ${response.statusCode} '
        '${response.request?.url} code=$errorCode body=${response.body}',
      );
    }

    return {
      'success': false,
      'statusCode': response.statusCode,
      'errorCode': errorCode,
      'message': (message != null && message.isNotEmpty) ? message : null,
    };
  }

  /// Sets the signed-in user's contact phone number.
  ///
  /// PUT /api/users/{id} replaces the whole user row, so [fullName], [username] and [email] are
  /// resent as-is - omitting them would blank those columns rather than leave them alone.
  static Future<Map<String, dynamic>> updateUserPhoneNumber({
    required String userId,
    required String phoneNumber,
    required String fullName,
    required String username,
    String? email,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/users/$userId');
    try {
      final response = await http
          .put(
            url,
            headers: _headers(token: token),
            body: jsonEncode({
              'Id': userId,
              'Username': username,
              'Email': email,
              'FullName': fullName,
              'PhoneNumber': phoneNumber,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (kDebugMode) {
        print('API UPDATE USER PHONE RESPONSE: ${response.statusCode}');
      }

      // The endpoint answers 204 No Content on success, so an empty body is expected here.
      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'success': true};
      }

      return _errorResult(response);
    } catch (e) {
      if (kDebugMode) print('API UPDATE USER PHONE EXCEPTION: $e');
      return {'success': false, 'message': null, 'networkError': true};
    }
  }

  /// Trades a Firebase ID token for one of our own JWTs.
  ///
  /// Firebase has already verified phone ownership by the time this is called, so the backend
  /// creates the account on first sign-in and returns a token straight away - there is no separate
  /// verify step and no password. Independent of [startRegistration], which is the WhatsApp path.
  static Future<Map<String, dynamic>> firebaseLogin(String idToken) async {
    final url = Uri.parse('$baseUrl/auth/firebase-login');
    try {
      // The single most useful line when this fails: it shows whether --dart-define=API_BASE_URL
      // actually took effect. The default (localhost:44386) is unreachable from an emulator, and
      // that is indistinguishable from a backend problem without seeing the URL.
      if (kDebugMode) {
        print('API FIREBASE LOGIN -> $url (idToken ${idToken.length} chars)');
      }

      final response = await http
          .post(
            url,
            headers: _headers(),
            body: jsonEncode({'IdToken': idToken}),
          )
          .timeout(const Duration(seconds: 20));

      if (kDebugMode) print('API FIREBASE LOGIN RESPONSE: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }

      // Body carries the backend's errorCode - without it a 401 is indistinguishable from a 400.
      if (kDebugMode) print('API FIREBASE LOGIN BODY: ${response.body}');

      // 400 = no token in the body, 401 = token rejected. Both arrive in the API's standard
      // { errorCode, message } shape, already localized to the request's language.
      try {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'statusCode': response.statusCode,
          'errorCode': errorData['errorCode'],
          'message': errorData['message'],
        };
      } catch (_) {
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      if (kDebugMode) print('API FIREBASE LOGIN EXCEPTION: $e');
      return {'success': false, 'message': null, 'networkError': true};
    }
  }


  /// Trades a Firebase ID token obtained through Google sign-in for one of our own JWTs.
  ///
  /// Its own endpoint rather than [firebaseLogin]: that one requires a phone_number claim and
  /// rejects every Google token, which carries an email instead. The account is created on first
  /// sign-in with an empty phone number, so the contact number is collected later at checkout.
  static Future<Map<String, dynamic>> googleLogin(String idToken) async {
    final url = Uri.parse('$baseUrl/auth/google');
    try {
      if (kDebugMode) {
        print('API GOOGLE LOGIN -> $url (idToken ${idToken.length} chars)');
      }

      final response = await http
          .post(
            url,
            headers: _headers(),
            body: jsonEncode({'IdToken': idToken}),
          )
          .timeout(const Duration(seconds: 20));

      if (kDebugMode) print('API GOOGLE LOGIN RESPONSE: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }

      if (kDebugMode) print('API GOOGLE LOGIN BODY: ${response.body}');

      // 400 = no token in the body, 401 = token rejected or no verified email. Both arrive in the
      // API's standard { errorCode, message } shape, already localized.
      try {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'statusCode': response.statusCode,
          'errorCode': errorData['errorCode'],
          'message': errorData['message'],
        };
      } catch (_) {
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      if (kDebugMode) print('API GOOGLE LOGIN EXCEPTION: $e');
      return {'success': false, 'message': null, 'networkError': true};
    }
  }
  /// Step 1 of the phone-first registration flow. Sends only the phone number; the backend
  /// replies by dispatching a 6-digit WhatsApp OTP. No account is created yet.
  static Future<Map<String, dynamic>> startRegistration(
    String phoneNumber,
  ) async {
    final url = Uri.parse('$baseUrl/auth/start-registration');
    try {
      final response = await http
          .post(
            url,
            headers: _headers(),
            body: jsonEncode({'PhoneNumber': phoneNumber}),
          )
          .timeout(const Duration(seconds: 20));

      if (kDebugMode)
        print('API START REGISTRATION RESPONSE: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? response.body,
          };
        } catch (_) {
          return {'success': false, 'message': response.body};
        }
      }
    } catch (e) {
      if (kDebugMode) print('API START REGISTRATION EXCEPTION: $e');
      // Network/timeout failure - no server message. Let the caller show a
      // localized "couldn't reach the server" message instead of the raw error.
      return {'success': false, 'message': null, 'networkError': true};
    }
  }

  /// Step 2 of the phone-first registration flow. Confirms the 6-digit WhatsApp OTP. On success
  /// the phone is marked verified but there is still no account and no token - the client moves
  /// on to collect a name and password via [completeRegistration].
  static Future<Map<String, dynamic>> verifyRegistrationOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    final url = Uri.parse('$baseUrl/auth/verify-registration-otp');
    try {
      final response = await http
          .post(
            url,
            headers: _headers(),
            body: jsonEncode({'PhoneNumber': phoneNumber, 'Otp': otp}),
          )
          .timeout(const Duration(seconds: 20));

      if (kDebugMode)
        print('API VERIFY REGISTRATION OTP RESPONSE: ${response.statusCode}');
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return _errorResult(response);
    } catch (e) {
      if (kDebugMode) print('API VERIFY REGISTRATION OTP EXCEPTION: $e');
      return {'success': false, 'message': null, 'networkError': true};
    }
  }

  /// Step 3 of the phone-first registration flow. The phone is already verified, so this creates
  /// the real account from the chosen name and password and returns the same auth payload as
  /// login (token, id, ...) so the client is logged straight in.
  static Future<Map<String, dynamic>> completeRegistration({
    required String phoneNumber,
    required String fullName,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/complete-registration');
    try {
      final response = await http
          .post(
            url,
            headers: _headers(),
            body: jsonEncode({
              'PhoneNumber': phoneNumber,
              'FullName': fullName,
              'Password': password,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (kDebugMode)
        print('API COMPLETE REGISTRATION RESPONSE: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return _errorResult(response);
    } catch (e) {
      if (kDebugMode) print('API COMPLETE REGISTRATION EXCEPTION: $e');
      return {'success': false, 'message': null, 'networkError': true};
    }
  }

  /// Requests a fresh OTP for a signup that has not been confirmed yet.
  static Future<Map<String, dynamic>> resendRegistrationOtp(
    String phoneNumber,
  ) async {
    final url = Uri.parse('$baseUrl/auth/resend-registration-otp');
    try {
      final response = await http
          .post(
            url,
            headers: _headers(),
            body: jsonEncode({'PhoneNumber': phoneNumber}),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': jsonDecode(response.body)['message'],
        };
      }
      return _errorResult(response);
    } catch (e) {
      return {'success': false, 'message': null, 'networkError': true};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String phoneNumber,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/signin');
    try {
      final response = await http
          .post(
            url,
            headers: _headers(),
            body: jsonEncode({
              'PhoneNumber': phoneNumber,
              'Password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (kDebugMode) print('API LOGIN RESPONSE: ${response.statusCode}');
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? response.body,
          };
        } catch (_) {
          return {'success': false, 'message': response.body};
        }
      }
    } catch (e) {
      if (kDebugMode) print('API LOGIN EXCEPTION: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Sends the Apple identity token to the backend, which verifies it with Apple
  /// and returns the same auth payload as a normal login. [fullName] and [email]
  /// are only available on the user's first Apple sign-in.
  static Future<Map<String, dynamic>> signInWithApple({
    required String identityToken,
    String? fullName,
    String? email,
  }) async {
    final url = Uri.parse('$baseUrl/auth/apple');
    try {
      final response = await http
          .post(
            url,
            headers: _headers(),
            body: jsonEncode({
              'IdentityToken': identityToken,
              'FullName': fullName,
              'Email': email,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (kDebugMode) print('API APPLE RESPONSE: ${response.statusCode}');
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? response.body,
          };
        } catch (_) {
          return {'success': false, 'message': response.body};
        }
      }
    } catch (e) {
      if (kDebugMode) print('API APPLE EXCEPTION: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> forgotPassword(String phoneNumber) async {
    final url = Uri.parse('$baseUrl/auth/forgot-password');
    try {
      final response = await http.post(
        url,
        headers: _headers(),
        body: jsonEncode({'PhoneNumber': phoneNumber}),
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': jsonDecode(response.body)['message'],
        };
      } else {
        return {
          'success': false,
          'message': jsonDecode(response.body)['message'] ?? response.body,
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> verifyOtp(
    String phoneNumber,
    String otp,
  ) async {
    final url = Uri.parse('$baseUrl/auth/verify-otp');
    try {
      final response = await http.post(
        url,
        headers: _headers(),
        body: jsonEncode({'PhoneNumber': phoneNumber, 'Otp': otp}),
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': jsonDecode(response.body)['message'],
        };
      } else {
        return {
          'success': false,
          'message': jsonDecode(response.body)['message'] ?? response.body,
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> resetPassword(
    String phoneNumber,
    String otp,
    String newPassword,
  ) async {
    final url = Uri.parse('$baseUrl/auth/reset-password');
    try {
      final response = await http.post(
        url,
        headers: _headers(),
        body: jsonEncode({
          'PhoneNumber': phoneNumber,
          'Otp': otp,
          'NewPassword': newPassword,
        }),
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': jsonDecode(response.body)['message'],
        };
      } else {
        return {
          'success': false,
          'message': jsonDecode(response.body)['message'] ?? response.body,
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Delivery prices the operator configured in the admin panel, used to label
  /// the Standard/Express choice at checkout. Display only - the server stamps
  /// the authoritative fee on the order from its own settings row.
  static Future<Map<String, dynamic>> getDeliveryPricing(String token) async {
    final url = Uri.parse('$baseUrl/settings/delivery-pricing');
    try {
      final response = await http.get(url, headers: _headers(token: token));

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return _errorResult(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createOrder({
    required double lat,
    required double lng,
    required String userId,
    required String token,
    String? marketingCode,

    /// 'Normal' or 'Express' - the server maps this to the delivery fee it
    /// stamps on the order.
    String type = 'Normal',
  }) async {
    final url = Uri.parse('$baseUrl/orders');
    try {
      final response = await http.post(
        url,
        headers: _headers(token: token),
        body: jsonEncode({
          'lat': lat,
          'long': lng,
          'userId': userId,
          'totalAmount': 0.0,
          'netAmount': 0.0,
          'deliveryAmount': 0.0,
          'cleanerAmount': 0.0,
          'marketingCode': marketingCode,
          'type': type,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return _errorResult(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getUserOrders({
    required String userId,
    required String token,
    int page = 1,
    int pageSize = 20,
  }) async {
    final url = Uri.parse(
      '$baseUrl/orders/user/$userId?page=$page&pageSize=$pageSize',
    );
    try {
      final response = await http.get(
        url,
        headers: _headers(token: token, json: false),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getUserLocations({
    required String userId,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/user-locations/$userId');
    try {
      final response = await http.get(
        url,
        headers: _headers(token: token, json: false),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> addUserLocation({
    required String userId,
    required String name,
    required double lat,
    required double lng,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/user-locations');
    try {
      final response = await http.post(
        url,
        headers: _headers(token: token),
        body: jsonEncode({
          'userId': userId,
          'name': name,
          'lat': lat,
          'long': lng,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteUserLocation({
    required String id,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/user-locations/$id');
    try {
      final response = await http.delete(
        url,
        headers: _headers(token: token, json: false),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Maps a picked file's extension to the image content type the backend
  /// whitelists. iOS commonly hands back .heic from the photo library, Android
  /// .jpg from the camera; both are accepted server-side. Unknown extensions
  /// fall back to jpeg rather than octet-stream, since image_picker only ever
  /// returns images.
  static MediaType _imageMediaType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      case 'heic':
        return MediaType('image', 'heic');
      case 'heif':
        return MediaType('image', 'heif');
      default:
        return MediaType('image', 'jpeg');
    }
  }

  // Support Ticket APIs
  //
  // Sent as multipart/form-data so an optional photo can ride along in the same
  // request. The backend endpoint is [Consumes("multipart/form-data")].
  static Future<Map<String, dynamic>> createTicket({
    required String userId,
    required String subject,
    required String message,
    required String category,
    required String token,
    String? attachmentPath,
  }) async {
    final url = Uri.parse('$baseUrl/support-tickets');
    try {
      final request = http.MultipartRequest('POST', url)
        ..headers.addAll(_headers(token: token, json: false))
        ..fields['userId'] = userId
        ..fields['subject'] = subject
        ..fields['message'] = message
        ..fields['category'] = category
        ..fields['status'] = 'Open';

      if (attachmentPath != null && attachmentPath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'attachment',
            attachmentPath,
            // Without this the part is sent as application/octet-stream, which the
            // backend rejects with ticket.attachment_invalid_type - it whitelists
            // image/* content types. MultipartFile does no extension sniffing.
            contentType: _imageMediaType(attachmentPath),
          ),
        );
      }

      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return _errorResult(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getUserTickets({
    required String userId,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/support-tickets/user/$userId');
    try {
      final response = await http.get(
        url,
        headers: _headers(token: token, json: false),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getAllTickets({
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/support-tickets');
    try {
      final response = await http.get(
        url,
        headers: _headers(token: token, json: false),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateTicketStatus({
    required String ticketId,
    required String status,
    String? response,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/support-tickets/$ticketId');
    try {
      final body = <String, dynamic>{'status': status};
      if (response != null) {
        body['response'] = response;
      }

      final httpResponse = await http.put(
        url,
        headers: _headers(token: token),
        body: jsonEncode(body),
      );

      if (httpResponse.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(httpResponse.body)};
      } else {
        return {'success': false, 'message': httpResponse.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateFcmToken({
    required String userId,
    required String fcmToken,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/auth/update-fcm-token');
    try {
      final response = await http.put(
        url,
        headers: _headers(token: token),
        body: jsonEncode({'userId': userId, 'token': fcmToken}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getNotifications(String token) async {
    final url = Uri.parse('$baseUrl/notifications');
    try {
      final response = await http.get(url, headers: _headers(token: token));

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> markAsRead(
    String id,
    String token,
  ) async {
    final url = Uri.parse('$baseUrl/notifications/$id/read');
    try {
      final response = await http.patch(url, headers: _headers(token: token));

      return {'success': response.statusCode == 200};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> markAllAsRead(String token) async {
    final url = Uri.parse('$baseUrl/notifications/read-all');
    try {
      final response = await http.patch(url, headers: _headers(token: token));

      return {'success': response.statusCode == 200};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteNotification(
    String id,
    String token,
  ) async {
    final url = Uri.parse('$baseUrl/notifications/$id');
    try {
      final response = await http.delete(url, headers: _headers(token: token));

      return {'success': response.statusCode == 200};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getItemTypes() async {
    final url = Uri.parse('$baseUrl/ItemTypes');
    try {
      final response = await http.get(url, headers: _headers());

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Marketing Code APIs
  static Future<Map<String, dynamic>> getMarketingCodes(String token) async {
    final url = Uri.parse('$baseUrl/MarketingCodes');
    try {
      final response = await http.get(
        url,
        headers: _headers(token: token, json: false),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createMarketingCode({
    required String code,
    required double discountPercentage,
    required double sharePercentage,
    required String marketerName,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/MarketingCodes');
    try {
      final response = await http.post(
        url,
        headers: _headers(token: token),
        body: jsonEncode({
          'code': code,
          'discountPercentage': discountPercentage,
          'sharePercentage': sharePercentage,
          'marketerName': marketerName,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteMarketingCode(
    String id,
    String token,
  ) async {
    final url = Uri.parse('$baseUrl/MarketingCodes/$id');
    try {
      final response = await http.delete(
        url,
        headers: _headers(token: token, json: false),
      );

      return {'success': response.statusCode == 200};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Deletes user account and all associated data from the server.
  static Future<Map<String, dynamic>> deleteAccount({
    required String userId,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/auth/delete-account/$userId');
    try {
      final response = await http.delete(url, headers: _headers(token: token));

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'success': true};
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? response.body,
          };
        } catch (_) {
          return {'success': false, 'message': response.body};
        }
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Driver trip APIs
  /// Trips assigned to the calling driver. The app buckets these into the
  /// collection / delivery tabs client-side by `status`, same as the admin
  /// dashboard - there is no separate trip "type" field.
  static Future<Map<String, dynamic>> getMyTrips({
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/Trips/my');
    try {
      final response = await http.get(
        url,
        headers: _headers(token: token, json: false),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> addOrderItems({
    required String orderId,
    required List<Map<String, dynamic>> items,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/orders/$orderId/items');
    try {
      final response = await http.post(
        url,
        headers: _headers(token: token),
        body: jsonEncode({'items': items}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> collectOrder({
    required String orderId,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/Trips/orders/$orderId/collect');
    try {
      final response = await http.post(
        url,
        headers: _headers(token: token, json: false),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? response.body,
          };
        } catch (_) {
          return {'success': false, 'message': response.body};
        }
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deliverToCleaner({
    required String tripId,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/Trips/$tripId/deliver-to-cleaner');
    try {
      final response = await http.post(
        url,
        headers: _headers(token: token, json: false),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? response.body,
          };
        } catch (_) {
          return {'success': false, 'message': response.body};
        }
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String status,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/Trips/orders/$orderId/status');
    try {
      final response = await http.put(
        url,
        headers: _headers(token: token),
        body: jsonEncode(status),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? response.body,
          };
        } catch (_) {
          return {'success': false, 'message': response.body};
        }
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deliverOrder({
    required String orderId,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/Trips/orders/$orderId/deliver');
    try {
      final response = await http.post(
        url,
        headers: _headers(token: token, json: false),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? response.body,
          };
        } catch (_) {
          return {'success': false, 'message': response.body};
        }
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
