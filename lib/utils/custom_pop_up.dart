import 'package:flutter/material.dart';

class CustomPopup {
  static void showPopup(BuildContext context, String title, String message, {bool? isSuccess, MessageType? type}) {
    Color titleColor;

    if (isSuccess != null) {
      // Preserve the existing success/error logic
      titleColor = isSuccess ? Colors.green : Colors.red;
    } else {
      // Handle info and warning messages
      switch (type) {
        case MessageType.warning:
          titleColor = Colors.orange;
          break;
        case MessageType.info:
          titleColor = Colors.blue;
          break;
        default:
          titleColor = Colors.black; // Default color if type is not specified
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

enum MessageType { warning, info }

