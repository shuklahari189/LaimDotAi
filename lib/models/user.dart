import 'package:isar/isar.dart';
part 'parts/user.g.dart';

@collection
class User {
  Id id = Isar.autoIncrement;
  String? name;
  String? refreshToken;
  String? parentName;
  User(this.name, this.refreshToken, this.parentName);
}
