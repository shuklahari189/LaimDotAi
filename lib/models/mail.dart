import 'package:isar/isar.dart';
part 'parts/mail.g.dart';

@collection
class Mail {
  Id id = Isar.autoIncrement;
  String? type;
  String? body;
  String? senderName;
  String? senderEmail;
  String? messageId;
  DateTime? timeReceived;
  String? forName;
  bool? archived;
  // for todo's
  DateTime? dueDate;
  bool? completed;
  Mail(
    this.type,
    this.body,
    this.senderName,
    this.senderEmail,
    this.messageId,
    this.timeReceived,
    this.forName,
    this.archived,
    this.dueDate,
    this.completed,
  );
}
