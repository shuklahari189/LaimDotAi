import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:flutter/gestures.dart';
import 'package:laim_ai/code_assets/fetch_process_and_store_mail.dart';
import 'package:laim_ai/code_assets/dates_and_strings.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:laim_ai/code_assets/colors.dart';
import 'dart:io';
import 'package:laim_ai/code_assets/routes.dart';
import 'package:laim_ai/code_assets/categories.dart';
import 'package:laim_ai/models/user.dart';
import 'package:laim_ai/models/mail.dart';

class Body extends StatefulWidget {
  final Isar isar;
  final Function setShowSettings;
  const Body({super.key, required this.isar, required this.setShowSettings});

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  String categorySelected = Categories.todo;
  List<User> users = List.empty(growable: true);
  String userSelected = "all";
  List<Mail> mails = List.empty(growable: true);
  bool loading = true;
  Map<String, int> usersAndTheirColorId = {};
  Map<String, int> mailCountList = {};

  void toggleCompleted(String? messageId) async {
    final toggleCompleteTodoRespponse = await http.post(
      Uri.parse('${dotenv.env["BACKEND_API"]}/todo/changeCompleteStatus'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"messageId": messageId}),
    );
    final toggleCompleteTodoResponseData = jsonDecode(
      toggleCompleteTodoRespponse.body,
    );
    for (int i = 0; i < mails.length; i++) {
      if (mails[i].messageId == messageId) {
        mails[i].completed = toggleCompleteTodoResponseData["completed"];
        if (mails[i].completed as bool) {
          mailCountList[Categories.complete] =
              (mailCountList[Categories.complete] as int) + 1;
          mailCountList[Categories.todo] =
              (mailCountList[Categories.todo] as int) - 1;
        } else {
          mailCountList[Categories.complete] =
              (mailCountList[Categories.complete] as int) - 1;
          mailCountList[Categories.todo] =
              (mailCountList[Categories.todo] as int) + 1;
        }
      }
    }

