import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Production server URL — HTTPS required for App Store / Play Store
  static const String baseUrl = 'http://65.109.146.40/drycleane/api';

  static Future<Map<String, dynamic>> signup({
    required String phoneNumber,
    required String password,
    required String fullName,
  }) async {
    final url = Uri.parse('$baseUrl/auth/signup');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
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
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'PhoneNumber': phoneNumber,
          'Password': password,
        }),
      );

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
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getUserOrders({
    required String userId,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/orders/user/$userId');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
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
        headers: {
          'Authorization': 'Bearer $token',
        },
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
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
        headers: {
          'Authorization': 'Bearer $token',
        },
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
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
        headers: {
          'Authorization': 'Bearer $token',
        },
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
        headers: {
          'Authorization': 'Bearer $token',
        },
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
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
        headers: {
          'Content-Type': 'application/json',
        },
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
        headers: {
          'Authorization': 'Bearer $token',
        },
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
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
        headers: {
          'Authorization': 'Bearer $token',
        },
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
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
}
