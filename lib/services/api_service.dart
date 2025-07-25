// lib/services/api_service.dart

import 'dart:convert';
import 'package:siddhaconnect/services/auth_manager.dart';
import 'package:siddhaconnect/services/auth_service.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'dart:io';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static Future<Map<String, dynamic>> login(String code, String password) async {
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
        print("User data received: ${responseData['user']}");
        await AuthService.saveUser(responseData["user"]);
      }

      return responseData;
    } else {
      throw Exception(json.decode(response.body)['message'] ?? "Login failed");
    }
  }

  // static Future<Map<String, dynamic>> punchIn(String latitude, String longitude, File image) async {
  //   final url = Uri.parse("${Config.backendUrl}/punch-in");
  //   String? token = await AuthService.getToken();
  //
  //   if (token == null) {
  //     return {
  //       "warning": true,
  //       "message": "User is not authenticated",
  //     };
  //   }
  //
  //   try {
  //     var request = http.MultipartRequest("POST", url);
  //     request.headers["Authorization"] = "Bearer $token";
  //     request.fields['latitude'] = latitude;
  //     request.fields['longitude'] = longitude;
  //
  //     final mimeType = lookupMimeType(image.path) ?? "image/jpeg";
  //     final fileStream = await http.MultipartFile.fromPath(
  //       'punchInImage',
  //       image.path,
  //       contentType: MediaType.parse(mimeType),
  //     );
  //
  //     request.files.add(fileStream);
  //
  //     final response = await request.send();
  //     final responseBody = await response.stream.bytesToString();
  //
  //     try {
  //       final decoded = json.decode(responseBody);
  //
  //       return {
  //         "statusCode": response.statusCode,
  //         ...decoded,
  //       };
  //     } catch (e) {
  //       return {
  //         "statusCode": response.statusCode,
  //         "warning": true,
  //         "message": "Server returned an unexpected response. Please try again later.",
  //         "rawResponse": responseBody,
  //       };
  //     }
  //   } catch (e) {
  //     return {
  //       "warning": true,
  //       "message": "Network or server error occurred: ${e.toString()}",
  //     };
  //   }
  // }