    setState(() {});
  }

  void toggleArchived(String? messageId) async {
    Mail? mail =
        await widget.isar.mails
            .filter()
            .messageIdEqualTo(messageId)
            .findFirst();

    if (mail != null) {
      mail.archived = !(mail.archived ?? false);
      await widget.isar.writeTxn(() async {
        await widget.isar.mails.put(mail);
      });

      for (int i = 0; i < mails.length; i++) {
        if (mails[i].messageId == messageId) {
          mails[i].archived = mail.archived;
          if (mails[i].archived as bool) {
            mailCountList[Categories.archive] =
                (mailCountList[Categories.archive] as int) + 1;
            mailCountList[mails[i].type as String] =
                (mailCountList[mails[i].type as String] as int) - 1;
          } else {
            mailCountList[Categories.archive] =
                (mailCountList[Categories.archive] as int) - 1;
            mailCountList[mails[i].type as String] =
                (mailCountList[mails[i].type as String] as int) + 1;
          }
        }
      }
    } else {
      final toggleArchivedTodoResponse = await http.post(
        Uri.parse('${dotenv.env["BACKEND_API"]}/todo/changeArchiveStatus'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"messageId": messageId}),
      );
      final toggleArchivedTodoResponseData = jsonDecode(
        toggleArchivedTodoResponse.body,
      );
      for (int i = 0; i < mails.length; i++) {
        if (mails[i].messageId == messageId) {
          mails[i].archived = toggleArchivedTodoResponseData["archived"];
          if (mails[i].archived as bool) {
            mailCountList[Categories.archive] =
                (mailCountList[Categories.archive] as int) + 1;
            if (mails[i].completed as bool) {
              mailCountList[Categories.complete] =
                  (mailCountList[Categories.complete] as int) - 1;
            } else {
              mailCountList[Categories.todo] =
                  (mailCountList[Categories.todo] as int) - 1;
            }
          } else {
            mailCountList[Categories.archive] =
                (mailCountList[Categories.archive] as int) - 1;
            if (mails[i].completed as bool) {
              mailCountList[Categories.complete] =
                  (mailCountList[Categories.complete] as int) + 1;
            } else {
              mailCountList[Categories.todo] =
                  (mailCountList[Categories.todo] as int) + 1;
            }
          }
        }
      }
    }
    setState(() {});
  }

  void setCategorySelected(String category) {
    setState(() {
      categorySelected = category;
    });
  }

  void settingNumbers() {
    for (int i = 0; i < users.length; i++) {
      mailCountList[users[i].name as String] = 0;
    }
    for (int i = 0; i < categories.length; i++) {
      mailCountList[categories[i]] = 0;
    }
    mailCountList["all"] = 0;
    for (int i = 0; i < mails.length; i++) {
      if (mails[i].type != Categories.empty) {
        mailCountList[mails[i].forName as String] =
            (mailCountList[mails[i].forName as String] as int) + 1;
        mailCountList["all"] = (mailCountList["all"] as int) + 1;
        if (userSelected == "all") {
          if (mails[i].type == Categories.todo &&
              mails[i].completed as bool &&
              !(mails[i].archived as bool)) {
            mailCountList[Categories.complete] =
                (mailCountList[Categories.complete] as int) + 1;
          } else if (mails[i].archived as bool) {
            mailCountList[Categories.archive] =
                (mailCountList[Categories.archive] as int) + 1;
          } else {
            mailCountList[mails[i].type as String] =
                (mailCountList[mails[i].type as String] as int) + 1;
          }
        } else if (mails[i].forName == userSelected) {
          if (mails[i].type == Categories.todo &&
              mails[i].completed as bool &&
              !(mails[i].archived as bool)) {
            mailCountList[Categories.complete] =
                (mailCountList[Categories.complete] as int) + 1;
          } else if (mails[i].archived as bool) {
            mailCountList[Categories.archive] =
                (mailCountList[Categories.archive] as int) + 1;
          } else {
            mailCountList[mails[i].type as String] =
                (mailCountList[mails[i].type as String] as int) + 1;
          }
        }
      }
    }
  }

  void setUserSelected(String user) {
    setState(() {
      userSelected = user;
      settingNumbers();
    });
  }

  Future<void> fetchAndSetMails() async {
    mails.clear();
    final List<Mail> mailsFetched =
        await widget.isar.mails.filter().forNameIsNotNull().findAll();
    mails.addAll(mailsFetched);
    for (int i = 0; i < users.length; i++) {
      final todosRequestResponse = await http.post(
        Uri.parse('${dotenv.env["BACKEND_API"]}/todo/getAllTodos'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userName": users[i].name?.toLowerCase()}),
      );
      final List<dynamic> allTodos = jsonDecode(todosRequestResponse.body);
      for (int i = 0; i < allTodos.length; i++) {
        Mail mail = Mail(
          allTodos[i]["type"],
          allTodos[i]["body"],
          allTodos[i]["senderName"],
          allTodos[i]["senderEmail"],
          allTodos[i]["messageId"],
          dateFromString(allTodos[i]["timeReceivedInStr"]),
          allTodos[i]["forName"].toLowerCase(),
          allTodos[i]["archived"],
          dateFromString(allTodos[i]["dueDateInStr"]),
          allTodos[i]["completed"],
        );
        mails.add(mail);
      }
    }

    settingNumbers();

    if (mounted) {
      setState(() {});
    }
  }

  void setup() async {
    final List<User> usersfetched =
        await widget.isar.users.filter().nameIsNotNull().findAll();
    users.addAll(usersfetched);
    for (int i = 0; i < usersfetched.length; i++) {
      usersAndTheirColorId[usersfetched[i].name as String] =
          usersfetched[i].colorId;
    }

    await fetchAndSetMails();

    setState(() {
      loading = false;
    });
  }

  @override
  void initState() {
    setup();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> content = List.empty(growable: true);

    // navbar
    List<Widget> navBar = List.empty(growable: true);
    if (!(Platform.isAndroid || Platform.isIOS)) {
      navBar.add(
        UsersMenu(
          users: users,
          userSelected: userSelected,
          setUserSelected: setUserSelected,
          mailCountList: mailCountList,
        ),
      );
    }
    navBar.add(
      GestureDetector(
        onTap: () async {
          if (!loading) {
            setState(() {
              loading = true;
            });
            for (int i = 0; i < users.length; i++) {
              await FPSMail.run(
                widget.isar,
                users[i].name,
                users[i].refreshToken,
              );
            }
            await fetchAndSetMails();
            if (mounted) {
              setState(() {
                loading = false;
              });
            }
          }
        },
        child: Image.asset("lib/assets/reload.png", width: 30),
      ),
    );
    navBar.add(
      GestureDetector(
        onTap: () {
          widget.setShowSettings(true);
        },
        child: Image.asset("lib/assets/settings.png", width: 100),
      ),
    );

    // navbar
    content.add(
      Container(
        padding: EdgeInsets.only(left: 40, right: 40, top: 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CategoriesDropDown(
              categorySelected: categorySelected,
              setCategorySelected: setCategorySelected,
              mailCountList: mailCountList,
            ),
            SizedBox(child: Row(spacing: 10, children: navBar)),
          ],
        ),
      ),
    );
    if (Platform.isAndroid || Platform.isIOS) {
      content.add(
        Container(
          padding: EdgeInsets.only(left: 40, right: 40, top: 10),
          color: Colors.transparent,
          child: UsersMenu(
            users: users,
            userSelected: userSelected,
            setUserSelected: setUserSelected,
            mailCountList: mailCountList,
          ),
        ),
      );
    }

    // body
    List<Widget> mailElements = List.empty(growable: true);

    for (int i = mails.length - 1; i > -1; i--) {
      bool typeCondition =
          ((mails[i].type == categorySelected &&
                  mails[i].archived == false &&
                  mails[i].completed == false) ||
              (mails[i].completed == true &&
                  categorySelected == Categories.complete &&
                  mails[i].archived == false) ||
              (mails[i].completed == false &&
                  categorySelected == Categories.todo &&
                  mails[i].archived == false &&
                  mails[i].type == Categories.todo) ||
              (mails[i].archived == true &&
                  categorySelected == Categories.archive));
      bool emptyCondition = (mails[i].type != Categories.empty);
      bool userCondition =
          (userSelected == "all" || userSelected == mails[i].forName);

      if (typeCondition && emptyCondition && userCondition) {
        if (Platform.isAndroid || Platform.isIOS) {
          mailElements.add(
            MobileMail(
              body: mails[i].body as String,
              from: mails[i].senderName as String,
              forName: mails[i].forName as String,
              recievedDate: mails[i].timeReceived ?? DateTime.now(),
              dueDate: mails[i].dueDate,
              type: mails[i].type as String,
              toggleArchived: toggleArchived,
              toggleCompleted:
                  (mails[i].type == "todo") ? toggleCompleted : null,
              usersAndTheirColorId: usersAndTheirColorId,
              completed: mails[i].completed,
              archived: mails[i].archived as bool,
              messageId: mails[i].messageId as String,
            ),
          );
        } else {
          mailElements.add(
            DesktopMail(
              body: mails[i].body as String,
              from: mails[i].senderName as String,
              forName: mails[i].forName as String,
              recievedDate: mails[i].timeReceived ?? DateTime.now(),
              dueDate: mails[i].dueDate,
              type: mails[i].type as String,
              toggleArchived: toggleArchived,
              toggleCompleted:
                  (mails[i].type == "todo") ? toggleCompleted : null,
              usersAndTheirColorId: usersAndTheirColorId,
              completed: mails[i].completed,
              archived: mails[i].archived as bool,
              messageId: mails[i].messageId as String,
            ),
          );
        }
      }
    }

    if (loading) {
      content.add(Expanded(child: Center(child: CircularProgressIndicator())));
    } else {
      content.add(
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
            child: ListView(children: mailElements),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Column(children: content),
    );
  }
}

