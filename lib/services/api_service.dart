// lib/services/api_service.dart

import 'dart:convert';
import 'package:dms_app/services/auth_service.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'dart:io';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static Future<Map<String, dynamic>> login(
      String code, String password) async {
    print("logginnn");
    final url = Uri.parse("${Config.backendUrl}/app/user/login");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode({"code": code, "password": password}),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print("📬 Full login response: $responseData");

      // Save token
      if (responseData.containsKey("token")) {
        await AuthService.saveToken(responseData["token"]);
      }

      // ✅ Save user
      if (responseData.containsKey("user")) {
        await AuthService.saveUser(responseData["user"]);
      }

      return responseData;
    } else {
      throw Exception(json.decode(response.body)['message'] ?? "Login failed");
    }
  }

  static Future<Map<String, dynamic>> punchIn(
      String latitude, String longitude, File image) async {
    final url = Uri.parse("${Config.backendUrl}/punch-in");
    String? token = await AuthService.getToken();

    if (token == null) {
      return {
        "warning": true,
        "message": "User is not authenticated",
      };
    }

    var request = http.MultipartRequest("POST", url);
    request.headers["Authorization"] = "Bearer $token";
    request.fields['latitude'] = latitude;
    request.fields['longitude'] = longitude;

    final mimeType = lookupMimeType(image.path) ?? "image/jpeg";
    final fileStream = await http.MultipartFile.fromPath(
      'punchInImage',
      image.path,
      contentType: MediaType.parse(mimeType),
    );

    request.files.add(fileStream);

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final decoded = json.decode(responseBody);

    // ✅ Return full response to frontend no matter what
    return {
      "statusCode": response.statusCode,
      ...decoded,
    };
  }


//punch out
  static Future<Map<String, dynamic>> punchOut(
      String latitude, String longitude, File image) async {
    final url = Uri.parse("${Config.backendUrl}/punch-out");

    // Fetch JWT token
    String? token = await AuthService.getToken();
    if (token == null) {
      throw Exception("User is not authenticated");
    }

    var request = http.MultipartRequest("POST", url);
    request.headers["Authorization"] = "Bearer $token";

    // ✅ Sending location data
    request.fields['latitude'] = latitude;
    request.fields['longitude'] = longitude;

    // ✅ Ensuring correct field name for backend (Must match multer field)
    final mimeType = lookupMimeType(image.path) ?? "image/jpeg";
    final fileStream = await http.MultipartFile.fromPath(
      'punchOutImage', // ✅ Field name should be "punchOutImage"
      image.path,
      contentType: MediaType.parse(mimeType),
    );

    request.files.add(fileStream);

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    final decoded = json.decode(responseBody);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return decoded;
    } else {
      // ❌ Error case
      throw Exception(decoded['message'] ?? "Punch-out failed");
    }
  }

// Get Weekly Beat Mapping Schedule
  static Future<Map<String, dynamic>> getWeeklyBeatMappingSchedule(
      String? startDate, String? endDate) async {
    final url = Uri.parse(
        "${Config.backendUrl}/get-weekly-beat-mapping-schedule" +
            (startDate != null && endDate != null
                ? "?startDate=$startDate&endDate=$endDate"
                : ""));

    print("Request URL: $url");

    String? token = await AuthService.getToken();
    if (token == null) {
      print("Token is null, user is not authenticated");
      throw Exception("User is not authenticated");
    }

    try {
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      // print("Response Status: ${response.statusCode}");
      // print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);

        // Check if "data" exists and is a list
        if (responseBody.containsKey("data") && responseBody["data"] is List) {
          return responseBody;
        } else {
          throw Exception("Unexpected response format: Missing 'data' key");
        }
      } else {
        throw Exception(json.decode(response.body)['error'] ??
            "Failed to fetch weekly beat mapping schedule");
      }
    } catch (e) {
      print("Error occurred: $e");
      throw Exception("Network error or invalid response: $e");
    }
  }

  static Future<Map<String, dynamic>>
      updateWeeklyBeatMappingStatusWithProximity(String scheduleId, String code,
          String status, double employeeLat, double employeeLong) async {
    print("API call initiated...");
    final url = Uri.parse(
        "${Config.backendUrl}/update-beat-mapping-status-proximity/$scheduleId/$code");

    print("API URL: $url");

    String? token = await AuthService.getToken();
    if (token == null) {
      print("Token is null, user is not authenticated");
      throw Exception("User is not authenticated");
    }

    try {
      final response = await http.put(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode({
          "status": status,
          "employeeLat": employeeLat,
          "employeeLong": employeeLong
        }),
      );

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            json.decode(response.body)['error'] ?? "Failed to update status");
      }
    } catch (e) {
      print("Error occurred: $e");
      throw Exception("Network error or invalid response: $e");
    }
  }

  static Future<Map<String, dynamic>> getUserDetails() async {
    final url = Uri.parse("${Config.backendUrl}/get-users-by-code");

    String? token = await AuthService.getToken();
    if (token == null) {
      throw Exception("User is not authenticated");
    }

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(json.decode(response.body)['message'] ??
            "Failed to fetch user details");
      }
    } catch (e) {
      print("Error occurred: $e");
      throw Exception("Network error or invalid response: $e");
    }
  }