//punch out

  static Future<Map<String, dynamic>> punchIn(String latitude, String longitude, File image) async {
    final url = Uri.parse("${Config.backendUrl}/punch-in");
    print("📡 API URL: $url");

    String? token = await AuthService.getToken();

    if (token == null) {
      print("❌ No auth token found");
      return {
        "success": false,
        "warning": true,
        "message": "User is not authenticated",
      };
    }

    try {
      print("📤 Preparing Punch In Multipart Request...");
      var request = http.MultipartRequest("POST", url);
      request.headers["Authorization"] = "Bearer $token";

      request.fields['latitude'] = latitude;
      request.fields['longitude'] = longitude;

      print("📍 Latitude: $latitude, Longitude: $longitude");

      final mimeType = lookupMimeType(image.path) ?? "image/jpeg";
      final fileStream = await http.MultipartFile.fromPath(
        'punchInImage',
        image.path,
        contentType: MediaType.parse(mimeType),
      );

      request.files.add(fileStream);
      print("📎 Attached Image: ${image.path}, MIME: $mimeType");

      final fileSize = image.lengthSync();
      print("🖼️ Uploading image size: $fileSize bytes");

      print("🚀 Sending request...");
      final stopwatch = Stopwatch()..start();

      final response = await request.send();

      stopwatch.stop();
      print("⏱️ Request completed in ${stopwatch.elapsedMilliseconds} ms");

      final responseBody = await response.stream.bytesToString();
      print("📥 Raw response body: $responseBody");

      try {
        final decoded = json.decode(responseBody);
        print("✅ Parsed response: $decoded");

        return {
          "statusCode": response.statusCode,
          "success": response.statusCode == 200 || response.statusCode == 201,
          ...decoded,
        };
      } catch (e) {
        print("⚠️ JSON parsing failed: ${e.toString()}");

        return {
          "statusCode": response.statusCode,
          "success": false,
          "warning": true,
          "message": "Server returned an unexpected response. Please try again later.",
          "rawResponse": responseBody,
        };
      }
    } catch (e) {
      print("❗ Request failed: ${e.toString()}");
      return {
        "warning": true,
        "message": "Network or server error occurred: ${e.toString()}",
      };
    }
  }

  // static Future<Map<String, dynamic>> punchOut(String latitude, String longitude, File image, {String? dealerCode}) async {
  //   final url = Uri.parse("${Config.backendUrl}/punch-out");
  //
  //   // Fetch JWT token
  //   String? token = await AuthService.getToken();
  //   if (token == null) {
  //     throw Exception("User is not authenticated");
  //   }
  //
  //   var request = http.MultipartRequest("POST", url);
  //   request.headers["Authorization"] = "Bearer $token";
  //
  //   // ✅ Sending location data
  //   request.fields['latitude'] = latitude;
  //   request.fields['longitude'] = longitude;
  //   // ✅ Add dealerCode only if it's provided
  //   if (dealerCode != null && dealerCode.isNotEmpty) {
  //     request.fields['dealerCode'] = dealerCode;
  //   }
  //
  //   // ✅ Ensuring correct field name for backend (Must match multer field)
  //   final mimeType = lookupMimeType(image.path) ?? "image/jpeg";
  //   final fileStream = await http.MultipartFile.fromPath(
  //     'punchOutImage', // ✅ Field name should be "punchOutImage"
  //     image.path,
  //     contentType: MediaType.parse(mimeType),
  //   );
  //
  //   request.files.add(fileStream);
  //
  //   final response = await request.send();
  //   final responseBody = await response.stream.bytesToString();
  //
  //   final decoded = json.decode(responseBody);
  //
  //   if (response.statusCode == 201 || response.statusCode == 200) {
  //     return decoded;
  //   } else {
  //     // ❌ Error case
  //     throw Exception(decoded['message'] ?? "Punch-out failed");
  //   }
  // }

  static Future<Map<String, dynamic>> punchOut(String latitude, String longitude, File image) async {
    final url = Uri.parse("${Config.backendUrl}/punch-out");

    // Fetch JWT token
    String? token = await AuthService.getToken();
    if (token == null) {
      return {
        "success": false, // ✅ ADDED
        "warning": true,  // ✅ ADDED
        "message": "User is not authenticated", // ✅ ADDED
      };
    }

    try {
      var request = http.MultipartRequest("POST", url);
      request.headers["Authorization"] = "Bearer $token";

      request.fields['latitude'] = latitude;
      request.fields['longitude'] = longitude;

      // if (dealerCode != null && dealerCode.isNotEmpty) {
      //   request.fields['dealerCode'] = dealerCode;
      // }

      final mimeType = lookupMimeType(image.path) ?? "image/jpeg";
      final fileStream = await http.MultipartFile.fromPath(
        'punchOutImage',
        image.path,
        contentType: MediaType.parse(mimeType),
      );
      request.files.add(fileStream);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      // final decoded = json.decode(responseBody);

      // ✅ Decode response safely
      Map<String, dynamic> decoded;
      try {
        decoded = json.decode(responseBody);
      } catch (e) {
        print("⚠️ JSON decode failed: $e");
        return {
          "statusCode": response.statusCode,
          "success": false,
          "warning": true,
          "message": "Unexpected server response. Please try again later.",
          "raw": responseBody,
        };
      }
// ✅ Optionally handle 401 (token expired)
      if (response.statusCode == 401) {
        return {
          "statusCode": 401,
          "success": false,
          "warning": true,
          "message": "Session expired. Please log in again.",
        };
      }
      // ✅ Unified response structure with success + statusCode
      return {
        "statusCode": response.statusCode, // ✅ ADDED
        "success": response.statusCode == 200 || response.statusCode == 201, // ✅ ADDED
        ...decoded, // ✅ ADDED
      };
    } catch (e) {
      // ✅ Fallback structured error response instead of throwing
      return {
        "success": false, // ✅ ADDED
        "warning": true,  // ✅ ADDED
        "message": "Punch-out failed: ${e.toString()}", // ✅ ADDED
      };
    }
  }