class DesktopMail extends StatefulWidget {
  final String body;
  final String from;
  final String forName;
  final DateTime recievedDate;
  final DateTime? dueDate;
  final String type;
  final Function toggleArchived;
  final Function? toggleCompleted;
  final Map<String, int> usersAndTheirColorId;
  final bool? completed;
  final bool archived;
  final String messageId;

  const DesktopMail({
    super.key,
    required this.body,
    required this.from,
    required this.forName,
    required this.recievedDate,
    required this.type,
    required this.toggleArchived,
    this.toggleCompleted,
    this.dueDate,
    required this.usersAndTheirColorId,
    this.completed,
    required this.archived,
    required this.messageId,
  });

  @override
  State<DesktopMail> createState() => _DesktopMailState();
}

class _DesktopMailState extends State<DesktopMail> {
  bool expaded = false;

  @override
  Widget build(BuildContext context) {
    Map<String, String> dateAndTime = formatDateTime(widget.recievedDate);

    return Container(
      margin: EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            blurRadius: 5,
            spreadRadius: 0.2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      child: Row(
        spacing: 20,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  expaded = !expaded;
                });
              },
              child: Text(
                widget.body,
                overflow: (expaded) ? null : TextOverflow.ellipsis,
              ),
            ),
          ),
          Text(widget.from),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(dateAndTime["date"] as String),
              Text(dateAndTime["time"] as String),
            ],
          ),
          ActionDropDown(
            toggleArchived: widget.toggleArchived,
            toggleCompleted: widget.toggleCompleted,
            type: widget.type,
            archived: widget.archived,
            completed: widget.completed,
            messageId: widget.messageId,
          ),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(100)),
              color:
                  colorList[widget.usersAndTheirColorId[widget.forName] as int],
            ),
          ),
        ],
      ),
    );
  }
}

class MobileMail extends StatefulWidget {
  final String body;
  final String from;
  final String forName;
  final DateTime recievedDate;
  final DateTime? dueDate;
  final String type;
  final Function toggleArchived;
  final Function? toggleCompleted;
  final Map<String, int> usersAndTheirColorId;
  final bool? completed;
  final bool archived;
  final String messageId;

