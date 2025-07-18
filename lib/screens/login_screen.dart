import 'package:siddhaconnect/screens/humanResource/hr_dashboard.dart';
import 'package:siddhaconnect/screens/humanResource/hr_sidebar.dart';
import 'package:siddhaconnect/screens/reset_password_screen.dart';
import 'package:siddhaconnect/services/auth_manager.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'employee/employee_dashboard.dart';
import 'dealer/dealer_dashboard.dart';
import 'mdd/mdd_dashboard.dart';
import 'admin/admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _login() async {
    if (_codeController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter both code and password")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final responseData = await ApiService.login(
        _codeController.text.trim(),
        _passwordController.text,
      );
      // ✅ Start token expiry timer HERE using context
      final token = responseData['token'];
      if (token != null) {
        AuthManager.startTokenExpiryTimer(context, token);
      }

      String role = responseData['user']['role'];

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login successful! Welcome, ${responseData['user']['name']}")),
      );

      if (role == "employee") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => EmployeeDashboard(user: responseData['user'])),
        );
      } else if (role == "dealer") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DealerDashboard(user: responseData['user'])),
        );
      } else if (role == "mdd") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MddDashboard(user: responseData['user'])),
        );
      } else if (role == "admin") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminDashboard(user: responseData['user'])),
        );
      } else if(role == "hr") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HrDashboard(user: responseData['user'])),
        );
      }
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Unknown role: $role. Contact support.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset("assets/company-logo.png", width: 250, height: 100),
              SizedBox(height: 10),
              // Text("Login to Siddha Connect", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              Text(
                "Welcome to Siddha Connect – Your Gateway to Smarter Insights and Field Operations!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              SizedBox(height: 30),
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: "Code",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromRGBO(255,61,0,0.8),
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text("Log in", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              SizedBox(height: 15),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ResetPasswordScreen()),
                  );
                },
                child: Text(
                  "Forgot password?",
                  style: TextStyle(
                    color: Colors.indigo,         // 🔷 Highlight color
                    fontWeight: FontWeight.bold,  // 💪 Bold text
                    fontSize: 15,                 // 🔠 Slightly larger
                    decoration: TextDecoration.underline, // 🔽 Underline (optional)
                  ),
                ),
              ),

              TextButton(onPressed: () {}, child: Text("Don't have an account? Sign up", style: TextStyle(color: Colors.black))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialLoginButton(IconData icon, String label) {
    return ElevatedButton.icon(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        minimumSize: Size(150, 45),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.black12),
        ),
      ),
      icon: Icon(icon, color: Colors.black),
      label: Text(label),
    );
  }
}
