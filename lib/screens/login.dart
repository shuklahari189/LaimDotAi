import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:laim_ai/models/user.dart';
import 'package:laim_ai/code_assets/routes.dart';

class Login extends StatefulWidget {
  final Isar isar;
  final bool addingUser;
  const Login({super.key, required this.isar, required this.addingUser});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                (Platform.isAndroid || Platform.isIOS)
                    ? BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    )
                    : BorderRadius.all(Radius.zero),
          ),
          alignment: Alignment(0, 0),
          child:
              (Platform.isAndroid || Platform.isIOS)
                  ?
                  // Smartphone ui
                  LoginContent(isar: widget.isar, addingUser: widget.addingUser)
                  :
                  // Desktop ui
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: LoginContent(
                      isar: widget.isar,
                      addingUser: widget.addingUser,
                    ),
                  ),
        ),
      ),
    );
  }
}

class LoginContent extends StatefulWidget {
  final Isar isar;
  final bool addingUser;
  const LoginContent({super.key, required this.isar, required this.addingUser});

  @override
  State<LoginContent> createState() => _LoginContentState();
}

class _LoginContentState extends State<LoginContent> {
  bool pressedSignupButton = false;
  final nameInputController = TextEditingController();
  String refreshToken = "";
  String accessToken = "";
  String mailId = "";
  String authCode = "";
  bool canPressEnter = true;
  bool canPressSignUp = false;