  const MobileMail({
    super.key,
    required this.body,
    required this.from,
    required this.forName,
    required this.recievedDate,
    required this.type,
    required this.toggleArchived,
    this.toggleCompleted,
    this.dueDate,
    required this.usersAndTheirColorId,
    this.completed,
    required this.archived,
    required this.messageId,
  });

  @override
  State<MobileMail> createState() => _MobileMailState();
}

class _MobileMailState extends State<MobileMail> {
  bool expaded = false;

  @override
  Widget build(BuildContext context) {
    Map<String, String> dateAndTime = formatDateTime(widget.recievedDate);

    return Container(
      margin: EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            blurRadius: 5,
            spreadRadius: 0.2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      expaded = !expaded;
                    });
                  },
                  child: Text(
                    widget.body,
                    overflow: (expaded) ? null : TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(widget.from)),
                    SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(dateAndTime["date"] as String),
                        Text(
                          dateAndTime["time"] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.w100,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 20),
                    ActionDropDown(
                      toggleArchived: widget.toggleArchived,
                      toggleCompleted: widget.toggleCompleted,
                      type: widget.type,
                      archived: widget.archived,
                      completed: widget.completed,
                      messageId: widget.messageId,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 10),
          Container(
            width: 5,
            height: 5,
            margin: EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  colorList[widget.usersAndTheirColorId[widget.forName] as int],
            ),
          ),
        ],
      ),
    );
  }
}

class ActionDropDown extends StatefulWidget {
  final String type;
  final Function toggleArchived;
  final Function? toggleCompleted;
  final bool archived;
  final bool? completed;
  final String messageId;
  const ActionDropDown({
    super.key,
    required this.toggleArchived,
    this.toggleCompleted,
    required this.type,
    required this.archived,
    this.completed,
    required this.messageId,
  });

  @override
  State<ActionDropDown> createState() => _ActionDropDownState();
}

