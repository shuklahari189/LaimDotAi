import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:laim_ai/models/mail.dart';
import 'package:laim_ai/models/user.dart';
import 'package:laim_ai/code_assets/routes.dart';
import 'package:laim_ai/screens/login.dart';
import 'package:laim_ai/screens/home.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  final directory = await getApplicationDocumentsDirectory();

  final dbName = "EP_save";

  final isar = await Isar.open(
    [UserSchema, MailSchema],
    directory: directory.path,
    name: dbName,
  );

  runApp(MainApp(isar: isar));
}

class MainApp extends StatefulWidget {
  final Isar isar;
  const MainApp({super.key, required this.isar});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.login,
      routes: {
        Routes.home: (context) => Home(isar: widget.isar),
        Routes.login: (context) => Login(isar: widget.isar, addingUser: false),
        Routes.addUser: (context) => Login(isar: widget.isar, addingUser: true),
      },
    );
  }
}