  void enterIfLoggedIn() async {
    if (!widget.addingUser) {
      final existingUser =
          await widget.isar.users.filter().nameIsNotNull().findFirst();
      if (existingUser != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, Routes.home);
        });
      } else {
        setState(() {
          canPressSignUp = true;
        });
      }
    } else {
      setState(() {
        canPressSignUp = true;
      });
    }
  }

  @override
  void initState() {
    enterIfLoggedIn();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> beforeAndAfterRedirection = List.empty(growable: true);
    beforeAndAfterRedirection.add(
      Container(
        alignment: Alignment(-1, 0),
        padding: EdgeInsets.all(6),
        margin: EdgeInsets.only(bottom: 80),
        child: Text(
          (widget.addingUser) ? "Add User" : "Login",
          style: TextStyle(
            fontSize: 28,
            fontFamily: "Roboto",
            fontWeight: FontWeight.w100,
            color: const Color.fromARGB(255, 107, 107, 107),
          ),
        ),
      ),
    );

    if (!pressedSignupButton) {
      beforeAndAfterRedirection.add(
        MouseRegion(
          child: GestureDetector(
            onTap: () async {
              if (canPressSignUp) {
                final Uri url = Uri.parse(
                  'https://accounts.google.com/o/oauth2/v2/auth?access_type=offline&response_type=code&client_id=${dotenv.env["GOOGLE_CLIENT_ID"]}&redirect_uri=${dotenv.env["GOOLGE_REDIRECT_URI"]}&scope=email%20openid%20https://www.googleapis.com/auth/gmail.readonly&prompt=consent',
                );
                if (!await launchUrl(url)) {
                  print('Could not launch $url');
                } else {
                  setState(() {
                    pressedSignupButton = true;
                  });
                }
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                color: Color(0xFFFF7140),
                borderRadius: BorderRadius.all(Radius.circular(100)),
              ),
              child: Row(
                spacing: 10,
                children: [
                  Image.asset("./lib/assets/google_icon.png", width: 30),
                  Text(
                    "Sign up with Google",
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: "Roboto",
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      beforeAndAfterRedirection.add(
        TextField(
          decoration: InputDecoration(
            label: Text("Name"),
            labelStyle: TextStyle(color: Colors.black38),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: BorderSide(
                style: BorderStyle.solid,
                color: Colors.red,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: BorderSide(
                style: BorderStyle.solid,
                color: Colors.blue,
              ),
            ),
          ),
          style: TextStyle(color: Colors.black),
          cursorColor: Colors.black,
          cursorHeight: 20,
          controller: nameInputController,
        ),
      );
      beforeAndAfterRedirection.add(
        MouseRegion(
          child: GestureDetector(
            onTap: () async {
              if (canPressEnter && nameInputController.text.isNotEmpty) {
                setState(() {
                  canPressEnter = false;
                });

                if (authCode.isEmpty) {
                  // authCode
                  final clipBoardData = await Clipboard.getData("text/plain");
                  if (clipBoardData?.text != null) {
                    String clipBoardText = clipBoardData?.text as String;
                    if (clipBoardText.split(" ")[0] == "code") {
                      authCode = clipBoardText.split(" ")[1];
                    } else {
                      // todo
                    }
                  } else {
                    // todo
                  }

                  // accessToken, refreshToken, and
                  final getTokensPostResponse = await http.post(
                    Uri.parse('https://oauth2.googleapis.com/token'),
                    body: {
                      "code": authCode,
                      "client_id": dotenv.env["GOOGLE_CLIENT_ID"],
                      "client_secret": dotenv.env["GOOGLE_CLIENT_SECRET"],
                      "redirect_uri": dotenv.env["GOOLGE_REDIRECT_URI"],
                      "grant_type": "authorization_code",
                    },
                  );
                  final Map<String, dynamic> tokensData = jsonDecode(
                    getTokensPostResponse.body,
                  );
                  refreshToken = tokensData["refresh_token"];
                  accessToken = tokensData["access_token"];

                  // mailId
                  final getUserInfoGetResponse = await http.get(
                    Uri.parse('https://www.googleapis.com/oauth2/v3/userinfo'),
                    headers: {"Authorization": "Bearer $accessToken"},
                  );
                  final Map<String, dynamic> userInfoData = jsonDecode(
                    getUserInfoGetResponse.body,
                  );
                  mailId = userInfoData["email"];
                  setState(() {});
                }

                // adding user to bacend and getting correct (userName)
                final addingUserToBackendPostResponse = await http.post(
                  Uri.parse('${dotenv.env["BACKEND_API"]}/device/addDevice'),
                  headers: {"Content-Type": "application/json"},
                  body: jsonEncode({
                    "userName": nameInputController.text,
                    "emailId": mailId,
                  }),
                );
                final Map<String, dynamic> addinUserToBacendResponseData =
                    jsonDecode(addingUserToBackendPostResponse.body);

                // adding user to db
                User user = User(
                  addinUserToBacendResponseData["userName"],
                  refreshToken,
                  "",
                );
                widget.isar.writeTxn(() => widget.isar.users.put(user));

                setState(() {});
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacementNamed(context, Routes.home);
                });
              }
            },
            child: Container(
              margin: EdgeInsets.only(top: 10),
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: Color(0xFFFF7140),
                borderRadius: BorderRadius.all(Radius.circular(5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 10,
                children: [
                  Text(
                    "Enter",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: "Roboto",
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (widget.addingUser) {
      beforeAndAfterRedirection.add(
        MouseRegion(
          child: GestureDetector(
            onTap: () {
              setState(() {});
              Navigator.pushReplacementNamed(context, Routes.home);
            },
            child: Container(
              margin: EdgeInsets.only(top: 10),
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: Color(0xFFFF7140),
                borderRadius:
                    (pressedSignupButton)
                        ? BorderRadius.all(Radius.circular(5))
                        : BorderRadius.all(Radius.circular(100)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 10,
                children: [
                  Text(
                    "Cancel",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: "Roboto",
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 600 * 0.7,
      width: 455 * 0.7,
      padding: EdgeInsets.all(30),
      child: Column(
        children: [
          Container(
            alignment: Alignment(0, 0),
            padding: EdgeInsets.all(5),
            child: Row(
              spacing: 4,
              children: [
                Container(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Image.asset("./lib/assets/mail_box.png", width: 45),
                ),
                Text(
                  "Laim.ai",
                  style: TextStyle(
                    fontSize: 25,
                    fontFamily: "Roboto",
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF806C),
                  ),
                ),
              ],
            ),
          ),
          ...beforeAndAfterRedirection,
        ],
      ),
    );
  }
}
