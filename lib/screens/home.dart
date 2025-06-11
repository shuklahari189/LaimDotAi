import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'dart:io';
import 'package:laim_ai/components/body.dart';
import 'package:laim_ai/components/settings.dart';

class Home extends StatefulWidget {
  final Isar isar;
  const Home({super.key, required this.isar});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool showSettings = false;

  void setShowSettings(bool state) {
    setState(() {
      showSettings = state;
    });
  }

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

    // Body
    stackedConents.add(
      Body(isar: widget.isar, setShowSettings: setShowSettings),
    );

    // Settings
    double settingsWidth = 300;
    if (showSettings) {
      stackedConents.add(
        Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment(1, 0),
            child: Container(
              alignment: Alignment(-1, 0),
              width:
                  (Platform.isAndroid || Platform.isIOS)
                      ? double.infinity
                      : settingsWidth,
              height: double.infinity,
              child: Settings(
                setShowSettings: setShowSettings,
                isar: widget.isar,
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(children: [...stackedConents]),
      ),
    );
  }
}