class _ActionDropDownState extends State<ActionDropDown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isDropdownOpen = false;

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    if (mounted) {
      setState(() {
        _isDropdownOpen = true;
      });
    }
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {
        _isDropdownOpen = false;
      });
    }
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Size size = renderBox.size;
    Offset offset = renderBox.localToGlobal(Offset.zero);

    final screenSize = MediaQuery.of(context).size;
    const dropdownHeight = 124;
    const dropdownWidth = 200;

    // Vertical space calculations
    final spaceBelow = screenSize.height - (offset.dy + size.height);
    final spaceAbove = offset.dy;
    final openAbove =
        spaceBelow < dropdownHeight && spaceAbove > dropdownHeight;

    // Horizontal space calculations
    final spaceRight = screenSize.width - offset.dx;
    final shiftLeft = spaceRight < dropdownWidth;

    final dx =
        shiftLeft
            ? (offset.dx + size.width - dropdownWidth).clamp(
              0.0,
              screenSize.width - dropdownWidth,
            )
            : offset.dx;
    final dy =
        openAbove
            ? offset.dy - dropdownHeight - 5
            : offset.dy + size.height + 5;

    String hoveringOver = "";
    String moveTo = "move to";
    String todo = "todo";
    String complete = "complete";
    String archive = "archive";
    Map<String, Gradient> categoriesAndGradients = {
      moveTo: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFFE0E0E0), // light gray
          Color.fromARGB(255, 219, 25, 25), // bluish gradient
        ],
      ),
      todo: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFFE0E0E0), // light gray
          Color.fromARGB(255, 219, 25, 25), // bluish gradient
        ],
      ),
      complete: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFFE0E0E0), // light gray
          Color.fromARGB(255, 0, 115, 255), // bluish gradient
        ],
      ),
      archive: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFFE0E0E0), // light gray
          Color.fromARGB(255, 0, 255, 64), // bluish gradient
        ],
      ),
    };

    return OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Closer
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeDropdown,
                behavior: HitTestBehavior.translucent,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color:
                      (Platform.isAndroid || Platform.isIOS)
                          ? Colors.black38
                          : Colors.transparent,
                ),
              ),
            ),
            // Dropdown
            Positioned(
              left: dx - 70,
              top: dy + ((openAbove) ? 58 : -58),
              child: StatefulBuilder(
                builder: (context, setStateOverlay) {
                  List<Widget> dropDownOptions = List.empty(growable: true);

                  // heading move to
                  dropDownOptions.add(
                    Material(
                      color: Colors.transparent,
                      child: MouseRegion(
                        onEnter: (_) {
                          setStateOverlay(() {
                            hoveringOver = moveTo;
                          });
                        },
                        onExit: (_) {
                          setStateOverlay(() {
                            if (hoveringOver == moveTo) {
                              hoveringOver = "";
                            }
                          });
                        },
                        child: GestureDetector(
                          onTap: () {
                            _closeDropdown();
                          },
                          child: Container(
                            width: 300,
                            padding: EdgeInsets.only(
                              top: 5 + 5,
                              left: 10 + 5,
                              bottom: 5 + 5,
                              right: 10 + 5,
                            ),
                            decoration: BoxDecoration(
                              gradient:
                                  ((hoveringOver == moveTo) ||
                                          (Platform.isAndroid ||
                                              Platform.isIOS))
                                      ? categoriesAndGradients[moveTo]
                                      : null,
                              border: Border.all(color: Colors.white),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              spacing: 10,
                              children: [
                                Expanded(
                                  child: Text(
                                    moveTo,
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontFamily: "Roboto",
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Image.asset(
                                  "lib/assets/right_arrow_circle_border.png",
                                  width: 28,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );

                  // archived and todo
                  if (widget.type == Categories.todo &&
                      widget.archived == false) {
                    // move to todo
                    if (widget.completed == true) {
                      dropDownOptions.add(
                        Material(
                          color: Colors.transparent,
                          child: MouseRegion(
                            onEnter: (_) {
                              setStateOverlay(() {
                                hoveringOver = todo;
                              });
                            },
                            onExit: (_) {
                              setStateOverlay(() {
                                if (hoveringOver == todo) {
                                  hoveringOver = "";
                                }
                              });
                            },
                            child: GestureDetector(
                              onTap: () {
                                (widget.toggleCompleted as Function)(
                                  widget.messageId,
                                );
                                _closeDropdown();
                              },
                              child: Container(
                                width: 300,
                                padding: EdgeInsets.only(
                                  top: 5 + 5,
                                  left: 10 + 5,
                                  bottom: 5 + 5,
                                  right: 10 + 5,
                                ),
                                decoration: BoxDecoration(
                                  gradient:
                                      ((hoveringOver == todo) ||
                                              (Platform.isAndroid ||
                                                  Platform.isIOS))
                                          ? categoriesAndGradients[todo]
                                          : null,
                                  border: Border.all(color: Colors.white),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  spacing: 10,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        todo,
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontFamily: "Roboto",
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Image.asset(
                                      "lib/assets/right_arrow_circle_border.png",
                                      width: 28,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    // move to complete
                    else {
                      dropDownOptions.add(
                        Material(
                          color: Colors.transparent,
                          child: MouseRegion(
                            onEnter: (_) {
                              setStateOverlay(() {
                                hoveringOver = complete;
                              });
                            },
                            onExit: (_) {
                              setStateOverlay(() {
                                if (hoveringOver == complete) {
                                  hoveringOver = "";
                                }
                              });
                            },
                            child: GestureDetector(
                              onTap: () {
                                if (widget.type == Categories.todo) {
                                  (widget.toggleCompleted as Function)(
                                    widget.messageId,
                                  );
                                }
                                _closeDropdown();
                              },
                              child: Container(
                                width: 300,
                                padding: EdgeInsets.only(
                                  top: 5 + 5,
                                  left: 10 + 5,
                                  bottom: 5 + 5,
                                  right: 10 + 5,
                                ),
                                decoration: BoxDecoration(
                                  gradient:
                                      ((hoveringOver == complete) ||
                                              (Platform.isAndroid ||
                                                  Platform.isIOS))
                                          ? categoriesAndGradients[complete]
                                          : null,
                                  border: Border.all(color: Colors.white),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  spacing: 10,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        complete,
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontFamily: "Roboto",
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Image.asset(
                                      "lib/assets/right_arrow_circle_border.png",
                                      width: 28,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                  }

                  // archive and unarchive
                  if (widget.archived == true) {
                    dropDownOptions.add(
                      Material(
                        color: Colors.transparent,
                        child: MouseRegion(
                          onEnter: (_) {
                            setStateOverlay(() {
                              hoveringOver = archive;
                            });
                          },
                          onExit: (_) {
                            setStateOverlay(() {
                              if (hoveringOver == archive) {
                                hoveringOver = "";
                              }
                            });
                          },
                          child: GestureDetector(
                            onTap: () {
                              widget.toggleArchived(widget.messageId);
                              _closeDropdown();
                            },
                            child: Container(
                              width: 300,
                              padding: EdgeInsets.only(
                                top: 5 + 5,
                                left: 10 + 5,
                                bottom: 5 + 5,
                                right: 10 + 5,
                              ),
                              decoration: BoxDecoration(
                                gradient:
                                    ((hoveringOver == archive) ||
                                            (Platform.isAndroid ||
                                                Platform.isIOS))
                                        ? categoriesAndGradients[archive]
                                        : null,
                                border: Border.all(color: Colors.white),
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(10),
                                  bottomRight: Radius.circular(10),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                spacing: 10,
                                children: [
                                  Expanded(
                                    child: Text(
                                      (widget.type == Categories.todo)
                                          ? ((widget.completed as bool)
                                              ? "Complete"
                                              : "todo")
                                          : widget.type,
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontFamily: "Roboto",
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Image.asset(
                                    "lib/assets/right_arrow_circle_border.png",
                                    width: 28,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  } else {
                    dropDownOptions.add(
                      Material(
                        color: Colors.transparent,
                        child: MouseRegion(
                          onEnter: (_) {
                            setStateOverlay(() {
                              hoveringOver = archive;
                            });
                          },
                          onExit: (_) {
                            setStateOverlay(() {
                              if (hoveringOver == archive) {
                                hoveringOver = "";
                              }
                            });
                          },
                          child: GestureDetector(
                            onTap: () {
                              widget.toggleArchived(widget.messageId);
                              _closeDropdown();
                            },
                            child: Container(
                              width: 300,
                              padding: EdgeInsets.only(
                                top: 5 + 5,
                                left: 10 + 5,
                                bottom: 5 + 5,
                                right: 10 + 5,
                              ),
                              decoration: BoxDecoration(
                                gradient:
                                    ((hoveringOver == archive) ||
                                            (Platform.isAndroid ||
                                                Platform.isIOS))
                                        ? categoriesAndGradients[archive]
                                        : null,
                                border: Border.all(color: Colors.white),
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(10),
                                  bottomRight: Radius.circular(10),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                spacing: 10,
                                children: [
                                  Expanded(
                                    child: Text(
                                      archive,
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontFamily: "Roboto",
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Image.asset(
                                    "lib/assets/right_arrow_circle_border.png",
                                    width: 28,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFE0E0E0), // light gray
                            Color(0xFF5E81AC), // bluish gradient
                          ],
                        ),
                      ),
                      child: Column(children: dropDownOptions),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: Container(
          color: Colors.transparent,
          child: Image.asset(
            "lib/assets/down_arrow_circle_border_grey.png",
            width: 30,
          ),
        ),
      ),
    );
  }
}

class UsersMenu extends StatefulWidget {
  final List<User> users;
  final String userSelected;
  final Function setUserSelected;
  final Map<String, int> mailCountList;
  const UsersMenu({
    super.key,
    required this.users,
    required this.userSelected,
    required this.setUserSelected,
    required this.mailCountList,
  });

  @override
  State<UsersMenu> createState() => _UsersMenuState();
}

class _UsersMenuState extends State<UsersMenu> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    List<Widget> menuItemUsers = List.empty(growable: true);
    for (int i = 0; i < widget.users.length - 1; i++) {
      menuItemUsers.add(
        MenuItem(
          userSelected: widget.userSelected,
          itemName: widget.users[i].name as String,
          setUserSelected: widget.setUserSelected,
          colorId: widget.users[i].colorId,
          mailCountList: widget.mailCountList,
        ),
      );
    }
    if (widget.users.isNotEmpty) {
      menuItemUsers.add(
        MenuItem(
          userSelected: widget.userSelected,
          itemName: widget.users[widget.users.length - 1].name as String,
          setUserSelected: widget.setUserSelected,
          colorId: widget.users[widget.users.length - 1].colorId,
          mailCountList: widget.mailCountList,
          lastItem: true,
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      spacing: 5,
      children: [
        Row(
          children: [
            MenuItem(
              itemName: "all",
              userSelected: widget.userSelected,
              setUserSelected: widget.setUserSelected,
              mailCountList: widget.mailCountList,
            ),
            Container(
              height: 61,
              width: 220,
              alignment: Alignment(0, 0),
              child: Listener(
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) {
                    final double scrollSpeedFactor = 0.25; // 👈 Lower = Slower
                    final double newOffset =
                        _scrollController.offset +
                        event.scrollDelta.dy * scrollSpeedFactor;

                    // Clamp to avoid overscroll
                    final maxScroll =
                        _scrollController.position.maxScrollExtent;
                    final minScroll =
                        _scrollController.position.minScrollExtent;

                    _scrollController.jumpTo(
                      newOffset.clamp(minScroll, maxScroll),
                    );
                  }
                },
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  controller: _scrollController,
                  children: menuItemUsers,
                ),
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            if (mounted) {
              setState(() {});
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.popAndPushNamed(context, Routes.addUser);
              });
            }
          },
          child: Image.asset("lib/assets/add_dashed_border.png", width: 25),
        ),
      ],
    );
  }
}

class MenuItem extends StatelessWidget {
  final bool lastItem;
  final String itemName;
  final Function setUserSelected;
  final int colorId;
  final String userSelected;
  final Map<String, int> mailCountList;
  const MenuItem({
    super.key,
    this.lastItem = false,
    required this.itemName,
    required this.setUserSelected,
    required this.userSelected,
    required this.mailCountList,
    this.colorId = 10,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = (userSelected == itemName);

    return GestureDetector(
      onTap: () {
        setUserSelected(itemName);
      },
      child: Container(
        margin: EdgeInsets.only(top: 5, bottom: 5, right: ((lastItem) ? 0 : 5)),
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.all(Radius.circular(100)),
                ),
                child: Row(
                  spacing: 10,
                  children: [
                    Text(
                      itemName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment(0, 0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(100)),
                        border: Border.all(color: Colors.white),
                        color: colorList[colorId],
                      ),
                      child: Text(
                        numberOfMails(mailCountList[itemName]),
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 2,
                margin: EdgeInsets.only(left: 10, right: 10, top: 5),
                color: (isSelected) ? colorList[colorId] : Colors.transparent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoriesDropDown extends StatefulWidget {
  final String categorySelected;
  final Function setCategorySelected;
  final Map<String, int> mailCountList;
  const CategoriesDropDown({
    super.key,
    required this.categorySelected,
    required this.setCategorySelected,
    required this.mailCountList,
  });

  @override
  State<CategoriesDropDown> createState() => _CategoriesDropDownState();
}

class _CategoriesDropDownState extends State<CategoriesDropDown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isDropdownOpen = false;

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    if (mounted) {
      setState(() {
        _isDropdownOpen = true;
      });
    }
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {
        _isDropdownOpen = false;
      });
    }
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Size size = renderBox.size;
    Offset offset = renderBox.localToGlobal(Offset.zero);

    final screenSize = MediaQuery.of(context).size;
    const dropdownHeight = 124;
    const dropdownWidth = 200;

    // Vertical space calculations
    final spaceBelow = screenSize.height - (offset.dy + size.height);
    final spaceAbove = offset.dy;
    final openAbove =
        spaceBelow < dropdownHeight && spaceAbove > dropdownHeight;

    // Horizontal space calculations
    final spaceRight = screenSize.width - offset.dx;
    final shiftLeft = spaceRight < dropdownWidth;

    final dx =
        shiftLeft
            ? (offset.dx + size.width - dropdownWidth).clamp(
              0.0,
              screenSize.width - dropdownWidth,
            )
            : offset.dx;
    final dy =
        openAbove
            ? offset.dy - dropdownHeight - 5
            : offset.dy + size.height + 5;

    String hoveringOver = "";

    List<String> categoriesExcSelected = List.empty(growable: true);
    for (int i = 0; i < categories.length; i++) {
      if (categories[i] != widget.categorySelected) {
        categoriesExcSelected.add(categories[i]);
      }
    }

    return OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Closer
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeDropdown,
                behavior: HitTestBehavior.translucent,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color:
                      (Platform.isAndroid || Platform.isIOS)
                          ? Colors.black38
                          : Colors.transparent,
                ),
              ),
            ),
            // Dropdown
            Positioned(
              left: dx,
              top: dy + ((openAbove) ? 58 : -58),
              child: StatefulBuilder(
                builder: (context, setStateOverlay) {
                  List<Widget> dropDownOptions = List.empty(growable: true);

                  dropDownOptions.add(
                    Material(
                      color: Colors.transparent,
                      child: MouseRegion(
                        onEnter: (_) {
                          setStateOverlay(() {
                            hoveringOver = widget.categorySelected;
                          });
                        },
                        onExit: (_) {
                          setStateOverlay(() {
                            if (hoveringOver == widget.categorySelected) {
                              hoveringOver = "";
                            }
                          });
                        },
                        child: GestureDetector(
                          onTap: () {
                            widget.setCategorySelected(widget.categorySelected);
                            _closeDropdown();
                          },
                          child: Container(
                            width: 300,
                            padding: EdgeInsets.only(
                              top: 5 + 5,
                              left: 10 + 5,
                              bottom: 5 + 5,
                              right: 10 + 5,
                            ),
                            decoration: BoxDecoration(
                              gradient:
                                  ((hoveringOver == widget.categorySelected) ||
                                          (Platform.isAndroid ||
                                              Platform.isIOS))
                                      ? categoriesAndGradients[widget
                                          .categorySelected]
                                      : null,
                              border: Border.all(color: Colors.white),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              spacing: 10,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.categorySelected.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontFamily: "Roboto",
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 28,
                                  height: 28,
                                  alignment: Alignment(0, 0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: Colors.black),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(100),
                                    ),
                                  ),
                                  child: Text(
                                    numberOfMails(
                                      widget.mailCountList[widget
                                          .categorySelected],
                                    ),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ),
                                Image.asset(
                                  "lib/assets/right_arrow_circle_border.png",
                                  width: 28,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                  for (int i = 0; i < categoriesExcSelected.length - 1; i++) {
                    dropDownOptions.add(
                      Material(
                        color: Colors.transparent,
                        child: MouseRegion(
                          onEnter: (_) {
                            setStateOverlay(() {
                              hoveringOver = categoriesExcSelected[i];
                            });
                          },
                          onExit: (_) {
                            setStateOverlay(() {
                              if (hoveringOver == categoriesExcSelected[i]) {
                                hoveringOver = "";
                              }
                            });
                          },
                          child: GestureDetector(
                            onTap: () {
                              widget.setCategorySelected(
                                categoriesExcSelected[i],
                              );
                              _closeDropdown();
                            },
                            child: Container(
                              width: 300,
                              padding: EdgeInsets.only(
                                top: 5 + 5,
                                left: 10 + 5,
                                bottom: 5 + 5,
                                right: 10 + 5,
                              ),
                              decoration: BoxDecoration(
                                gradient:
                                    ((hoveringOver ==
                                                categoriesExcSelected[i]) ||
                                            (Platform.isAndroid ||
                                                Platform.isIOS))
                                        ? categoriesAndGradients[categoriesExcSelected[i]]
                                        : null,
                                border: Border.all(color: Colors.white),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                spacing: 10,
                                children: [
                                  Expanded(
                                    child: Text(
                                      categoriesExcSelected[i].toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontFamily: "Roboto",
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 28,
                                    height: 28,
                                    alignment: Alignment(0, 0),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: Colors.black),
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(100),
                                      ),
                                    ),
                                    child: Text(
                                      numberOfMails(
                                        widget
                                            .mailCountList[categoriesExcSelected[i]],
                                      ),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  Image.asset(
                                    "lib/assets/right_arrow_circle_border.png",
                                    width: 28,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  dropDownOptions.add(
                    Material(
                      color: Colors.transparent,
                      child: MouseRegion(
                        onEnter: (_) {
                          setStateOverlay(() {
                            hoveringOver =
                                categoriesExcSelected[categoriesExcSelected
                                        .length -
                                    1];
                          });
                        },
                        onExit: (_) {
                          setStateOverlay(() {
                            if (hoveringOver ==
                                categoriesExcSelected[categoriesExcSelected
                                        .length -
                                    1]) {
                              hoveringOver = "";
                            }
                          });
                        },
                        child: GestureDetector(
                          onTap: () {
                            widget.setCategorySelected(
                              categoriesExcSelected[categoriesExcSelected
                                      .length -
                                  1],
                            );
                            _closeDropdown();
                          },
                          child: Container(
                            width: 300,
                            padding: EdgeInsets.only(
                              top: 5 + 5,
                              left: 10 + 5,
                              bottom: 5 + 5,
                              right: 10 + 5,
                            ),
                            decoration: BoxDecoration(
                              gradient:
                                  ((hoveringOver ==
                                              categoriesExcSelected[categoriesExcSelected
                                                      .length -
                                                  1]) ||
                                          (Platform.isAndroid ||
                                              Platform.isIOS))
                                      ? categoriesAndGradients[categoriesExcSelected[categoriesExcSelected
                                              .length -
                                          1]]
                                      : null,
                              border: Border.all(color: Colors.white),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                              ),
                            ),
                            child: Row(
                              spacing: 10,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    categoriesExcSelected[categoriesExcSelected
                                                .length -
                                            1]
                                        .toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontFamily: "Roboto",
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 28,
                                  height: 28,
                                  alignment: Alignment(0, 0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(100),
                                    ),
                                    color: Colors.white,
                                    border: Border.all(color: Colors.black),
                                  ),
                                  child: Text(
                                    numberOfMails(
                                      widget
                                          .mailCountList[categoriesExcSelected[categoriesExcSelected
                                              .length -
                                          1]],
                                    ),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ),
                                Image.asset(
                                  "lib/assets/right_arrow_circle_border.png",
                                  width: 28,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );

                  return ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFE0E0E0), // light gray
                            Color(0xFF5E81AC), // bluish gradient
                          ],
                        ),
                      ),
                      child: Column(children: dropDownOptions),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: Container(
          color: Colors.transparent,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 5,
            children: [
              Text(
                widget.categorySelected.toUpperCase(),
                style: TextStyle(
                  fontFamily: "Roboto",
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 25,
                ),
              ),
              Container(
                width: 25,
                height: 25,
                alignment: Alignment(0, 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(50)),
                  color: Colors.white,
                  border: Border.all(color: Colors.black),
                ),
                child: Text(
                  numberOfMails(widget.mailCountList[widget.categorySelected]),
                  style: TextStyle(
                    fontFamily: "Roboto",
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 10,
                  ),
                ),
              ),
              Image.asset("lib/assets/down_arrow_circle_border.png", width: 30),
            ],
          ),
        ),
      ),
    );
  }
}

String numberOfMails(Object? count) {
  if (count == null) {
    return "0";
  } else {
    return "$count";
  }
}
