// class User {
//   final String username;
//   final String name;

//   User({required this.username, required this.name});

//   factory User.Json(Map<String, dynamic> json) {
//     return User(
//       username: json['username'],
//       name: json['name'],
//     );
//   }
// }

class User {
  final String username;
  final String name;
  final String flat;

  User({required this.username, required this.name, required this.flat});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      flat: json['flat'] ?? '',
    );
  }
}
