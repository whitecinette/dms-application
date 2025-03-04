// lib/services/api_service.dart

import 'dart:convert';
import 'package:dms_app/services/auth_service.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart'; // ✅ Import this for MediaType

class ApiService {
  static Future<Map<String, dynamic>> login(String code, String password) async {
    final url = Uri.parse("${Config.backendUrl}/app/user/login");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode({"code": code, "password": password}),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);

      // Ensure token exists in the response
      if (responseData.containsKey("token")) {
        await AuthService.saveToken(responseData["token"]);  // Save token
      } else {
        throw Exception("Token not found in response");
      }

      return responseData;
    } else {
      throw Exception(json.decode(response.body)['message'] ?? "Login failed");
    }
  }

  // punch in api
  static Future<Map<String, dynamic>> punchIn(String latitude, String longitude, File image) async {
    final url = Uri.parse("${Config.backendUrl}/punch-in");
    String? token = await AuthService.getToken();

    if (token == null) {
      throw Exception("User is not authenticated");
    }

    var request = http.MultipartRequest("POST", url);
    request.headers["Authorization"] = "Bearer $token";

    // ✅ Correct field names (Must match backend)
    request.fields['latitude'] = latitude;
    request.fields['longitude'] = longitude;

    // ✅ Ensure correct field name: "punchInImage" (Same as in Multer)
    final mimeType = lookupMimeType(image.path) ?? "image/jpeg";
    final fileStream = await http.MultipartFile.fromPath(
      'punchInImage', // ✅ Must match "punchInImage" in upload.single("punchInImage")
      image.path,
      contentType: MediaType.parse(mimeType),
    );

    request.files.add(fileStream);

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      return json.decode(responseBody);
    } else {
      throw Exception(json.decode(responseBody)['message'] ?? "Punch-in failed");
    }
  }


//punch out
  static Future<Map<String, dynamic>> punchOut(String latitude, String longitude, File image) async {
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

    if (response.statusCode == 201) {
      return json.decode(responseBody);
    } else {
      throw Exception(json.decode(responseBody)['message'] ?? "Punch-out failed");
    }
  }


// Get Weekly Beat Mapping Schedule
  static Future<Map<String, dynamic>> getWeeklyBeatMappingSchedule(String? startDate, String? endDate) async {
    final url = Uri.parse("${Config.backendUrl}/get-weekly-beat-mapping-schedule" +
        (startDate != null && endDate != null ? "?startDate=$startDate&endDate=$endDate" : ""));

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
        throw Exception(json.decode(response.body)['error'] ?? "Failed to fetch weekly beat mapping schedule");
      }
    } catch (e) {
      print("Error occurred: $e");
      throw Exception("Network error or invalid response: $e");
    }
  }


  static Future<Map<String, dynamic>> updateWeeklyBeatMappingStatusWithProximity(String scheduleId, String code, String status, double employeeLat, double employeeLong) async {

    print("API call initiated...");
    final url = Uri.parse("${Config.backendUrl}/update-beat-mapping-status-proximity/$scheduleId/$code");

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
        throw Exception(json.decode(response.body)['error'] ?? "Failed to update status");
      }
    } catch (e) {
      print("Error occurred: $e");
      throw Exception("Network error or invalid response: $e");
    }
  }

// // update weekly beat mapping schedule
//   static Future<Map<String, dynamic>> updateWeeklyBeatMappingStatus(String scheduleId, String dealerCode, String day, String status) async {
//     final url = Uri.parse("${Config.backendUrl}/update-weekly-beat-mapping-status/$scheduleId/$dealerCode");
//
//     String? token = await AuthService.getToken();
//     if (token == null) {
//       print("Token is null, user is not authenticated");
//       throw Exception("User is not authenticated");
//     }
//
//     try {
//       final response = await http.put(
//         url,
//         headers: {
//           "Authorization": "Bearer $token",
//           "Content-Type": "application/json"
//         },
//         body: jsonEncode({
//           "day": day,
//           "status": status
//         }),
//       );
//
//       if (response.statusCode == 200) {
//         return json.decode(response.body);
//       } else {
//         throw Exception(json.decode(response.body)['error'] ?? "Failed to update status");
//       }
//     } catch (e) {
//       print("Error occurred: $e");
//       throw Exception("Network error or invalid response: $e");
//     }
//   }



//   update weekly beat mapping shedule with proximity
}



