import 'package:intl/intl.dart';

DateTime? dateFromString(String? dateStr) {
  if (dateStr != null) {
    String formattedDate = dateStr
        .replaceFirst(RegExp(r"^[A-Za-z]+, "), "") // Remove day of the week
        .replaceAll(
          RegExp(r"\s\([A-Za-z]+\)$"),
          "",
        ) // Remove the timezone abbreviation
        // Step 2: Reformat the date from "22 Apr 2025" to "2025-04-22"
        .replaceFirstMapped(RegExp(r"(\d{2}) (\w{3}) (\d{4})"), (match) {
          // Convert month abbreviation to month number
          Map<String, String> monthMap = {
            'Jan': '01',
            'Feb': '02',
            'Mar': '03',
            'Apr': '04',
            'May': '05',
            'Jun': '06',
            'Jul': '07',
            'Aug': '08',
            'Sep': '09',
            'Oct': '10',
            'Nov': '11',
            'Dec': '12',
          };
          String monthNumber = monthMap[match[2]]!;
          return "${match[3]}-$monthNumber-${match[1]}"; // "2025-04-22"
        })
        // Step 3: Format the time zone to "-07:00"
        .replaceAllMapped(RegExp(r"(\d{2})(\d{2})$"), (match) {
          return "${match[1]}:${match[2]}"; // Convert "-0700" to "-07:00"
        })
        // Step 4: Add the "T" separator between date and time
        .replaceFirst(" ", "T");

    // 🛠 Fix: Handle GMT
    formattedDate = formattedDate.replaceAll("GMT", "+00:00");

    try {
      DateTime dateTime = DateTime.parse(formattedDate);
      // print("correctly parsed date string is [$formattedDate]");
      return dateTime;
    } catch (e) {
      // print(
      //   "Error occurred while converting date str to datetime, date string is [$formattedDate]",
      // );
    }
  }
  print("hii got null date");
  return null;
}

Map<String, String> formatDateTime(DateTime dateTime) {
  // Format date like "may 20, 2025"
  final dateFormatter = DateFormat('MMMM d, yyyy');
  String dateStr = dateFormatter.format(dateTime).toLowerCase();

  // Format time like "10: 40 am"
  final timeFormatter = DateFormat('h: mm a');
  String timeStr = timeFormatter.format(dateTime).toLowerCase();

  return {'date': dateStr, 'time': timeStr};
}
