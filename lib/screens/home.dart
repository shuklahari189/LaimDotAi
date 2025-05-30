import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'dart:io';

// ********************
// final authCode = await Clipboard.getData("text/plain");
//             if (authCode?.text?.split(" ")[0] != "code") {
// ********************
// hitting google api
// final refTokenPostResponse = await http.post(
//   Uri.parse('https://oauth2.googleapis.com/token'),
//   body: {
//     "code": 1,
//     "client_id": dotenv.env["GOOGLE_CLIENT_ID"],
//     "client_secret": dotenv.env["GOOGLE_CLIENT_SECRET"],
//     "redirect_uri": dotenv.env["GOOLGE_REDIRECT_URI"],
//     "grant_type": "authorization_code",
//   },
// );
// final Map<String, dynamic> refTokenData = jsonDecode(refTokenPostResponse.body);
// ********************
// hitting backend
// final addingUserToBackendPostResponse = await http.post(
//                 Uri.parse('${dotenv.env["BACKEND_API"]}/device/addDevice'),
//                 headers: {"Content-Type": "application/json"},
//                 body: jsonEncode({
//                   "userName": nameInputController.text,
//                   "emailId": mailId,
//                 }),
//               );
//               final Map<String, dynamic> addinUserToBacendResponseData =
//                   jsonDecode(addingUserToBackendPostResponse.body);
// *******************

class Home extends StatefulWidget {
  final Isar isar;
  const Home({super.key, required this.isar});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool showSettings = false;

  @override
  Widget build(BuildContext context) {
    List<Widget> stackedConents = List.empty(growable: true);

    // BG
    stackedConents.add(
      Center(
        child: SizedBox.expand(
          child: ClipRRect(
            borderRadius:
                (Platform.isAndroid || Platform.isIOS)
                    ? BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    )
                    : BorderRadius.all(Radius.zero),
            child: Image.asset(
              "./lib/assets/diamond_gradient_bacground.png",
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );

    // Settings
    if (showSettings) {
      stackedConents.add(
        Container(
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment(1, 0),
          child: Container(
            alignment: Alignment(-1, 0),
            width: 300,
            height: double.infinity,
            color: Colors.blue,
          ),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(children: [...stackedConents]),
        ),
      ),
    );
  }
}
