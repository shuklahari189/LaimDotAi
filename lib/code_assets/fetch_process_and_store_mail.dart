import 'package:laim_ai/code_assets/categories.dart';
import 'package:isar/isar.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:laim_ai/models/mail.dart';
import 'package:laim_ai/code_assets/dates_and_strings.dart';

class FPSMail {
  static Future<void> run(Isar isar, String? name, String? refreshToken) async {
    String accessToken = await getAccessToken(refreshToken);
    Map<String, dynamic> data = await fetchMessageIds(accessToken);

    final mails =
        await isar.mails.filter().forNameEqualTo(name?.toLowerCase()).findAll();
    for (var message in data["messages"]) {
      bool exists = mails.any((m) => m.messageId == message["id"]);

      final addTodoToBackendResponse = await http.post(
        Uri.parse('${dotenv.env["BACKEND_API"]}/todo/messageIdExists'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"messageId": message["id"]}),
      );

      bool existsInBackend = (addTodoToBackendResponse.body == "yes");

      if (!exists && !existsInBackend) {
        // Fetch full mail
        Map<String, dynamic> mail = await fetchMail(accessToken, message["id"]);

        String? encodedBody;
        String fullBodyText = '';

        // Check if direct body exists
        if (mail["payload"]?["body"]?["data"] != null) {
          encodedBody = mail["payload"]["body"]["data"];
        }
        // Or maybe in parts[0]
        else if (mail["payload"]?["parts"] != null &&
            mail["payload"]["parts"].isNotEmpty &&
            mail["payload"]["parts"][0]?["body"]?["data"] != null) {
          encodedBody = mail["payload"]["parts"][0]["body"]["data"];
        }

        if (encodedBody != null) {
          // Normalize base64url string (add missing padding if needed)
          String normalized = encodedBody.padRight(
            (encodedBody.length + 3) ~/ 4 * 4,
            '=',
          );
          String decoded = utf8.decode(base64Url.decode(normalized));

          // Parse HTML
          final parsed = html_parser.parse(decoded);
          fullBodyText = parsed.body?.text.trim() ?? '';
        }

        // Get sender name and email
        String senderName = '';
        String senderEmail = '';
        if (mail["payload"]?["headers"] != null) {
          for (var header in mail["payload"]["headers"]) {
            if (header["name"] == "From") {
              final fromValue = header["value"];
              final match = RegExp(r'(.*)<(.*)>').firstMatch(fromValue);
              if (match != null) {
                senderName = match.group(1)?.trim() ?? '';
                senderEmail = match.group(2)?.trim() ?? '';
              } else {
                senderEmail = fromValue.trim();
              }
            }
          }
        }

        // Get subject
        String subject = '';
        if (mail["payload"]?["headers"] != null) {
          for (var header in mail["payload"]["headers"]) {
            if (header["name"] == "Subject") {
              subject = header["value"] ?? '';
            }
          }
        }

        // Get date
        String date = '';
        if (mail["payload"]?["headers"] != null) {
          for (var header in mail["payload"]["headers"]) {
            if (header["name"] == "Date") {
              date = header["value"] ?? '';
            }
          }
        }

        DateTime? dateOfMessage = dateFromString(date);

        final processedMail = await processMail(
          fullBodyText,
          senderName,
          senderEmail,
          subject,
          date,
        );

        // print("proceesing");
        // print(processedMail?["type"]);

        if (processedMail?["type"] == Categories.todo &&
            processedMail != null) {
          final addTodoToBackendResponse = await http.post(
            Uri.parse('${dotenv.env["BACKEND_API"]}/todo/addTodo'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "messageId": message["id"],
              "forName": name?.toLowerCase(),
              "senderName": senderName,
              "senderEmail": senderEmail,
              "type": Categories.todo,
              "body": processedMail["body"],
              "timeReceived": dateOfMessage.toString(),
              "archived": false,
              "completed": false,
              "dueDate": dateFromString(processedMail["dueDate"]).toString(),
            }),
          );
          final Map<String, dynamic> addTodoToBackendResponseData = jsonDecode(
            addTodoToBackendResponse.body,
          );
          addTodoToBackendResponseData;
        } else if (processedMail != null) {
          Mail mailToBeInserted = Mail(
            processedMail["type"],
            processedMail["body"],
            senderName,
            senderEmail,
            message["id"],
            dateOfMessage,
            name,
            false,
            dateFromString(processedMail["dueDate"]),
            false,
          );
          await isar.writeTxn(() => isar.mails.put(mailToBeInserted));
        }
        // print("done");
      }
    }
  }

  static Future<Map<String, dynamic>?> processMail(
    String? fullBodyText,
    String? senderName,
    String? senderEmail,
    String? subject,
    String? date,
  ) async {
    final payload = {
      "model": "gpt-4.1",
      "messages": [
        {
          "role": "system",
          "content":
              "You are an assistant designed to convert emails into concise, actionable todo tasks or important messages. Follow these instructions carefully:\n\nIgnore and discard any emails that are spam, advertisements, newsletters, automated messages without actionable or important informational content, or general information without tasks or relevant messages. Even if there are some actionable tasks or messages, make sure they are not promotional and that they are genuine.\n\nIdentify and extract actionable tasks or requests explicitly stated or clearly implied by the email sender. Ignore broad campaigns, public calls for nominations, surveys, or any content that appears promotional, even if it contains a link to take action.\n\nEmails should only be passed through if the user is being asked to do something specifically directed at them, and the task is non-promotional, time-sensitive, or consequential.\n\nAdditionally, identify important messages that, while not requiring explicit immediate action, contain critical information the user should be aware of (e.g., price increases, service disruptions, policy changes).\n\nFor each actionable task identified, clearly summarize it into a concise todo statement.\nFor each important message, clearly summarize the information as a message.\n\nInclude essential details necessary to complete each task or understand each message within the clear task summary, such as:\n- Action to perform (e.g., 'Call,' 'Email,' 'Submit report') for tasks\n- Person or entity involved (include names, titles, or roles clearly mentioned)\n- Relevant dates and deadlines (explicit or implicit)\n- Important context, locations, or references explicitly provided in the email.\n\nDo NOT include general instructions, safety housekeeping, or routine policies unless they are unique to the user's case or require acknowledgment.\nOnly create a MESSAGE if the information is critical, not already included in a TO-DO, and requires the user's awareness independently.\nDo NOT generate a MESSAGE for supporting context, links, or documents that are already captured inside a TO-DO.\nConsolidate everything into a single TO-DO when appropriate.\nIf multiple tasks or messages are present, list them clearly and separately.\n\n(IMPORTANT) YOUR OUTPUT SHOULD ONLY BE JSON OBJECT FOLLOWING THESE RULES AND SHOULD ONLY BE ONE OF THE FOLLOWING (as we will json parse your output directly):\n- For to-do: { type: 'todo', body: <summary>, action: <action>, dueDate: <date or null> }\n- For message: { type: 'message', body: <summary> }\n- For promotions: { type: 'promotion', body: <summary> }\n- If no actionable task or notification is found: { type: 'empty', body: 'NO ACTIONABLE TASK OR IMPORTANT MESSAGE FOUND' }",
        },
        {
          "role": "user",
          "content":
              "Below is the email to process:\n\nsender_name: $senderName\nsender_mail: $senderEmail\nmail_subject: $subject\nfull_body_text: $fullBodyText\ntime_received: $date",
        },
      ],
    };

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        "Authorization": "Bearer ${dotenv.env["OPENAI_SECRET"]}",
        "Content-Type": "application/json",
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final messageContent = data['choices'][0]['message']['content'];
      final parsed = jsonDecode(messageContent);

      return parsed;
    } else {
      return null;
    }
  }

  static Future<Map<String, dynamic>> fetchMail(
    String? accessToken,
    String? messageId,
  ) async {
    final response = await http.get(
      Uri.parse(
        'https://gmail.googleapis.com/gmail/v1/users/me/messages/$messageId',
      ),
      headers: {"Authorization": "Bearer $accessToken"},
    );
    final Map<String, dynamic> data = jsonDecode(response.body);
    return data;
  }

  static Future<Map<String, dynamic>> fetchMessageIds(
    String? accessToken,
  ) async {
    final response = await http.get(
      Uri.parse(
        'https://www.googleapis.com/gmail/v1/users/me/messages?maxResults=10&q=category:primary',
      ),
      headers: {"Authorization": "Bearer $accessToken"},
    );
    final Map<String, dynamic> data = jsonDecode(response.body);
    return data;
  }

  static Future<String> getAccessToken(String? refreshToken) async {
    final response = await http.post(
      Uri.parse('https://oauth2.googleapis.com/token'),
      body: {
        "client_id": dotenv.env["GOOGLE_CLIENT_ID"],
        "client_secret": dotenv.env["GOOGLE_CLIENT_SECRET"],
        "refresh_token": refreshToken,
        "grant_type": "refresh_token",
      },
    );
    final Map<String, dynamic> data = jsonDecode(response.body);
    return data["access_token"];
  }
}