// update user details by  code
  static Future<Map<String, dynamic>> editUser(
      Map<String, dynamic> updateData) async {
    final url = Uri.parse("${Config.backendUrl}/edit-users-by-code");

    String? token = await AuthService.getToken();
    if (token == null) {
      throw Exception("User is not authenticated");
    }

    try {
      final response = await http.put(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode({"updateData": updateData}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            json.decode(response.body)['message'] ?? "Failed to update user");
      }
    } catch (e) {
      print("Error occurred: $e");
      throw Exception("Network error or invalid response: $e");
    }
  }

  // Get all attendance records
  static Future<Map<String, dynamic>> getAllAttendance(
      {String? startDate,
      String? endDate,
      int page = 1,
      int limit = 10}) async {
    final queryParams = {
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final url = Uri.parse("${Config.backendUrl}/get-all-attendance")
        .replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(json.decode(response.body)['message'] ??
            "Failed to fetch attendance records");
      }
    } catch (e) {
      print("Error occurred: $e");
      throw Exception("Network error or invalid response: $e");
    }
  }

// get all employees
  static Future<Map<String, dynamic>> getAllEmployees(
      {int page = 1, int limit = 10}) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final url = Uri.parse("${Config.backendUrl}/get-emp-for-hr")
        .replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(json.decode(response.body)['message'] ??
            "Failed to fetch employee records");
      }
    } catch (e) {
      print("Error occurred: $e");
      throw Exception("Network error or invalid response: $e");
    }
  }

  // get salary for all employee
  static Future<Map<String, dynamic>> getAllSalaries() async {
    final url = Uri.parse("${Config.backendUrl}/salary-details");

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(json.decode(response.body)['message'] ??
            "Failed to fetch salary details");
      }
    } catch (e) {
      print("Error occurred: $e");
      throw Exception("Network error or invalid response: $e");
    }
  }

  static Future<Map<String, dynamic>> getUserProfile() async {
    final url = Uri.parse(
        "${Config.backendUrl}/app/user/profile"); // or your actual profile endpoint
    String? token = await AuthService.getToken();

    if (token == null) {
      throw Exception("User is not authenticated");
    }

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData[
            "user"]; // assuming your API returns { success: true, user: {...} }
      } else {
        throw Exception("Failed to fetch user profile");
      }
    } catch (e) {
      print("Profile fetch error: $e");
      throw Exception("Something went wrong while fetching user info");
    }
  }

// get dealer by employee code
  static Future<List<Map<String, dynamic>>> getDealersByEmployee() async {
    final url = Uri.parse("${Config.backendUrl}/get-dealer-by-employee");

    String? token = await AuthService.getToken();
    if (token == null) {
      throw Exception("User is not authenticated");
    }

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData.containsKey("dealers") &&
            responseData["dealers"] is List) {
          final dealersData =
              List<Map<String, dynamic>>.from(responseData["dealers"]);
          // print("✅ Dealers fetched successfully: $dealersData");
          return dealersData;
        } else {
          throw Exception("No dealers found for this employee.");
        }
      } else {
        final errorData = json.decode(response.body);
        print("❌ Error fetching dealers: ${errorData['message']}");
        throw Exception(
            errorData['message'] ?? "Failed to fetch dealer details.");
      }
    } catch (e) {
      print("❗ Error occurred: $e");
      throw Exception("Network error or invalid response: $e");
    }
  }

// Update geo_tag picture latitude and longitude
  static Future<void> updateGeotag({
    required String code,
    required double latitude,
    required double longitude,
    required File imageFile,
  }) async {
    final url = Uri.parse("${Config.backendUrl}/update-geo-tag-lat-long");
    try {
      var request = http.MultipartRequest('PUT', url)
        ..headers['Content-Type'] = 'multipart/form-data' // Add this header
        ..fields['code'] = code
        ..fields['latitude'] = latitude.toString()
        ..fields['longitude'] = longitude.toString()
        ..files.add(
          await http.MultipartFile.fromPath(
            'geotag_picture',
            imageFile.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );

      final response = await request.send();

      final responseData = await response.stream.bytesToString();
      // log("🔎 Response Data: $responseData");

      if (response.statusCode == 200) {
        final decodedData = json.decode(responseData);
        print("✅ Geotag updated successfully: ${decodedData['message']}");
      } else {
        print("❌ Error updating geotag: ${response.reasonPhrase}");
        throw Exception("Failed to update geotag: ${response.reasonPhrase}");
      }
    } catch (e) {
      print("❗ Error occurred: $e");
      throw Exception("Network error or invalid response: $e");
    }
  }

  // get all weekly beat mapping status
  static Future<List<Map<String, dynamic>>> getAllWeeklyBeatMapping({
    String? status,
    String? searchQuery,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = {
      if (status != null && status != 'all') 'status': status,
      if (searchQuery != null && searchQuery.isNotEmpty) 'search': searchQuery,
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final queryString = Uri(queryParameters: queryParams).query;
    final url = Uri.parse(
        "${Config.backendUrl}/get-all-weekly-beat-mapping?$queryString");

    String? token = await AuthService.getToken();
    if (token == null) throw Exception("User not authenticated");

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data["data"] ?? []);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? "Error fetching data");
      }
    } catch (e) {
      throw Exception("❗ Network error: $e");
    }
  }

// get attendance by employee
  static Future<List<Map<String, dynamic>>> getEmployeeAttendance(
      {String? status}) async {
    String queryString = status != null ? "?status=$status" : "";
    final url = Uri.parse("${Config.backendUrl}/get-attandance$queryString");

    String? token = await AuthService.getToken();
    if (token == null) throw Exception("User not authenticated");

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['data'] != null && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          return [];
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? "Error fetching data");
      }
    } catch (e) {
      throw Exception("❗ Network error: $e");
    }
  }
}
