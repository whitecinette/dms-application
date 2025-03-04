import 'package:flutter/material.dart';
import '../screens/employee/employee_sidebar.dart'; // Ensure correct import

class Header extends StatelessWidget implements PreferredSizeWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final dynamic user;

  Header({required this.scaffoldKey, required this.user});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Color(0xFF001F3F),
      elevation: 2,
      automaticallyImplyLeading: false, // Removes default hamburger
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Side: Hamburger Menu & Logo
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.menu, color: Colors.white, size: 28),
                onPressed: () {
                  scaffoldKey.currentState?.openDrawer();
                },
              ),
              SizedBox(width: 10),

              // LOGO instead of Text
              Image.asset(
                'assets/company-logo.png', // Path to logo
                height: 40, // Adjust size
              ),
            ],
          ),

          // Right Side: Profile Icon
          IconButton(
            icon: Icon(Icons.account_circle, color: Colors.white, size: 30),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
