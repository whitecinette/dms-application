import 'package:flutter/material.dart';
enum MessageType { success, warning, info, error }

class CustomPopup {
  static void showPopup(BuildContext context, String title, String message, {bool? isSuccess, MessageType? type}) {
    Color titleColor;

    if (isSuccess != null) {
      // Preserve the existing success/error logic
      titleColor = isSuccess ? Colors.green : Colors.red;
    } else {
      // Handle info and warning messages
      switch (type) {
        case MessageType.success: // ✅ ADDED
          titleColor = Colors.green;
          break;
        case MessageType.warning:
          titleColor = Colors.orange;
          break;
        case MessageType.error:
          titleColor = Colors.red;
          break;
        case MessageType.info:
        default:
          titleColor = Colors.blue; // Default color if type is not specified
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: TextStyle(color: titleColor),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
}


