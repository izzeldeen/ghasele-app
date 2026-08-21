import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Defaults to production, so a build that forgets the override still points
  // somewhere real rather than silently failing against localhost.
  //
  // Override for local development:
  //   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5001/api
  // (10.0.2.2 is the Android emulator's host loopback; note iOS App Transport
  // Security blocks cleartext HTTP, so a device needs an HTTPS endpoint.)
  //
  // The /api suffix is required - controllers are routed at "api/[controller]".
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.cleanyjo.com/api',
  );

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
      print('API ERROR ${response.statusCode} '
          '${response.request?.url} code=$errorCode body=${response.body}');
    }

    return {
      'success': false,
      'statusCode': response.statusCode,
      'errorCode': errorCode,
      'message': (message != null && message.isNotEmpty) ? message : null,
    };
  }

  static Future<Map<String, dynamic>> signup({
    required String phoneNumber,
    required String password,
    required String fullName,
  }) async {
    final url = Uri.parse('$baseUrl/auth/signup');
    try {
      final response = await http.post(
        url,
        headers: _headers(),
        body: jsonEncode({
          'PhoneNumber': phoneNumber,
          'Password': password,
          'FullName': fullName,
        }),
      );

      if (kDebugMode) print('API SIGNUP RESPONSE: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {'success': false, 'message': errorData['message'] ?? response.body};
        } catch (_) {
          return {'success': false, 'message': response.body};
        }
      }
    } catch (e) {
      if (kDebugMode) print('API SIGNUP EXCEPTION: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String phoneNumber,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/signin');
    try {
      final response = await http.post(
        url,
        headers: _headers(),
        body: jsonEncode({
          'PhoneNumber': phoneNumber,
          'Password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      if (kDebugMode) print('API LOGIN RESPONSE: ${response.statusCode}');
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {'success': false, 'message': errorData['message'] ?? response.body};
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
      final response = await http.post(
        url,
        headers: _headers(),
        body: jsonEncode({
          'IdentityToken': identityToken,
          'FullName': fullName,
          'Email': email,
        }),
      ).timeout(const Duration(seconds: 15));

      if (kDebugMode) print('API APPLE RESPONSE: ${response.statusCode}');
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {'success': false, 'message': errorData['message'] ?? response.body};
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
        return {'success': true, 'message': jsonDecode(response.body)['message']};
      } else {
        return {'success': false, 'message': jsonDecode(response.body)['message'] ?? response.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp) async {
    final url = Uri.parse('$baseUrl/auth/verify-otp');
    try {
      final response = await http.post(
        url,
        headers: _headers(),
        body: jsonEncode({'PhoneNumber': phoneNumber, 'Otp': otp}),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'message': jsonDecode(response.body)['message']};
      } else {
        return {'success': false, 'message': jsonDecode(response.body)['message'] ?? response.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> resetPassword(String phoneNumber, String otp, String newPassword) async {
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
        return {'success': true, 'message': jsonDecode(response.body)['message']};
      } else {
        return {'success': false, 'message': jsonDecode(response.body)['message'] ?? response.body};
      }
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
    final url = Uri.parse('$baseUrl/orders/user/$userId?page=$page&pageSize=$pageSize');
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

  // Support Ticket APIs
  static Future<Map<String, dynamic>> createTicket({
    required String userId,
    required String subject,
    required String message,
    required String category,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/support-tickets');
    try {
      final response = await http.post(
        url,
        headers: _headers(token: token),
        body: jsonEncode({
          'userId': userId,
          'subject': subject,
          'message': message,
          'category': category,
          'status': 'Open',
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
      final body = <String, dynamic>{
        'status': status,
      };
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
        body: jsonEncode({
          'userId': userId,
          'token': fcmToken,
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

  static Future<Map<String, dynamic>> getNotifications(String token) async {
    final url = Uri.parse('$baseUrl/notifications');
    try {
      final response = await http.get(
        url,
        headers: _headers(token: token),
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

  static Future<Map<String, dynamic>> markAsRead(String id, String token) async {
    final url = Uri.parse('$baseUrl/notifications/$id/read');
    try {
      final response = await http.patch(
        url,
        headers: _headers(token: token),
      );

      return {'success': response.statusCode == 200};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> markAllAsRead(String token) async {
    final url = Uri.parse('$baseUrl/notifications/read-all');
    try {
      final response = await http.patch(
        url,
        headers: _headers(token: token),
      );

      return {'success': response.statusCode == 200};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteNotification(String id, String token) async {
    final url = Uri.parse('$baseUrl/notifications/$id');
    try {
      final response = await http.delete(
        url,
        headers: _headers(token: token),
      );

      return {'success': response.statusCode == 200};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getItemTypes() async {
    final url = Uri.parse('$baseUrl/ItemTypes');
    try {
      final response = await http.get(
        url,
        headers: _headers(),
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

  static Future<Map<String, dynamic>> deleteMarketingCode(String id, String token) async {
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
      final response = await http.delete(
        url,
        headers: _headers(token: token),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'success': true};
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {'success': false, 'message': errorData['message'] ?? response.body};
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
  static Future<Map<String, dynamic>> getMyTrips({required String token}) async {
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
      final response = await http.post(url, headers: _headers(token: token, json: false));

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {'success': false, 'message': errorData['message'] ?? response.body};
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
      final response = await http.post(url, headers: _headers(token: token, json: false));

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {'success': false, 'message': errorData['message'] ?? response.body};
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
          return {'success': false, 'message': errorData['message'] ?? response.body};
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
      final response = await http.post(url, headers: _headers(token: token, json: false));

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {'success': false, 'message': errorData['message'] ?? response.body};
        } catch (_) {
          return {'success': false, 'message': response.body};
        }
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
