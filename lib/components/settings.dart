import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:laim_ai/models/user.dart';
import 'package:laim_ai/code_assets/routes.dart';
import 'dart:convert';

class Settings extends StatefulWidget {
  final Function setShowSettings;
  final Isar isar;

  const Settings({
    super.key,
    required this.setShowSettings,
    required this.isar,
  });

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool loggingOut = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(204, 91, 53, 1),
        leading: GestureDetector(
          onTap: () {
            if (!loggingOut) {
              widget.setShowSettings(false);
            }
          },
          child: Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text("Settings", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () async {
                if (!loggingOut) {
                  setState(() {
                    loggingOut = true;
                  });

                  final List<User> usersfetched =
                      await widget.isar.users
                          .filter()
                          .nameIsNotNull()
                          .findAll();
                  for (var user in usersfetched) {
                    await http.post(
                      Uri.parse(
                        '${dotenv.env["BACKEND_API"]}/device/deleteDevice',
                      ),
                      headers: {"Content-Type": "application/json"},
                      body: jsonEncode({"userName": user.name}),
                    );
                  }

                  await widget.isar.writeTxn(() => widget.isar.clear());
                  setState(() {});
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.pushReplacementNamed(context, Routes.login);
                  });
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.pinkAccent, // Color at the top
                      Colors.blue, // Color at the bottom
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    "Logout",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Color.fromRGBO(204, 91, 53, 1),
    );
  }
}