// Get Weekly Beat Mapping Schedule
  static Future<Map<String, dynamic>> getWeeklyBeatMappingSchedule(String? startDate, String? endDate) async {
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

  static Future<Map<String, dynamic>> updateWeeklyBeatMappingStatusWithProximity(String scheduleId, String code, String status, double employeeLat, double employeeLong) async {
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

  static Future<Map<String, dynamic>> getUserDetails() async {final url = Uri.parse("${Config.backendUrl}/get-users-by-code");

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
  static Future<Map<String, dynamic>> editUser(Map<String, dynamic> updateData) async {
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
  static Future<Map<String, dynamic>> getAllAttendance({String? startDate, String? endDate, int page = 1, int limit = 10}) async {final queryParams = {if (startDate != null) 'startDate': startDate, if (endDate != null) 'endDate': endDate, 'page': page.toString(), 'limit': limit.toString(),};

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
  static Future<Map<String, dynamic>> getAllEmployees({int page = 1, int limit = 10}) async {final queryParams = {'page': page.toString(), 'limit': limit.toString(),};

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

    // ✅ Get JWT token using the same method as punchOut
    String? token = await AuthService.getToken();
    if (token == null) {
      throw Exception("User is not authenticated");
    }

    try {
      var request = http.MultipartRequest('PUT', url);
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['code'] = code;
      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();

      final mimeType = lookupMimeType(imageFile.path) ?? "image/jpeg";
      final imageMultipart = await http.MultipartFile.fromPath(
        'geotag_picture', // ✅ Must match multer field name
        imageFile.path,
        contentType: MediaType.parse(mimeType),
      );

      request.files.add(imageMultipart);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final decoded = json.decode(responseBody);
        print("✅ Geotag updated successfully: ${decoded['message']}");
      } else {
        final decoded = json.decode(responseBody);
        throw Exception(decoded['message'] ?? "Failed to update geotag");
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
  static Future<List<Map<String, dynamic>>> getEmployeeAttendance({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (status != null) queryParams['status'] = status;
    if (startDate != null) queryParams['startDate'] = startDate.toIso8601String().split('T').first;
    if (endDate != null) queryParams['endDate'] = endDate.toIso8601String().split('T').first;

    final uri = Uri.parse("${Config.backendUrl}/get-attandance").replace(queryParameters: queryParams);

    String? token = await AuthService.getToken();
    if (token == null) throw Exception("User not authenticated");

    try {
      final response = await http.get(
        uri,
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

  static Future<List<Map<String, dynamic>>> getJaipurDealers({String? search}) async {
    // Add search parameter to the query if it's provided
    final uri = Uri.parse('${Config.backendUrl}/get-jaipur-dealers')
        .replace(queryParameters: search != null ? {'search': search} : {});

    final response = await http.get(uri);
    print("Dealer API response: ${response.statusCode}");
    print("Body: ${response.body}");

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final List dealers = jsonResponse['data']; // ✅ Access `data` key
      return List<Map<String, dynamic>>.from(dealers);
    } else {
      throw Exception('Failed to load dealers: ${response.statusCode}');
    }
  }
// get hierarchy filters
  static Future<Map<String, List<Map<String, dynamic>>>> getHierarchyFilters({
    Map<String, String>? query,
  }) async {
    print("Hitting the hierarchy data...");

    final uri = Uri.parse('${Config.backendUrl}/get-hierarchy-filter')
        .replace(queryParameters: query ?? {});

    final response = await http.get(uri);
    print("Hierarchy API response: ${response.statusCode}");
    print("Body: ${response.body}");

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      // Convert each key (smd, asm, etc.) to List<Map>
      final Map<String, List<Map<String, dynamic>>> parsedData = {};
      jsonResponse.forEach((key, value) {
        parsedData[key] = List<Map<String, dynamic>>.from(value);
      });

      return parsedData;
    } else {
      throw Exception('Failed to load hierarchy filters: ${response.statusCode}');
    }
  }

//   leave request api
  static Future<Map<String, dynamic>> requestLeave(Map<String, dynamic> leaveData) async {
    print("📤 Sending leave request...");
    final url = Uri.parse("${Config.backendUrl}/request-leave");

    final token = await AuthService.getToken(); // assumes you saved token via login
    if (token == null) {
      throw Exception("No token found. Please login again.");
    }

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: json.encode(leaveData),
    );

    print("📥 Leave response status: ${response.statusCode}");

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print("✅ Leave request successful: $responseData");
      return responseData;
    } else {
      final error = json.decode(response.body);
      print("❌ Leave request failed: $error");
      throw Exception(error['message'] ?? error['error'] ?? "Leave request failed");
    }
  }

  static Future<List<Map<String, dynamic>>> getRequestedLeaves({
    String? fromDate,
    String? toDate,
    String? status,
  }) async {
    print("Fetching leave requests for logged-in employee");

    // Build query parameters map
    final queryParams = <String, String>{};
    if (fromDate != null) queryParams['fromDate'] = fromDate;
    if (toDate != null) queryParams['toDate'] = toDate;
    if (status != null) queryParams['status'] = status;

    // Build URI with query parameters
    final uri = Uri.parse('${Config.backendUrl}/get-requested-leave-emp').replace(queryParameters: queryParams);

    String? token = await AuthService.getToken();
    if (token == null) throw Exception("User not authenticated");

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print("Leave requests API response: ${response.statusCode}");
    print("Body: ${response.body}");

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      if (jsonResponse['success'] == true) {
        return List<Map<String, dynamic>>.from(jsonResponse['leaves']);
      } else {
        throw Exception('API returned success false');
      }
    } else {
      throw Exception('Failed to load leave requests: ${response.statusCode}');
    }
  }

}

