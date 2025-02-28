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
  static Future<Map<String, dynamic>> punchOut(String latitude, String longitude) async {
    final url = Uri.parse("${Config.backendUrl}/punch-out");

    // Fetch the JWT token from your authentication service
    String? token = await AuthService.getToken();
    print("Stored Token: $token");

    if (token == null) {
      throw Exception("User is not authenticated");
    }

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token", // Pass JWT token in the header
      },
      body: json.encode({
        "latitude": latitude,
        "longitude": longitude,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(json.decode(response.body)['message'] ?? "Punch-out failed");
    }
  }
}


